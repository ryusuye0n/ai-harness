#!/usr/bin/env bash
# 에이전트 변환: core/agents/<이름>.md 를 Codex 형식(.toml)으로 바꿔 stdout 으로 낸다.
#
#   convert-agent.sh core/agents/doc-polisher.md > .codex/agents/doc-polisher.toml
#
# 프론트매터의 name, description 과 본문(developer_instructions)만 옮긴다.
# tools 는 Codex 에이전트 파일에 대응하는 항목이 없어서 버린다.
set -u

src="${1:-}"
[ -f "$src" ] || { echo "오류: 파일이 없습니다: $src" >&2; exit 1; }

# 프론트매터에서 한 줄짜리 값을 꺼낸다.
frontmatter_value() {
  awk -v key="$1" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 {
      i = index($0, ":")
      if (i > 0 && substr($0, 1, i - 1) == key) {
        value = substr($0, i + 1)
        sub(/^[ \t]+/, "", value)
        print value
        exit
      }
    }
  ' "$src"
}

# 프론트매터 뒤의 본문을 꺼내고 앞쪽 빈 줄을 없앤다.
body_text() {
  awk 'c >= 2 { print } /^---$/ { c++ }' "$src" | sed '/./,$!d'
}

# TOML 한 줄 문자열. 작은따옴표가 없으면 이스케이프가 필요 없는 리터럴 문자열을 쓴다.
toml_string() {
  case "$1" in
    *"'"*)
      local escaped="${1//\\/\\\\}"
      escaped="${escaped//\"/\\\"}"
      printf '"%s"' "$escaped"
      ;;
    *) printf "'%s'" "$1" ;;
  esac
}

name="$(frontmatter_value name)"
description="$(frontmatter_value description)"
body="$(body_text)"

[ -n "$name" ] || { echo "오류: name 이 없습니다: $src" >&2; exit 1; }
[ -n "$description" ] || { echo "오류: description 이 없습니다: $src" >&2; exit 1; }
[ -n "$body" ] || { echo "오류: 본문이 비어 있습니다: $src" >&2; exit 1; }
case "$body" in
  *"'''"*) echo "오류: 본문에 ''' 가 있어 TOML 로 옮길 수 없습니다: $src" >&2; exit 1 ;;
esac

printf 'name = %s\n' "$(toml_string "$name")"
printf 'description = %s\n' "$(toml_string "$description")"
printf "developer_instructions = '''\n%s\n'''\n" "$body"
