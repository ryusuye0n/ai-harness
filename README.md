# ai-harness

AI 코딩 도구(Claude Code, Codex)에서 쓰는 훅, 에이전트, 스킬을 모아 둔 하네스입니다.

되돌릴 수 없는 명령과 비밀값 유출을 막는 안전 훅, 검사·문서·디버깅 같은 반복 작업을 맡길 에이전트와 스킬을 어느 프로젝트에나 명령 한 줄로 설치합니다. 언어나 컨벤션은 담지 않고, 쓰는 사람이 자기 프로젝트에 맞게 채웁니다.

## 들어 있는 것

| 구분 | 이름 | 하는 일 |
|---|---|---|
| 훅 | `irreversible-block` | 루트·홈·작업 폴더를 통째로 지우는 `rm -rf`, `git push --force`, `git reset --hard`, 원격 삭제, `curl \| sh` 같은 되돌릴 수 없는 명령을 막습니다 |
| 훅 | `secret-block` | 토큰과 키가 코드나 명령에 들어가는 것, `.env`와 개인 키를 `git add` 하는 것을 막습니다 |
| 훅 | `tool-log` | 도구 호출을 한 줄씩 기록합니다 |
| 에이전트 | `contradiction-finder` | 지침 문서끼리, 문서와 코드가 어긋나는 곳을 찾아 보고합니다 (파일 수정 안 함) |
| 에이전트 | `doc-polisher` | 문서를 현재 코드에 맞게 갱신합니다 |
| 에이전트 | `prompt-polisher` | 에이전트와 스킬 파일을 점검하고 개선안을 제안합니다 (파일 수정 안 함) |
| 에이전트 | `web-researcher` | 웹에서 최신 정보를 찾아 출처와 함께 정리합니다 |
| 스킬 | `planning` | 구현 전에 인터뷰로 요구사항을 정리해 스펙 문서를 만듭니다 |
| 스킬 | `systematic-debugging` | 원인을 확인한 뒤에만 고치는 디버깅 절차입니다 |
| 스킬 | `security-checklist` | 변경한 코드를 스택과 무관한 기준으로 보안 점검합니다 |
| 스킬 | `test` | 변경한 동작에 맞는 테스트를 작성하고 실행해 확인합니다 |

각 항목의 자세한 설명은 [훅](core/hooks/README.md), [에이전트](core/agents/README.md), [스킬](core/skills/README.md) 문서에 있습니다.

## 빠르게 시작

필요한 것: `git`, `bash`(윈도우에서는 Git Bash), `jq` 또는 `node`, 그리고 Claude Code 또는 Codex.

```bash
git clone https://github.com/ryusuye0n/ai-harness.git
cd ai-harness

./install.sh ../my-repo --dry-run    # 무엇이 들어갈지 먼저 확인
./install.sh ../my-repo              # 설치
```

설치한 뒤 할 일은 세 가지입니다.

