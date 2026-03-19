---
created: 2026-03-13
updated: 2026-03-13
---
# Key Files

| Path | Purpose |
|------|---------|
| `scripts/tamagotchi` | Bash state engine CLI (decay, events, achievements, JSON) |
| `scripts/toast` | macOS WebView toast + queue controller |
| `scripts/statusline` | Claude Code status line bridge (context %, usage, git) |
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
