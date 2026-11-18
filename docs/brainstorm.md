---
status: approved
stepsCompleted: [1, 2]
approved_by: user
---

# Game Concept Brainstorming — Horizontal Mech Shooter

## Session Input
- User seed: a horizontal shooting game with exactly one level.
- Project context (from `docs/project-context.md`): PC only, 60 FPS locked, Mobile renderer, 1920x1080 base resolution, GDScript 4.x.

## Divergent Concepts Explored
Five concept directions were presented and discussed:

1. **[A] Classic run-and-gun** — auto-scrolling level, run/jump/shoot waves (Contra-style).
2. **[B] Momentum dogfighter** — free horizontal flight with inertia and drift.
3. **[C] Boss gauntlet** — one long multi-phase boss fight as the whole level.
4. **[D] Fragile dodge-hell** — one hit kills; weaving through dense bullet patterns.
5. **[E] Mounted shooter** — ride a vehicle/mount that moves and shoots; player focuses on dodging and timing. **← SELECTED**

## Selected Concept: Mounted Mech Shooter
- **Mount**: a mech / walker — an armored machine stomping horizontally through the level.
- **Player fantasy (dominant emotion)**: **power fantasy** — overwhelming firepower, blowing everything up.
- **Structure**: exactly **one level**, kept challenging and replayable by **escalating enemy waves** across the level's length.

## Core Verbs
- **Move / strafe** — precise horizontal and vertical movement of the mech (user-selected emphasis).
- **Aim & shoot** — continuous fire at incoming waves (genre baseline of a shooter).
- **Signature move: Charge shot** — hold fire to charge a screen-clearing heavy blast, released on a cooldown.

## Primary Player Loop
`Strafe the mech to dodge -> shoot down enemy waves -> charge and release a heavy blast at big threats -> explosions, score, and feedback -> next, harder wave arrives -> level ends after the final wave.`

Loop shape: **[Action: move + shoot] -> [Feedback/Reward: explosions, score, power fantasy payoff] -> [Challenge/Mastery: escalating enemy waves and the charge-shot cooldown decision]**

## Convergent Decisions Summary
| Decision | Choice |
|---|---|
| Concept direction | [E] Mounted shooter |
| Mount | Mech / walker |
| Dominant emotion | Power fantasy |
| One-level challenge | Escalating enemy waves |
| Signature move | Charge shot (hold to charge, cooldown) |
| Core verb emphasis | Move / strafe (+ aim & shoot as genre baseline) |
