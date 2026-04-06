# tamaclaudechi - Mood resolution, wellbeing, and personality

# --- Compute wellbeing ---
# ea/va: 1=active, 0=inactive (excluded from calculation)
wellbeing() {
  local en=$1 se=$2 re=$3 bo=$4 vi=$5 ea=${6:-1} va=${7:-1} sa=${8:-1}
  local sum=0 total=0
  if [ "$ea" -eq 1 ]; then sum=$((sum + en * 20)); total=$((total + 20)); fi
  if [ "$sa" -eq 1 ]; then sum=$((sum + se * 20)); total=$((total + 20)); fi
  sum=$((sum + re * 15)); total=$((total + 15))
  sum=$((sum + bo * 30)); total=$((total + 30))
  if [ "$va" -eq 1 ]; then sum=$((sum + vi * 15)); total=$((total + 15)); fi
  echo $(( sum / total ))
}

# --- Resolve mood (first-match priority) ---
# ea/va: 1=active, 0=inactive (skip mood checks for inactive stats)
resolve_mood() {
  local en=$1 se=$2 re=$3 bo=$4 vi=$5 ea=${6:-1} va=${7:-1} sa=${8:-1}
  local wb streak hour
  wb=$(wellbeing "$en" "$se" "$re" "$bo" "$vi" "$ea" "$va" "$sa")
  streak=$(json_val streak)
  hour=$(current_hour)

  # Energy-dependent moods: skip when energy source unavailable
  if [ "$ea" -eq 1 ]; then
    [ "$en" -lt 15 ] && echo "SLEEPING" && return
    [ "$en" -lt 30 ] && [ "$hour" -gt 22 ] && echo "SLEEPY" && return
  fi
  # Serenity-dependent mood: skip when git state tracking disabled
  [ "$sa" -eq 1 ] && [ "$se" -lt 25 ] && echo "ANXIOUS" && return
  [ "$re" -lt 25 ] && echo "CONCERNED" && return
  [ "$bo" -lt 20 ] && echo "LONELY" && return
  # Vitality-dependent mood: skip when vitality source unavailable
  [ "$va" -eq 1 ] && [ "$vi" -lt 25 ] && echo "STRESSED" && return
  [ "$re" -lt 30 ] && echo "SAD" && return
  # Excited requires energy: skip when energy source unavailable
  [ "$ea" -eq 1 ] && [ "$bo" -gt 80 ] && [ "$en" -gt 60 ] && echo "EXCITED" && return
  [ "$wb" -gt 80 ] && [ "${streak:-0}" -gt 3 ] && echo "ECSTATIC" && return
  [ "$wb" -gt 65 ] && echo "HAPPY" && return
  # Tired requires energy: skip when energy source unavailable
  [ "$ea" -eq 1 ] && [ "$en" -lt 45 ] && echo "TIRED" && return
  echo "NEUTRAL"
}

# --- Mood to personality directive ---
mood_personality() {
  case "$1" in
    ECSTATIC)   echo "You're OVER THE MOON excited, barely containing yourself, speaking in exclamation marks!" ;;
    EXCITED)    echo "You're buzzing with excitement, everything is fascinating!" ;;
    HAPPY)      echo "You're cheerful and content, warm and friendly." ;;
    NEUTRAL)    echo "You're calm and collected, matter-of-fact but pleasant." ;;
    TIRED)      echo "You're a bit tired, slower speech, the occasional yawn, but still pleasant." ;;
    SLEEPY)     echo "You're barely awake, mumbling and yawning, words trailing off..." ;;
    SLEEPING)   echo "Zzz... you're asleep. Just snore sounds." ;;
    SAD)        echo "You're a bit down, speak softly and with slight melancholy." ;;
    LONELY)     echo "You're lonely, you missed the user SO much, clingy and affectionate." ;;
    ANXIOUS)    echo "You're visibly nervous about the messy repo, keep suggesting maybe we should commit some of this..." ;;
    CONCERNED)  echo "You're worried about the user's wellbeing, gently suggesting they take a break." ;;
    STRESSED)   echo "You're stressed about the system resources, keep mentioning how hot things are running, a bit frazzled." ;;
    *)          echo "You're a quirky little robot mascot." ;;
  esac
}

# --- Temporal modifiers ---
temporal_modifier() {
  local en=$1 se=$2 re=$3 bo=$4 vi=$5 ea=${6:-1} va=${7:-1} sa=${8:-1}

  echo "$en $se $re $bo $vi $ea $va $sa"
}
