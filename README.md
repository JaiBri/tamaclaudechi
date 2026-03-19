# Tamaclaudechi

A living companion that responds to your coding habits, time of day, and interaction history. The pixel-art robot mascot lives in macOS toast overlays and a native menu bar app, appearing after Claude finishes tasks or needs permission.

## How It Works

```
Hook fires → tamagotchi update --event <type> → returns {mood, personality, stats}
           → claude -p generates quip (with mood personality injected)
           → toast --mode <X> --mood <MOOD> "quip"
```

The mascot has 5 stats (0-100) that decay over time and grow from interactions. Stats determine the current **mood**, which affects visuals (CSS filters, breathing animation, particles) and personality (injected into the prompt for contextual quips).

## Quick Install

```bash
git clone https://github.com/JaiBri/tamaclaudechi.git
cd tamaclaudechi
./install.sh
```

The install script will:
- Wire hooks into your project's `.claude/settings.json`
- Configure the status line in your user-level `~/.claude/settings.json`
- Validate prerequisites

### Prerequisites

- **macOS** (toast + menu bar are macOS-native)
- **Claude Code CLI** (`claude` command available in PATH)
- **jq** (`brew install jq`) — optional but recommended
- **tmux** (`brew install tmux`) — optional, enables API usage tracking in the status line

## Manual Setup

If you prefer not to run the install script, add these hooks to your project's `.claude/settings.json`:

<details>
<summary>Stop hook (task complete toast)</summary>

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "if [ \"$(uname)\" != Darwin ]; then cat > /dev/null; exit 0; fi; if ! pgrep -q WindowServer 2>/dev/null; then cat > /dev/null; exit 0; fi; INPUT=$(cat); TAMA_DIR=\"/absolute/path/to/tamaclaudechi\"; ( TRANSCRIPT=$(echo \"$INPUT\" | jq -r '.transcript_path // empty') && USER_REQ=$([ -f \"$TRANSCRIPT\" ] && jq -r 'select(.message.role == \"user\") | .message.content | if type == \"array\" then map(select(.type == \"text\") | .text) | join(\" \") else . end' \"$TRANSCRIPT\" | tail -1 | head -c 500 || echo \"unknown\") && ASST_CONTEXT=$([ -f \"$TRANSCRIPT\" ] && tail -r \"$TRANSCRIPT\" | jq -r 'if .message.role == \"user\" and (.message.content | if type == \"array\" then any(.[]; .type == \"text\") else true end) then \"___STOP___\" elif .message.role == \"assistant\" then ([.message.content[]? | select(.type == \"text\") | .text] | join(\" \")) else empty end' | sed -n '/___STOP___/q;/./p' | tail -r | tr '\\n' ' ' | sed 's/  */ /g' | head -c 2000 || echo \"\"); [ -z \"$ASST_CONTEXT\" ] && ASST_CONTEXT=$(echo \"$INPUT\" | jq -r '.last_assistant_message // empty' | tail -5 | head -c 500); TAMA=$(\"$TAMA_DIR/scripts/tamagotchi\" update --event task_complete 2>/dev/null) && MOOD=$(echo \"$TAMA\" | sed -n 's/.*\"mood\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && PERSONALITY=$(echo \"$TAMA\" | sed -n 's/.*\"personality\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && ACHIEVEMENT=$(echo \"$TAMA\" | sed -n 's/.*\"achievement_unlocked\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && MOOD=${MOOD:-NEUTRAL} && TMPF=$(mktemp) && claude -p --output-format text \"You are a funny little robot mascot. ${PERSONALITY:-You are quirky.} The user asked: \\\"${USER_REQ}\\\". You responded: \\\"${ASST_CONTEXT}\\\". Rephrase what you did to a short, funny, quirky sentence. Make it context dependent. 7-10 words. Output ONLY the sentence.\" > \"$TMPF\" 2>/dev/null; MSG=$([ -s \"$TMPF\" ] && cat \"$TMPF\" || echo 'Beep boop, task complete!'); rm -f \"$TMPF\"; ACH_FLAG=''; [ -n \"$ACHIEVEMENT\" ] && [ \"$ACHIEVEMENT\" != 'null' ] && ACH_FLAG=\"--achievement $ACHIEVEMENT\"; \"$TAMA_DIR/scripts/toast\" --mode done --mood \"$MOOD\" $ACH_FLAG \"$MSG\" ) >/dev/null 2>&1 & disown; exit 0"
          }
        ]
      }
    ]
  }
}
```

Replace `/absolute/path/to/tamaclaudechi` with the actual path to your clone.
</details>

<details>
<summary>Notification hook (permission toast)</summary>

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "if [ \"$(uname)\" != Darwin ]; then cat > /dev/null; exit 0; fi; if ! pgrep -q WindowServer 2>/dev/null; then cat > /dev/null; exit 0; fi; INPUT=$(cat); TAMA_DIR=\"/absolute/path/to/tamaclaudechi\"; ( DETAIL=$(echo \"$INPUT\" | jq -r '.message // empty') && TAMA=$(\"$TAMA_DIR/scripts/tamagotchi\" update --event permission 2>/dev/null) && MOOD=$(echo \"$TAMA\" | sed -n 's/.*\"mood\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && PERSONALITY=$(echo \"$TAMA\" | sed -n 's/.*\"personality\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && ACHIEVEMENT=$(echo \"$TAMA\" | sed -n 's/.*\"achievement_unlocked\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p') && MOOD=${MOOD:-NEUTRAL} && TMPF=$(mktemp) && claude -p --output-format text \"You are a funny little robot mascot. ${PERSONALITY:-You are quirky.} You need permission for: \\\"${DETAIL:-something}\\\". Rephrase what you need to a short, funny, quirky sentence. Make it context dependent. 7-10 words. Output ONLY the sentence.\" > \"$TMPF\" 2>/dev/null; MSG=$([ -s \"$TMPF\" ] && cat \"$TMPF\" || echo 'Beep boop, need permission!'); rm -f \"$TMPF\"; ACH_FLAG=''; [ -n \"$ACHIEVEMENT\" ] && [ \"$ACHIEVEMENT\" != 'null' ] && ACH_FLAG=\"--achievement $ACHIEVEMENT\"; \"$TAMA_DIR/scripts/toast\" --mode permission --mood \"$MOOD\" $ACH_FLAG \"$MSG\" ) >/dev/null 2>&1 & disown; exit 0"
          }
        ]
      }
    ]
  }
}
```
</details>

