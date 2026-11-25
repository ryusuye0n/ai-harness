# agents

Claude Code가 작업을 맡길 때 쓰는 서브에이전트 모음입니다. 스택과 컨벤션에 상관없이 어느 프로젝트에서나 쓸 수 있는 것만 담았고, 프로젝트별 규칙은 각 레포의 `CLAUDE.md`에서 가져옵니다.

## 목록

| 에이전트 | 하는 일 | 파일 수정 | 도구 |
|---|---|---|---|
| `contradiction-finder` | 지침 문서끼리, 문서와 코드가 어긋나는 곳을 찾아 보고 | 안 함 | Read, Grep, Glob |
| `doc-polisher` | 문서를 현재 코드에 맞게 갱신 (규칙을 새로 만들지 않음) | 문서만 | Read, Grep, Glob, Edit |
| `prompt-polisher` | 에이전트, 스킬, 프롬프트 파일을 점검하고 개선안 제안 | 안 함 | Read, Grep, Glob |
| `web-researcher` | 웹에서 최신 정보를 찾아 출처와 함께 정리 | 안 함 | WebSearch, WebFetch |

## 쓰는 방법

필요한 `.md` 파일을 쓰려는 레포의 `.claude/agents/`로 복사합니다. Claude가 `description`을 보고 알맞은 때에 맡기고, 에이전트 이름을 직접 불러서 시킬 수도 있습니다.

## 에이전트 추가

`core/agents/<이름>.md`를 만들고 아래 프론트매터를 채웁니다.

```markdown
---
name: <파일 이름과 같게>
description: <언제 쓰는지. 사용자가 할 법한 요청 문구를 넣는다>
tools: <필요한 도구만>
---

본문: 역할, 절차, 원칙, 보고 형식
```

도구는 필요한 것만 허용합니다. 검사만 하는 에이전트에는 편집 도구를 주지 않습니다.
