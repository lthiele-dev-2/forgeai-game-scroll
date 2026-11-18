---
title: 'Juice: Screen Shake, Explosions, Hit-Flash & Charge Glow'
epic: '4'
story_key: '4.4'
forge_task_id: ''
priority: 'MEDIUM'
story_points: 5
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [4.4]: Juice: Screen Shake, Explosions, Hit-Flash & Charge Glow

## Intent & User Value
As a player, I want explosions, screen shake on the charge blast, hit-flash on enemies, and a visible charge glow, so that the power fantasy lands with visceral feedback.

## Acceptance Criteria
- Given the mech's `Camera2D`, when `Events.charge_fired` or `Events.enemy_destroyed` with a large score fires, then a screen shake is applied by decaying `Camera2D.offset` in `_process(delta)` — no node churn, per `docs/architecture.md` §6.
- Given an enemy destroyed, when `Events.enemy_destroyed` fires, then a pooled `CPUParticles2D` explosion spawns at `pos` with amounts capped (per §6) and returns to its pool after `emitting` finishes.
- Given an enemy taking damage, when `take_damage` runs, then its sprite flashes (hit-flash, e.g. `modulate` tween) briefly.
- Given the charge shot held, when `Events.charge_changed(level)` rises, then the mech's `ChargeGlow` visibility/scale follows `level`.
- Given all effects, when they end, then transient nodes are removed with `queue_free()`/pool release and Autoload connections are disconnected in `_exit_tree()`.
- Given `res://tests/test_juice.gd`, when GUT runs, then shake offset decays toward zero and explosion pool reuse works.

## Godot Changes Plan
- `res://scripts/utils/screen_shake.gd` (or camera offset logic in mech) — decaying `Camera2D.offset`
- `res://scenes/effects/explosion.tscn` + pooled `CPUParticles2D`
- `res://scripts/entities/enemies/enemy.gd` — hit-flash on `take_damage`
- `res://scripts/entities/mech.gd` / `mech.tscn` — ChargeGlow driven by `charge_changed`
- `res://tests/test_juice.gd` — GUT tests

## Tasks & Subtasks
- [ ] Screen shake on charge blast / big explosions
- [ ] Pooled explosion particles with capped amounts
- [ ] Enemy hit-flash
- [ ] ChargeGlow following charge level
- [ ] `res://tests/test_juice.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
