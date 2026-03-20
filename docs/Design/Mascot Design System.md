---
created: 2026-03-13
updated: 2026-03-20
description: "Stat definitions, mood cascade, visual specs, achievements, and temporal modifiers"
---
# Mascot Design Reference

## Stats (v4, 0–100 scale)

Each stat measures a genuinely different dimension — no two stats grow from the same behavior. The [[Instructions/Tamagotchi CLI]] implements all stat mutations and decay.

### Stat Overview
- **Energy**: Circadian curve tied to time of day. Unchanged from v1.
- **Serenity**: Repo tidiness — inspects git state on every update. −1/hr decay.
- **Rest**: Healthy work patterns — rewards breaks, penalizes overwork. +2/hr passive recovery (caps at 80).
- **Bond**: Relationship consistency — streaks, depth, returning. −0.5/hr decay (slowest).
- **Vitality**: System health — maps from CPU/RAM/disk/swap/GPU metrics. Converges toward system-derived target.

### Energy Circadian Curve
| Time | Range | Behavior |
|------|-------|----------|
| 06–10 | 40 → 90 | Rising (waking up) |
| 10–18 | 80–100 | Plateau |
| 18–22 | 80 → 50 | Declining |
| 22–02 | Cap 40, decay to 20 | Tired zone |
| 02–06 | Cap 15 | Exhausted (asleep) |

### Serenity — Git State Signals
| Signal | Effect |
|--------|--------|
| Clean working tree | +15 |
| ≤2 open branches | +10 |
| Recent commit (within 1hr) | +5 |
| Dirty files | −2 per 10 files |
| >3 open branches | −3 per extra |
| Stale merged branches | −5 each |
| Large uncommitted diff (>500 lines) | −8 |

### Rest — Work Pattern Signals
| Signal | Effect |
|--------|--------|
| 2hr+ break during daytime | +10 |
| Weekend off (checked Monday) | +10/day |
| Session 1–3 hours | +5 |
| Start after 8am | +3 |
| Working past 10pm | −3/hr |
| Working past midnight | −5/hr (stacks) |
| Session >4 hours | −8 |

### Bond — Consistency Signals
| Signal | Effect |
|--------|--------|
| Daily streak (3+ interactions/day) | +5/day |
| 7-day streak | +15 bonus |
| 30-day streak | +25 bonus |
| Long session (30min+) | +8 |
| Claude-assisted commit | +8 |
| Return after 2–3 day absence | +5 |
| Pet interaction | +5 |

### Derived
- **Wellbeing** = `energy×0.20 + serenity×0.20 + rest×0.15 + bond×0.30 + vitality×0.15` (weights adjust when energy/vitality sources unavailable)
- **Streak**: Consecutive days with 3+ interactions
- **Lifetime interactions**: Total prompts witnessed (never resets)

## Mood Priority Cascade

| # | Condition | Mood |
|---|-----------|------|
| 1 | energy < 15 | SLEEPING |
| 2 | energy < 30 AND hour > 22 | SLEEPY |
| 3 | serenity < 25 | ANXIOUS |
| 4 | rest < 25 | CONCERNED |
| 5 | bond < 20 | LONELY |
| 6 | vitality < 25 | STRESSED |
| 7 | rest < 30 | SAD |
| 8 | bond > 80 AND energy > 60 | EXCITED |
| 9 | wellbeing > 80 AND streak > 3 | ECSTATIC |
| 10 | wellbeing > 65 | HAPPY |
| 11 | energy < 45 | TIRED |
| 12 | else | NEUTRAL |

## Mood Visuals

| Mood | Breathing | Filter | Color | Particles |
|------|-----------|--------|-------|-----------|
| ECSTATIC | Fast (200ms), big bounce | `brightness(1.15) saturate(1.3)` | `#4ade80` | Double confetti + sparkles |
| EXCITED | Quick wiggle (250ms) | — | `#22d3ee` | Sparkle stars |
| HAPPY | Normal (350ms) | — | `#4ade80` | Standard confetti |
| NEUTRAL | Calm (450ms) | — | `#e2e8f0` | None |
| TIRED | Slow (600ms), 3deg tilt | `brightness(0.85)` | `#94a3b8` | Occasional yawn bob |
| SLEEPY | Very slow (800ms), 8deg tilt | `brightness(0.7) saturate(0.5)` | `#64748b` | ZZZ floating up |
| SLEEPING | Still (1000ms), 12deg tilt | `brightness(0.5) saturate(0.3)` | `#475569` | ZZZ only, no speech |
| SAD | Slow sway (550ms), 2deg tilt | `saturate(0.6) brightness(0.9)` | `#818cf8` | Rain drops |
| LONELY | Very slow (700ms), 3deg tilt | `saturate(0.4) brightness(0.8)` | `#a78bfa` | Tear drop |
| ANXIOUS | Jittery shake (250ms) | — | `#fbbf24` | Warning signs + save icon |
| CONCERNED | Slow worried wobble (500ms) | — | `#38bdf8` | Hearts + coffee cup |

## Mood Personality Directives

Injected into codex prompt to shape the quip's tone:
- **ECSTATIC**: "OVER THE MOON excited, speaking in exclamation marks!"
- **EXCITED**: "Buzzing with excitement, everything is fascinating!"
- **ANXIOUS**: "Visibly nervous about the messy repo, suggesting we commit..."
- **CONCERNED**: "Worried about the user's wellbeing, gently suggesting a break"
- **STRESSED**: "Stressed about system resources, keeps mentioning how hot things are running, a bit frazzled"
- **SLEEPY**: "Barely awake, mumbling and yawning, words trailing off..."
- **LONELY**: "Lonely, missed the user SO much, clingy and affectionate"
- **SAD**: "A bit down, speak softly and with slight melancholy"

## Achievements

| Achievement | Trigger | Effect |
|-------------|---------|--------|
| First Friend | First interaction | Heart burst |
| Night Owl | 10+ lifetime interactions & active 0–5am | Owl particles |
| Centurion | 100 lifetime interactions | Gold confetti |
| Streak Master | 7-day streak | Star shower |
| Resurrector | Return after 7+ days away | Tears of joy |
| Marathon | 20+ interactions in one session | Medal + confetti |

## Temporal Modifiers

- **Witching hour (03–05)**: Purple tint, ghost particles (future)
- **Anniversary of firstMet**: Rainbow override (future)

## Eye Tracking Integration (idea)

Use an eye tracker so the mascot appears where the user is actually looking on screen. With a multi-monitor setup, the mascot would follow gaze across displays — showing up on whichever screen (and region) has the user's attention.

## Easter Eggs (future)

- All stats at 100 → "Nirvana" mode: golden aura, speaks in haiku
- All stats below 20 → "Ghost" mode: translucent, whispers
- User prompt contains "love" → +20 bond, heart explosion

---

## See Also

- [[Architecture/System Overview]] — how stats flow through the event pipeline
- [[Instructions/Tamagotchi CLI]] — CLI implementation of decay and events
- [[Instructions/Toast Overlay]] — mood visual implementation (CSS, particles)
