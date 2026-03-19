---
created: 2026-03-13
updated: 2026-03-13
---
# Menu Bar Companion

Location: `menubar/`

## Features

- SwiftUI `MenuBarExtra` that reads `status --json` from the CLI.
- 60s polling + `DispatchSource` watcher on `~/.config/claude-mascot/state.json` for instant refreshes.
- Quick actions (Feed/Pet) proxy to the CLI so streaks/achievements stay accurate.
- Mood badge + stat bars mirror the Tamagotchi data model.

## Dev Commands

```bash
cd menubar
swift run                          # Launch in debug, menu bar only
swift build -c release             # Compile binary in .build/release/
./build-app.sh [~/Applications/...]
./install-login-item.sh [/path/to/TamagotchiMenuBar.app]
```

- `build-app.sh` wraps the release binary into a minimal `.app` bundle under `menubar/build/` (or the path you pass in) with `LSUIElement=1` so it never shows a Dock icon.
- `install-login-item.sh` (macOS only) uses AppleScript/System Events to add the bundled app to Login Items; rerun it if you move/update the app.
- Set `TAMAGOTCHI_CLI_PATH` if the CLI lives outside the repo.

## Files to Know

- `Package.swift` — SwiftPM executable target.
- `Sources/TamagotchiMenuBar/main.swift` — SwiftUI entry point, view model, watchers, and UI.
- `build-app.sh` — helper to produce `TamagotchiMenuBar.app`.
- `install-login-item.sh` — adds/removes the login item.
