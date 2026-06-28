#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "ruamel.yaml",
# ]
# ///
"""
clangd_suppress.py - clangd 에러를 자동으로 .clangd에 반영

사용법:
  clangd_suppress.py mm/cma.c
  clangd_suppress.py drivers/gpu/drm/drm_drv.c
  clangd_suppress.py --scan   # compile_commands.json의 모든 파일 검사
  clangd_suppress.py --dry-run mm/cma.c
"""

import argparse
import json
import platform
import re
import subprocess
import sys
from pathlib import Path

from ruamel.yaml import YAML


def find_repo_root() -> Path:
    """CWD에서 상위로 올라가며 compile_commands.json 또는 .git이 있는 디렉토리를 반환"""
    for directory in [Path.cwd(), *Path.cwd().parents]:
        if (directory / "compile_commands.json").exists():
            return directory
        if (directory / ".git").exists():
            return directory
    print("오류: compile_commands.json 또는 .git 디렉토리를 찾을 수 없습니다.", file=sys.stderr)
    sys.exit(1)


REPO_ROOT = find_repo_root()
CLANGD_CONFIG = REPO_ROOT / ".clangd"
CLANGD_BIN = "clangd"


def is_linux_kernel_repo() -> bool:
    """현재 저장소가 리눅스 커널 저장소인지 확인 (Kbuild 및 Kconfig 존재 여부)"""
    return (REPO_ROOT / "Kbuild").exists() and (REPO_ROOT / "Kconfig").exists()

# GCC 전용 플래그 목록 (clangd가 인식하지 못하는 플래그)
GCC_ONLY_FLAGS = [
    # GCC 전용 최적화/코드생성 플래그
    "-fno-allow-store-data-races",
    "-fconserve-stack",
    "-fno-var-tracking",
    "-femit-struct-debug-baseonly",
    "-fno-stack-clash-protection",
    # GCC 전용 경고 플래그
    "-Wno-alloc-size-larger-than",
    "-Wno-stringop-overflow",
    "-Wno-stringop-truncation",
    "-Wno-override-init",
    "-Wno-packed-not-aligned",
    "-Wno-maybe-uninitialized",
    "-Wno-dangling-pointer",
    "-Wno-format-overflow",
    "-Wno-format-truncation",
    # ABI 플래그: clangd가 타겟 없이 처리 불가 (macOS/네이티브 컴파일러 환경)
    "-mabi=*",
    # AArch64 GCC 전용 플래그 (glob 패턴)
    "-mstack-protector-guard=*",
    "-mstack-protector-guard-reg=*",
    # Assembler 플래그 (clangd 불필요)
    "-Wa,*",
]

# Linux 아키텍처 include 경로 → clangd --target triple 매핑
ARCH_TARGET_MAP = {
    "arch/arm64":    "aarch64-linux-gnu",
    "arch/arm":      "arm-linux-gnueabi",
    "arch/x86":      "x86_64-linux-gnu",
    "arch/riscv":    "riscv64-linux-gnu",
    "arch/mips":     "mips-linux-gnu",
    "arch/powerpc":  "powerpc64le-linux-gnu",
    "arch/loongarch": "loongarch64-linux-gnu",
    "arch/s390":     "s390x-linux-gnu",
}




# ── 타겟 감지 ────────────────────────────────────────────────────────────────

