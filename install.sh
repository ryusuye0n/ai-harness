#!/usr/bin/env bash
# ai-harness 설치 스크립트: 하네스 파일을 다른 레포의 .claude/ 로 복사한다.
#
#   ./install.sh <대상 레포 경로> [--only hooks,agents,skills,templates]
#                [--stack 이름[,이름...]] [--tool claude] [--force] [--dry-run]
#
# 이미 있는 파일은 덮어쓰지 않고 건너뛴다. --force 를 주면 하네스가 만든 파일만 덮어쓴다.
# 대상 레포의 CLAUDE.md 와 .claude/settings.json 은 사용자 파일이라 --force 로도 덮어쓰지 않는다.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
사용법: ./install.sh <대상 레포 경로> [옵션]

옵션
  --only <목록>    설치할 구성만 고른다. 쉼표로 구분: hooks, agents, skills, templates
                   (기본: 전부)
  --stack <목록>   stacks/ 의 스택 팩도 함께 설치한다. 쉼표로 구분
  --tool <이름>    대상 도구 (현재 claude 만 지원)
  --force          이미 있는 하네스 파일을 덮어쓴다
  --dry-run        파일을 복사하지 않고 무엇을 할지만 보여 준다
  -h, --help       이 도움말
EOF
}

die() {
  echo "오류: $1" >&2
  exit 1
}

target=""
only="hooks,agents,skills,templates"
stacks=""
tool="claude"
force=0
dry_run=0

while [ $# -gt 0 ]; do
  case "$1" in
    --only) [ $# -ge 2 ] || die "--only 에 값이 필요합니다."; only="$2"; shift 2 ;;
    --stack) [ $# -ge 2 ] || die "--stack 에 값이 필요합니다."; stacks="$2"; shift 2 ;;
    --tool) [ $# -ge 2 ] || die "--tool 에 값이 필요합니다."; tool="$2"; shift 2 ;;
    --force) force=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h | --help) usage; exit 0 ;;
    -*) die "알 수 없는 옵션: $1 (--help 로 사용법을 확인하세요)" ;;
    *) [ -z "$target" ] || die "대상 경로는 하나만 줄 수 있습니다."; target="$1"; shift ;;
  esac
done

[ -n "$target" ] || { usage; exit 1; }
[ -d "$target" ] || die "대상 폴더가 없습니다: $target"
target="$(cd "$target" && pwd)"
[ "$tool" = "claude" ] || die "아직 지원하지 않는 도구입니다: $tool (현재 claude 만 지원)"

has_part() {
  case ",$only," in *",$1,"*) return 0 ;; esac
  return 1
}

IFS=',' read -r -a only_list <<< "$only"
for part in "${only_list[@]}"; do
  case "$part" in
    hooks | agents | skills | templates) ;;
    *) die "--only 에 알 수 없는 구성이 있습니다: $part" ;;
  esac
done

stack_list=()
if [ -n "$stacks" ]; then
  IFS=',' read -r -a stack_list <<< "$stacks"
  for name in "${stack_list[@]}"; do
    case "$name" in
      "" | *[!A-Za-z0-9_-]*) die "스택 팩 이름이 올바르지 않습니다: '$name'" ;;
    esac
    [ -d "$ROOT/stacks/$name" ] || die "스택 팩이 없습니다: $name (stacks/ 아래 폴더 이름을 확인하세요)"
  done
fi

# 하네스 레포 자신에게 설치하는 실수를 막는다.
[ "$target" != "$ROOT" ] || die "하네스 레포 자신에는 설치할 수 없습니다."

copied=0
overwritten=0
unchanged=0
skipped=0

# ── 복사 ──────────────────────────────────────────────────────

say() { printf '%s\n' "$1"; }

# 한 파일을 복사한다. $3 은 화면에 보여 줄 대상 레포 기준 경로다.
copy_file() {
  local src="$1" dest="$2" shown="$3" verb
  if [ -e "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      unchanged=$((unchanged + 1))
      return
    fi
    if [ "$force" -ne 1 ]; then
      skipped=$((skipped + 1))
      say "건너뜀 (이미 있고 내용이 다름): $shown"
      return
    fi
    verb="덮어씀"
    overwritten=$((overwritten + 1))
  else
    verb="추가"
    copied=$((copied + 1))
  fi

  if [ "$dry_run" -eq 1 ]; then
    say "[dry-run] $verb: $shown"
  else
    mkdir -p "$(dirname "$dest")" && cp -p "$src" "$dest" || die "복사하지 못했습니다: $shown"
    say "$verb: $shown"
  fi
}

# 폴더 안의 파일을 같은 구조로 복사한다. 하네스 문서와 자리표시 파일은 건너뛴다.
copy_tree() {
  local src_dir="$1" dest_dir="$2" file rel
  [ -d "$src_dir" ] || return 0
  while IFS= read -r -d '' file; do
    rel="${file#"$src_dir"/}"
    copy_file "$file" "$dest_dir/$rel" "${dest_dir#"$target"/}/$rel"
  done < <(find "$src_dir" -type f ! -name README.md ! -name .gitkeep ! -name settings.hooks.json -print0 | sort -z)
}

# ── core ──────────────────────────────────────────────────────

has_part hooks && copy_tree "$ROOT/core/hooks" "$target/.claude/hooks"
has_part agents && copy_tree "$ROOT/core/agents" "$target/.claude/agents"
has_part skills && copy_tree "$ROOT/core/skills" "$target/.claude/skills"

# ── 스택 팩 ───────────────────────────────────────────────────
# 이름 검사는 위에서 이미 끝냈다. 복사 도중에 오류로 멈추지 않게 하려는 것이다.

for name in ${stack_list[@]+"${stack_list[@]}"}; do
  copy_tree "$ROOT/stacks/$name/skills" "$target/.claude/skills"
  copy_tree "$ROOT/stacks/$name/hooks/modules" "$target/.claude/hooks/modules"
done

# ── 마무리 ────────────────────────────────────────────────────

echo
[ "$dry_run" -eq 1 ] && echo "(dry-run: 실제로 복사하지 않았습니다)"
echo "추가 $copied · 덮어씀 $overwritten · 같아서 건너뜀 $unchanged · 건너뜀 $skipped"

if has_part hooks || has_part templates; then
  echo
  echo "다음 할 일"
  if has_part hooks; then
    echo "  - 훅은 jq 또는 node 가 있어야 동작합니다."
    if [ "${settings_kept:-0}" -eq 1 ] || ! has_part templates; then
      echo "  - 기존 .claude/settings.json 에 templates/settings.json 의 hooks 항목을 직접 합치세요."
    fi
  fi
  has_part templates && echo "  - CLAUDE.md 의 빈칸을 프로젝트에 맞게 채우세요."
fi
exit 0
