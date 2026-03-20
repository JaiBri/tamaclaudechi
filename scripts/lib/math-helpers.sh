# tamaclaudechi - Math utility functions

# Clamp value between 0 and 100
clamp() {
  local val=$1
  [ "$val" -lt 0 ] && val=0
  [ "$val" -gt 100 ] && val=100
  echo "$val"
}
