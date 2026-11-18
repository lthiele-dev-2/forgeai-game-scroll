---
title: 'Level 01 Scene: Parallax, Bounds & Spawn Markers'
epic: '2'
story_key: '2.1'
forge_task_id: ''
priority: 'HIGH'
story_points: 5
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
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
- [ ] `res://scenes/levels/level_01.tscn` — build the node tree (parallax, bounds, spawner + markers, containers)
- [ ] `res://scripts/levels/level_01.gd` — `bounds` property, mech instantiation, call-down wiring
- [ ] `res://tests/test_level_01.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
