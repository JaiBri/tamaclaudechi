# tamaclaudechi - LLM call log reader/formatter

LOG_FILE="$STATE_DIR/llm-calls.jsonl"

# --- Read last N log entries ---
read_llm_log() {
  local n="${1:-10}"
  if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
    echo "No log entries yet."
    echo "Log file: $LOG_FILE"
    return 0
  fi
  tail -"$n" "$LOG_FILE"
}

# --- Format log entries for human display ---
format_llm_log() {
  local n="${1:-10}"
  if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
    echo "No log entries yet."
    echo "Log file: $LOG_FILE"
    return 0
  fi

  local count
  count=$(wc -l < "$LOG_FILE" | tr -d ' ')
  echo "LLM Call Log ($count total entries, showing last $n)"
  echo "────────────────────────────────────────"

  tail -"$n" "$LOG_FILE" | while IFS= read -r line; do
    local ts event mood response error project user_req
    ts=$(echo "$line" | jq -r '.ts // "?"')
    event=$(echo "$line" | jq -r '.event // "?"')
    mood=$(echo "$line" | jq -r '.mood // "?"')
    response=$(echo "$line" | jq -r '.response // ""')
    error=$(echo "$line" | jq -r '.error // ""')
    project=$(echo "$line" | jq -r '.project // "?"')
    user_req=$(echo "$line" | jq -r '.user_req // ""' | head -c 80)

    echo ""
    echo "  $ts  [$event]  mood=$mood"
    [ -n "$user_req" ] && echo "  user: ${user_req}..."
    if [ -n "$error" ]; then
      echo "  ERROR: $error"
    elif [ -n "$response" ]; then
      echo "  quip: $response"
    fi
    echo "  project: $project"
  done
  echo ""
}