def detect_target_from_cdb() -> str | None:
    """compile_commands.json에서 Linux 크로스 컴파일 타겟 triple을 추론.

    컴파일러 이름에 타겟 prefix(aarch64-linux-gnu-gcc 등)가 있으면
    이미 타겟이 지정된 것으로 보고 None을 반환한다.
    그렇지 않으면 -I 경로에서 arch/* 패턴으로 아키텍처를 감지한다.
    처음 N개 항목은 호스트 툴(scripts/dtc 등)일 수 있으므로
    아키텍처 경로를 찾을 때까지 최대 MAX_SCAN_ENTRIES개를 순회한다.

    Returns:
        타겟 triple 문자열 또는 None (오버라이드 불필요 시)
    """
    MAX_SCAN_ENTRIES = 200

    cdb_path = REPO_ROOT / "compile_commands.json"
    if not cdb_path.exists():
        return None
    try:
        entries = json.loads(cdb_path.read_text())
    except json.JSONDecodeError:
        return None

    for entry in entries[:MAX_SCAN_ENTRIES]:
        try:
            args: list[str] = entry.get("arguments", [])
            if not args:
                args = entry.get("command", "").split()
        except (KeyError, AttributeError):
            continue

        if not args:
            continue

        # 컴파일러에 이미 타겟 prefix가 있으면 오버라이드 불필요
        compiler_name = Path(args[0]).name
        if "-linux-" in compiler_name or "-elf-" in compiler_name:
            return None

        # include 경로(-I)에서 아키텍처 감지
        for arg in args:
            for arch_path, target in ARCH_TARGET_MAP.items():
                if arch_path in arg:
                    return target

    return None


# ── YAML 다중 문서 로드/저장 헬퍼 ───────────────────────────────

def load_clangd_docs() -> list[dict]:
    """현재 .clangd의 다중 YAML 문서 목록 로드"""
    if not CLANGD_CONFIG.exists():
        return [{}]
    yaml = YAML()
    try:
        with open(CLANGD_CONFIG, "r", encoding="utf-8") as f:
            docs = list(yaml.load_all(f))
        return docs if docs else [{}]
    except Exception:
        return [{}]


def save_clangd_docs(docs: list[dict]) -> None:
    """다중 YAML 문서 목록을 .clangd에 저장"""
    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)
    with open(CLANGD_CONFIG, "w", encoding="utf-8") as f:
        yaml.dump_all(docs, f)


# ── CompileFlags.Add ─────────────────────────────────────────────────────────

def get_existing_add_flags() -> set[str]:
    """현재 .clangd의 CompileFlags.Add 목록 추출 (글로벌 설정 기준)"""
    docs = load_clangd_docs()
    data = docs[0]
    add_list = data.get("CompileFlags", {}).get("Add", [])
    if isinstance(add_list, str):
        return {add_list}
    return set(add_list) if add_list else set()


def add_compile_add_flags(new_flags: set[str]) -> None:
    """새 플래그를 .clangd CompileFlags.Add 섹션에 추가 (글로벌 설정 기준)"""
    docs = load_clangd_docs()
    data = docs[0]

    if "CompileFlags" not in data or data["CompileFlags"] is None:
        data["CompileFlags"] = {}

    existing_add = data["CompileFlags"].get("Add", [])
    if isinstance(existing_add, str):
        existing_add = [existing_add]
    elif existing_add is None:
        existing_add = []

    updated = sorted(list(set(existing_add) | new_flags))
    data["CompileFlags"]["Add"] = updated
    save_clangd_docs(docs)


# ── CompileFlags.Remove ──────────────────────────────────────────────────────

def get_existing_remove_flags() -> set[str]:
    """현재 .clangd의 CompileFlags.Remove 목록 추출"""
    docs = load_clangd_docs()
    data = docs[0]
    remove_list = data.get("CompileFlags", {}).get("Remove", [])
    if isinstance(remove_list, str):
        return {remove_list}
    return set(remove_list) if remove_list else set()


def add_remove_flags(new_flags: set[str]) -> None:
    """새 플래그를 .clangd CompileFlags.Remove 섹션에 추가"""
    docs = load_clangd_docs()
    data = docs[0]

    if "CompileFlags" not in data or data["CompileFlags"] is None:
        data["CompileFlags"] = {}

    existing_remove = data["CompileFlags"].get("Remove", [])
    if isinstance(existing_remove, str):
        existing_remove = [existing_remove]
    elif existing_remove is None:
        existing_remove = []

    updated = sorted(list(set(existing_remove) | new_flags))
    data["CompileFlags"]["Remove"] = updated
    save_clangd_docs(docs)


# ── Diagnostics.Suppress ────────────────────────────────────────────────────

def get_existing_suppressions() -> set[str]:
    """현재 .clangd에서 Suppress 목록 추출"""
    docs = load_clangd_docs()
    data = docs[0]
    suppress_list = data.get("Diagnostics", {}).get("Suppress", [])
    if isinstance(suppress_list, str):
        return {suppress_list}
    return set(suppress_list) if suppress_list else set()


