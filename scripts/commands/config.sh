# tamaclaudechi - Config command: view and manage configuration

cmd_config() {
  ensure_config
  local subcmd="${1:-get}"
  shift || true

  case "$subcmd" in
    get)
      cat "$CONFIG_FILE"
      ;;
    repo-roots)
      local action=""
      local path_arg=""
      while [ $# -gt 0 ]; do
        case "$1" in
          --add) action="add"; path_arg="$2"; shift 2 ;;
          --remove) action="remove"; path_arg="$2"; shift 2 ;;
          --scan) action="scan"; shift ;;
          *) shift ;;
        esac
      done
      case "$action" in
        add)
          if [ -z "$path_arg" ]; then
            echo "Usage: tamagotchi config repo-roots --add <path>" >&2
            return 1
          fi
          config_repo_roots_add "$path_arg"
          echo "Added: $path_arg"
          ;;
        remove)
          if [ -z "$path_arg" ]; then
            echo "Usage: tamagotchi config repo-roots --remove <path>" >&2
            return 1
          fi
          config_repo_roots_remove "$path_arg"
          echo "Removed: $path_arg"
          ;;
        scan)
          config_repo_roots_scan
          ;;
        *)
          config_repo_roots
          ;;
      esac
      ;;
    *)
      echo "Usage: tamagotchi config {get|repo-roots} [--add|--remove|--scan]" >&2
      return 1
      ;;
  esac
}
