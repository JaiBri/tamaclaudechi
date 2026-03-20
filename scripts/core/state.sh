# tamaclaudechi - State management: file paths, defaults, migration, writing

STATE_DIR="$HOME/.config/claude-mascot"
STATE_FILE="$STATE_DIR/state.json"
CONFIG_FILE="$STATE_DIR/config.json"

ensure_config() {
  mkdir -p "$STATE_DIR"
  [ -f "$CONFIG_FILE" ] || echo '{"version":1,"repoRoots":[]}' > "$CONFIG_FILE"
}

# --- Defaults (v4) ---
default_state() {
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  cat <<EOF
{
  "version": 4,
  "stats": { "energy": 70, "serenity": 50, "rest": 70, "bond": 100, "vitality": 80 },
  "meta": {
    "lastInteraction": "$now",
    "lastSessionStart": "$now",
    "todayInteractions": 0,
    "streak": 0,
    "lifetimeInteractions": 0,
    "firstMet": "$now",
    "name": null,
    "sessionStartTime": "$now",
    "todayWorkStart": null,
    "todayWorkEnd": null,
    "history": []
  },
  "achievements": {
    "firstFriend": false,
    "nightOwl": false,
    "centurion": false,
    "streakMaster": false,
    "resurrector": false,
    "speedDemon": false,
    "marathon": false
  },
  "currentMood": "NEUTRAL"
}
EOF
}

# --- Ensure state file exists ---
ensure_state() {
  if [ ! -d "$STATE_DIR" ]; then
    mkdir -p "$STATE_DIR"
  fi
  if [ ! -f "$STATE_FILE" ]; then
    default_state > "$STATE_FILE"
  fi
  # Migrate v1 → v2 → v3 → v4
  migrate_state
}

