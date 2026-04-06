# tamaclaudechi - Update command: apply decay, events, and write new state

cmd_update() {
  local event="${1:-prompt}"

  ensure_state

  # Apply decay
  local decayed
  decayed=$(apply_decay)
  read -r en se re bo vi ea va sa <<< "$decayed"

  # Apply serenity convergence from git state (inline to preserve _d_* detail vars)
  if [ "$sa" -eq 1 ]; then
    local _serenity_result
    _serenity_result=$(compute_serenity_from_git)
    local _serenity_adj
    read -r _serenity_adj _d_dirty_count _d_branch_count _d_merged_count _d_diff_insertions _d_diff_deletions _d_last_commit_ago _d_in_git_repo <<< "$_serenity_result"

    if [ "$_d_in_git_repo" = "true" ]; then
      local serenity_target=$((50 + _serenity_adj))
      [ "$serenity_target" -lt 10 ] && serenity_target=10
      [ "$serenity_target" -gt 95 ] && serenity_target=95
      # Blend stored serenity 1/3 of the way toward target each call
      local distance=$((serenity_target - se))
      local step=$(( (distance + (distance > 0 ? 2 : -2)) / 3 ))
      # Ensure we always move at least 1 point toward target
      if [ "$distance" -gt 0 ] && [ "$step" -lt 1 ]; then step=1; fi
      if [ "$distance" -lt 0 ] && [ "$step" -gt -1 ]; then step=-1; fi
      [ "$distance" -eq 0 ] && step=0
      se=$(clamp $((se + step)))
    fi
  else
    _d_in_git_repo=false
  fi

  # Apply rest adjustments from work patterns (captures detail values)
  local rest_result
  rest_result=$(compute_rest_adjustment)
  local rest_adj
  read -r rest_adj _d_session_minutes _d_late_night_penalty _d_is_marathon _d_interaction_density <<< "$rest_result"
  re=$(clamp $((re + rest_adj)))

  # Apply event bonuses
  local boosted
  boosted=$(apply_event "$event" "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va")
  read -r en se re bo vi ea va <<< "$boosted"

  # Temporal modifiers
  local temped
  temped=$(temporal_modifier "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va" "$sa")
  read -r en se re bo vi ea va sa <<< "$temped"

  # Check achievements
  local achievement
  achievement=$(check_achievements "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va")

  # Resolve mood
  local mood
  mood=$(resolve_mood "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va" "$sa")

  # Write state
  write_state "$en" "$se" "$re" "$bo" "$vi" "$mood" "$achievement"

  # Output JSON
  output_json "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va" "$sa" "$mood" "$achievement"
}
