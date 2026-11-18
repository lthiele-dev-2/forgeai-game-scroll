---
title: 'Enemy Bullets, Mech Hull Damage & Death'
epic: '3'
story_key: '3.5'
forge_task_id: 'cmwm5rpeh002nistvjcwdu4hm'
priority: 'HIGH'
story_points: 5
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [3.5]: Enemy Bullets, Mech Hull Damage & Death

## Intent & User Value
As a player, I want enemy fire and contact to visibly drain my mech's hull integrity and end the run at 0, so that dodging matters and losing is a real consequence.

## Acceptance Criteria
- Given `res://scenes/entities/projectiles/enemy_bullet.tscn` (pooled `Area2D`), when fired by an enemy weapon, then it travels left toward the player side at an `@export`ed speed in `_physics_process(delta)` and releases to the pool on hit or leaving bounds.
- Given the mech's `Hitbox (Area2D)`, when an `enemy_bullet` or enemy body enters, then `mech.take_damage(base_damage * enemy_multiplier)` runs and `Events.player_hit(damage, pos)` is emitted.
- Given `res://scripts/entities/mech.gd`, when inspected, then `@export max_hull: int = 100` and `hull` starts at `max_hull`; each `take_damage(d)` reduces hull, emits `Events.hull_changed(hull, max_hull)`, and at 0 emits `Events.player_died()` exactly once (game-over flow handled by GameManager, story 2.3).
- Given hull at 0, when `player_died` fires, then the mech stops accepting movement input (game over state owns teardown).
- Given `res://tests/test_damage.gd`, when GUT runs, then damage formula (`base_damage * enemy_multiplier`), `hull_changed` emission, and single `player_died` at 0 are verified.

## Godot Changes Plan
- `res://scenes/entities/projectiles/enemy_bullet.tscn` + script — pooled enemy projectile
- `res://scripts/entities/enemies/enemy.gd` — weapon fire spawns `enemy_bullet` from pool
- `res://scripts/entities/mech.gd` — `hull`/`max_hull`, `take_damage()`, `Events.hull_changed`/`player_hit`/`player_died`
- `res://scenes/entities/mech.tscn` — `Hitbox (Area2D)` with `area_entered` wiring
- `res://tests/test_damage.gd` — GUT tests

## Tasks & Subtasks
- [ ] `enemy_bullet.tscn` + script — pooled bullet
- [ ] `res://scripts/entities/mech.gd` — hull, damage intake, signals
- [ ] Enemy weapon fire integration
- [ ] `res://tests/test_damage.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
