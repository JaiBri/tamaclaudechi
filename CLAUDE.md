# CLAUDE.md

## What This Is

Tamaclaudechi — a living coding companion for Claude Code. A pixel-art mascot that reacts to your coding habits with moods, stats, achievements, and contextual quips via macOS toasts and a native menu bar app.

## Components

- **State engine** (`scripts/tamagotchi`) — Bash CLI that manages 5 stats, mood cascades, achievements, decay, and JSON output. All state mutations flow through this.
- **Toast overlay** (`scripts/toast`) — macOS WebView toast with mood-aware visuals, particles, and speech bubbles.
- **Status line** (`scripts/statusline`) — Bridges Claude Code context metrics + API usage into the menu bar.
- **Usage scraper** (`scripts/usage-scraper`) — Background tmux session that polls `/usage` from Claude Code.
- **System monitor** (`scripts/system-monitor`) — macOS resource collector (CPU/RAM/disk/GPU).
- **Menu bar app** (`menubar/`) — SwiftUI companion that shows live stats, activity strip, and quick actions.

## Dev Commands

```bash
# CLI
./scripts/tamagotchi status              # ASCII dashboard
./scripts/tamagotchi status --json       # JSON snapshot
./scripts/tamagotchi update --event X    # Mutate state + return JSON

# Menu bar
cd menubar && swift run                  # Debug build + launch
pkill -f TamaclaudechiMenuBar; cd menubar && bash build-app.sh && open build/TamaclaudechiMenuBar.app

# Status line test
echo '{"context_window":{"remaining_percentage":72,"used_percentage":28},"session_id":"test"}' | ./scripts/statusline
```

## Key Constraints

- **All stat mutations go through `scripts/tamagotchi`** — consumers (hooks, menu bar) never write state directly
- **State is user-wide** at `~/.config/claude-mascot/state.json` — not repo-specific
- **Hooks use `claude -p`** for quip generation — no external AI services needed
- **macOS only** — toast and menu bar use native macOS APIs

## Docs

Full vault at `docs/` — start with `docs/CLAUDE-START-HERE.md`. Key docs:

| Doing this? | Read first |
|-------------|-----------|
| Changing stats or moods | `docs/Design/Mascot Design System.md` |
| Changing the CLI | `docs/Instructions/Tamagotchi CLI.md` |
| Changing the menu bar app | `docs/Instructions/Menu Bar Companion.md` |
| Changing the status line | `docs/Instructions/Status Line.md` |
| Understanding the pipeline | `docs/Architecture/System Overview.md` |
| Finding files | `docs/Reference/Key Files.md` |
