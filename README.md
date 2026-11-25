# ai-harness

AI 코딩 도구에서 쓰는 스킬, 훅, 에이전트를 모아 둔 하네스입니다.

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

`install.sh`가 하네스 파일을 대상 레포로 복사합니다. bash가 필요하고, 윈도우에서는 Git Bash로 실행합니다.

```bash
./install.sh <대상 레포 경로>
```

대상 레포의 `.claude/`에 훅, 에이전트, 스킬을 넣고, 레포 루트에 `CLAUDE.md` 양식을, `.claude/settings.json`에 설정 양식을 넣습니다.

```bash
./install.sh ../my-repo --dry-run              무엇을 할지만 보기
./install.sh ../my-repo --only agents,hooks    일부만 설치
./install.sh ../my-repo --stack go             stacks/go 팩도 함께 설치
```

| 옵션 | 설명 |
|---|---|
| `--only <목록>` | 설치할 구성만 고릅니다: `hooks`, `agents`, `skills`, `templates` (쉼표로 구분, 기본은 전부) |
| `--stack <목록>` | `stacks/` 아래 스택 팩을 함께 설치합니다 |
| `--tool <이름>` | 대상 도구입니다. `claude`(기본) 또는 `codex` |
| `--force` | 이미 있는 하네스 파일을 덮어씁니다 |
| `--dry-run` | 복사하지 않고 결과만 보여 줍니다 |

- 이미 있는 파일은 덮어쓰지 않고 건너뜁니다. `--force`는 하네스가 만든 파일만 덮어씁니다.
- 대상 레포의 `CLAUDE.md`와 `.claude/settings.json`은 사용자 파일이라 `--force`로도 덮어쓰지 않습니다. 설정 파일이 이미 있다면 [templates/settings.json](templates/settings.json)의 `hooks` 항목을 직접 합칩니다.
- `--tool codex`는 `.codex/`, `.agents/`, `AGENTS.md`에 Codex 형식으로 변환해서 넣습니다. 자세한 내용은 [adapters/codex/README.md](adapters/codex/README.md)에 있습니다.

설치한 뒤에는 `CLAUDE.md`의 빈칸을 프로젝트에 맞게 채웁니다. 커밋과 PR 규칙을 비워 두면 처음 만든 커밋의 형식을 규칙으로 삼아 기록합니다. 설정 항목 설명은 [templates/README.md](templates/README.md)에 있습니다. 훅은 `jq` 또는 `node`가 있어야 동작합니다.

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

## 라이선스

[MIT](LICENSE). 다른 레포에서 가져온 파일은 원 저작권 표기를 `NOTICE`에 남깁니다.
