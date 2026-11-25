#!/usr/bin/env bash
# command-guard: 되돌릴 수 없는 셸 명령을 막는다.
#
# 막을지 말지는 "위험해 보이는가"가 아니라 "되돌릴 수 있는가"로 정한다.
# `rm -rf dist` 는 다시 빌드하면 되고 `git push --force-with-lease` 는 남의 커밋을 덮지 않는다.
# 그런 것까지 막으면 훅을 꺼 버리게 되고, 그러면 정말 위험한 명령도 같이 열린다.
#
# 입력: PreToolUse JSON (stdin)   출력: 막을 때 exit 2 + stderr 안내

. "$(dirname "$0")/../../lib/json.sh"
HOOK_INPUT="$(cat)"

[ "$(json_get tool_name)" = "Bash" ] || exit 0
command="$(json_get tool_input.command)"
[ -n "$command" ] || exit 0

block() {
  echo "[command-guard] 차단: $1" >&2
  echo "$2" >&2
  exit 2
}

# 파이프 앞뒤 명령도 따로 검사하려고 &&, ||, ;, |, & 기준으로 한 줄씩 나눈다.
segments="$(printf '%s' "$command" | sed 's/&&/\n/g; s/||/\n/g; s/[;|&]/\n/g')"

# ── 1. 시스템과 작업 트리 파괴 ──────────────────────────────────

re='(^|[[:space:];&|])sudo[[:space:]]+rm([[:space:]]|$)'
if [[ "$command" =~ $re ]]; then
  block "sudo rm" "관리자 권한 삭제는 훅이 되돌릴 수 없습니다. 직접 실행하세요."
fi

# rm 이 -r 과 -f 로 루트, 홈, 상위·현재 디렉터리 전체 같은 곳을 지우는지 본다.
rm_wipes_everything() {
  local -a words
  local word recursive=0 force=0 seen_rm=0 wipes=0
  read -r -a words <<< "$1"
  for word in "${words[@]}"; do
    if [ "$seen_rm" -eq 0 ]; then
      [ "$word" = "rm" ] && seen_rm=1
      continue
    fi
    case "$word" in
      --recursive) recursive=1 ;;
      --force) force=1 ;;
      --*) ;;
      -*r* | -*R*)
        recursive=1
        case "$word" in -*f*) force=1 ;; esac
        ;;
      -*f*) force=1 ;;
      -*) ;;
      "/" | "/*" | "~" | "~/" | "~/*" | '$HOME' | '$HOME/' | '${HOME}' | ".." | "../" | "." | "./" | "*" | "./*")
        wipes=1
        ;;
      /[a-zA-Z] | /[a-zA-Z]/) wipes=1 ;;
    esac
  done
  [ "$recursive" -eq 1 ] && [ "$force" -eq 1 ] && [ "$wipes" -eq 1 ]
}

while IFS= read -r segment; do
  if rm_wipes_everything "$segment"; then
    block "rm -rf (루트·홈·작업 디렉터리 전체)" "복구할 수 없는 삭제입니다. 지울 대상을 정확히 지정하세요."
  fi
done <<< "$segments"

re='(^|[[:space:]])dd[[:space:]]+[^|;&]*of=/dev/'
if [[ "$command" =~ $re ]]; then
  block "dd of=/dev/..." "디바이스를 덮어씁니다. 직접 실행하세요."
fi

re='(^|[[:space:];&|])mkfs(\.[a-z0-9]+)?([[:space:]]|$)'
if [[ "$command" =~ $re ]]; then
  block "mkfs" "파일시스템을 새로 만드는 명령입니다. 직접 실행하세요."
fi

re='>[[:space:]]*/dev/(sd[a-z]|hd[a-z]|vd[a-z]|nvme|mem|kmem)'
if [[ "$command" =~ $re ]]; then
  block "디바이스에 직접 쓰기" "디바이스에 바로 쓰는 명령입니다. 직접 실행하세요."
fi

# ── 2. git: 남의 커밋을 덮거나 작업 내용을 버리는 명령 ──────────────

# --force-with-lease 는 허용하고, 그냥 --force, -f, +refspec 만 막는다.
git_force_push() {
  local -a words
  local word seen_git=0 seen_push=0
  read -r -a words <<< "$1"
  for word in "${words[@]}"; do
    if [ "$seen_git" -eq 0 ]; then
      [ "$word" = "git" ] && seen_git=1
      continue
    fi
    if [ "$seen_push" -eq 0 ]; then
      [ "$word" = "push" ] && seen_push=1
      continue
    fi
    case "$word" in
      --force-with-lease* | --force-if-includes) ;;
      --force) return 0 ;;
      --*) ;;
      -*f*) return 0 ;;
      +*) return 0 ;;
    esac
  done
  return 1
}

# git reset --hard 와 git clean -f 는 커밋하지 않은 변경을 되살릴 수 없게 만든다.
# git clean 은 -n(--dry-run)이 있으면 실제로 지우지 않으므로 통과시킨다.
git_discards_work() {
  local -a words
  local word sub="" seen_git=0 found=0 dry=0
  read -r -a words <<< "$1"
  for word in "${words[@]}"; do
    if [ "$seen_git" -eq 0 ]; then
      [ "$word" = "git" ] && seen_git=1
      continue
    fi
    if [ -z "$sub" ]; then
      case "$word" in reset | clean) sub="$word" ;; esac
      continue
    fi
    case "$sub:$word" in
      reset:--hard) found=1 ;;
      clean:--force) found=1 ;;
      clean:--dry-run) dry=1 ;;
      clean:--*) ;;
      clean:-*)
        case "$word" in -*f*) found=1 ;; esac
        case "$word" in -*n*) dry=1 ;; esac
        ;;
    esac
  done
  [ "$found" -eq 1 ] && [ "$dry" -eq 0 ]
}

while IFS= read -r segment; do
  if git_force_push "$segment"; then
    block "git push --force" "남의 커밋을 덮을 수 있습니다. --force-with-lease 를 쓰거나 직접 실행하세요."
  fi
  if git_discards_work "$segment"; then
    block "git reset --hard / git clean -f" "커밋하지 않은 변경이 사라집니다. 상태를 확인한 뒤 직접 실행하세요."
  fi
done <<< "$segments"

exit 0
