# tamaclaudechi - JSON output for hook consumption

# --- Output JSON for hook consumption ---
# Detail variables are set by callers (cmd_update/cmd_status) before calling this
output_json() {
  local en=$1 se=$2 re=$3 bo=$4 vi=$5 ea=${6:-1} va=${7:-1} mood=${8} achievement="${9:-}"
  local personality wb name streak lifetime
  personality=$(mood_personality "$mood")
  wb=$(wellbeing "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va")
  name=$(json_val name)
  streak=$(json_val streak)
  lifetime=$(json_val lifetimeInteractions)

  local ach_json="null"
  [ -n "$achievement" ] && ach_json="\"$achievement\""

  local name_json
  if [ "$name" = "null" ] || [ -z "$name" ]; then
    name_json="null"
  else
    name_json="\"$name\""
  fi

  local pers_esc
  pers_esc=$(printf '%s' "$personality" | sed 's/\\/\\\\/g; s/"/\\"/g')

  # Energy: usage-based target
  local energy_target energy_source
  energy_target=$(usage_energy_target)
  if [ "$energy_target" -eq -1 ]; then
    energy_target="null"
    energy_source="fallback"
  else
    energy_source="usage"
  fi

  # Vitality: system health target
  local vitality_target vitality_source
  vitality_target=$(system_vitality_target)
  if [ "$vitality_target" -eq -1 ]; then
    vitality_target="null"
    vitality_source="fallback"
  else
    vitality_source="system"
  fi

  # Work start ISO for rest details
  local work_start_iso
  work_start_iso=$(json_val todayWorkStart)
  local ws_detail_json
  if [ "$work_start_iso" = "null" ] || [ -z "$work_start_iso" ]; then
    ws_detail_json="null"
  else
    ws_detail_json="\"$work_start_iso\""
  fi

  # Today's interactions and session minutes for bond details
  local today_interactions session_mins_val first_met_val days_since_first
  today_interactions=$(json_val todayInteractions)
  session_mins_val="${_d_session_minutes:-0}"
  first_met_val=$(json_val firstMet)
  if [ "$first_met_val" != "null" ] && [ -n "$first_met_val" ]; then
    local first_met_epoch now_ep_d
    first_met_epoch=$(iso_to_epoch "$first_met_val")
    now_ep_d=$(now_epoch)
    days_since_first=$(( (now_ep_d - first_met_epoch) / 86400 ))
  else
    days_since_first=0
  fi

  # History from state
  local history_json
  history_json=$(json_array_val history)

  # Current hour for rest details
  local hour
  hour=$(current_hour)

  cat <<EOF
{
  "mood": "$mood",
  "personality": "$pers_esc",
  "stats": { "energy": $en, "serenity": $se, "rest": $re, "bond": $bo, "vitality": $vi },
  "wellbeing": $wb,
  "name": $name_json,
  "streak": ${streak:-0},
  "lifetime": ${lifetime:-0},
  "achievement_unlocked": $ach_json,
  "details": {
    "serenity": {
      "in_git_repo": ${_d_in_git_repo:-false},
      "dirty_count": ${_d_dirty_count:-0},
      "branch_count": ${_d_branch_count:-0},
      "merged_stale_count": ${_d_merged_count:-0},
      "diff_insertions": ${_d_diff_insertions:-0},
      "diff_deletions": ${_d_diff_deletions:-0},
      "last_commit_ago_secs": ${_d_last_commit_ago:-0}
    },
    "rest": {
      "session_minutes": ${_d_session_minutes:-0},
      "work_start_iso": $ws_detail_json,
      "current_hour": $hour,
      "late_night_penalty": ${_d_late_night_penalty:-0},
      "is_marathon": ${_d_is_marathon:-false},
      "interaction_density": ${_d_interaction_density:-0}
    },
    "bond": {
      "streak_days": ${streak:-0},
      "today_interactions": ${today_interactions:-0},
      "session_minutes": $session_mins_val,
      "lifetime_interactions": ${lifetime:-0},
      "days_since_first_met": $days_since_first
    },
    "energy": {
      "usage_target": $energy_target,
      "source": "$energy_source"
    },
    "vitality": {
      "system_target": $vitality_target,
      "source": "$vitality_source"
    }
  },
  "history": $history_json
}
EOF
}
