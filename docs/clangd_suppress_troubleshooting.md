# VSCode clangd 경고 억제 실패 트러블슈팅 (`implicit-function-declaration`)

## 1. 개요
VSCode 환경에서 C/C++ 소스 코드를 편집할 때, 정의되지 않은 함수 호출에 대해 `Call to undeclared function 'DEBUG_LOCKS_WARN_ON'; ISO C99 and later do not support implicit function declarations (fix available)clang(-Wimplicit-function-declaration)` 와 같은 경고가 발생하였습니다.
이 경고를 억제하기 위해 `clangd_suppress.py` 스크립트를 사용하여 `.clangd` 파일에 에러 ID를 등록하려 했으나 해당 경고가 잡히지(suppress) 않는 문제가 발생했습니다.

## 2. 원인 분석
`clangd_suppress.py`는 `clangd --check` 명령을 백그라운드에서 실행하고, 출력 결과에서 에러 Diagnostic ID를 정규표현식을 통해 파싱하여 `.clangd` 파일에 추가하는 방식으로 작동합니다.

기존의 파싱부 정규표현식은 다음과 같았습니다:
```python
diag_ids = set(re.findall(r"E\[.*?\] \[([a-zA-Z0-9_]+)\]", output))
```

* `clangd`의 에러 ID에는 하이픈(`-`)이 포함된 형태가 많습니다. (예: `implicit-function-declaration`, `unused-variable` 등)
* 하지만 기존의 문자열 클래스 `[a-zA-Z0-9_]`에는 하이픈(`-`)이 포함되어 있지 않아, `[implicit-function-declaration]` 패턴이 정상적으로 매칭되지 않고 누락되었습니다.
* 이로 인해 `clangd` 경고 억제용 파일인 `.clangd` 내 `Diagnostics.Suppress` 리스트에 에러 ID가 등록되지 못했습니다.

## 3. 해결 조치
`clangd_suppress.py` 파일 내 diagnostic ID를 추출하는 정규표현식에 하이픈(`-`)을 지원하도록 아래와 같이 수정하였습니다:

```python
# 수정 전
diag_ids = set(re.findall(r"E\[.*?\] \[([a-zA-Z0-9_]+)\]", output))

# 수정 후
diag_ids = set(re.findall(r"E\[.*?\] \[([a-zA-Z0-9_-]+)\]", output))
```

수정 후 테스트 결과, 하이픈이 들어간 에러 ID(`implicit-function-declaration`)도 정상적으로 감지되는 것을 확인했습니다.

## 4. 이후 조치 사항
1. VSCode에서 `Shift + Cmd + P` (macOS) 또는 `Ctrl + Shift + P` (Windows/Linux)를 눌러 Command Palette를 엽니다.
2. `clangd: Restart language server` 명령을 실행하여 `clangd`를 재시작합니다.
3. 스크립트 실행 후 갱신된 `.clangd` 설정이 반영되어 경고가 억제되는 것을 확인합니다.

---

## 5. `fatal_too_many_errors` 문제 해결

### 1) 개요
`clangd` 분석 도중 아래와 같은 치명적 오류가 발생하며 에러 스캔이 중단되는 현상이 있었습니다:
```text
Too many errors emitted, stopping now clang(fatal_too_many_errors)
```

### 2) 원인 분석
* `clang` 또는 `clangd`는 분석 도중 에러가 기본 설정 한도(보통 20개)를 넘어가면 분석 속도 저하를 막기 위해 구문 분석 및 에러 출력을 강제로 중단합니다.
* 커널 코드와 같이 헤더 파일 매핑 등이 복잡한 환경에서는 초기에 include 에러가 폭발하면서 에러 한도를 초과하기 쉽습니다.
* 분석이 중단되면 그 이후에 등장하는 에러와 경고를 [clangd_suppress.py](file:///Users/khg/Projects/my-scripts/clangd_suppress.py)가 다 파싱하지 못하는 문제가 발생합니다.

### 3) 해결 조치
* `.clangd` 파일의 `CompileFlags.Add` 섹션에 `-ferror-limit=0` 플래그를 추가하면 컴파일러가 감지하는 에러 개수 한도를 무제한으로 설정하여, 아무리 많은 에러가 발생해도 중단되지 않고 소스 파일 전체를 파싱할 수 있게 됩니다.
* [clangd_suppress.py](file:///Users/khg/Projects/my-scripts/clangd_suppress.py) 스크립트가 다음과 같이 개선되었습니다:
  * `.clangd` 설정 파일이 신규 생성될 때 `CompileFlags.Add`에 `-ferror-limit=0`이 기본 포함되도록 하였습니다.
  * 이미 존재하는 `.clangd` 설정에 대해서도 `-ferror-limit=0`이 누락되어 있다면 자동으로 보완하여 추가되도록 기능을 추가하였습니다.
