# tamaclaudechi - Pet command: bond boost interaction

cmd_pet() {
  ensure_state
  local decayed
  decayed=$(apply_decay)
  read -r en se re bo vi ea va <<< "$decayed"
  local boosted
  boosted=$(apply_event "pet" "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va")
  read -r en se re bo vi ea va <<< "$boosted"
  local mood
  mood=$(resolve_mood "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va")
  write_state "$en" "$se" "$re" "$bo" "$vi" "$mood"
  echo "Hehe that tickles! Bond is now $bo/100."
}
