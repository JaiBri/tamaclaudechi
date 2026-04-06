# tamaclaudechi - Time-based stat decay

# --- Usage-based energy target ---
# Returns target energy based on API token usage pace, or -1 if data unavailable
usage_energy_target() {
  local usage_data
  usage_data=$(read_usage_json) || { echo "-1"; return; }

  local session_pct session_elapsed week_pct week_elapsed
  read -r session_pct session_elapsed week_pct week_elapsed <<< "$usage_data"

  # pace = pct_used - pct_time_elapsed (positive = burning hot)
  local week_pace=$(( week_pct - week_elapsed ))
  local session_pace=$(( session_pct - session_elapsed ))
  local combined_pace=$(( (week_pace + session_pace) / 2 ))
  local target=$(( 70 - combined_pace ))

  # Clamp 10-100
  [ "$target" -lt 10 ] && target=10
  [ "$target" -gt 100 ] && target=100
  echo "$target"
}

# --- System vitality target ---
# Returns target vitality based on system metrics, or -1 if data unavailable
system_vitality_target() {
  local system_data
  system_data=$(read_system_json) || { echo "-1"; return; }

  local cpu ram swap disk gpu
  read -r cpu ram swap disk gpu <<< "$system_data"

  # disk penalty only when >80%
  local disk_penalty=$(( disk > 80 ? (disk - 80) * 2 : 0 ))
  # swap weighted at half
  local swap_weighted=$(( swap / 2 ))

  local pressure=$(( (cpu * 40 + ram * 30 + swap_weighted * 10 + disk_penalty * 10 + gpu * 10) / 100 ))
  local target=$(( 100 - pressure ))

  # Clamp 10-100
  [ "$target" -lt 10 ] && target=10
  [ "$target" -gt 100 ] && target=100
  echo "$target"
}

# --- Apply time-based decay ---
# Returns: energy serenity rest bond vitality (space-separated)
apply_decay() {
  local last_iso energy serenity rest bond vitality
  last_iso=$(json_val lastInteraction)
  energy=$(stat_val energy)
  serenity=$(stat_val serenity)
  rest=$(stat_val rest)
  bond=$(stat_val bond)
  vitality=$(stat_val vitality)
  : "${vitality:=80}"

  local last_epoch now_ep hours_elapsed
  last_epoch=$(iso_to_epoch "$last_iso")
  now_ep=$(now_epoch)
  hours_elapsed=$(( (now_ep - last_epoch) / 3600 ))

  # Cap decay at 48 hours to prevent total zeroing after long absence
  [ "$hours_elapsed" -gt 48 ] && hours_elapsed=48

  # Session-gap reset: if 2+ hours since last interaction, reset sessionStartTime
  if [ "$hours_elapsed" -ge 2 ]; then
    local now_iso
    now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    sed -i '' "s/\"sessionStartTime\": *\"[^\"]*\"/\"sessionStartTime\": \"$now_iso\"/" "$STATE_FILE"
  fi

  if [ "$hours_elapsed" -gt 0 ]; then
    # Serenity: no longer time-decayed — entirely git-driven via convergence

    # Rest: +8/hr when idle (0→100 in ~12h)
    rest=$(clamp $(( rest + 8 * hours_elapsed )))
  fi

  # Bond: daily model — check for date rollover
  local last_date today_date
  last_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${last_iso%Z}" +%Y%m%d 2>/dev/null || echo "")
  today_date=$(date +%Y%m%d)

  if [ -n "$last_date" ] && [ "$last_date" != "$today_date" ]; then
    # Calculate missed days
    local last_epoch_day today_epoch_day days_gap missed
    last_epoch_day=$(date -j -f "%Y%m%d" "$last_date" +%s 2>/dev/null || echo "$last_epoch")
    today_epoch_day=$(date -j -f "%Y%m%d" "$today_date" +%s 2>/dev/null || echo "$now_ep")
    days_gap=$(( (today_epoch_day - last_epoch_day) / 86400 ))
    missed=$(( days_gap - 1 ))  # last_date was active, don't penalize it
    [ "$missed" -lt 0 ] && missed=0
    [ "$missed" -gt 10 ] && missed=10  # cap at 10 days = -100 max

    bond=$(clamp $(( bond - 10 * missed + 10 )))  # -10 per missed day, +10 for today
  fi

  # Check for 2hr+ break during daytime (gap > 2hrs, hour 8-20)
  local hour
  hour=$(current_hour)
  if [ "$hours_elapsed" -ge 2 ] && [ "$hour" -ge 8 ] && [ "$hour" -le 20 ]; then
    rest=$(clamp $((rest + 10)))
  fi

  # Check for weekend rest bonus (Monday check)
  local dow
  dow=$(date +%u) # 1=Monday
  if [ "$dow" -eq 1 ] && [ "$hours_elapsed" -ge 24 ]; then
    local last_day
    last_day=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${last_iso%Z}" +%u 2>/dev/null || echo "0")
    if [ "${last_day:-0}" -le 5 ]; then
      local weekend_days=0
      [ "${last_day:-0}" -le 5 ] && weekend_days=2
      [ "${last_day:-0}" -eq 6 ] && weekend_days=1
      rest=$(clamp $((rest + 10 * weekend_days)))
    fi
  fi

  # Energy: blend toward usage-based target
  local target
  target=$(usage_energy_target)
  if [ "$target" -ne -1 ]; then
    if [ "$energy" -gt "$target" ]; then
      local decay=$(( (energy - target) / 2 ))
      [ "$decay" -lt 1 ] && decay=1
      energy=$(clamp $(( energy - decay )))
    elif [ "$energy" -lt "$target" ]; then
      local rise=$(( (target - energy) / 3 ))
      [ "$rise" -lt 1 ] && rise=1
      energy=$(clamp $(( energy + rise )))
    fi
  fi

  # Vitality: blend toward system health target
  local vi_target
  vi_target=$(system_vitality_target)
  if [ "$vi_target" -ne -1 ]; then
    if [ "$vitality" -gt "$vi_target" ]; then
      local vi_decay=$(( (vitality - vi_target) / 2 ))
      [ "$vi_decay" -lt 1 ] && vi_decay=1
      vitality=$(clamp $(( vitality - vi_decay )))
    elif [ "$vitality" -lt "$vi_target" ]; then
      local vi_rise=$(( (vi_target - vitality) / 3 ))
      [ "$vi_rise" -lt 1 ] && vi_rise=1
      vitality=$(clamp $(( vitality + vi_rise )))
    fi
  fi

  # Availability flags: 1 if data source exists, 0 if fallback
  local en_active=1 vi_active=1 se_active=1
  [ "$target" -eq -1 ] && en_active=0
  [ "$vi_target" -eq -1 ] && vi_active=0
  local git_cfg; git_cfg=$(config_val gitStateEnabled)
  [ "$git_cfg" = "false" ] && se_active=0

  echo "$energy $serenity $rest $bond $vitality $en_active $vi_active $se_active"
}