def add_suppressions(new_ids: set[str]) -> None:
    """새 ID를 .clangd Suppress 섹션에 추가"""
    docs = load_clangd_docs()
    data = docs[0]

    if "Diagnostics" not in data or data["Diagnostics"] is None:
        data["Diagnostics"] = {}

    existing_suppress = data["Diagnostics"].get("Suppress", [])
    if isinstance(existing_suppress, str):
        existing_suppress = [existing_suppress]
    elif existing_suppress is None:
        existing_suppress = []

    updated = sorted(list(set(existing_suppress) | new_ids))
    data["Diagnostics"]["Suppress"] = updated
    save_clangd_docs(docs)


# ── Tweak.Remove ────────────────────────────────────────────────────────────

def get_existing_remove_tweaks() -> set[str]:
    """현재 .clangd의 Tweak.Remove 목록 추출"""
    docs = load_clangd_docs()
    data = docs[0]
    remove_list = data.get("Tweak", {}).get("Remove", [])
    if isinstance(remove_list, str):
        return {remove_list}
    return set(remove_list) if remove_list else set()


def add_remove_tweaks(new_tweaks: set[str]) -> None:
    """새 Tweak을 .clangd Tweak.Remove 섹션에 추가"""
    docs = load_clangd_docs()
    data = docs[0]

    if "Tweak" not in data or data["Tweak"] is None:
        data["Tweak"] = {}

    existing_remove = data["Tweak"].get("Remove", [])
    if isinstance(existing_remove, str):
        existing_remove = [existing_remove]
    elif existing_remove is None:
        existing_remove = []

    updated = sorted(list(set(existing_remove) | new_tweaks))
    data["Tweak"]["Remove"] = updated
    save_clangd_docs(docs)


# ── .clangd 초기 생성 및 타겟 보장 ─────────────────────────────────────────

def ensure_clangd_exists() -> None:
    """clangd 설정 파일이 없으면 기본 내용으로 생성."""
    if CLANGD_CONFIG.exists():
        return

    docs = [
        {
            "CompileFlags": {
                "Add": ["-ferror-limit=0"],
                "Remove": sorted(GCC_ONLY_FLAGS)
            }
        }
    ]

    if is_linux_kernel_repo():
        docs.append({
            "If": {
                "PathMatch": [r".*\.h", r".*\.hpp"]
            },
            "CompileFlags": {
                "Add": ["-include=linux/mm.h", "-include=asm/pgtable.h"]
            }
        })

    target = detect_target_from_cdb()
    if target:
        docs[0]["CompileFlags"]["Add"].append(f"--target={target}")
        print(f"타겟 감지: {target} → CompileFlags.Add에 --target 추가")

    save_clangd_docs(docs)
    print(f".clangd 파일 생성 완료 → {CLANGD_CONFIG}")


def ensure_target_in_add_flags(dry_run: bool = False) -> None:
    """기존 .clangd에 --target이 빠져 있으면 보완한다."""
    target = detect_target_from_cdb()
    if not target:
        return

    target_flag = f"--target={target}"
    existing_add = get_existing_add_flags()

    # glob 형태(-mabi=*)를 고려해 prefix 매칭으로 확인
    already_set = any(
        f == target_flag or f.startswith("--target=")
        for f in existing_add
    )
    if already_set:
        return

    print(f"CompileFlags.Add에 {target_flag} 누락 → {'(dry-run) ' if dry_run else ''}추가")
    if not dry_run:
        add_compile_add_flags({target_flag})


def ensure_error_limit_in_add_flags(dry_run: bool = False) -> None:
    """기존 .clangd에 -ferror-limit=0이 빠져 있으면 보완한다."""
    error_limit_flag = "-ferror-limit=0"
    existing_add = get_existing_add_flags()

    if error_limit_flag in existing_add:
        return

    print(f"CompileFlags.Add에 {error_limit_flag} 누락 → {'(dry-run) ' if dry_run else ''}추가")
    if not dry_run:
        add_compile_add_flags({error_limit_flag})


