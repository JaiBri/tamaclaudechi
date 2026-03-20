# tamaclaudechi - Diagnose command: check hooks, state, logs, data sources

cmd_diagnose() {
  ensure_state
  ensure_config
  source "$SCRIPT_DIR/lib/log.sh"

  local subcmd="${1:-all}"
  shift || true

  case "$subcmd" in
    logs)   _diag_logs "${1:-10}" ;;
    hooks)  _diag_hooks ;;
    state)  _diag_state ;;
    sources) _diag_sources ;;
    all)
      _diag_state
      echo ""
      _diag_hooks
      echo ""
      _diag_sources
      echo ""
      _diag_logs "${1:-5}"
      ;;
    *)
      echo "Usage: tamagotchi diagnose [logs [N] | hooks | state | sources | all]" >&2
      return 1
      ;;
  esac
}

# --- Logs subcmd ---
_diag_logs() {
  echo "── LLM Call Log ──"
  format_llm_log "${1:-10}"
}

# --- Hooks subcmd ---
_diag_hooks() {
  echo "── Hook Status ──"

  local roots
  roots=$(jq -r '.repoRoots[]? // empty' "$CONFIG_FILE" 2>/dev/null)

  if [ -z "$roots" ]; then
    echo "  No repo roots configured."
    echo "  Add with: ./scripts/tamagotchi config repo-roots --add /path/to/project"
    return 0
  fi

  echo "$roots" | while IFS= read -r root; do
    local settings="$root/.claude/settings.json"
    if [ ! -f "$settings" ]; then
      printf "  %-40s  %s\n" "$root" "MISSING — no .claude/settings.json"
      continue
    fi

    local stop_count notif_count
    stop_count=$(jq '[.hooks.Stop[]? | select(.hooks[]?.command | contains("TAMA_DIR="))] | length' "$settings" 2>/dev/null || echo 0)
    notif_count=$(jq '[.hooks.Notification[]? | select(.hooks[]?.command | contains("TAMA_DIR="))] | length' "$settings" 2>/dev/null || echo 0)

    local status="ok"
    local details="Stop=$stop_count Notif=$notif_count"

    if [ "$stop_count" -eq 0 ] && [ "$notif_count" -eq 0 ]; then
      status="NOT INSTALLED"
    elif [ "$stop_count" -gt 1 ] || [ "$notif_count" -gt 1 ]; then
      status="DUPLICATES"
    fi

    printf "  %-40s  %s  (%s)\n" "$root" "$status" "$details"
  done
}

# --- State subcmd ---
_diag_state() {
  echo "── State ──"

  if [ ! -f "$STATE_FILE" ]; then
    echo "  State file: MISSING ($STATE_FILE)"
    return 1
  fi

  local version mood last_interaction
  version=$(jq -r '.version // "unknown"' "$STATE_FILE" 2>/dev/null)
  mood=$(jq -r '.currentMood // "unknown"' "$STATE_FILE" 2>/dev/null)
  last_interaction=$(jq -r '.meta.lastInteraction // "never"' "$STATE_FILE" 2>/dev/null)

  echo "  File: $STATE_FILE"
  echo "  Version: $version"
  echo "  Mood: $mood"
  echo "  Last interaction: $last_interaction"

  # Check version
  if [ "$version" != "4" ]; then
    echo "  WARNING: Expected version 4, got $version"
  fi

  # Check freshness
  if [ "$last_interaction" != "never" ] && [ "$last_interaction" != "null" ]; then
    local last_epoch now_epoch age_hrs
    last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_interaction" +%s 2>/dev/null || echo 0)
    now_epoch=$(date +%s)
    if [ "$last_epoch" -gt 0 ]; then
      age_hrs=$(( (now_epoch - last_epoch) / 3600 ))
      if [ "$age_hrs" -gt 24 ]; then
        echo "  WARNING: State is ${age_hrs}h old (last interaction >24h ago)"
      fi
    fi
  fi

  # Check stats exist
  local stat_count
  stat_count=$(jq '.stats | keys | length' "$STATE_FILE" 2>/dev/null || echo 0)
  echo "  Stats: $stat_count (expected 5)"
  if [ "$stat_count" -ne 5 ]; then
    echo "  WARNING: Expected 5 stats (energy, serenity, rest, bond, vitality)"
  fi

  # Show current stats
  local en se re bo vi
  en=$(jq '.stats.energy // "?"' "$STATE_FILE" 2>/dev/null)
  se=$(jq '.stats.serenity // "?"' "$STATE_FILE" 2>/dev/null)
  re=$(jq '.stats.rest // "?"' "$STATE_FILE" 2>/dev/null)
  bo=$(jq '.stats.bond // "?"' "$STATE_FILE" 2>/dev/null)
  vi=$(jq '.stats.vitality // "?"' "$STATE_FILE" 2>/dev/null)
  echo "  Values: energy=$en serenity=$se rest=$re bond=$bo vitality=$vi"
}

# --- Sources subcmd ---
_diag_sources() {
  echo "── Data Sources ──"

  # Usage data (for energy)
  local usage_file="$STATE_DIR/usage.json"
  if [ -f "$usage_file" ]; then
    local usage_age
    usage_age=$(( ($(date +%s) - $(stat -f %m "$usage_file" 2>/dev/null || echo 0)) ))
    if [ "$usage_age" -lt 300 ]; then
      echo "  usage.json: ok (${usage_age}s old)"
    else
      echo "  usage.json: STALE (${usage_age}s old, >5min)"
    fi
  else
    echo "  usage.json: MISSING — energy will use fallback (circadian)"
  fi

  # System data (for vitality)
  local system_file="$STATE_DIR/system.json"
  if [ -f "$system_file" ]; then
    local sys_age
    sys_age=$(( ($(date +%s) - $(stat -f %m "$system_file" 2>/dev/null || echo 0)) ))
    if [ "$sys_age" -lt 300 ]; then
      echo "  system.json: ok (${sys_age}s old)"
    else
      echo "  system.json: STALE (${sys_age}s old, >5min)"
    fi
  else
    echo "  system.json: MISSING — vitality will use fallback"
  fi

  # Usage scraper
  if tmux has-session -t claude-usage 2>/dev/null; then
    echo "  usage-scraper: RUNNING (tmux session: claude-usage)"
  else
    echo "  usage-scraper: NOT RUNNING — start with: ./scripts/usage-scraper start"
  fi

  # System monitor
  local monitor_script="$SCRIPT_DIR/system-monitor"
  if [ -x "$monitor_script" ]; then
    echo "  system-monitor: available"
  else
    echo "  system-monitor: NOT FOUND at $monitor_script"
  fi
}
