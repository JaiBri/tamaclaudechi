#!/bin/bash
set -euo pipefail

APP_PATH="${1:-$HOME/Applications/TamaclaudechiMenuBar.app}"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ Couldn't find app bundle at $APP_PATH. Build it first (./menubar/build-app.sh)." >&2
  exit 1
fi

osascript - "$APP_PATH" <<'OSA'
on run argv
  set appPath to POSIX file (item 1 of argv)
  tell application "System Events"
    if login item "Tamaclaudechi Menu Bar" exists then
      delete login item "Tamaclaudechi Menu Bar"
    end if
    make login item at end with properties {name:"Tamaclaudechi Menu Bar", path:appPath, hidden:true}
  end tell
end run
OSA

echo "✅ Added Tamaclaudechi Menu Bar to Login Items"
