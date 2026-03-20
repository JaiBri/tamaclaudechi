---
created: 2026-03-13
updated: 2026-03-20
description: "Canonical file list with locations and purposes"
---
# Key Files

| Path | Purpose |
|------|---------|
| `scripts/tamagotchi` | Bash state engine CLI (decay, events, achievements, JSON) |
| `scripts/lib/` | Shared bash helpers (JSON parsing, time, math) |
| `scripts/core/` | Engine logic (state, decay, events, serenity, mood, achievements) |
| `scripts/commands/` | CLI command implementations (update, status, reset, pet, config, usage) |
| `scripts/lib/log.sh` | LLM call log reader/formatter for diagnostics |
| `scripts/commands/diagnose.sh` | Diagnostic checks (hooks, state, logs, data sources) |
| `scripts/toast` | macOS WebView toast + queue controller |
| `scripts/toast-assets/` | Extracted toast HTML template and Swift WebView controller |
| `scripts/statusline` | Claude Code status line bridge (context %, usage, git) |
| `scripts/statusline-sections/` | Extracted statusline section renderers (git, usage, system, session) |
| `scripts/usage-scraper` | tmux-based `/usage` scraper for API plan metrics |
| `scripts/system-monitor` | macOS system resource collector (CPU/RAM/disk/GPU) |
| `assets/voices/` | Toast audio assets |
| `assets/claude.png` | Pixel art sprite used across surfaces |
| `menubar/Package.swift` | SwiftPM manifest for the menu bar companion |
| `menubar/Sources/TamaclaudechiMenuBar/main.swift` | SwiftUI app + watcher implementation |
| `menubar/build-app.sh` | Builds `TamaclaudechiMenuBar.app` bundle |
| `menubar/install-login-item.sh` | Adds/removes login item |
| `docs/` | Obsidian-style vault (Architecture, Design, Instructions, Reference) |
| `install.sh` | Wires hooks + statusline into a Claude Code project |

---

## See Also

- [[Architecture/System Overview]] — how files relate in the pipeline
- [[Vault Index]] — full documentation index
