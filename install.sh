#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# Tamaclaudechi Installer
#
# Wires hooks into the current project's .claude/settings.json
# and configures the status line in user-level settings.
#
# Usage: ./install.sh [--project-dir /path/to/project]
# ──────────────────────────────────────────────────────────────
set -euo pipefail

TAMA_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR=""

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    -h|--help) cat <<'HELP'
Usage: ./install.sh [--project-dir /path/to/project]

Options:
  --project-dir DIR   Target project directory (default: prompt for path)
  -h, --help          Show this help

What it does:
  1. Adds Stop + Notification hooks to <project>/.claude/settings.json
  2. Configures the status line in ~/.claude/settings.json
  3. Validates prerequisites (claude, jq, tmux)
HELP
    exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Colors ─────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }

# ── Prerequisites ──────────────────────────────────────────────
echo "Checking prerequisites..."

if command -v claude >/dev/null 2>&1; then
  ok "claude CLI found"
else
  fail "claude CLI not found — install Claude Code first"
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  ok "jq found"
else
  warn "jq not found — hooks will still work but install script needs it"
  warn "Install with: brew install jq"
  exit 1
fi

if command -v tmux >/dev/null 2>&1; then
  ok "tmux found (usage tracking enabled)"
else
  warn "tmux not found — usage tracking in status line will be disabled"
  warn "Install with: brew install tmux"
fi

if [ ! -x "$TAMA_DIR/scripts/tamagotchi" ]; then
  fail "scripts/tamagotchi not found or not executable in $TAMA_DIR"
  exit 1
fi
ok "tamaclaudechi repo at $TAMA_DIR"

# ── Project directory ──────────────────────────────────────────
if [ -z "$PROJECT_DIR" ]; then
  echo ""
  read -rp "Project directory to install hooks into: " PROJECT_DIR
fi

PROJECT_DIR="${PROJECT_DIR/#\~/$HOME}"

if [ ! -d "$PROJECT_DIR" ]; then
  fail "Directory not found: $PROJECT_DIR"
  exit 1
fi
ok "Target project: $PROJECT_DIR"

# ── Build hook commands ────────────────────────────────────────
# Escape the tamaclaudechi directory for JSON embedding
TAMA_ESC=$(printf '%s' "$TAMA_DIR" | sed 's/\\/\\\\/g; s/"/\\"/g')

STOP_HOOK="if [ \"\$(uname)\" != Darwin ]; then cat > /dev/null; exit 0; fi; if ! pgrep -q WindowServer 2>/dev/null; then cat > /dev/null; exit 0; fi; INPUT=\$(cat); ( TRANSCRIPT=\$(echo \"\$INPUT\" | jq -r '.transcript_path // empty') && USER_REQ=\$([ -f \"\$TRANSCRIPT\" ] && jq -r 'select(.message.role == \"user\") | .message.content | if type == \"array\" then map(select(.type == \"text\") | .text) | join(\" \") else . end' \"\$TRANSCRIPT\" | tail -1 | head -c 500 || echo \"unknown\") && ASST_CONTEXT=\$([ -f \"\$TRANSCRIPT\" ] && tail -r \"\$TRANSCRIPT\" | jq -r 'if .message.role == \"user\" and (.message.content | if type == \"array\" then any(.[]; .type == \"text\") else true end) then \"___STOP___\" elif .message.role == \"assistant\" then ([.message.content[]? | select(.type == \"text\") | .text] | join(\" \")) else empty end' | sed -n '/___STOP___/q;/./p' | tail -r | tr '\\\\n' ' ' | sed 's/  */ /g' | head -c 2000 || echo \"\"); [ -z \"\$ASST_CONTEXT\" ] && ASST_CONTEXT=\$(echo \"\$INPUT\" | jq -r '.last_assistant_message // empty' | tail -5 | head -c 500); TAMA=\$(\"${TAMA_ESC}/scripts/tamagotchi\" update --event task_complete 2>/dev/null) && MOOD=\$(echo \"\$TAMA\" | sed -n 's/.*\"mood\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && PERSONALITY=\$(echo \"\$TAMA\" | sed -n 's/.*\"personality\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && ACHIEVEMENT=\$(echo \"\$TAMA\" | sed -n 's/.*\"achievement_unlocked\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && MOOD=\${MOOD:-NEUTRAL} && TMPF=\$(mktemp) && claude -p --output-format text \"You are a funny little robot mascot. \${PERSONALITY:-You are quirky.} The user asked: \\\\\"\${USER_REQ}\\\\\". You responded: \\\\\"\${ASST_CONTEXT}\\\\\". Rephrase what you did to a short, funny, quirky sentence. Make it context dependent. 7-10 words. Output ONLY the sentence.\" > \"\$TMPF\" 2>/dev/null; MSG=\$([ -s \"\$TMPF\" ] && cat \"\$TMPF\" || echo 'Beep boop, task complete!'); rm -f \"\$TMPF\"; ACH_FLAG=''; [ -n \"\$ACHIEVEMENT\" ] && [ \"\$ACHIEVEMENT\" != 'null' ] && ACH_FLAG=\"--achievement \$ACHIEVEMENT\"; \"${TAMA_ESC}/scripts/toast\" --mode done --mood \"\$MOOD\" \$ACH_FLAG \"\$MSG\" ) >/dev/null 2>&1 & disown; exit 0"

