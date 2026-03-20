# tamaclaudechi - Event bonus application

# --- Apply event bonuses ---
# Returns: energy serenity rest bond vitality en_active vi_active
apply_event() {
  local event="$1"
  local en="$2" se="$3" re="$4" bo="$5" vi="$6" ea="${7:-1}" va="${8:-1}"

  # Event-specific bonuses
  case "$event" in
    task_complete)
      # Bond no longer boosted by task_complete — managed by daily model
      ;;
    session_start)
      en=$(clamp $((en + 15)))
      ;;
    pet)
      bo=$(clamp $((bo + 5)))
      ;;
  esac

  echo "$en $se $re $bo $vi $ea $va"
}
