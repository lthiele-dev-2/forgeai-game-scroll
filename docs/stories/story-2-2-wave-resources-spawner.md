---
title: 'Wave Data Resources & WaveSpawner'
epic: '2'
story_key: '2.2'
forge_task_id: 'cmwm5omym002cistvxds9m2d8'
priority: 'HIGH'
story_points: 8
status: 'in-review'
engine: 'godot-4'
baseline_commit: '893fc918d7409d5a96ca45f4a2a2fa87ae6ade22'
---

# Story [2.2]: Wave Data Resources & WaveSpawner

## Intent & User Value
As a player, I want escalating enemy waves that spawn sequentially along the level, so that each cleared wave makes the next one harder and the level ends after the final wave.

## Acceptance Criteria
- Given `res://resources/waves/wave_01.tres` … `wave_05.tres` and `res://resources/enemy_stats.tres`, when inspected, then each wave resource (a `Resource` with `@export` fields) holds enemy types, counts, spawn interval, HP/fire-rate multipliers, and score values — adding a wave means adding a resource, not code (`docs/architecture.md` §5).
- Given `res://scripts/levels/wave_spawner.gd`, when `spawn_wave(n)` is called down by the game flow, then it reads `wave_0n.tres`, computes `wave_multiplier = 1 + 0.25 * (n - 1)`, instantiates enemies from the pool at the `Marker2D` spawn points with the interval, applies HP/count/fire-rate scaling, and emits `Events.wave_started(n)` and `Events.enemy_spawned(type)` per enemy.
- Given a wave's enemies all destroyed, when the spawner counts alive enemies, then at zero it emits `Events.wave_cleared(n)` exactly once and does not respawn that wave.
- Given concurrent enemies, when the spawner updates, then no more than ~24 enemies are alive at once (per `docs/architecture.md` §6); excess spawns are skipped or queued.
- Given `res://tests/test_wave_spawner.gd`, when GUT runs, then `wave_multiplier` for n=1..5 equals 1.0, 1.25, 1.5, 1.75, 2.0, spawn counting is correct, and `wave_cleared` fires once at zero alive.

## Godot Changes Plan
- `res://resources/waves/wave_01.tres` … `wave_05.tres` — data-driven wave definitions (`WaveData` resource class in `res://scripts/resources/wave_data.gd`)
- `res://resources/enemy_stats.tres` — per-enemy-type stats (`EnemyStats` resource)
- `res://scripts/levels/wave_spawner.gd` — `spawn_wave(n)`, alive counting, pool usage, `Events` emissions
- `res://scenes/levels/level_01.tscn` — `WaveSpawner` node with `Marker2D` children
- `res://tests/test_wave_spawner.gd` — GUT tests for multiplier formula, counting, single `wave_cleared`

## Tasks & Subtasks
- [x] `res://scripts/resources/wave_data.gd` + `res://scripts/resources/enemy_stats.gd` — resource classes
- [x] `res://resources/waves/wave_01.tres` … `wave_05.tres` — five wave definitions with escalating counts/HP/fire rate
- [x] `res://scripts/levels/wave_spawner.gd` — spawn logic, multiplier, alive counter, pool integration
- [x] `res://tests/test_wave_spawner.gd` — GUT tests
- [x] Verify headless with `godot --headless --check-only` and run GUT (deferred to `godot-verify` column)

## Dev Agent Record
- **Verify Environment Failure (godot-verify, attempt 2):**
  - `godot --version` -> `/usr/bin/bash: line 1: godot: command not found`; full filesystem search (`find / -xdev -iname "*godot*"`) found no Godot 4.x binary in the container; no `## Human Interaction Resume` authorizing static fallback was present.
  - GUT framework present (`addons/gut/gut_cmdln.gd`) and tests present (`tests/test_wave_spawner.gd` etc.), but cannot be executed without the `godot` binary.
   - `forge_ask_human` called on task cmwm5omym002cistvxds9m2d8: proceed with static GDScript/scene verification, or wait for environment fix.
- **Verify Environment Resolution (godot-verify, attempt 3):**
   - Human resume answer: godot binary is `C:\dev\apps\godot\4.7.2` (Windows host path). That path does not exist in this Linux container (probed directly, plus full-filesystem search); provisioned the official `Godot_v4.7.2-stable_linux.x86_64` headless binary instead and recorded it here per the resume rule. `repair_attempts` reset to 0.
   - `godot --version` -> `4.7.2.stable.official.ed1daf0bf`; `godot --headless --import` -> exit 0 (all `.tscn`/`.tres` parse cleanly).
   - `godot --headless --quit` (main scene smoke load) -> exit 0, no script errors. Note: per-script `--check-only -s` outside the scene tree fails on autoload identifiers (`Events`); in-project compile via GUT/scene load is the authoritative check.
   - GUT (`godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`): 41/41 tests passed, 238 asserts, exit 0 after 1 repair attempt (see below).
   - **Repair attempt 1:** `test_spawn_wave_rejects_invalid_and_missing_waves` failed only because `load()` on missing `wave_99.tres` logs engine errors that GUT counts as unexpected. Fixed in `scripts/levels/wave_spawner.gd` `spawn_wave()` by guarding with `ResourceLoader.exists(path)` before `load()` — no test assertion weakened. Re-run: all 41 tests pass, exit 0.
- **Debug Log:**
  - `WaveSpawner` is generic over `WaveData`/`EnemyStats`; enemy `PackedScene`s resolve lazily from `enemy_stats.tres` scene paths, with `scene_overrides` as the test seam (enemy scenes land in Epic 3 per readiness-report observation 1).
  - Alive counting: `_alive` array pruned by `is_instance_valid` in `_physics_process`, plus one pop per `Events.enemy_destroyed` so pool-released enemies count as destroyed; `wave_cleared` guarded by `_cleared_emitted` + `_cleared_waves`.
- **Completion Notes:**
  - `wave_multiplier(n) = 1 + 0.25*(n-1)` static; applied to count (rounded), HP, and fire rate; score falls back to `enemy_stats` when the wave resource omits it.
  - Cap `max_alive` (~24 default) holds spawns in `_spawn_queue` until a slot frees.
  - `level_01.tscn` WaveSpawner node now runs `wave_spawner.gd` with `enemy_stats.tres` assigned.
