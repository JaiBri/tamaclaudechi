# tamaclaudechi - Achievement checking and unlocking

# --- Check and unlock achievements ---
check_achievements() {
  local en=$1 se=$2 re=$3 bo=$4 vi=$5 ea=${6:-1} va=${7:-1}
  local unlocked=""

  local lifetime today streak last_iso
  lifetime=$(json_val lifetimeInteractions)
  today=$(json_val todayInteractions)
  streak=$(json_val streak)
  last_iso=$(json_val lastInteraction)
  local hour
  hour=$(current_hour)

  # First Friend
  if [ "$(json_val firstFriend)" = "false" ]; then
    unlocked="firstFriend"
  fi

  # Night Owl
  if [ "$(json_val nightOwl)" = "false" ] && [ "$hour" -ge 0 ] && [ "$hour" -lt 5 ] && [ "${lifetime:-0}" -ge 10 ]; then
    unlocked="nightOwl"
  fi

  # Centurion
  if [ "$(json_val centurion)" = "false" ] && [ "${lifetime:-0}" -ge 99 ]; then
    unlocked="centurion"
  fi

  # Streak Master
  if [ "$(json_val streakMaster)" = "false" ] && [ "${streak:-0}" -ge 7 ]; then
    unlocked="streakMaster"
  fi

  # Resurrector
  if [ "$(json_val resurrector)" = "false" ]; then
    local last_epoch now_ep days_away
    last_epoch=$(iso_to_epoch "$last_iso")
    now_ep=$(now_epoch)
    days_away=$(( (now_ep - last_epoch) / 86400 ))
    if [ "$days_away" -ge 7 ]; then
      unlocked="resurrector"
    fi
  fi

  # Marathon
  if [ "$(json_val marathon)" = "false" ] && [ "${today:-0}" -ge 20 ]; then
    unlocked="marathon"
  fi

  echo "$unlocked"
}