def ensure_default_includes_in_add_flags(dry_run: bool = False) -> None:
    """기존 .clangd의 두 번째 문서(헤더 조건부)에 -include=linux/mm.h 및 -include=asm/pgtable.h가 빠져 있으면 보완한다."""
    docs = load_clangd_docs()

    # [클린업] 혹시 예전 버전의 스크립트 실행으로 첫 번째(글로벌) 문서에 강제 인클루드 찌꺼기가 남아있으면 제거
    global_add = docs[0].get("CompileFlags", {}).get("Add", [])
    if isinstance(global_add, list):
        cleaned_add = [f for f in global_add if not f.startswith("-include=linux/mm.h") and not f.startswith("-include=asm/pgtable.h")]
        if len(cleaned_add) != len(global_add):
            print("글로벌 CompileFlags.Add에서 이전 헤더 강제 인클루드 찌꺼기 제거")
            if not dry_run:
                docs[0]["CompileFlags"]["Add"] = cleaned_add
                save_clangd_docs(docs)

    if not is_linux_kernel_repo():
        return

    default_includes = [
        "-include=linux/mm.h",
        "-include=asm/pgtable.h"
    ]

    # 두 번째 문서(헤더용 설정)가 없으면 추가
    if len(docs) < 2:
        docs.append({
            "If": {
                "PathMatch": [r".*\.h", r".*\.hpp"]
            },
            "CompileFlags": {
                "Add": []
            }
        })

    header_doc = docs[1]
    if "CompileFlags" not in header_doc or header_doc["CompileFlags"] is None:
        header_doc["CompileFlags"] = {}
    if "Add" not in header_doc["CompileFlags"] or header_doc["CompileFlags"]["Add"] is None:
        header_doc["CompileFlags"]["Add"] = []

    existing_includes = header_doc["CompileFlags"]["Add"]
    if isinstance(existing_includes, str):
        existing_includes = [existing_includes]

    missing_includes = sorted(list(set(default_includes) - set(existing_includes)))

    if not missing_includes:
        return

    print(f"헤더 전용 CompileFlags.Add에 {missing_includes} 누락 → {'(dry-run) ' if dry_run else ''}추가")
    if not dry_run:
        header_doc["CompileFlags"]["Add"] = sorted(list(set(existing_includes) | set(default_includes)))
        save_clangd_docs(docs)



# ── clangd --check 실행 ──────────────────────────────────────────────────────

# "unknown target ABI" 또는 "CreateTargetInfo() return null" 발생 시
# --target 오버라이드가 필요함을 나타내는 패턴
_TARGET_ERROR_RE = re.compile(
    r"unknown target ABI|CreateTargetInfo\(\) return null"
)


