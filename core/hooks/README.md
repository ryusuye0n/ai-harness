# hooks

Claude Code가 도구를 쓰기 전후에 실행되는 스크립트 모음입니다. 규칙은 담지 않고, 되돌릴 수 없는 일과 비밀값 유출처럼 어느 프로젝트에서나 막아야 하는 것만 다룹니다.

## 구조

```
hooks/
├─ dispatcher/run.sh      이벤트 이름을 받아 modules/ 안의 모듈을 순서대로 실행
├─ lib/json.sh            훅 입력(JSON)에서 값을 꺼내는 헬퍼
├─ modules/
│   ├─ command-guard/     되돌릴 수 없는 셸 명령 차단
│   ├─ secret-guard/      비밀값과 비밀 파일 차단
│   └─ logging/           도구 호출 기록
└─ settings.hooks.json    settings.json에 합쳐 넣는 설정 예시
```

## 쓰는 방법

1. 이 `hooks/` 폴더를 쓰려는 레포의 `.claude/hooks/`로 복사합니다.
2. `settings.hooks.json`의 `hooks` 항목을 레포의 `.claude/settings.json`에 합칩니다.
3. 필요 없는 모듈은 `modules/` 아래에서 폴더째 지웁니다.

`jq` 또는 `node`가 있어야 합니다. 둘 다 없으면 훅이 동작하지 않고 경고만 남깁니다. 윈도우에서는 Git Bash가 필요합니다.

## 모듈

| 모듈 | 이벤트 | 하는 일 |
|---|---|---|
| `command-guard` | preToolUse | 루트·홈·작업 디렉터리를 통째로 지우는 `rm -rf`, `sudo rm`, `dd of=/dev/`, `mkfs`, `git push --force`(`--force-with-lease`는 허용), `git reset --hard`, `git clean -f`, 원격 브랜치·태그 삭제, `gh repo delete`, `curl ... \| sh` 차단 |
| `secret-guard` | preToolUse | Write·Edit·Bash(Codex는 apply_patch 포함) 입력에서 토큰과 키 패턴 차단, `.env`·개인 키 파일의 `git add` 차단 (`.env.example`은 허용) |
| `logging` | preToolUse | 도구 호출을 `~/.claude/logs/harness-tools.log`에 한 줄씩 기록. 위치는 `HARNESS_LOG_FILE`로 바꿈 |

막을 때는 종료 코드 2와 이유를 돌려주고, Claude가 그 이유를 읽고 다른 방법을 찾습니다. `command-guard`는 "위험해 보이는가"가 아니라 "되돌릴 수 있는가"를 기준으로 합니다.

## 알아둘 점

- 명령 문자열을 보고 판단하는 방식이라 **보안 경계가 아니라 실수를 막는 안전장치**입니다. 따옴표나 변수로 돌려 쓰면 지나갈 수 있습니다.
- `logging`은 명령을 200자까지 그대로 남기고 가리지 않습니다. 명령에 비밀값이 섞일 수 있습니다.

## 모듈 추가

`modules/<이름>/<이벤트>.sh`를 만들면 디스패처가 찾아서 실행합니다. 이벤트 이름은 `preToolUse`, `postToolUse`, `sessionStart`입니다. 모듈은 JSON 입력을 stdin으로 받고, 도구 호출을 막으려면 stderr에 이유를 쓰고 `exit 2`로 끝냅니다. `preToolUse` 외의 이벤트를 쓰려면 `settings.json`에 해당 이벤트 항목을 추가합니다.
