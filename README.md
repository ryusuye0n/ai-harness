# ai-harness

AI 코딩 도구(Claude Code, Codex)에서 쓰는 훅, 에이전트, 스킬 모음입니다.
컨벤션과 기술 스택은 담지 않습니다. 쓰는 사람이 자기 프로젝트에 맞게 채웁니다.

## 사용 방법

필요한 것: `git`, `bash`(윈도우에서는 Git Bash), `jq` 또는 `node`

```bash
git clone https://github.com/ryusuye0n/ai-harness.git
cd ai-harness
./install.sh <대상 레포 경로>
```

| 옵션 | 설명 |
|---|---|
| `--dry-run` | 복사하지 않고 무엇이 들어갈지만 보여 줍니다 |
| `--only <목록>` | `hooks`, `agents`, `skills`, `templates` 중 일부만 설치합니다 |
| `--stack <이름>` | `stacks/` 아래 스택 팩도 함께 설치합니다 |
| `--tool <이름>` | `claude`(기본) 또는 `codex` |
| `--force` | 이미 있는 하네스 파일을 덮어씁니다 |

이미 있는 파일은 덮어쓰지 않고 건너뜁니다. 대상 레포의 `CLAUDE.md`와 `.claude/settings.json`은 `--force`로도 덮어쓰지 않으니, 설정 파일이 이미 있다면 [templates/settings.json](templates/settings.json)의 `hooks` 항목을 직접 합칩니다.

## 이런 걸 막아 줍니다

되돌릴 수 없는 명령과 비밀값이 든 입력은 실행하기 전에 막고, 이유를 에이전트에게 돌려줍니다.

```
git push --force origin main
[irreversible-block] 차단: git push --force
남의 커밋을 덮을 수 있습니다. --force-with-lease 를 쓰거나 직접 실행하세요.
```

## 컨벤션

하네스에는 커밋, 브랜치, PR 규칙이 없습니다. 설치한 뒤 대상 레포의 `CLAUDE.md`(Codex는 `AGENTS.md`)에 직접 적습니다.

- 규칙을 적어 두면 에이전트가 그대로 따릅니다.
- 비워 두면 에이전트가 형식을 임의로 정하지 않고, **처음 만든 커밋의 형식을 규칙으로 삼습니다.** 정리해서 보여 주고 확인받은 뒤 `CLAUDE.md`에 적습니다.
- 모든 프로젝트에 적용할 개인 취향은 `~/.claude/CLAUDE.md`에 적습니다.

## 더 보기

- [훅](core/hooks/README.md) · [에이전트](core/agents/README.md) · [스킬](core/skills/README.md)
- [Codex 어댑터](adapters/codex/README.md) · [템플릿](templates/README.md) · [스택 팩 만들기](stacks/_template/README.md)

## 라이선스

[MIT](LICENSE)