def check_file(filepath: str) -> tuple[set[str], set[str], set[str], bool]:
    """clangd --check로 에러 ID, unknown 플래그, 실패한 tweak, 타겟 오버라이드 필요 여부를 수집.

    Returns:
        (diagnostic_ids, unknown_flags, failed_tweaks, needs_target_override)
    """
    print(f"  검사 중: {filepath}")
    result = subprocess.run(
        [CLANGD_BIN, f"--check={filepath}", "--log=error"],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    output = result.stderr + result.stdout

    # E[...] [error_id] 패턴 → Diagnostics.Suppress 대상
    diag_ids = set(re.findall(r"E\[.*?\] \[([a-zA-Z0-9_-]+)\]", output))

    # unknown argument / unused argument 패턴 → CompileFlags.Remove 대상
    unknown_flags = set(
        re.findall(r"(?:unknown|unused) argument[:\s]+'([^']+)'", output, re.IGNORECASE)
    )

    # 실패한 tweak 패턴 (tweak: DefineOutline ==> FAIL) → Tweak.Remove 대상
    failed_tweaks = set(
        re.findall(r"tweak:\s*([a-zA-Z0-9_-]+)\s*==>\s*FAIL", output)
    )

    # 타겟 ABI 오류 → CompileFlags.Add에 --target 추가 필요
    needs_target = bool(_TARGET_ERROR_RE.search(output))

    return diag_ids, unknown_flags, failed_tweaks, needs_target


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="clangd 에러를 .clangd에 자동 반영")
    parser.add_argument("files", nargs="*", help="검사할 소스 파일 (REPO_ROOT 기준 상대경로)")
    parser.add_argument("--scan", action="store_true", help="compile_commands.json의 전체 파일 검사")
    parser.add_argument("--dry-run", action="store_true", help="변경 없이 발견된 항목만 출력")
    args = parser.parse_args()

    if not args.files and not args.scan:
        parser.print_help()
        sys.exit(1)

    ensure_clangd_exists()
    # 파일 신규/기존 여부 관계없이 --target 누락 여부를 항상 확인
    ensure_target_in_add_flags(dry_run=args.dry_run)
    ensure_error_limit_in_add_flags(dry_run=args.dry_run)
    ensure_default_includes_in_add_flags(dry_run=args.dry_run)

    files_to_check = list(args.files)

    if args.scan:
        cdb_path = REPO_ROOT / "compile_commands.json"
        if not cdb_path.exists():
            print("compile_commands.json not found", file=sys.stderr)
            sys.exit(1)
        cdb = json.loads(cdb_path.read_text())
        files_to_check = [e["file"] for e in cdb]
        print(f"전체 {len(files_to_check)}개 파일 검사...")

    existing_suppress = get_existing_suppressions()
    existing_remove = get_existing_remove_flags()
    existing_add = get_existing_add_flags()
    existing_remove_tweaks = get_existing_remove_tweaks()
    found_ids: set[str] = set()
    found_flags: set[str] = set()
    found_add_flags: set[str] = set()
    found_tweaks: set[str] = set()

    for f in files_to_check:
        diag_ids, unknown_flags, failed_tweaks, needs_target = check_file(f)

        new_ids = diag_ids - existing_suppress - found_ids
        if new_ids:
            print(f"    새 diagnostic ID 발견: {new_ids}")
            found_ids.update(new_ids)

        new_flags = unknown_flags - existing_remove - found_flags
        if new_flags:
            print(f"    새 unknown 플래그 발견: {new_flags}")
            found_flags.update(new_flags)

        new_tweaks = failed_tweaks - existing_remove_tweaks - found_tweaks
        if new_tweaks:
            print(f"    새 실패한 Tweak 발견: {new_tweaks}")
            found_tweaks.update(new_tweaks)

        if needs_target:
            target = detect_target_from_cdb()
            if target:
                target_flag = f"--target={target}"
                if target_flag not in existing_add and target_flag not in found_add_flags:
                    print(f"    타겟 ABI 오류 감지 → CompileFlags.Add 추가 필요: {target_flag}")
                    found_add_flags.add(target_flag)
            else:
                print(
                    "    경고: 타겟 ABI 오류가 감지됐지만 아키텍처를 자동 감지할 수 없습니다.\n"
                    "    .clangd의 CompileFlags.Add에 --target=<triple>을 수동으로 추가하세요.",
                    file=sys.stderr,
                )

    changed = bool(found_ids or found_flags or found_add_flags or found_tweaks)
    if not changed:
        print("새로 추가할 항목 없음.")
        return

    if found_add_flags:
        print(f"\nCompileFlags.Add에 추가할 플래그:    {sorted(found_add_flags)}")
    if found_flags:
        print(f"CompileFlags.Remove에 추가할 플래그: {sorted(found_flags)}")
    if found_ids:
        print(f"Diagnostics.Suppress에 추가할 ID:   {sorted(found_ids)}")
    if found_tweaks:
        print(f"Tweak.Remove에 추가할 Tweak:         {sorted(found_tweaks)}")

    if args.dry_run:
        print("(dry-run: .clangd 변경 없음)")
        return

    if found_add_flags:
        add_compile_add_flags(found_add_flags)
    if found_flags:
        add_remove_flags(found_flags)
    if found_ids:
        add_suppressions(found_ids)
    if found_tweaks:
        add_remove_tweaks(found_tweaks)

    print(f"\n.clangd 업데이트 완료 → {CLANGD_CONFIG}")
    print("VSCode에서 'clangd: Restart language server'를 실행하세요.")


if __name__ == "__main__":
    main()
