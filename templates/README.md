# templates

레포에 복사해서 쓰는 양식입니다. 하네스는 규칙을 정해 주지 않으므로, 아래 파일의 값은 쓰는 사람이 자기 프로젝트에 맞게 바꿉니다.

## CLAUDE.md

프로젝트 개요와 커밋, 브랜치, PR 규칙, 코드 스타일을 적는 빈 양식입니다. 레포 루트에 복사해서 채웁니다.

## settings.json

`.claude/settings.json`으로 복사해서 씁니다. 이미 설정 파일이 있다면 필요한 항목만 합칩니다.

| 항목 | 값 | 설명 |
|---|---|---|
| `attribution` | `commit`, `pr`를 빈 문자열로 | 커밋과 PR에 AI 표기가 붙지 않게 합니다. 표기를 원하면 문구를 채웁니다. |
| `language` | `korean` | Claude의 응답 언어입니다. 다른 언어를 쓰면 바꿉니다. |
| `permissions.allow` | `git status`, `diff`, `log`, `show`, `rev-parse`, `ls-files` | 상태를 읽기만 하는 git 명령은 묻지 않고 허용합니다. |
| `permissions.deny` | `.env`, `.env.local`, `*.pem`, `id_rsa*` 읽기 | 비밀이 들어 있는 파일은 읽지 못하게 합니다. |
| `hooks` | `PreToolUse` 디스패처 연결 | `core/hooks`를 `.claude/hooks/`에 복사했을 때 동작합니다. 내용은 `core/hooks/settings.hooks.json`과 같습니다. |

### 일부러 허용하지 않은 것

`git add`, `git commit`, `git push`는 허용 목록에 넣지 않았습니다. 그래서 실행할 때마다 확인을 받습니다. 커밋과 push를 자동으로 허용하려면 `permissions.allow`에 직접 추가하세요.

### 알아둘 점

- 권한 규칙의 형식은 Claude Code 버전에 따라 조금 다를 수 있습니다. 규칙이 먹지 않으면 쓰는 버전의 문서에 맞게 고칩니다.
- `deny`는 읽기를 막는 규칙입니다. `.env.example` 같은 견본은 막지 않습니다.