# --- Migrate v1 → v4 state ---
migrate_state() {
  local version
  version=$(json_val version)

  # v1 → v3 (skip v2 intermediate)
  if [ "${version:-1}" = "1" ]; then
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Read old stats — map to reasonable v3 defaults
    local energy bond
    energy=$(json_val energy)
    bond=$(json_val bond)

    # Preserve what maps: energy stays, bond stays (but capped lower since it was inflated)
    # New stats start at defaults
    local last_interaction last_session today streak lifetime first_met name
    last_interaction=$(json_val lastInteraction)
    last_session=$(json_val lastSessionStart)
    today=$(json_val todayInteractions)
    streak=$(json_val streak)
    lifetime=$(json_val lifetimeInteractions)
    first_met=$(json_val firstMet)
    name=$(json_val name)

    local name_json
    if [ "$name" = "null" ] || [ -z "$name" ]; then
      name_json="null"
    else
      name_json="\"$name\""
    fi

    # Cap migrated bond (was inflated by +3 per interaction)
    [ "${bond:-10}" -gt 50 ] && bond=50

    # Read achievement flags
    local a_firstFriend a_nightOwl a_centurion a_streakMaster a_resurrector a_speedDemon a_marathon
    a_firstFriend=$(json_val firstFriend)
    a_nightOwl=$(json_val nightOwl)
    a_centurion=$(json_val centurion)
    a_streakMaster=$(json_val streakMaster)
    a_resurrector=$(json_val resurrector)
    a_speedDemon=$(json_val speedDemon)
    a_marathon=$(json_val marathon)

    cat > "$STATE_FILE" <<EOF
{
  "version": 3,
  "stats": { "energy": ${energy:-70}, "serenity": 50, "rest": 70, "bond": ${bond:-10} },
  "meta": {
    "lastInteraction": "${last_interaction:-$now}",
    "lastSessionStart": "${last_session:-$now}",
    "todayInteractions": ${today:-0},
    "streak": ${streak:-0},
    "lifetimeInteractions": ${lifetime:-0},
    "firstMet": "${first_met:-$now}",
    "name": $name_json,
    "sessionStartTime": "$now",
    "todayWorkStart": null,
    "todayWorkEnd": null,
    "history": []
  },
  "achievements": {
    "firstFriend": ${a_firstFriend:-false},
    "nightOwl": ${a_nightOwl:-false},
    "centurion": ${a_centurion:-false},
    "streakMaster": ${a_streakMaster:-false},
    "resurrector": ${a_resurrector:-false},
    "speedDemon": ${a_speedDemon:-false},
    "marathon": ${a_marathon:-false}
  },
  "currentMood": "NEUTRAL"
}
EOF
    return
  fi

  # v2 → v3: drop appetite and food-group fields
  if [ "${version:-1}" = "2" ]; then
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local energy serenity rest bond
    energy=$(stat_val energy)
    serenity=$(stat_val serenity)
    rest=$(stat_val rest)
    bond=$(stat_val bond)

    local last_interaction last_session today streak lifetime first_met name
    last_interaction=$(json_val lastInteraction)
    last_session=$(json_val lastSessionStart)
    today=$(json_val todayInteractions)
    streak=$(json_val streak)
    lifetime=$(json_val lifetimeInteractions)
    first_met=$(json_val firstMet)
    name=$(json_val name)

    local name_json
    if [ "$name" = "null" ] || [ -z "$name" ]; then
      name_json="null"
    else
      name_json="\"$name\""
    fi

    local session_start work_start work_end
    session_start=$(json_val sessionStartTime)
    work_start=$(json_val todayWorkStart)
    work_end=$(json_val todayWorkEnd)

    local ws_json we_json
    if [ "$work_start" = "null" ] || [ -z "$work_start" ]; then
      ws_json="null"
    else
      ws_json="\"$work_start\""
    fi
    if [ "$work_end" = "null" ] || [ -z "$work_end" ]; then
      we_json="null"
    else
      we_json="\"$work_end\""
    fi

    local history_json
    history_json=$(json_array_val history)

    local a_firstFriend a_nightOwl a_centurion a_streakMaster a_resurrector a_speedDemon a_marathon
    a_firstFriend=$(json_val firstFriend)
    a_nightOwl=$(json_val nightOwl)
    a_centurion=$(json_val centurion)
    a_streakMaster=$(json_val streakMaster)
    a_resurrector=$(json_val resurrector)
    a_speedDemon=$(json_val speedDemon)
    a_marathon=$(json_val marathon)

    local current_mood
    current_mood=$(json_val currentMood)

    cat > "$STATE_FILE" <<EOF
{
  "version": 3,
  "stats": { "energy": ${energy:-70}, "serenity": ${serenity:-50}, "rest": ${rest:-70}, "bond": ${bond:-10} },
  "meta": {
    "lastInteraction": "${last_interaction:-$now}",
    "lastSessionStart": "${last_session:-$now}",
    "todayInteractions": ${today:-0},
    "streak": ${streak:-0},
    "lifetimeInteractions": ${lifetime:-0},
    "firstMet": "${first_met:-$now}",
    "name": $name_json,
    "sessionStartTime": "${session_start:-$now}",
    "todayWorkStart": $ws_json,
    "todayWorkEnd": $we_json,
    "history": ${history_json:-[]}
  },
  "achievements": {
    "firstFriend": ${a_firstFriend:-false},
    "nightOwl": ${a_nightOwl:-false},
    "centurion": ${a_centurion:-false},
    "streakMaster": ${a_streakMaster:-false},
    "resurrector": ${a_resurrector:-false},
    "speedDemon": ${a_speedDemon:-false},
    "marathon": ${a_marathon:-false}
  },
  "currentMood": "${current_mood:-NEUTRAL}"
}
EOF
  fi

  # v3 → v4: add vitality, reset bond to daily model
  if [ "${version:-1}" = "3" ]; then
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local energy serenity rest
    energy=$(stat_val energy)
    serenity=$(stat_val serenity)
    rest=$(stat_val rest)

    local last_interaction last_session today streak lifetime first_met name
    last_interaction=$(json_val lastInteraction)
    last_session=$(json_val lastSessionStart)
    today=$(json_val todayInteractions)
    streak=$(json_val streak)
    lifetime=$(json_val lifetimeInteractions)
    first_met=$(json_val firstMet)
    name=$(json_val name)

    local name_json
    if [ "$name" = "null" ] || [ -z "$name" ]; then
      name_json="null"
    else
      name_json="\"$name\""
    fi

    local session_start work_start work_end
    session_start=$(json_val sessionStartTime)
    work_start=$(json_val todayWorkStart)
    work_end=$(json_val todayWorkEnd)

    local ws_json we_json
    if [ "$work_start" = "null" ] || [ -z "$work_start" ]; then
      ws_json="null"
    else
      ws_json="\"$work_start\""
    fi
    if [ "$work_end" = "null" ] || [ -z "$work_end" ]; then
      we_json="null"
    else
      we_json="\"$work_end\""
    fi

    local history_json
    history_json=$(json_array_val history)

    local a_firstFriend a_nightOwl a_centurion a_streakMaster a_resurrector a_speedDemon a_marathon
    a_firstFriend=$(json_val firstFriend)
    a_nightOwl=$(json_val nightOwl)
    a_centurion=$(json_val centurion)
    a_streakMaster=$(json_val streakMaster)
    a_resurrector=$(json_val resurrector)
    a_speedDemon=$(json_val speedDemon)
    a_marathon=$(json_val marathon)

    local current_mood
    current_mood=$(json_val currentMood)

    cat > "$STATE_FILE" <<EOF
{
  "version": 4,
  "stats": { "energy": ${energy:-70}, "serenity": ${serenity:-50}, "rest": ${rest:-70}, "bond": 100, "vitality": 80 },
  "meta": {
    "lastInteraction": "${last_interaction:-$now}",
    "lastSessionStart": "${last_session:-$now}",
    "todayInteractions": ${today:-0},
    "streak": ${streak:-0},
    "lifetimeInteractions": ${lifetime:-0},
    "firstMet": "${first_met:-$now}",
    "name": $name_json,
    "sessionStartTime": "${session_start:-$now}",
    "todayWorkStart": $ws_json,
    "todayWorkEnd": $we_json,
    "history": ${history_json:-[]}
  },
  "achievements": {
    "firstFriend": ${a_firstFriend:-false},
    "nightOwl": ${a_nightOwl:-false},
    "centurion": ${a_centurion:-false},
    "streakMaster": ${a_streakMaster:-false},
    "resurrector": ${a_resurrector:-false},
    "speedDemon": ${a_speedDemon:-false},
    "marathon": ${a_marathon:-false}
  },
  "currentMood": "${current_mood:-NEUTRAL}"
}
EOF
  fi
}

