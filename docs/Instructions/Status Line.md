---
created: 2026-03-15
updated: 2026-03-17
---
# Status Line (Context Monitor)

The status line script bridges Claude Code's context window metrics into the Tamaclaudchi system, powering the "Brain" bar in the menu bar companion.

## How It Works

1. Claude Code invokes `scripts/statusline` after every assistant message
2. The script receives JSON on stdin with `context_window.remaining_percentage`, `session_id`, etc.
3. It writes `~/.config/claude-mascot/context.json` (same directory as `state.json`)
4. The menu bar app watches `context.json` and displays the Brain bar

## Installation

Add to your **user-level** `~/.claude/settings.json` (not the project-level one):

```json
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/scripts/statusline"
  }
}
```

Replace the path with the actual absolute path to the script.

### Prerequisites for Usage Tracking

Usage tracking requires tmux to manage a background Claude probe session:

```bash
brew install tmux
```

If tmux is not installed, the usage section is silently omitted from the status line.

## Output Format

### Terminal Status Line

```
🧠 96%  │  📊 65% week · 75% sess  │  ● dev  │  ● tunnel  │  🌿 main ✅
```

Sections (left to right):
- **Brain** — context window remaining (with urgency indicators at 60/40/20%)
- **Usage** — API plan usage with pace-colored percentages (omitted if no data or stale)
- **Dev** — Vite dev server status (green = running, red = stopped)
- **Tunnel** — cloudflared tunnel status
- **Git** — branch, sync state, dirty state, diff stats

### Usage Pace Colors

Each percentage is independently colored based on how it compares to elapsed time in the period:

- **Green**: usage >= elapsed — on pace or ahead (making good use of allocation)
- **Yellow**: usage < elapsed - 10% — below pace (might waste allocation)
- **Red**: usage > 90% — running hot, might exhaust early
- **No color**: roughly on track (within 10% of elapsed)

### Context JSON

`~/.config/claude-mascot/context.json`:

```json
{
  "remaining": 72,
  "used": 28,
  "session_id": "abc123",
  "updated_at": "2026-03-15T14:30:00Z",
  "git": { ... },
  "usage": {
    "session_pct": 75,
    "session_elapsed_pct": 48,
    "session_resets": "2:59pm",
    "week_all_pct": 65,
    "week_all_elapsed_pct": 44,
    "week_all_resets": "Mar 23 at 9:59am",
    "extra_spent": 15.21,
    "extra_budget": 15.00,
    "scraped_at": "2026-03-17T12:00:00Z"
  }
}
```

### Usage JSON

`~/.config/claude-mascot/usage.json` — written by the usage scraper, read by the statusline:

```json
{
  "session_pct": 75,
  "session_resets": "2:59pm",
  "session_elapsed_pct": 48,
  "week_all_pct": 65,
  "week_all_resets": "Mar 23 at 9:59am",
  "week_all_elapsed_pct": 44,
  "extra_spent": 15.21,
  "extra_budget": 15.00,
  "scraped_at": "2026-03-17T12:00:00Z"
}
```

## Usage Scraper (`scripts/usage-scraper`)

The scraper manages a detached tmux session (`claude-usage`) that runs a Claude Code probe instance. It sends `/usage`, captures the terminal output, parses percentages and reset times, computes pace, and writes `usage.json`.

### How It Runs

- **Triggered automatically** by the statusline when `usage.json` is missing or older than 5 minutes
- Runs in the background (spawned with `&` and `disown`)
- Uses a directory-based lock (`~/.config/claude-mascot/.usage-scraper.lock`) to prevent concurrent runs
- Stale locks (>60s) are automatically cleaned up

### tmux Session Lifecycle

- Created on first scrape: `tmux new-session -d -s claude-usage -x 120 -y 40 "claude --name usage-probe"`
- Persists between scrapes — reused for subsequent `/usage` queries
- If the session dies (e.g., Claude crashes), it's automatically recreated on next scrape
- Manual cleanup: `tmux kill-session -t claude-usage`

### Staleness Rules

- **Statusline hides usage** if `usage.json` is older than 15 minutes
- **Statusline triggers scraper** if `usage.json` is older than 5 minutes
- Scraper takes ~5-15 seconds to run (longer on first invocation due to Claude startup)

## Behavior Notes

- The status line fires **after every Claude response**, not continuously between messages
- If the context file is older than 5 minutes, the menu bar shows "No active session"
- The script also outputs a one-line status for Claude Code's own terminal status bar

## Testing

```bash
# Test statusline (without usage data)
echo '{"context_window":{"remaining_percentage":45,"used_percentage":55},"session_id":"test"}' \
  | ./scripts/statusline

# Test scraper (requires tmux)
./scripts/usage-scraper && cat ~/.config/claude-mascot/usage.json

# Verify tmux session
tmux list-sessions | grep claude-usage

# Test statusline with usage data present
echo '{"context_window":{"remaining_percentage":72,"used_percentage":28},"session_id":"test"}' \
  | ./scripts/statusline

# View context.json (includes usage)
cat ~/.config/claude-mascot/context.json

# Kill probe session for cleanup
tmux kill-session -t claude-usage
```
