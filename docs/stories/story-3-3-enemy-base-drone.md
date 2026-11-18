---
title: 'Enemy Base Script & Drone Enemy'
epic: '3'
story_key: '3.3'
forge_task_id: ''
priority: 'HIGH'
story_points: 5
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [3.3]: Enemy Base Script & Drone Enemy

## Intent & User Value
As a player, I want the first enemy type — a drone that approaches and fires at the mech — so that waves have a basic threat to dodge and shoot down.

## Acceptance Criteria
- Given `res://scripts/entities/enemies/enemy.gd` as a shared base (`CharacterBody2D`), when a subclass scene is built, then it provides `hp`, `take_damage(amount)`, a `Hitbox (Area2D)` child whose `area_entered` calls `take_damage`, and on death it emits `Events.enemy_destroyed(enemy_type, pos, score_value)` then `queue_free()` (or returns to pool).
- Given `res://scenes/entities/enemies/drone.tscn`, when instanced by the WaveSpawner, then its tree is `Drone (CharacterBody2D)` with `CollisionShape2D`, `Sprite2D`, `Hitbox (Area2D)`, and `Weapon (Node2D)` + `Muzzle (Marker2D)` per `docs/architecture.md` §3.4.
- Given a spawned drone, when it updates in `_physics_process(delta)`, then it moves toward the player's x position (leftward) until within an `@export`ed attack range, then stops and fires `enemy_bullet` at the `fire_rate` from `enemy_stats.tres` scaled by the wave multiplier.
- Given a drone's HP reaching 0, when `take_damage` runs, then it emits `Events.enemy_destroyed('drone', global_position, score_value)` and is removed with `queue_free()`/pool release — never `free()` mid-frame.
- Given `res://tests/test_enemy_base.gd`, when GUT runs, then damage/death emission and drone approach-stop behavior are verified.

## Godot Changes Plan
- `res://scripts/entities/enemies/enemy.gd` — base class: hp, `take_damage()`, hitbox wiring, death signal, pool-aware removal
- `res://scenes/entities/enemies/drone.tscn` + `res://scripts/entities/enemies/drone.gd` — drone scene and simple approach-and-fire AI
- `res://tests/test_enemy_base.gd` — GUT tests

## Tasks & Subtasks
- [ ] `res://scripts/entities/enemies/enemy.gd` — base enemy with damage/death
- [ ] `res://scenes/entities/enemies/drone.tscn` + `drone.gd` — drone scene + AI
- [ ] `res://tests/test_enemy_base.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