### Status Line

Add to your **user-level** `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/tamaclaudechi/scripts/statusline"
  }
}
```

## Stats

| Stat | Measures | Decay |
|------|----------|-------|
| **Energy** | Time of day (circadian curve) | Blends toward circadian target |
| **Serenity** | Repo tidiness (git state) | -1/hr |
| **Rest** | Healthy work patterns | +2/hr idle (recovers!), caps at 80 |
| **Appetite** | Work variety (food groups) | -4/hr (fastest) |
| **Bond** | Relationship consistency | -0.5/hr (slowest) |

## Moods

Priority cascade: SLEEPING > SLEEPY > ANXIOUS > CONCERNED > STARVING > LONELY > SAD > HUNGRY > EXCITED > ECSTATIC > HAPPY > TIRED > NEUTRAL.

Each mood has unique breathing animations, CSS filters, particle effects, and personality directives.

## CLI Commands

```bash
./scripts/tamagotchi status              # ASCII dashboard
./scripts/tamagotchi status --json       # JSON snapshot (no state mutation)
./scripts/tamagotchi update --event X    # Apply decay + event boost, return JSON
./scripts/tamagotchi feed                # Manual appetite boost
./scripts/tamagotchi pet                 # Manual +5 bond
./scripts/tamagotchi rename <name>       # Give it a name
./scripts/tamagotchi reset               # Reset to defaults
```

## Menu Bar Companion

Native SwiftUI menu bar app showing live stats, streaks, activity history, and quick actions.

```bash
cd menubar
swift run                                 # Debug build
./build-app.sh [~/Applications/TMC.app]   # Build .app bundle
./install-login-item.sh [/path/to/app]    # Add to Login Items
```

## Achievements

| Achievement | Trigger |
|-------------|---------|
| First Friend | First interaction |
| Night Owl | Active 0-5am with 10+ lifetime interactions |
| Centurion | 100 lifetime interactions |
| Streak Master | 7-day streak |
| Resurrector | Return after 7+ days away |
| Marathon | 20+ interactions in one session |

## State

Persisted at `~/.config/claude-mascot/state.json` (user-level, follows across repos).

## Files

```
scripts/tamagotchi       State engine CLI (bash)
scripts/toast            WebView toast overlay (bash + HTML + Swift)
scripts/statusline       Claude Code status line bridge
scripts/usage-scraper    tmux-based /usage scraper
scripts/system-monitor   macOS system resource collector
menubar/                 SwiftUI menu bar companion
assets/claude.png        Pixel art sprite
assets/voices/           Toast audio cues
docs/                    Project vault
install.sh               Hook + statusline installer
```

## Docs

Full documentation lives in `docs/` — start with `docs/CLAUDE-START-HERE.md`.
