# _template

새 스택 팩을 만들 때 복사해서 쓰는 뼈대입니다. 이 폴더 자체는 설치용이 아니어서 `install.sh --stack _template`은 거부됩니다.

## 만드는 순서

1. 폴더를 복사해서 이름을 바꿉니다. 이름은 영문, 숫자, `-`, `_`만 씁니다.

   ```bash
   cp -r stacks/_template stacks/<이름>
   ```

2. 예시 스킬과 예시 모듈을 지우거나 자기 것으로 바꿉니다.
   - `skills/example-skill/` → 그 스택 전용 스킬
   - `hooks/modules/example-check/` → 그 스택 전용 훅 모듈
3. 훅 모듈은 파일을 고친 뒤에 도는 `postToolUse` 이벤트용입니다. `example-check`의 `EXTENSIONS`와 `CHECK_COMMAND`만 채워도 동작합니다.
4. 모듈이 `postToolUse`를 쓰면 `settings.json`에 해당 항목이 있어야 합니다. `settings.hooks.json`의 `hooks`를 대상 레포의 `.claude/settings.json`에 합칩니다. `install.sh`는 설정 파일을 합쳐 주지 않습니다.
5. 대상 레포에 설치합니다.

   ```bash
   ./install.sh <대상 레포 경로> --stack <이름>
   ```

## 구조

```
stacks/<이름>/
├─ skills/<스킬>/SKILL.md          그 스택 전용 스킬
├─ hooks/modules/<모듈>/<이벤트>.sh  그 스택 전용 훅 모듈
└─ settings.hooks.json             settings.json에 합칠 훅 연결 (설치되지 않음)
```

`install.sh`는 `skills/`는 `.claude/skills/`로, `hooks/modules/`는 `.claude/hooks/modules/`로 복사합니다.

## 지킬 것

- 이 스택에서만 필요한 것만 담습니다. 스택과 무관한 것은 `core/`에 속합니다.
- 컨벤션을 박아 두지 않습니다. 커밋 형식, 폴더 구조 같은 프로젝트 규칙은 쓰는 사람이 `CLAUDE.md`에 적습니다.
- 훅 모듈은 도구 호출을 막을 때 stderr에 이유를 쓰고 `exit 2`로 끝냅니다. 다른 종료 코드는 막지 않고 알리기만 합니다.
- 훅 모듈이 외부 명령(린터, 포맷터 등)을 쓴다면 README에 필요한 도구를 적습니다.
