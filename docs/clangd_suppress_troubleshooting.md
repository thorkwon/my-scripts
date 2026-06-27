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
