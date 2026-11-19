---
title: 'Wave Data Resources & WaveSpawner'
epic: '2'
story_key: '2.2'
forge_task_id: 'cmwm5omym002cistvxds9m2d8'
priority: 'HIGH'
story_points: 8
status: 'in-progress'
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
- **Debug Log:**
  - `WaveSpawner` is generic over `WaveData`/`EnemyStats`; enemy `PackedScene`s resolve lazily from `enemy_stats.tres` scene paths, with `scene_overrides` as the test seam (enemy scenes land in Epic 3 per readiness-report observation 1).
  - Alive counting: `_alive` array pruned by `is_instance_valid` in `_physics_process`, plus one pop per `Events.enemy_destroyed` so pool-released enemies count as destroyed; `wave_cleared` guarded by `_cleared_emitted` + `_cleared_waves`.
- **Completion Notes:**
  - `wave_multiplier(n) = 1 + 0.25*(n-1)` static; applied to count (rounded), HP, and fire rate; score falls back to `enemy_stats` when the wave resource omits it.
  - Cap `max_alive` (~24 default) holds spawns in `_spawn_queue` until a slot frees.
  - `level_01.tscn` WaveSpawner node now runs `wave_spawner.gd` with `enemy_stats.tres` assigned.
