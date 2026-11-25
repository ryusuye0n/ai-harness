# Codex 어댑터. install.sh 가 --tool codex 일 때 불러와서 실행한다. 직접 실행하지 않는다.
# install.sh 의 say, copy_file, copy_tree, install_user_file, has_part, 카운터와 변수를 그대로 쓴다.
#
# 대응 관계
#   core/hooks/*              → .codex/hooks/*            (훅 래퍼 codex.sh 를 함께 둔다)
#   core/agents/<이름>.md     → .codex/agents/<이름>.toml  (convert-agent.sh 로 변환)
#   core/skills/*             → .agents/skills/*           (SKILL.md 에서 allowed-tools 줄을 뺀다)
#   templates/CLAUDE.md       → AGENTS.md
#   adapters/codex/hooks.json → .codex/hooks.json

adapter_dir="$ROOT/adapters/codex"

config_file=".codex/hooks.json"
config_source="adapters/codex/hooks.json"
instruction_file="AGENTS.md"
tool_note="Codex 는 새로 추가하거나 바뀐 훅을 /hooks 에서 검토하고 신뢰해야 실행합니다."

# 변환한 임시 파일을 복사한다. 임시 파일의 권한(600)이 그대로 남지 않게 644 로 맞춘다.
codex_copy_converted() {
  local converted="$1" dest="$2" shown="$3"
  chmod 644 "$converted"
  copy_file "$converted" "$dest" "$shown"
  rm -f "$converted"
}

# 스킬 폴더를 복사한다. Codex 는 allowed-tools 를 쓰지 않으므로 SKILL.md 에서 그 줄을 뺀다.
codex_copy_skills() {
  local src_dir="$1" dest_dir="$2" file rel tmp shown
  [ -d "$src_dir" ] || return 0
  while IFS= read -r -d '' file; do
    rel="${file#"$src_dir"/}"
    shown="${dest_dir#"$target"/}/$rel"
    if [ "${file##*/}" = "SKILL.md" ]; then
      tmp="$(mktemp)"
      awk '
        NR == 1 && $0 == "---" { in_frontmatter = 1; print; next }
        in_frontmatter && $0 == "---" { in_frontmatter = 0; print; next }
        in_frontmatter && /^allowed-tools:/ { next }
        { print }
      ' "$file" > "$tmp"
      codex_copy_converted "$tmp" "$dest_dir/$rel" "$shown"
    else
      copy_file "$file" "$dest_dir/$rel" "$shown"
    fi
  done < <(find "$src_dir" -type f ! -name README.md ! -name .gitkeep -print0 | sort -z)
}

codex_copy_agents() {
  local file name tmp
  for file in "$ROOT"/core/agents/*.md; do
    [ -f "$file" ] || continue
    name="$(basename "$file" .md)"
    [ "$name" != "README" ] || continue
    tmp="$(mktemp)"
    if ! bash "$adapter_dir/convert-agent.sh" "$file" > "$tmp"; then
      rm -f "$tmp"
      die "에이전트를 변환하지 못했습니다: $name"
    fi
    codex_copy_converted "$tmp" "$target/.codex/agents/$name.toml" ".codex/agents/$name.toml"
  done
}

has_part hooks && {
  copy_tree "$ROOT/core/hooks" "$target/.codex/hooks"
  copy_file "$adapter_dir/hooks/codex.sh" "$target/.codex/hooks/dispatcher/codex.sh" ".codex/hooks/dispatcher/codex.sh"
}
has_part agents && codex_copy_agents
has_part skills && codex_copy_skills "$ROOT/core/skills" "$target/.agents/skills"

for name in ${stack_list[@]+"${stack_list[@]}"}; do
  codex_copy_skills "$ROOT/stacks/$name/skills" "$target/.agents/skills"
  copy_tree "$ROOT/stacks/$name/hooks/modules" "$target/.codex/hooks/modules"
done

if has_part templates; then
  install_user_file "$ROOT/templates/CLAUDE.md" "$target/AGENTS.md" "AGENTS.md"
  install_user_file "$adapter_dir/hooks.json" "$target/.codex/hooks.json" ".codex/hooks.json" || settings_kept=1
fi
