---
created: 2026-03-13
updated: 2026-03-13
---
# System Overview

## Event Flow

```
Hooks (.claude) → scripts/tamagotchi update --event <type>
               → returns { mood, personality, stats, achievement }
               → claude -p generates mood-aware quip
               → scripts/toast --mode <done|permission> --mood <MOOD> "quip"
```

- All stats (energy, serenity, rest, appetite, bond) live in `~/.config/claude-mascot/state.json` (v2 format).
- `scripts/tamagotchi` owns every mutation: time decay, event boosts, git-state inspection (serenity), work-pattern tracking (rest), food-group classification (appetite), temporal modifiers, achievements, JSON output.
- `scripts/toast` handles the on-screen macOS WebView bubble, moods, and permission/done variations.
- The SwiftUI menu bar app polls the CLI via `status --json`, watches the state file for instant refreshes, and exposes quick actions that proxy to `tamagotchi feed/pet`.

## Persistence

- State file is user-wide: `~/.config/claude-mascot/state.json`.
- CLI ensures the directory exists on demand.
- Menu bar watcher follows the same path and recreates watchers if the file is deleted/regenerated.

## Key Timers

- CLI applies decay whenever it runs based on `lastInteraction` and the circadian schedule.
- Menu bar refresh timer (60s) keeps stats fresh even without file events.

## Multi-Surface Behavior

- Hooks + toast show the mascot reactively during automation tasks or permission prompts.
- Menu bar companion keeps baseline visibility/stats accessible at all times.
- Both surfaces rely on the *same* CLI + state machine so Phase 1/Phase 2 parity is preserved.
