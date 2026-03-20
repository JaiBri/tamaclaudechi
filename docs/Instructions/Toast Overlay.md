---
created: 2026-03-13
updated: 2026-03-20
description: macOS WebView toast system — queue mechanism, mood visuals, CLI flags, and asset structure
---
# Toast Overlay

## Overview

The toast is a macOS floating WebView that renders a pixel-art mascot inside a frosted-glass speech bubble. It appears in the top-right corner of the screen, delivers a message with karaoke-style word-by-word text reveal, plays short voice lines through the mascot (who reacts to audio with squash-and-stretch animation), and exits with a spin-out animation. The system supports mood-specific visuals (CSS filters, breathing speed, particle effects), a permission mode with amber pulsing, and achievement celebration overlays with custom particle bursts.

Messages are enqueued and played sequentially by a single background processor, so callers return immediately.

## Script Location and Assets

```
scripts/toast                          Bash wrapper (~252 lines): arg parsing, queue, compile, processor loop
scripts/toast-assets/toast.html        HTML/CSS/JS template for the WebView
scripts/toast-assets/ToastController.swift   Swift WebView controller (NSWindow + WKWebView)
assets/voices/v*.mp3                   Short voice-line clips played during messages
```

## CLI Flags

```
toast [--mode permission|done] [--mood MOOD] [--achievement ACH] "message text" [duration_seconds]
```

| Flag | Values | Default | Effect |
|------|--------|---------|--------|
| `--mode` | `permission`, `done` | `done` | `permission` adds an amber border pulse and orbiting `?` marks; lit words turn yellow instead of the mood color and have no text-shadow. `done` triggers confetti for HAPPY/ECSTATIC moods. |
| `--mood` | See mood table below | `NEUTRAL` | Controls mascot CSS filter, breathing animation speed/amplitude, tilt, text color, and particle system. |
| `--achievement` | `firstFriend`, `nightOwl`, `centurion`, `streakMaster`, `resurrector`, `marathon` | (none) | Triggers a celebration overlay specific to the achievement type. |
| positional 1 | string | `"Hello"` | Message text displayed in the speech bubble. |
| positional 2 | integer (seconds) | `3` | How long the message text stays visible after voice playback finishes. |

### Moods

Nine moods are defined in the HTML template's `MOOD_CONFIG` object:

| Mood | Breathing Speed (ms) | Filter | Text Color | Particles |
|------|---------------------|--------|------------|-----------|
| `ECSTATIC` | 200 | brightness(1.15) saturate(1.3) | `#4ade80` | Double confetti burst |
| `EXCITED` | 250 | (none) | `#22d3ee` | Sparkles |
| `HAPPY` | 350 | (none) | `#4ade80` | Confetti |
| `NEUTRAL` | 450 | (none) | `#e2e8f0` | None |
| `TIRED` | 600 | brightness(0.85) | `#94a3b8` | Yawn (`~` floaters) |
| `SLEEPY` | 800 | brightness(0.7) saturate(0.5) | `#64748b` | Zzz |
| `SLEEPING` | 1000 | brightness(0.5) saturate(0.3) | `#475569` | Zzz (no speech bubble shown) |
| `SAD` | 550 | saturate(0.6) brightness(0.9) | `#818cf8` | Rain |
| `LONELY` | 700 | saturate(0.4) brightness(0.8) | `#a78bfa` | Tears |

The `SLEEPING` mood is special: it suppresses the speech bubble entirely and only shows Zzz particles.

### Achievements

Each achievement name maps to a distinct particle celebration in the HTML:

| Achievement | Effect |
|-------------|--------|
| `firstFriend` | Burst of green heart emojis |
| `nightOwl` | Floating owl emojis |
| `centurion` | Double confetti explosion |
| `streakMaster` | Rapid star emojis |
| `resurrector` | Crying-face emojis |
| `marathon` | Confetti + medal emojis |

## Queue Mechanism

The queue prevents overlapping toasts when multiple callers fire in quick succession.

1. **Enqueue** -- The script writes `MODE|MSG|DURATION_MS|MOOD|ACHIEVEMENT` to a timestamped file in `/tmp/toast-queue/`. The filename uses `date +%s%N` plus the PID to guarantee uniqueness and sort order.
2. **Return immediately** -- If a processor is already running (checked via PID file at `/tmp/toast-processor.pid`), the script exits after enqueuing.
3. **Processor loop** -- If no processor is running, the script spawns a background subshell (`&` + `disown`) that loops:
   - Reads all queued files, sorted chronologically.
   - Sleeps 150ms to let rapid-fire toasts accumulate into a batch.
   - Builds a JSON batch (`/tmp/toast-batch.json`) with all messages, voice file paths, and timing metadata.
   - Runs the compiled Swift binary synchronously, passing the total display time in milliseconds.
   - After the binary exits, sleeps 300ms and checks for new queued files; if none, removes the PID file and exits.

### Timing calculation

Per-message display time: `voiceDur + 100 + duration + 1000 + 250` ms.
Total batch time adds entrance (700ms), exit (1000ms), inter-message gaps (150ms each), per-message audio latency buffer (500ms each), and a 2000ms margin.

## HTML Template

The template (`toast.html`) is copied to `/tmp/toast.html` at processor startup and loaded by the Swift binary via `file://` URL. It reads `/tmp/toast-batch.json` via fetch and runs the batch sequentially.

