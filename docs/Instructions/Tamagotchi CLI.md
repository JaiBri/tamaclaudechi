---
created: 2026-03-13
updated: 2026-03-13
---
# Tamagotchi CLI

Location: `scripts/tamagotchi`

## Commands

```bash
./scripts/tamagotchi status              # ASCII dashboard
./scripts/tamagotchi status --json       # JSON snapshot (no state mutation)
./scripts/tamagotchi update --event X    # Apply decay + event boost, return JSON
./scripts/tamagotchi feed                # Manual appetite boost (food group: carbs)
./scripts/tamagotchi pet                 # Manual +5 bond
./scripts/tamagotchi rename <name>       # Set mascot name
./scripts/tamagotchi reset               # Reset everything to defaults
```

`update --event <type>` accepts: `task_complete`, `permission`, `prompt`, `code_change`, `test_run`, `lint_run`, `docs_change`, `refactor`, `session_start`, `feed`, `pet`.

## Stats (v2)

Each stat measures a genuinely different dimension — no two stats grow from the same behavior.

| Stat | Measures | Decay |
|------|----------|-------|
| **Energy** | Time of day (circadian curve) | Blends toward circadian target |
| **Serenity** | Repo tidiness (git state inspection) | −1/hr |
| **Rest** | Healthy work patterns | +2/hr when idle (recovers!), caps at 80 passively |
| **Appetite** | Work variety (food group system) | −4/hr (fastest) |
| **Bond** | Relationship consistency | −0.5/hr (slowest) |

### Serenity — git state signals

Inspected on every `update` by running git commands in the current repo:

- Clean working tree: +15
- ≤2 open branches: +10
- Recent commit (within 1hr): +5
- Dirty files: −2 per 10 files
- >3 open branches: −3 per extra
- Stale merged branches: −5 each
- Large uncommitted diff (>500 lines): −8

### Rest — work pattern signals

- 2hr+ break during daytime: +10
- Weekend off (checked Monday): +10/day
- Session 1–3 hours: +5
- Reasonable start (after 8am): +3
- Working past 10pm: −3/hr
- Working past midnight: −5/hr (stacks)
- Session >4 hours: −8

### Appetite — food group system

Events classify into food groups with diminishing returns on repetition:

| Food group | Triggers |
|---|---|
| Protein | `code_change`, `task_complete` |
| Vegetables | `test_run`, `lint_run` |
| Carbs | `prompt`, `permission`, `feed` |
| Fiber | `docs_change`, `refactor` |

First meal of a group: +20. Same group again: +15 → +10 → +5 → +2. Switching to a different group resets all diminishing return counters.

### Bond — consistency signals

- Daily streak (3+ interactions/day): +5/day
- 7-day streak milestone: +15
- 30-day streak milestone: +25
- Long session (30min+): +8
- Committing Claude-assisted code (`task_complete`): +8
- Return after 2–3 day absence: +5
- Pet interaction: +5

## Wellbeing Formula

`wellbeing = energy×0.20 + serenity×0.20 + rest×0.15 + appetite×0.25 + bond×0.20`

## Mood Cascade

Priority order: SLEEPING → SLEEPY → ANXIOUS → CONCERNED → STARVING → LONELY → SAD → HUNGRY → EXCITED → ECSTATIC → HAPPY → TIRED → NEUTRAL.

New moods:
- **ANXIOUS**: serenity < 25 — nervous about messy repo
- **CONCERNED**: rest < 25 — worried about user's wellbeing

## Persistence

State lives at `~/.config/claude-mascot/state.json` (per-user, v2 format), created automatically. v1 state files are auto-migrated on first run.

## Output Shape

Both `update` and `status --json` return:

```json
{
  "mood": "HAPPY",
  "personality": "tone for quips",
  "stats": { "energy": 90, "serenity": 85, "rest": 60, "appetite": 45, "bond": 55 },
  "wellbeing": 65,
  "name": "Claude Mascot",
  "streak": 3,
  "lifetime": 42,
  "achievement_unlocked": "nightOwl" | null
}
```

Consumers (hooks, menu bar, etc.) must never mutate stats directly — always shell out to this CLI.
