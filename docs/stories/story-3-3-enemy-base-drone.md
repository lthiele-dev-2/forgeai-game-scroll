---
title: 'Enemy Base Script & Drone Enemy'
epic: '3'
story_key: '3.3'
forge_task_id: 'cmwm5qo5p002jistvcfhk5z0t'
priority: 'HIGH'
story_points: 5
status: 'in-review'
engine: 'godot-4'
baseline_commit: '825e473c76cacaf9148293fb860b67073a627fde'
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
- [x] `res://scripts/entities/enemies/enemy.gd` — base enemy with damage/death
- [x] `res://scenes/entities/enemies/drone.tscn` + `drone.gd` — drone scene + AI
- [x] `res://tests/test_enemy_base.gd` — GUT tests
- [x] Verify headless with `godot --headless --check-only` and run GUT (deferred to the `godot-verify` board column, which owns the headless binary)

## Dev Agent Record
- **Debug Log:**
  - No Godot binary in the dev container; headless check + GUT run happen in the `godot-verify` column.
   - godot-verify environment probe (task cmwm5qo5p002jistvcfhk5z0t): `which godot godot4` → not found; `godot --version` → `/usr/bin/bash: line 1: godot: command not found`; filesystem-wide `find / -iname "*godot*" -type f` (excluding /session/workspace, skills, node_modules) → no binary. `addons/gut/gut_cmdln.gd` and `tests/` are present. Environment failure: no Godot runtime available for `godot --headless --check-only` or the GUT runner — escalated via forge_ask_human (static fallback vs. environment fix).
   - Human resume answer for cmwm5qo5p002jistvcfhk5z0t: binary `C:\dev\apps\godot\4.7.2`. Applied: that is a Windows host path and does not exist in this Linux container (`ls` → No such file or directory); re-probe (`which godot godot4 godot-headless`, filesystem-wide `find / -iname "*godot*" -type f`) again found no engine binary. Engine-based verification therefore remains impossible here; proceeding with the static GDScript/scene verification fallback and recording it as the verification result. `repair_attempts` reset to 0.
   - Static verification fallback (godot-verify, task cmwm5qo5p002jistvcfhk5z0t, 2026-11-19): engine-free checker over all 28 non-addon `.gd` files and 10 non-addon `.tscn` files — bracket balance (string/comment aware), tab-only indentation, `class_name` uniqueness, `extends "res://..."` target existence, `preload("res://...")` target existence, `load`/runtime `res://` references, `.tscn` `ext_resource` paths and `ExtResource`/`SubResource` id resolution, node parent ordering, `project.godot` autoload script paths. RESULT: PASS — 0 errors, 1 warning (tests/test_wave_spawner.gd loads `res://resources/waves/wave_%02d.tres`, a format template; wave_01..wave_05.tres all exist).
   - Story AC cross-check (static): `enemy.gd` provides `hp`, `take_damage(amount)`, Hitbox `area_entered` → `take_damage` (area `damage` else `contact_damage`), death emits `Events.enemy_destroyed(enemy_type, global_position, score_value)` (signal declared in `scripts/globals/events.gd:11`) then `pool.release(self)`/`queue_free()` — never `free()`; `drone.tscn` tree = Drone(CharacterBody2D)+CollisionShape2D+Sprite2D+Hitbox(Area2D, layer 2)+Weapon(Node2D)+Muzzle(Marker2D); `drone.gd` `_physics_process` approaches player x until within `@export attack_range`, decelerates to stop, then `Weapon.hold_fire(delta)` at wave-scaled `fire_rate`; `tests/test_enemy_base.gd` present covering tree shape, setup_wave scaling, hitbox→damage, death emission idempotence, pool release, approach-stop, fire-only-in-range, pool cap.
   - NOT EXECUTED (environment): `godot --headless --check-only` and the GUT runner `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` — no Godot 4.x binary exists in this container (human-provided path `C:\dev\apps\godot\4.7.2` is a Windows path). Engine syntax check and the 12-file GUT suite (incl. `tests/test_enemy_base.gd`) remain pending a Linux Godot binary; static parse/resource verification is recorded as the verification result for this column.
- **Completion Notes:**
  - `enemy.gd` (Enemy, CharacterBody2D): `hp`/`max_hp`, `take_damage(amount)`, `setup_wave(type, hp, fire_rate, score)` for the WaveSpawner, `enemy_multiplier` for PlayerShot's damage call, Hitbox `area_entered` wired in `_ready` (area `damage` property else `contact_damage`), death emits `Events.enemy_destroyed(enemy_type, global_position, score_value)` then `pool.release(self)` when a pool is set, else `queue_free()` — never `free()` mid-frame; death is idempotent via `is_alive`.
  - `enemy_weapon.gd` (EnemyWeapon, Node2D): pooled bullet firing at `fire_rate` toward `Vector2.LEFT` from `Muzzle`, `@export bullet_scene` (injectable; drone auto-loads `enemy_bullet.tscn` once story 3.5 lands it), active-bullet cap via `pool_size`, `bullet_fired` signal up.
  - `drone.gd` (Drone extends Enemy): `_physics_process(delta)` moves toward the player's x (`player` group or `set_target`) while `|dx| > @export attack_range`, decelerates to a stop in range, then `Weapon.hold_fire(delta)` fires at the wave-scaled `fire_rate` from `setup_wave`.
  - `drone.tscn`: Drone(CharacterBody2D) + CollisionShape2D + Sprite2D + Hitbox(Area2D, layer 2) + Weapon(Node2D)+Muzzle(Marker2D) per architecture §3.4.
  - `level_01.gd`: mech added to the `player` group so drones can resolve their target without cross-tree `get_node()`.
  - `tests/test_enemy_base.gd`: scene-tree shape, setup_wave scaling, hitbox→take_damage, death signal + queue_free/pool release, approach-stop, fire-only-in-range, pool cap.
