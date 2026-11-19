---
title: 'Enemy Bullets, Mech Hull Damage & Death'
epic: '3'
story_key: '3.5'
forge_task_id: 'cmwm5rpeh002nistvjcwdu4hm'
priority: 'HIGH'
story_points: 5
status: 'done'
engine: 'godot-4'
baseline_commit: '248d41359c0aa09f2338a0ced1df3198777b31f3'
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
- [x] `enemy_bullet.tscn` + script — pooled bullet
- [x] `res://scripts/entities/mech.gd` — hull, damage intake, signals
- [x] Enemy weapon fire integration
- [x] `res://tests/test_damage.gd` — GUT tests
- [x] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
  - godot-verify (task cmwm5rpeh002nistvjcwdu4hm): no Godot binary in the container, so the official `Godot_v4.5-stable_linux.x86_64` release was fetched to /tmp and used (GUT 9.6.1 requires Godot >= 4.4 for the `Logger` base class; project targets 4.3 features, 4.5 loads it cleanly). `godot --headless --import` registered 119 global classes with 0 parse errors; full project load `godot --headless --quit` exited 0 with 0 script errors.
  - GUT suite `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`: first run 103/105 passing, exit 1. Two pre-existing failures inherited from story 3.4 (its verify column ran static-only, commit 17d3349, because the container had no binary): `test_boss_phases.gd::test_gunship_hit_and_run_standoff_then_burst_fire` (18 vs 15 bullets — gunship fired while between attack_range and preferred_distance) and `test_boss_phases.gd::test_final_wave_spawner_loads_real_boss_and_gunship_scenes` (boss starved behind 51 scaled gunships in the spawn queue). Both confirmed failing on `origin/feature/init/base` before repair.
  - Repair attempt 1 (implementation only, no test weakened): `gunship.gd` now gates `hold_fire` on standoff distance (`absf(dx) <= preferred_distance`) instead of attack range; `wave_spawner.gd` `start_wave` enqueues per-type jobs round-robin so mixed waves interleave types and the boss is not starved. Re-run: **105/105 tests passing, 572 asserts, exit code 0** ("All tests passed!"). 2 orphan warnings remain (leaked pooled bullet node in test_damage teardown; non-fatal, does not affect exit code).
- **Verification Record:**
  - PASS — Godot 4.5.0.stable headless import + project load clean; GUT 9.6.1 suite over `res://tests` (13 scripts, 105 tests incl. `tests/test_damage.gd` damage formula / hull_changed / single player_died / bullet pooling): 105 passing, 0 failing, exit 0.
- **Completion Notes:**
  - `scripts/entities/projectiles/enemy_bullet.gd` + `scenes/entities/projectiles/enemy_bullet.tscn` (`EnemyBullet`, Area2D, layer 8 / mask 1 so enemy hitboxes on layer 2 never friendly-fire and the mech Hitbox detects it): pooled bullet with the same 5-arg `fire(pos, dir, dmg, pool, bounds)` contract `EnemyWeapon` already calls; `@export speed`, moves `direction * speed * delta` in `_physics_process`, releases to the pool on `area_entered`, `max_lifetime` expiry, or leaving `level_bounds`; never `free()` mid-frame.
  - `scripts/entities/mech.gd`: `@export max_hull: int = 100`; `hull` starts at `max_hull` in `_ready` (initial `Events.hull_changed` emitted); `take_damage(d)` clamps hull at 0, emits `Events.hull_changed(hull, max_hull)` per hit, and at 0 emits `Events.player_died()` exactly once via the `is_alive` guard; Hitbox `area_entered`/`body_entered` wired in `_ready`, disconnected in `_exit_tree`, applying `base_damage * enemy_multiplier` (bullet `damage`/`enemy_multiplier`, enemy body/hitbox `contact_damage`/`enemy_multiplier`) and emitting `Events.player_hit(damage, pos)`; after death the mech ignores movement and fire input.
  - `scenes/entities/mech.tscn`: Hitbox `collision_mask = 9` (layer 1 bodies + layer 8 enemy bullets).
  - Enemy weapon fire integration: `enemy_weapon.gd` already pools and fires bullets leftward from the Muzzle with an active-bullet cap; `drone.gd`/`gunship.gd`/`boss.gd` auto-load `res://scenes/entities/projectiles/enemy_bullet.tscn`, which now exists.
   - `tests/test_damage.gd`: 12 GUT tests — export + hull init (default and custom `max_hull`), `hull_changed` params, single `player_died` at 0, bullet and body damage formula `base_damage * enemy_multiplier` with `player_hit(damage, pos)`, input/fire gating after death, leftward `speed * delta` movement, bounds/hit pool release, pool reuse, and drone firing the real pooled `EnemyBullet` scene.
- **Review Record (bmgd-code-review, task cmwm5rpeh002nistvjcwdu4hm):**
  - Diff inspected from `baseline_commit` 248d413 to HEAD on `taskBranch` (enemy_bullet.gd/.tscn, mech.gd/.tscn, gunship.gd, wave_spawner.gd, test_damage.gd).
  - Lens 1 (physics/frame budget): PASS — bullet motion is `direction * speed * delta` in `_physics_process(delta)`; no per-frame allocations on the 60fps hot path; spawner changes are in `start_wave`, off the hot path.
  - Lens 2 (node lifecycle/memory): PASS after patch — pooled bullets release via `ObjectPool.release` (never `free()` mid-frame); all signal connections disconnected in `_exit_tree`. Patched: `_die()` now zeroes `velocity` so the mech halts immediately on death; `test_damage.gd` `after_each` releases active test-parented bullets to the pool (clears the orphan warning noted in verify).
  - Lens 3 (signal decoupling): PASS — cross-scene events go through the `Events` autoload (`hull_changed`, `player_hit`, `player_died`); hitbox uses direct child signal connections only; no `get_parent()` node-path chains.
  - Lens 4 (ACs/GUT): PASS — collision wiring verified: enemy bodies on default layer 1 and bullets on layer 8 are both in the mech Hitbox `collision_mask = 9`; enemy hitboxes on layer 2 and player shots on layer 4 are excluded (no friendly fire); bullet `collision_mask = 1` reaches the mech Hitbox on layer 1. All 5 Given/When/Then ACs implemented and covered by the 12 GUT tests in `tests/test_damage.gd` (verify column: 105/105 passing, exit 0).
