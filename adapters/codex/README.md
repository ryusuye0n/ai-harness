# codex 어댑터

`core/`의 원본을 Codex가 읽는 형식으로 바꿔서 설치합니다. 원본은 `core/`와 `stacks/` 한 곳에만 두고, Codex용 파일은 설치할 때 만들어집니다.

```bash
./install.sh <대상 레포 경로> --tool codex
```

## 어디로 어떻게 들어가는가

| 원본 | 설치 위치 | 바뀌는 점 |
|---|---|---|
| `core/hooks/*` | `.codex/hooks/*` | 그대로 복사하고, 래퍼 `codex.sh`를 함께 둔다 |
| `core/agents/<이름>.md` | `.codex/agents/<이름>.toml` | `name`, `description`, 본문(`developer_instructions`)만 옮긴다. `tools`는 버린다 |
| `core/skills/*` | `.agents/skills/*` | `SKILL.md`에서 `allowed-tools` 줄만 뺀다 |
| `templates/CLAUDE.md` | `AGENTS.md` | 내용은 같다 |
| `adapters/codex/hooks.json` | `.codex/hooks.json` | `PreToolUse`에 래퍼를 연결한다 |
| `stacks/<이름>/skills`, `hooks/modules` | `.agents/skills`, `.codex/hooks/modules` | 스킬은 위와 같이 변환한다 |

`AGENTS.md`와 `.codex/hooks.json`은 사용자 파일이라 이미 있으면 `--force`로도 덮어쓰지 않습니다. `hooks.json`이 이미 있다면 `adapters/codex/hooks.json`의 `hooks` 항목을 직접 합칩니다.

## 파일

| 파일 | 하는 일 |
|---|---|
| `adapter.sh` | `install.sh`가 불러서 실행하는 설치 규칙 |
| `convert-agent.sh` | 에이전트 `.md`를 `.toml`로 바꿔 출력 |
| `hooks/codex.sh` | `core`의 디스패처를 실행하고, 모듈이 막았을 때 Codex가 읽는 JSON으로 알리는 래퍼 |
| `hooks.json` | 설치할 훅 설정 |

## Claude와 달라지는 점

- **에이전트의 도구 제한이 사라집니다.** Codex 에이전트 파일에는 `tools`에 해당하는 항목이 없습니다. 검사만 하는 에이전트(`contradiction-finder`, `prompt-polisher`, `web-researcher`)의 "수정하지 않는다"는 본문 지시로만 남습니다.
- **훅은 `PreToolUse`만 연결합니다.** 대상은 `Bash|apply_patch`입니다.
  - `irreversible-block`은 `Bash`만 봅니다.
  - `secret-block`은 `apply_patch`의 패치 내용(`tool_input.command`)에서 비밀값 패턴을 찾습니다. Codex의 파일 수정 입력에는 파일 경로 필드가 없다고 문서에 적혀 있습니다.
- **막는 방법이 다릅니다.** 래퍼가 모듈의 거부(`exit 2`)를 `permissionDecision: "deny"` JSON으로 바꿔 알리고 `exit 0`으로 끝냅니다. `PostToolUse`는 `decision: "block"` JSON을 씁니다.
- **스택 팩의 `settings.hooks.json`은 Claude 형식**이라 자동으로 연결되지 않습니다. `PostToolUse` 모듈을 쓰려면 `.codex/hooks.json`에 직접 추가합니다.
- **새로 설치하거나 바뀐 훅은 Codex의 `/hooks`에서 검토하고 신뢰해야 실행됩니다.**

## 검증 현황

| 확인한 것 | 방법 |
|---|---|
| 에이전트 변환 결과가 유효한 TOML이고 이름, 설명, 본문이 원본과 같음 | TOML 파서로 4개 모두 비교, 작은따옴표와 `'''` 같은 예외 입력까지 확인 |
| 설치 위치, 재실행, 덮어쓰기 규칙, `--only`, `--stack` | 시나리오 테스트 |
| `hooks.json`의 명령이 git 저장소의 루트와 하위 폴더, 저장소가 아닌 폴더에서 훅을 찾아 실행 | Codex와 같은 입력(`tool_name`, `tool_input.command`)을 넣어 실행 |
| 위험한 `Bash` 명령과 비밀값이 든 `apply_patch`가 거부 JSON으로 막히고 이유에 비밀값이 노출되지 않음 | 위와 같은 방식 |

**확인하지 못한 것은 실제 Codex에서의 동작입니다.** 형식은 Codex 공식 문서(hooks, skills, subagents, AGENTS.md)를 근거로 만들었지만, 문서 일부는 요약본으로 읽었습니다. 아래는 Codex를 쓰는 환경에서 직접 확인이 필요합니다.

- 훅을 신뢰한 뒤 실제로 실행되는지, 거부 JSON을 읽고 도구 호출을 막는지
- 변환한 에이전트와 스킬을 Codex가 불러오는지, `allowed-tools`를 뺀 `SKILL.md`가 문제없는지
- `apply_patch` 입력의 실제 모양이 문서에 적힌 대로 `tool_input.command`에 패치를 담는지