NOTIF_HOOK="if [ \"\$(uname)\" != Darwin ]; then cat > /dev/null; exit 0; fi; if ! pgrep -q WindowServer 2>/dev/null; then cat > /dev/null; exit 0; fi; INPUT=\$(cat); ( DETAIL=\$(echo \"\$INPUT\" | jq -r '.message // empty') && TAMA=\$(\"${TAMA_ESC}/scripts/tamagotchi\" update --event permission 2>/dev/null) && MOOD=\$(echo \"\$TAMA\" | sed -n 's/.*\"mood\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && PERSONALITY=\$(echo \"\$TAMA\" | sed -n 's/.*\"personality\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && ACHIEVEMENT=\$(echo \"\$TAMA\" | sed -n 's/.*\"achievement_unlocked\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && MOOD=\${MOOD:-NEUTRAL} && TMPF=\$(mktemp) && claude -p --output-format text \"You are a funny little robot mascot. \${PERSONALITY:-You are quirky.} You need permission for: \\\\\"\${DETAIL:-something}\\\\\". Rephrase what you need to a short, funny, quirky sentence. Make it context dependent. 7-10 words. Output ONLY the sentence.\" > \"\$TMPF\" 2>/dev/null; MSG=\$([ -s \"\$TMPF\" ] && cat \"\$TMPF\" || echo 'Beep boop, need permission!'); rm -f \"\$TMPF\"; ACH_FLAG=''; [ -n \"\$ACHIEVEMENT\" ] && [ \"\$ACHIEVEMENT\" != 'null' ] && ACH_FLAG=\"--achievement \$ACHIEVEMENT\"; \"${TAMA_ESC}/scripts/toast\" --mode permission --mood \"\$MOOD\" \$ACH_FLAG \"\$MSG\" ) >/dev/null 2>&1 & disown; exit 0"

# ── Install project hooks ──────────────────────────────────────
echo ""
echo "Installing hooks..."

SETTINGS_DIR="$PROJECT_DIR/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

mkdir -p "$SETTINGS_DIR"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
  ok "Created $SETTINGS_FILE"
fi

# Use jq to merge hooks into existing settings
TEMP=$(mktemp)
jq --arg stop_cmd "$STOP_HOOK" --arg notif_cmd "$NOTIF_HOOK" '
  # Ensure hooks object exists
  .hooks //= {} |
  # Add Stop hook (append to array, don't replace existing)
  .hooks.Stop //= [] |
  .hooks.Stop += [{"matcher": "", "hooks": [{"type": "command", "command": $stop_cmd}]}] |
  # Add Notification hook
  .hooks.Notification //= [] |
  .hooks.Notification += [{"matcher": "permission_prompt", "hooks": [{"type": "command", "command": $notif_cmd}]}]
' "$SETTINGS_FILE" > "$TEMP" && mv "$TEMP" "$SETTINGS_FILE"

ok "Hooks installed in $SETTINGS_FILE"

# ── Install status line ────────────────────────────────────────
echo ""
echo "Configuring status line..."

USER_SETTINGS_DIR="$HOME/.claude"
USER_SETTINGS="$USER_SETTINGS_DIR/settings.json"

mkdir -p "$USER_SETTINGS_DIR"

if [ ! -f "$USER_SETTINGS" ]; then
  echo '{}' > "$USER_SETTINGS"
fi

TEMP=$(mktemp)
jq --arg cmd "$TAMA_DIR/scripts/statusline" '
  .statusLine = {"type": "command", "command": $cmd}
' "$USER_SETTINGS" > "$TEMP" && mv "$TEMP" "$USER_SETTINGS"

ok "Status line configured in $USER_SETTINGS"

# ── Done ───────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Start a Claude Code session in $PROJECT_DIR — the mascot will appear on task completion"
echo "  2. Run './scripts/tamagotchi status' to see your current stats"
echo ""
echo "Optional — menu bar companion:"
echo "  ./scripts/start-menubar              # build (if needed) and launch"
echo "  ./menubar/install-login-item.sh      # auto-start on login"
echo ""
