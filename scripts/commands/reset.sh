# tamaclaudechi - Reset command: restore default state

cmd_reset() {
  ensure_state
  default_state > "$STATE_FILE"
  echo "Mascot state reset to defaults."
}
