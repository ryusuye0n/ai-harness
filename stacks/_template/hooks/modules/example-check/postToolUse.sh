#!/usr/bin/env bash
# 예시 모듈: 파일을 고친 뒤에 검사 명령을 실행하는 모양을 보여 준다.
#
# 복사해서 폴더 이름을 바꾸고 아래 두 값을 채워 쓴다. 비어 있으면 아무것도 하지 않는다.
#
#   EXTENSIONS    검사할 파일 확장자. 공백으로 구분한다.          예: "ts tsx"
#   CHECK_COMMAND 검사 명령. 고친 파일의 경로가 맨 뒤에 붙는다.   예: "npx eslint"
#
# 검사가 실패하면 출력을 보여 주고 exit 2 로 끝낸다. Claude 가 그 내용을 읽고 고친다.
# 공백이 들어간 명령 인자는 지원하지 않는다. 복잡한 검사는 별도 스크립트로 빼서 부른다.
#
# 입력: PostToolUse JSON (stdin)

EXTENSIONS=""
CHECK_COMMAND=""

[ -n "$EXTENSIONS" ] && [ -n "$CHECK_COMMAND" ] || exit 0

. "$(dirname "$0")/../../lib/json.sh"
HOOK_INPUT="$(cat)"

file="$(json_get tool_input.file_path)"
[ -n "$file" ] && [ -f "$file" ] || exit 0

ext="${file##*.}"
case " $EXTENSIONS " in
  *" $ext "*) ;;
  *) exit 0 ;;
esac

# shellcheck disable=SC2086
output="$($CHECK_COMMAND "$file" 2>&1)"
status=$?

if [ "$status" -ne 0 ]; then
  echo "[example-check] 검사 실패: $file" >&2
  printf '%s\n' "$output" | head -40 >&2
  exit 2
fi

exit 0
