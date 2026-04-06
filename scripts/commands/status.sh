# tamaclaudechi - Status command: display current stats (ASCII or JSON)

cmd_status() {
  local mode="ascii"
  while [ $# -gt 0 ]; do
    case "$1" in
      --json)
        mode="json"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  ensure_state

  # Apply decay for display (don't write)
  local decayed
  decayed=$(apply_decay)
  read -r en se re bo vi ea va sa <<< "$decayed"

  # Apply serenity convergence from git state for display (inline to preserve _d_* detail vars)
  if [ "$sa" -eq 1 ]; then
  local _serenity_result
  _serenity_result=$(compute_serenity_from_git)
  local _serenity_adj
  read -r _serenity_adj _d_dirty_count _d_branch_count _d_merged_count _d_diff_insertions _d_diff_deletions _d_last_commit_ago _d_in_git_repo <<< "$_serenity_result"

  if [ "$_d_in_git_repo" = "true" ]; then
    local serenity_target=$((50 + _serenity_adj))
    [ "$serenity_target" -lt 10 ] && serenity_target=10
    [ "$serenity_target" -gt 95 ] && serenity_target=95
    local distance=$((serenity_target - se))
    local step=$(( (distance + (distance > 0 ? 2 : -2)) / 3 ))
    if [ "$distance" -gt 0 ] && [ "$step" -lt 1 ]; then step=1; fi
    if [ "$distance" -lt 0 ] && [ "$step" -gt -1 ]; then step=-1; fi
    [ "$distance" -eq 0 ] && step=0
    se=$(clamp $((se + step)))
  fi
  else
    _d_in_git_repo=false
  fi

  # Compute rest details for display (no drain applied — status is read-only)
  local rest_result
  rest_result=$(compute_rest_adjustment)
  local rest_adj
  read -r rest_adj _d_session_minutes _d_late_night_penalty _d_is_marathon _d_interaction_density <<< "$rest_result"

  local temped
  temped=$(temporal_modifier "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va" "$sa")
  read -r en se re bo vi ea va sa <<< "$temped"

  local mood wb name streak lifetime
  mood=$(resolve_mood "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va" "$sa")
  wb=$(wellbeing "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va" "$sa")
  name=$(json_val name)
  streak=$(json_val streak)
  lifetime=$(json_val lifetimeInteractions)

  if [ "$mode" = "json" ]; then
    output_json "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va" "$sa" "$mood"
    return
  fi

  local display_name="${name}"
  [ "$display_name" = "null" ] || [ -z "$display_name" ] && display_name="Claude Mascot"

  echo "╭─────────────────────────────╮"
  printf "│  %-27s│\n" "$display_name"
  echo "│─────────────────────────────│"
  printf "│  Mood:      %-16s│\n" "$mood"
  printf "│  Wellbeing: %-16s│\n" "$wb/100"
  echo "│                             │"
  if [ "$ea" -eq 1 ]; then
    printf "│  Energy:    %-5s" "$en"
    local bar=""
    local i=0
    while [ $i -lt $((en / 10)) ]; do bar="${bar}█"; i=$((i + 1)); done
    printf "%-11s│\n" "$bar"
  else
    printf "│  Energy:    %-16s│\n" "—"
  fi
  if [ "$sa" -eq 1 ]; then
    printf "│  Serenity:  %-5s" "$se"
    local bar=""; local i=0
    while [ $i -lt $((se / 10)) ]; do bar="${bar}█"; i=$((i + 1)); done
    printf "%-11s│\n" "$bar"
  fi
  printf "│  Rest:      %-5s" "$re"
  bar=""; i=0
  while [ $i -lt $((re / 10)) ]; do bar="${bar}█"; i=$((i + 1)); done
  printf "%-11s│\n" "$bar"
  printf "│  Bond:      %-5s" "$bo"
  bar=""; i=0
  while [ $i -lt $((bo / 10)) ]; do bar="${bar}█"; i=$((i + 1)); done
  printf "%-11s│\n" "$bar"
  if [ "$va" -eq 1 ]; then
    printf "│  Vitality:  %-5s" "$vi"
    bar=""; i=0
    while [ $i -lt $((vi / 10)) ]; do bar="${bar}█"; i=$((i + 1)); done
    printf "%-11s│\n" "$bar"
  else
    printf "│  Vitality:  %-16s│\n" "—"
  fi
  echo "│                             │"
  printf "│  Streak:    %-5s days      │\n" "${streak:-0}"
  printf "│  Lifetime:  %-5s prompts   │\n" "${lifetime:-0}"
  echo "╰─────────────────────────────╯"
}
