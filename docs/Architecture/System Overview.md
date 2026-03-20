---
created: 2026-03-13
updated: 2026-03-20
description: "Event pipeline, state persistence, and multi-surface architecture"
---
# System Overview

## Event Flow

```
Hooks (.claude) → scripts/tamagotchi update --event <type>
               → returns { mood, personality, stats, achievement }
               → claude -p generates mood-aware quip
               → scripts/toast --mode <done|permission> --mood <MOOD> "quip"
```

- All stats (energy, serenity, rest, bond, vitality) live in `~/.config/claude-mascot/state.json` (v4 format).
- `scripts/tamagotchi` owns every mutation: time decay, event boosts, git-state inspection (serenity), work-pattern tracking (rest), temporal modifiers, achievements, JSON output. See [[Instructions/Tamagotchi CLI]] for command reference.
- `scripts/toast` handles the on-screen macOS WebView bubble, moods, and permission/done variations. See [[Instructions/Toast Overlay]] for wiring details.
- The [[Instructions/Menu Bar Companion]] polls the CLI via `status --json`, watches the state file for instant refreshes, and exposes quick actions that proxy to `tamagotchi pet`.

## Persistence

- State file is user-wide: `~/.config/claude-mascot/state.json`.
- CLI ensures the directory exists on demand.
- Menu bar watcher follows the same path and recreates watchers if the file is deleted/regenerated.

## Key Timers

- CLI applies decay whenever it runs based on `lastInteraction` and the circadian schedule.
- Menu bar refresh timer (60s) keeps stats fresh even without file events.
- The [[Instructions/Status Line]] fires after every assistant message, writing context metrics for the menu bar Brain bar.

## LLM Call Logging

Hook LLM calls are logged to `~/.config/claude-mascot/llm-calls.jsonl` for diagnostics. Each entry records the timestamp, event type, user request, assistant context, mood, personality, full prompt, response, and project path. The log auto-rotates to 200 lines. Use `./scripts/tamagotchi diagnose logs` to inspect.

## Multi-Surface Behavior

- Hooks + toast show the mascot reactively during automation tasks or permission prompts.
- Menu bar companion keeps baseline visibility/stats accessible at all times.
- Both surfaces rely on the *same* CLI + state machine so Phase 1/Phase 2 parity is preserved.

Stat definitions, mood cascade, and visual specs are documented in [[Design/Mascot Design System]].

---

## See Also

- [[Design/Mascot Design System]] — stat definitions, mood cascade, visual specs
- [[Instructions/Tamagotchi CLI]] — CLI commands and state mutation interface
- [[Instructions/Toast Overlay]] — toast display pipeline
- [[Instructions/Menu Bar Companion]] — menu bar polling and watcher
- [[Instructions/Status Line]] — context window and usage monitoring
