---
title: 'Level 01 Scene: Parallax, Bounds & Spawn Markers'
epic: '2'
story_key: '2.1'
forge_task_id: 'cmwm5o4kz002bistv8oa8c3cy'
priority: 'HIGH'
story_points: 5
status: 'in-progress'
engine: 'godot-4'
baseline_commit: 'ab2cfcc48bee52de2014218b1daac251b0b6164f'
---

# Story [2.1]: Level 01 Scene: Parallax, Bounds & Spawn Markers

## Intent & User Value
As a player, I want a single side-scrolling level with parallax depth and clearly defined edges, so that the battlefield reads as a long industrial stretch and the mech/camera have hard limits to stay inside it.

## Acceptance Criteria
- Given `res://scenes/levels/level_01.tscn`, when instanced, then the root `Level01 (Node2D)` has children `ParallaxBackground` (three `ParallaxLayer`s: far/mid/near), `Bounds (StaticBody2D)`, `WaveSpawner (Node2D)` with `Marker2D` spawn points along the level length, `Entities (Node2D)`, and `Projectiles (Node2D)`, matching `docs/architecture.md` §3.2.
- Given `res://scripts/levels/level_01.gd`, when the level enters the tree, then it exposes `bounds: Rect2` (level rectangle used for mech clamping and camera limits) and calls down `mech.set_bounds(bounds)` and the wave spawner configuration when the mech spawns.
- Given the `Bounds (StaticBody2D)`, when inspected, then it has `CollisionShape2D`s covering all four level edges so nothing leaves the level.
- Given the parallax layers, when the camera moves horizontally, then far/mid/near layers scroll at decreasing rates (parallax depth) with draw calls kept under 200 per frame (few large sprites, per `docs/architecture.md` §6).
- Given the `Marker2D` spawn points under `WaveSpawner`, when read, then they are positioned along the level's length at the x positions waves should appear.
- Given headless verification, when `godot --headless --check-only` and GUT tests in `res://tests/test_level_01.gd` run, then the scene parses, `bounds` is a valid non-empty `Rect2`, and marker count > 0.

## Godot Changes Plan
- `res://scenes/levels/level_01.tscn` — full level scene per architecture §3.2
- `res://scripts/levels/level_01.gd` — exposes `bounds: Rect2`, spawns/instances the mech into `Entities`, pushes bounds down to mech and camera
- `res://tests/test_level_01.gd` — GUT tests for bounds validity and spawn marker presence

## Tasks & Subtasks
- [x] `res://scenes/levels/level_01.tscn` — build the node tree (parallax, bounds, spawner + markers, containers)
- [x] `res://scripts/levels/level_01.gd` — `bounds` property, mech instantiation, call-down wiring
- [x] `res://tests/test_level_01.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT (handled by the `to_verify` column)

## Dev Agent Record
- **Debug Log:**
  - Level rect fixed to Rect2(0, -540, 5760, 1080), matching the camera rig tests (`tests/test_camera_rig.gd` LEVEL_BOUNDS).
  - Bounds StaticBody2D carries four CollisionShape2D edges (64px thick) overlapping each edge of `bounds`.
  - Five Marker2D spawn points (x = 1440..5280) under WaveSpawner; WaveSpawner left as plain Node2D — `wave_spawner.gd` is story 2.2, `level_01.gd` calls down `set_bounds` via `has_method` guard so the scene stays loadable until then.
- **Completion Notes:**
  - `Level01` exposes `@export var bounds: Rect2`, spawns the mech into `Entities` on `_ready()` and pushes bounds down via `mech.set_bounds(bounds)` (camera limits follow inside Mech).
  - GUT tests in `res://tests/test_level_01.gd` cover scene structure, bounds validity/edge coverage, parallax rates, spawn markers, and mech spawn wiring.
