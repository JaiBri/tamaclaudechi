# tamaclaudechi - Time utility functions

now_epoch() {
  date +%s
}

iso_to_epoch() {
  local ts="$1"
  if [ -z "$ts" ] || [ "$ts" = "null" ]; then
    now_epoch
    return
  fi
  TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "${ts%Z}" +%s 2>/dev/null || now_epoch
}

current_hour() {
  date +%H | sed 's/^0//'
}