# --- Update state file ---
write_state() {
  local en=$1 se=$2 re=$3 bo=$4 vi=$5 mood=$6 achievement="${7:-}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local last_session lifetime today streak first_met name
  last_session=$(json_val lastSessionStart)
  lifetime=$(json_val lifetimeInteractions)
  today=$(json_val todayInteractions)
  streak=$(json_val streak)
  first_met=$(json_val firstMet)
  name=$(json_val name)

  local session_start work_start work_end
  session_start=$(json_val sessionStartTime)
  work_start=$(json_val todayWorkStart)
  work_end=$(json_val todayWorkEnd)

  # Increment counters
  lifetime=$((${lifetime:-0} + 1))
  today=$((${today:-0} + 1))

  # Update streak logic
  local last_iso last_date today_date
  last_iso=$(json_val lastInteraction)
  last_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${last_iso%Z}" +%Y%m%d 2>/dev/null || echo "")
  today_date=$(date +%Y%m%d)

  # Read history from state
  local history_json
  history_json=$(json_array_val history)

  if [ -n "$last_date" ]; then
    local yesterday
    yesterday=$(date -j -v-1d +%Y%m%d 2>/dev/null || echo "")
    if [ "$last_date" = "$yesterday" ] && [ "$today" -le 1 ]; then
      streak=$((${streak:-0} + 1))
    elif [ "$last_date" != "$today_date" ] && [ "$last_date" != "$yesterday" ]; then
      streak=0
    fi
    if [ "$last_date" != "$today_date" ]; then
      # Date rollover — snapshot yesterday's interactions into history
      local prev_today_count
      prev_today_count=$(json_val todayInteractions)
      local prev_date_iso
      prev_date_iso=$(date -j -f "%Y%m%d" "$last_date" +"%Y-%m-%d" 2>/dev/null || echo "")
      if [ -n "$prev_date_iso" ] && [ "${prev_today_count:-0}" -gt 0 ]; then
        local new_entry="{\"date\":\"$prev_date_iso\",\"interactions\":${prev_today_count:-0}}"
        if [ "$history_json" = "[]" ] || [ -z "$history_json" ]; then
          history_json="[$new_entry]"
        else
          # Prepend new entry and trim to 14
          history_json=$(echo "$history_json" | sed "s/^\[/[$new_entry,/")
          history_json=$(echo "$history_json" | perl -e '
            my $json = <STDIN>;
            my @entries;
            while ($json =~ /(\{[^}]+\})/g) { push @entries, $1 }
            splice(@entries, 14) if @entries > 14;
            print "[" . join(",", @entries) . "]";
          ')
        fi
      fi
      today=1
      work_start="null"
      work_end="null"
    fi
  fi

  # Check if 3+ interactions today for streak qualification
  if [ "$today" -ge 3 ] && [ "${streak:-0}" -eq 0 ]; then
    streak=1
  fi

  # Update work time tracking
  if [ "$work_start" = "null" ] || [ -z "$work_start" ]; then
    work_start="$now"
  fi
  work_end="$now"

  # Handle name JSON
  local name_json
  if [ "$name" = "null" ] || [ -z "$name" ]; then
    name_json="null"
  else
    name_json="\"$name\""
  fi

  # Work start/end JSON
  local ws_json we_json
  if [ "$work_start" = "null" ] || [ -z "$work_start" ]; then
    ws_json="null"
  else
    ws_json="\"$work_start\""
  fi
  if [ "$work_end" = "null" ] || [ -z "$work_end" ]; then
    we_json="null"
  else
    we_json="\"$work_end\""
  fi

  # Update achievement flags
  local a_firstFriend a_nightOwl a_centurion a_streakMaster a_resurrector a_speedDemon a_marathon
  a_firstFriend=$(json_val firstFriend)
  a_nightOwl=$(json_val nightOwl)
  a_centurion=$(json_val centurion)
  a_streakMaster=$(json_val streakMaster)
  a_resurrector=$(json_val resurrector)
  a_speedDemon=$(json_val speedDemon)
  a_marathon=$(json_val marathon)

  if [ -n "$achievement" ]; then
    case "$achievement" in
      firstFriend) a_firstFriend="true" ;;
      nightOwl) a_nightOwl="true" ;;
      centurion) a_centurion="true" ;;
      streakMaster) a_streakMaster="true" ;;
      resurrector) a_resurrector="true" ;;
      speedDemon) a_speedDemon="true" ;;
      marathon) a_marathon="true" ;;
    esac
  fi

  cat > "$STATE_FILE" <<EOF
{
  "version": 4,
  "stats": { "energy": $en, "serenity": $se, "rest": $re, "bond": $bo, "vitality": $vi },
  "meta": {
    "lastInteraction": "$now",
    "lastSessionStart": "$last_session",
    "todayInteractions": $today,
    "streak": $streak,
    "lifetimeInteractions": $lifetime,
    "firstMet": "$first_met",
    "name": $name_json,
    "sessionStartTime": "${session_start:-$now}",
    "todayWorkStart": $ws_json,
    "todayWorkEnd": $we_json,
    "history": $history_json
  },
  "achievements": {
    "firstFriend": $a_firstFriend,
    "nightOwl": $a_nightOwl,
    "centurion": $a_centurion,
    "streakMaster": $a_streakMaster,
    "resurrector": $a_resurrector,
    "speedDemon": $a_speedDemon,
    "marathon": $a_marathon
  },
  "currentMood": "$mood"
}
EOF
}
