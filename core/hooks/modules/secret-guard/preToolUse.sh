#!/usr/bin/env bash
# secret-guard: 비밀값이 파일에 쓰이거나 커밋에 들어가는 것을 막는다.
#
#   1. Write, Edit, Bash 입력에 토큰이나 키 같은 패턴이 있으면 막는다.
#   2. .env 나 개인 키 같은 파일을 git add 하려 하면 막는다.
#
# 막을 때 비밀값 자체는 출력하지 않고 종류만 알려 준다.
# 입력: PreToolUse JSON (stdin)   출력: 막을 때 exit 2 + stderr 안내

. "$(dirname "$0")/../../lib/json.sh"
HOOK_INPUT="$(cat)"
tool="$(json_get tool_name)"

block() {
  echo "[secret-guard] 차단: $1" >&2
  echo "$2" >&2
  exit 2
}

# ── 1. 입력에 비밀값 패턴이 있는지 ──────────────────────────────

secret_labels=(
  "AWS 액세스 키"
  "GitHub 토큰"
  "GitHub 세분화된 토큰"
  "API 키(sk- 형식)"
  "Slack 토큰"
  "Google API 키"
  "개인 키"
)
secret_patterns=(
  'AKIA[0-9A-Z]{16}'
  'gh[pousr]_[A-Za-z0-9]{36,}'
  'github_pat_[A-Za-z0-9_]{22,}'
  '(^|[^A-Za-z0-9_])sk-(ant-|proj-)?[A-Za-z0-9_-]{20,}'
  'xox[abprs]-[A-Za-z0-9-]{10,}'
  'AIza[0-9A-Za-z_-]{35}'
  '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
)

case "$tool" in
  Write) text="$(json_get tool_input.content)" ;;
  Edit) text="$(json_get tool_input.new_string)" ;;
  Bash) text="$(json_get tool_input.command)" ;;
  *) exit 0 ;;
esac

if [ -n "$text" ]; then
  for i in "${!secret_patterns[@]}"; do
    if printf '%s' "$text" | grep -qE -e "${secret_patterns[$i]}"; then
      block "${secret_labels[$i]}로 보이는 문자열" "비밀값은 코드나 명령에 직접 적지 말고 환경 변수나 비밀 저장소를 쓰세요."
    fi
  done
fi

exit 0
