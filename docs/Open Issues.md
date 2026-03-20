---
created: 2026-03-13
updated: 2026-03-20
description: "Structural observations and tech debt tracking"
---
# Mascot Open Issues

### Monolithic menubar Swift file
**Noticed:** 2026-03-20

`menubar/Sources/TamaclaudechiMenuBar/main.swift` is 1865 lines mixing models, views, animations, and settings. Should split into separate Swift files with proper SwiftPM targets.

### Duplicated serenity convergence
**Noticed:** 2026-03-20

`cmd_update` and `cmd_status` both inline the same serenity convergence logic (~20 lines each). Should extract to a shared function in `core/serenity.sh`.

### `write_state` is a 180-line function
**Noticed:** 2026-03-20

Even after the split into `core/state.sh`, `write_state` has too many responsibilities (decay tracking, stat clamping, JSON assembly). Consider splitting further.

### No automated tests
**Noticed:** 2026-03-20

Only manual verification exists for the bash scripts. A lightweight bash test harness (e.g., bats-core) would catch regressions in stat math, mood cascade, and JSON output.

### Hook re-install duplicates entries
**Noticed:** 2026-03-20 — **Fixed:** 2026-03-20

`install.sh` used `+= [...]` (append) when adding hooks, meaning each re-install duplicated all hook entries. Fixed: install logic now removes existing tamaclaudechi hooks before adding new ones.

### Stale hooks in consumer projects
**Noticed:** 2026-03-20 — **Fixed:** 2026-03-20

Frontend hooks were installed from an older version of `install.sh` and were missing `cd "$TAMA_DIR"` before `claude -p`, causing it to run in the wrong CWD. Fixed by re-installing hooks after updating templates.

### Transcript parsing picks up tool_result messages
**Noticed:** 2026-03-20 — **Fixed:** 2026-03-20

User request extraction from transcript used `select(.message.role == "user")` which also matched tool_result messages, feeding tool output to the LLM instead of actual user requests. Fixed: jq filter now excludes entries whose content array contains tool_result items.
