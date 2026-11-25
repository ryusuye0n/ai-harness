#!/usr/bin/env bash
# Codex 용 훅 래퍼.  사용법: codex.sh <preToolUse|postToolUse|sessionStart>
#
# core 의 run.sh 를 그대로 실행하고, 모듈이 막았을 때(exit 2) 그 이유를 Codex 가 읽는 JSON 으로 바꿔 알린다.
#   - preToolUse  : 도구 호출을 거부한다 (permissionDecision: deny)
#   - postToolUse : 결과 대신 피드백을 모델에게 돌려준다 (decision: block)
# JSON 을 낸 뒤에는 exit 0 으로 끝낸다. 그 밖의 종료 코드는 run.sh 의 것을 그대로 돌려준다.
set -u

event="${1:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

quote_json() {
  if command -v node >/dev/null 2>&1; then
    node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
  else
    jq -n --arg s "$1" '$s'
  fi
}

err_file="$(mktemp)"
trap 'rm -f "$err_file"' EXIT

bash "$here/run.sh" "$event" 2>"$err_file"
status=$?
reason="$(cat "$err_file")"

if [ "$status" -ne 2 ]; then
  [ -n "$reason" ] && printf '%s\n' "$reason" >&2
  exit "$status"
fi

[ -n "$reason" ] || reason="프로젝트 훅이 막았습니다."
case "$event" in
  preToolUse)
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' "$(quote_json "$reason")"
    exit 0
    ;;
  postToolUse)
    printf '{"decision":"block","reason":%s}\n' "$(quote_json "$reason")"
    exit 0
    ;;
esac

printf '%s\n' "$reason" >&2
exit 2