1. `my-repo/CLAUDE.md`의 빈칸을 채웁니다. 커밋과 PR 규칙은 비워 둬도 됩니다. ([컨벤션 적는 법](#컨벤션-적는-법))
2. 레포에 `.claude/settings.json`이 이미 있었다면 [templates/settings.json](templates/settings.json)의 `hooks` 항목을 직접 합칩니다. 없었다면 설치할 때 함께 들어갑니다.
3. 그 레포에서 Claude Code를 엽니다. 훅이 막으면 `[irreversible-block] 차단: ...`처럼 이유가 전달됩니다.

Codex를 쓴다면 `--tool codex`를 붙입니다.

```bash
./install.sh ../my-repo --tool codex
```

## 원칙

- **하네스는 도구만 제공합니다.** 스킬, 훅, 에이전트가 여기에 들어 있습니다.
- **컨벤션과 기술 스택은 쓰는 사람이 주입합니다.** 커밋 규칙, 브랜치 규칙, 코드 스타일 같은 프로젝트 지침은 하네스에 넣지 않고 각 레포의 `CLAUDE.md`에 직접 적습니다.
- **원본은 한 곳에만 둡니다.** `core/`와 `stacks/`가 원본이고, 도구별 파일은 `adapters/`가 원본에서 만들어 냅니다.

## 구조

```
ai-harness/
├─ core/            스택과 무관한 것
│   ├─ skills/      스킬
│   ├─ agents/      에이전트
│   └─ hooks/       훅 디스패처와 안전 모듈
├─ stacks/          스택별 묶음 (폴더 하나가 스택 하나)
├─ adapters/        도구별 변환 규칙
│   ├─ claude/
│   └─ codex/
├─ install.sh       하네스를 다른 레포로 복사하는 스크립트
└─ templates/       레포에 복사해서 채워 쓰는 양식
    ├─ CLAUDE.md
    └─ settings.json
```

## 사용 방법

`install.sh`가 하네스 파일을 대상 레포로 복사합니다. Claude는 대상 레포의 `.claude/`에 훅, 에이전트, 스킬을 넣고, 레포 루트에 `CLAUDE.md` 양식을, `.claude/settings.json`에 설정 양식을 넣습니다.

```bash
./install.sh <대상 레포 경로> [옵션]
```

```bash
./install.sh ../my-repo --dry-run              무엇을 할지만 보기
./install.sh ../my-repo --only agents,hooks    일부만 설치
./install.sh ../my-repo --stack <이름>         stacks/<이름> 팩도 함께 설치
```

| 옵션 | 설명 |
|---|---|
| `--only <목록>` | 설치할 구성만 고릅니다: `hooks`, `agents`, `skills`, `templates` (쉼표로 구분, 기본은 전부) |
| `--stack <목록>` | `stacks/` 아래 스택 팩을 함께 설치합니다 |
| `--tool <이름>` | 대상 도구입니다. `claude`(기본) 또는 `codex` |
| `--force` | 이미 있는 하네스 파일을 덮어씁니다 |
| `--dry-run` | 복사하지 않고 결과만 보여 줍니다 |

- 이미 있는 파일은 덮어쓰지 않고 건너뜁니다. `--force`는 하네스가 만든 파일만 덮어씁니다.
- 대상 레포의 `CLAUDE.md`와 `.claude/settings.json`은 사용자 파일이라 `--force`로도 덮어쓰지 않습니다.
- `--tool codex`는 `.codex/`, `.agents/`, `AGENTS.md`에 Codex 형식으로 변환해서 넣습니다. 자세한 내용은 [adapters/codex/README.md](adapters/codex/README.md)에 있습니다.
- 설정 항목 설명은 [templates/README.md](templates/README.md)에 있습니다.

## 컨벤션 적는 법

하네스에는 커밋, 브랜치, PR 규칙이 없습니다. 쓰는 사람이 아래 위치에 적습니다.

| 무엇을 | 어디에 |
|---|---|
| 프로젝트 규칙 (커밋, 브랜치, PR 제목, 코드 스타일) | 그 레포의 `CLAUDE.md` (Codex는 `AGENTS.md`) |
| PR 본문 양식 | 그 레포의 `.github/PULL_REQUEST_TEMPLATE.md` |
| 모든 프로젝트에 적용할 개인 취향 | `~/.claude/CLAUDE.md` |

`CLAUDE.md` 양식에는 커밋, 브랜치, PR 규칙 칸이 비어 있습니다. 프로젝트를 시작할 때 채우는 것을 기본으로 합니다.

비워 두면 에이전트가 형식을 임의로 정하지 않고, **사용자가 처음 만든 커밋(또는 PR 제목)의 형식을 규칙으로 삼습니다.** 형식을 정리해서 보여 주고 확인받은 뒤에 `CLAUDE.md`의 빈칸에 적으며, 이미 채워진 칸은 고치지 않습니다. 이 동작은 양식 맨 위의 지침이 시키는 것이라 항상 지켜진다고 보장할 수는 없습니다.

## 업데이트와 제거

**업데이트**: 하네스 폴더에서 `git pull`을 한 뒤 `install.sh`를 같은 옵션으로 다시 실행합니다. 같은 파일은 건너뛰고, 새로 생긴 파일은 추가됩니다. **내가 고친 하네스 파일은 덮어쓰지 않고 "건너뜀"으로 알려 줍니다.** 새 버전으로 바꾸려면 `--force`를 쓰되, 그 파일에 한 수정은 사라집니다.

**제거**: 제거 스크립트는 없습니다. 대상 레포에서 아래를 직접 지웁니다. 내가 만든 파일이 섞여 있을 수 있으니 지우기 전에 확인하세요.

| 도구 | 지울 것 |
|---|---|
| Claude | `.claude/hooks`, `.claude/agents`, `.claude/skills`의 하네스 파일, `.claude/settings.json`의 `hooks` 항목 |
| Codex | `.codex/hooks`, `.codex/agents`, `.codex/hooks.json`, `.agents/skills`의 하네스 파일 |

`CLAUDE.md`(`AGENTS.md`)는 내 규칙이 담긴 파일이라 하네스가 지우지 않습니다.

## 문제 해결

| 증상 | 확인할 것 |
|---|---|
| 훅이 아무것도 막지 않는다 | `.claude/settings.json`에 `hooks` 항목이 있는지, `jq` 또는 `node`가 설치되어 있는지 확인합니다. 둘 다 없으면 `[harness] jq 또는 node 가 없어 훅을 건너뜁니다` 경고가 나옵니다 |
| Codex에서 훅이 실행되지 않는다 | Codex는 새로 추가하거나 바뀐 훅을 `/hooks`에서 검토하고 신뢰해야 실행합니다 |
| 윈도우에서 훅이 오류를 낸다 | Git Bash가 필요합니다. 스크립트에 `\r`(CRLF)이 섞였다면 LF로 저장하세요 |
| 막으면 안 되는 명령이 막힌다 | `irreversible-block`은 명령 문자열을 보고 판단합니다. 그 모듈만 빼려면 `.claude/hooks/modules/irreversible-block/` 폴더를 지웁니다 |
| `permissions` 규칙이 먹지 않는다 | 규칙 문법은 Claude Code 버전에 따라 다를 수 있습니다. 쓰는 버전의 문서에 맞게 `settings.json`을 고칩니다 |
| 설치가 "건너뜀"만 출력한다 | 이미 있는 파일은 덮어쓰지 않는 것이 기본입니다. 바꾸려면 `--force`를 씁니다 |

## 스택 팩 추가

폴더 하나가 스택 하나입니다. `stacks/<이름>/` 아래에 스킬과 훅 모듈을 두면 되고, `core/`는 건드리지 않습니다. `stacks/_template/`을 복사해서 시작하면 되고, 자세한 방법은 [stacks/_template/README.md](stacks/_template/README.md)에 있습니다.

```
stacks/<이름>/
├─ skills/            그 스택 전용 스킬
└─ hooks/modules/     그 스택 전용 훅 모듈
```

## 도구 지원

| 도구 | 상태 |
|---|---|
| Claude Code | 우선 지원 |
| Codex | 지원. 변환 형식과 설치 동작만 검증했고 실제 Codex에서의 동작은 미검증 ([adapters/codex](adapters/codex/README.md)) |

**검증한 것**: 훅의 차단과 허용, 비밀값 검사, 디스패처, 설치 스크립트의 설치·재실행·덮어쓰기 규칙, Codex 변환 결과의 형식을 시나리오 테스트로 확인했습니다. 다만 자동 테스트는 이 레포에 포함하지 않았습니다.

**검증하지 못한 것**: 실제 Claude Code에서 에이전트와 스킬이 알맞은 때에 호출되는지, `permissions` 규칙 문법, 컨벤션이 비어 있을 때 첫 커밋 형식을 따르는 지침이 지켜지는지, 실제 Codex에서의 동작, `jq`를 쓰는 환경(`node`로만 확인했습니다)입니다.

## 라이선스

[MIT](LICENSE)
