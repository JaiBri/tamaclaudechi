# tamaclaudechi - Rename command: give the mascot a name

cmd_rename() {
  local new_name="$1"
  if [ -z "$new_name" ]; then
    echo "Usage: tamagotchi rename <name>"
    exit 1
  fi
  ensure_state
  sed -i '' "s/\"name\":.*/\"name\": \"$new_name\"/" "$STATE_FILE"
  echo "Mascot renamed to: $new_name"
}
