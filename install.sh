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
# Hook commands use heredocs for readability; __TAMA_DIR__ is replaced afterward

read -r -d '' STOP_HOOK <<'ENDHOOK' || true
if [ "$CLAUDE_CODE_HOOK" = 1 ]; then cat > /dev/null; exit 0; fi; if [ "$(uname)" != Darwin ]; then cat > /dev/null; exit 0; fi; if ! pgrep -q WindowServer 2>/dev/null; then cat > /dev/null; exit 0; fi; INPUT=$(cat); TAMA_DIR="__TAMA_DIR__"; LOG_FILE="$HOME/.config/claude-mascot/llm-calls.jsonl"; ( TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty'); USER_REQ=$([ -f "$TRANSCRIPT" ] && jq -r 'select(.message.role == "user") | select(.message.content | if type == "array" then all(.[]; .type != "tool_result") else true end) | .message.content | if type == "array" then map(select(.type == "text") | .text) | join(" ") else . end' "$TRANSCRIPT" | tail -1 | head -c 500 || echo "unknown"); ASST_CONTEXT=$([ -f "$TRANSCRIPT" ] && tail -r "$TRANSCRIPT" | jq -r 'if .message.role == "user" and (.message.content | if type == "array" then any(.[]; .type == "text") else true end) then "___STOP___" elif .message.role == "assistant" then ([.message.content[]? | select(.type == "text") | .text] | join(" ")) else empty end' | sed -n '/___STOP___/q;/./p' | tail -r | tr '\n' ' ' | sed 's/  */ /g' | head -c 2000 || echo ""); [ -z "$ASST_CONTEXT" ] && ASST_CONTEXT=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' | tail -5 | head -c 500); TAMA=$("$TAMA_DIR/scripts/tamagotchi" update --event task_complete 2>/dev/null) || TAMA=""; MOOD=$(echo "$TAMA" | sed -n 's/.*"mood"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'); PERSONALITY=$(echo "$TAMA" | sed -n 's/.*"personality"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'); ACHIEVEMENT=$(echo "$TAMA" | sed -n 's/.*"achievement_unlocked"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'); MOOD=${MOOD:-NEUTRAL}; MSG=$(cd "$TAMA_DIR" && "$TAMA_DIR/scripts/generate-message" --mode done --mood "$MOOD" --personality "$PERSONALITY" --user-req "$USER_REQ" --asst-context "$ASST_CONTEXT" 2>/dev/null) || MSG='Beep boop, task complete!'; [ -z "$MSG" ] && MSG='Beep boop, task complete!'; PROMPT="(via generate-message)"; LLM_ERR=""; mkdir -p "$(dirname "$LOG_FILE")"; _UR=$(printf '%s' "$USER_REQ" | jq -Rs .); _AC=$(printf '%s' "$ASST_CONTEXT" | jq -Rs .); _PR=$(printf '%s' "$PROMPT" | jq -Rs .); _RS=$(printf '%s' "$MSG" | jq -Rs .); _ER=$(printf '%s' "$LLM_ERR" | jq -Rs .); _PE=$(printf '%s' "$PERSONALITY" | jq -Rs .); printf '{"ts":"%s","event":"task_complete","user_req":%s,"asst_ctx":%s,"mood":"%s","personality":%s,"prompt":%s,"response":%s,"error":%s,"project":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$_UR" "$_AC" "$MOOD" "$_PE" "$_PR" "$_RS" "$_ER" "$PWD" >> "$LOG_FILE"; tail -200 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"; ACH_FLAG=''; [ -n "$ACHIEVEMENT" ] && [ "$ACHIEVEMENT" != 'null' ] && ACH_FLAG="--achievement $ACHIEVEMENT"; "$TAMA_DIR/scripts/toast" --mode done --mood "$MOOD" $ACH_FLAG "$MSG" ) >/dev/null 2>&1 & disown; exit 0
ENDHOOK
STOP_HOOK="${STOP_HOOK//__TAMA_DIR__/$TAMA_DIR}"

read -r -d '' NOTIF_HOOK <<'ENDHOOK' || true
if [ "$CLAUDE_CODE_HOOK" = 1 ]; then cat > /dev/null; exit 0; fi; if [ "$(uname)" != Darwin ]; then cat > /dev/null; exit 0; fi; if ! pgrep -q WindowServer 2>/dev/null; then cat > /dev/null; exit 0; fi; INPUT=$(cat); TAMA_DIR="__TAMA_DIR__"; LOG_FILE="$HOME/.config/claude-mascot/llm-calls.jsonl"; ( DETAIL=$(echo "$INPUT" | jq -r '.message // empty') || DETAIL=""; TAMA=$("$TAMA_DIR/scripts/tamagotchi" update --event permission 2>/dev/null) || TAMA=""; MOOD=$(echo "$TAMA" | sed -n 's/.*"mood"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'); PERSONALITY=$(echo "$TAMA" | sed -n 's/.*"personality"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'); ACHIEVEMENT=$(echo "$TAMA" | sed -n 's/.*"achievement_unlocked"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'); MOOD=${MOOD:-NEUTRAL}; MSG=$(cd "$TAMA_DIR" && "$TAMA_DIR/scripts/generate-message" --mode permission --mood "$MOOD" --personality "$PERSONALITY" --user-req "$DETAIL" 2>/dev/null) || MSG='Beep boop, need permission!'; [ -z "$MSG" ] && MSG='Beep boop, need permission!'; PROMPT="(via generate-message)"; LLM_ERR=""; mkdir -p "$(dirname "$LOG_FILE")"; _DE=$(printf '%s' "$DETAIL" | jq -Rs .); _PR=$(printf '%s' "$PROMPT" | jq -Rs .); _RS=$(printf '%s' "$MSG" | jq -Rs .); _ER=$(printf '%s' "$LLM_ERR" | jq -Rs .); _PE=$(printf '%s' "$PERSONALITY" | jq -Rs .); printf '{"ts":"%s","event":"permission","user_req":%s,"asst_ctx":"","mood":"%s","personality":%s,"prompt":%s,"response":%s,"error":%s,"project":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$_DE" "$MOOD" "$_PE" "$_PR" "$_RS" "$_ER" "$PWD" >> "$LOG_FILE"; tail -200 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"; ACH_FLAG=''; [ -n "$ACHIEVEMENT" ] && [ "$ACHIEVEMENT" != 'null' ] && ACH_FLAG="--achievement $ACHIEVEMENT"; "$TAMA_DIR/scripts/toast" --mode permission --mood "$MOOD" $ACH_FLAG "$MSG" ) >/dev/null 2>&1 & disown; exit 0
ENDHOOK
NOTIF_HOOK="${NOTIF_HOOK//__TAMA_DIR__/$TAMA_DIR}"

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

# Use jq to merge hooks — remove existing tamaclaudechi hooks first (dedup), then add new
TEMP=$(mktemp)
jq --arg stop_cmd "$STOP_HOOK" --arg notif_cmd "$NOTIF_HOOK" '
  # Ensure hooks object exists
  .hooks //= {} |
  # Remove existing tamaclaudechi Stop hooks, preserve others (e.g. chat-namer)
  .hooks.Stop = [(.hooks.Stop // [])[] | select(.hooks[0].command | contains("TAMA_DIR=") | not)] |
  .hooks.Stop += [{"matcher": "", "hooks": [{"type": "command", "command": $stop_cmd}]}] |
  # Remove existing tamaclaudechi Notification hooks, preserve others
  .hooks.Notification = [(.hooks.Notification // [])[] | select(.hooks[0].command | contains("TAMA_DIR=") | not)] |
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
