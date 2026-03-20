# tamaclaudechi - Rest adjustment computation from work patterns

# --- Rest: compute from work patterns ---
# Returns: adjustment session_minutes late_night_penalty is_marathon interaction_density
compute_rest_adjustment() {
  local hour session_start_iso
  hour=$(current_hour)
  session_start_iso=$(json_val sessionStartTime)

  # Base drain: -2 per message
  local base_drain=2
  local late_night_extra=0

  # Night gradient (22:00–05:59): extra drain based on depth into the night
  # depth: hour>=22 → hour-22, hour<6 → hour+2
  # extra = depth + 1  (ranges 1–8)
  if [ "$hour" -ge 22 ]; then
    late_night_extra=$(( (hour - 22) + 1 ))
  elif [ "$hour" -lt 6 ]; then
    late_night_extra=$(( (hour + 2) + 1 ))
  fi

  local adjustment=$(( -(base_drain + late_night_extra) ))

  # Session length (informational only — no longer affects adjustment)
  local session_start_epoch now_ep session_minutes session_hours is_marathon
  session_start_epoch=$(iso_to_epoch "$session_start_iso")
  now_ep=$(now_epoch)
  session_minutes=$(( (now_ep - session_start_epoch) / 60 ))
  session_hours=$(( session_minutes / 60 ))
  is_marathon=false
  [ "$session_hours" -ge 4 ] && is_marathon=true

  # Interaction density (informational only — no longer affects adjustment)
  local interaction_density=0
  local today_count
  today_count=$(json_val todayInteractions)
  today_count=${today_count:-0}
  local work_start_iso_rd
  work_start_iso_rd=$(json_val todayWorkStart)
  if [ "$work_start_iso_rd" != "null" ] && [ -n "$work_start_iso_rd" ] && [ "$today_count" -gt 0 ]; then
    local ws_epoch now_ep_rd hours_worked
    ws_epoch=$(iso_to_epoch "$work_start_iso_rd")
    now_ep_rd=$(now_epoch)
    hours_worked=$(( (now_ep_rd - ws_epoch) / 3600 ))
    [ "$hours_worked" -lt 1 ] && hours_worked=1
    interaction_density=$((today_count / hours_worked))
  fi

  echo "$adjustment $session_minutes $late_night_extra $is_marathon $interaction_density"
}
