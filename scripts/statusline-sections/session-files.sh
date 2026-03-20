# ── Session files section ──────────────────────────────────
# Sourced by scripts/statusline — not executable on its own.
# Requires: CONTEXT_DIR, session_id, color variables

session_files_section() {
  # Guard: need git and a session_id
  [ -z "$session_id" ] && return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  local baseline_file="${CONTEXT_DIR}/.session-baseline-${session_id}"

  # Current dirty files: tracked changes + untracked
  local current_files
  current_files=$({ git diff --name-only HEAD 2>/dev/null; git status --porcelain 2>/dev/null | perl -ne 'print "$1\n" if /^\?\? (.+)$/'; } | sort -u)

  # First invocation: save baseline and return
  if [ ! -f "$baseline_file" ]; then
    echo "$current_files" > "$baseline_file"
    return
  fi

  # Set difference: current - baseline = session files
  local session_only
  session_only=$(comm -23 <(echo "$current_files") <(sort -u "$baseline_file"))

  [ -z "$session_only" ] && return

  local count
  count=$(echo "$session_only" | wc -l | tr -d ' ')

  # Extract basenames (max 3)
  local names=()
  local i=0
  while IFS= read -r f; do
    [ $i -ge 3 ] && break
    names+=("$(basename "$f")")
    i=$((i + 1))
  done <<< "$session_only"

  local joined=""
  for j in "${!names[@]}"; do
    [ "$j" -gt 0 ] && joined="${joined}, "
    joined="${joined}${names[$j]}"
  done

  local suffix=""
  if [ "$count" -gt 3 ]; then
    suffix=" ${DIM}+$((count - 3)) more${RESET}"
  fi

  local label="files"
  [ "$count" -eq 1 ] && label="file"

  # Export for context.json
  _session_files_count="$count"
  _session_files_names="$joined"

  session_files="📂 ${count} ${label}  ·  ${joined}${suffix}"
}