### Lifecycle

1. **Entrance** -- Mascot slides in from the right (`bouncySlideIn`, 600ms), then starts a persistent breathing animation loop parameterized by the current mood.
2. **Per message** -- Bubble fades in (`bubbleIn`, 250ms). Words start dimmed (`rgba(255,255,255,0.2)`) and light up one by one at intervals timed to the voice duration. Voice lines play through Web Audio API with an analyser node; the mascot reacts to audio volume with squash-and-stretch, bounce, and rotation. After voice playback and display duration, the bubble fades out (`bubbleOut`, 200ms).
3. **Exit** -- Confetti particles vacuum toward the mascot, then the mascot spins out (`spinOut`, 800ms). The page sets `document.title = 'CLOSE'`, which the Swift controller observes to terminate.

### Click behavior

Clicking the speech bubble sets `document.title = 'ACTIVATE'`, which triggers the Swift controller to run `/tmp/toast-activate.sh` (an AppleScript/shell script generated by the bash wrapper that activates the correct terminal window/tab based on `$TERM_PROGRAM` and TTY). Supported terminals: Apple Terminal, iTerm2, Ghostty, VS Code.

### Interactions

- **Double-click mascot** -- Triggers a "pet" jiggle animation with green heart particles.
- **Long-press mascot** (1 second) -- Shows a temporary stats HUD displaying the current mood.

## Swift WebView Controller

`ToastController.swift` creates a transparent, borderless, always-on-top `NSWindow` containing a `WKWebView`.

| Property | Value |
|----------|-------|
| Window style | `.borderless`, transparent background, no shadow |
| Window level | `.floating` |
| Size | 420 x 160 points |
| Position | Top-right of the visible screen frame, inset 20pt from edges |
| Collection behavior | `canJoinAllSpaces`, `stationary` (visible on all desktops, stays put during Mission Control) |
| Activation policy | `.accessory` (no Dock icon, no menu bar) |

### Click-through with selective interactivity

The window starts with `ignoresMouseEvents = true` (full click-through). Global and local mouse-move monitors run a throttled hit test (50ms interval) that evaluates JavaScript in the WebView to check whether the cursor is over `.bubble`, `.mascot-wrap`, or `.stats-hud`. If it is, `ignoresMouseEvents` is set to `false` so the user can click; otherwise it reverts to `true` so clicks pass through to windows underneath.

### Termination

The controller observes `webView.title` via KVO:
- `"CLOSE"` -- calls `NSApplication.shared.terminate(nil)` (normal exit after animation finishes).
- `"ACTIVATE"` -- runs `/tmp/toast-activate.sh`, waits for it to finish, then terminates.

A safety timeout (the total batch time passed as the first CLI argument, in milliseconds) schedules forced termination via `DispatchQueue.main.asyncAfter`.

### Compilation

The Swift source is compiled once and cached at `/tmp/toast_webview`. Recompilation only happens if the binary is missing or the source file is newer:

```bash
swiftc -o /tmp/toast_webview ToastController.swift -framework Cocoa -framework WebKit
```

## Voice Lines

Voice files live in `assets/voices/` and follow the naming pattern `v*.mp3`.

### Selection logic

The number of voice lines per message scales with word count:

| Words | Voice lines played |
|-------|--------------------|
| 1 | 1 |
| 2--4 | 2 |
| 5--8 | 3 |
| 9+ | 4 |

Lines are picked randomly with two constraints:
- **No consecutive duplicates** -- the same file cannot play twice in a row (within a message or across messages in a batch).
- **Combination cooldown** -- an order-independent fingerprint of the selected set is checked against `/tmp/toast-voice-cooldown` (keeps the last 5 combinations). If the combination was recently used, the picker retries up to 10 times, then falls back to the first attempt.

### Duration and timing

Each voice file's duration is read via `afinfo` (macOS built-in). The sum of all selected voice durations for a message determines the karaoke word-reveal timing and the voice-reactive animation duration. If `afinfo` fails, 800ms is used as a fallback per file.

Audio playback happens in the WebView via the Web Audio API. Files are loaded as `file://` URLs and routed through an `AnalyserNode` so the mascot animation can react to real audio volume. Audio volume is set to 0.15 (15%).

## Testing

Basic smoke tests:

```bash
# Standard done-mode toast
./scripts/toast --mood HAPPY "Test message" 3

# Permission mode with anxious mood
./scripts/toast --mood SAD --mode permission "Need access to calendar" 5

# Achievement celebration
./scripts/toast --achievement firstFriend "You made a friend!" 4

# Sleeping mood (no bubble, just Zzz)
./scripts/toast --mood SLEEPING "Goodnight" 3

# Rapid-fire queue test (second toast should queue behind the first)
./scripts/toast --mood EXCITED "First message" 2 && ./scripts/toast --mood HAPPY "Second message" 2
```

To inspect the batch JSON after a toast plays: `cat /tmp/toast-batch.json | python3 -m json.tool`.

To force recompilation of the Swift binary: `rm /tmp/toast_webview` before running.

## See Also

- [[Architecture/System Overview]] -- where toast fits in the event pipeline
- [[Design/Mascot Design System]] -- mood visuals and particle specs
- [[Instructions/Tamagotchi CLI]] -- generates mood data consumed by toast
