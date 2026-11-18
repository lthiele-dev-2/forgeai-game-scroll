---
title: 'Mech Scene & Heavy/Floaty Movement Physics'
epic: '1'
story_key: '1.2'
forge_task_id: ''
priority: 'HIGH'
story_points: 8
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [1.2]: Mech Scene & Heavy/Floaty Movement Physics

## Intent & User Value
As a player, I want the mech to strafe in 2D with a heavy, deliberate feel — slow acceleration ramp, long deceleration lag, and strong gravity when airborne — so that dodging enemy fire feels weighty and skillful rather than twitchy.

## Acceptance Criteria
- Given `res://scenes/entities/mech.tscn` instanced in the level, when the scene loads, then the root is `Mech (CharacterBody2D)` with children `CollisionShape2D`, `Visual (Node2D)` (AnimatedSprite2D + ChargeGlow), `Weapon (Node2D)` with `Muzzle (Marker2D)`, `Hitbox (Area2D)`, and `Camera2D`, matching `docs/architecture.md` §3.3.
- Given `res://scripts/entities/mech.gd`, when inspected, then tuning parameters are `@export`ed: `max_speed`, `acceleration`, `deceleration`, `gravity`, and strafe bounds (`bounds: Rect2`).
- Given the mech at rest, when `move_right` is held, then horizontal velocity ramps toward `max_speed` following `velocity.x = move_toward(velocity.x, input * max_speed, acceleration * delta)` inside `_physics_process(delta)` — never in `_process`.
- Given the mech moving at `max_speed`, when input is released, then velocity decays with the `deceleration` lag (not instantly), producing the floaty feel.
- Given the mech airborne, when gravity applies, then `velocity.y` increases by `gravity * delta` each physics tick until landing via `move_and_slide()`.
- Given 8-way input (`move_left/right/up/down` combined), when a diagonal is held, then both axes integrate independently and the mech moves diagonally within the level bounds.
- Given the mech at a level edge, when it would cross the bounds, then its position is clamped to the level `bounds: Rect2` after `move_and_slide()`.
- Given headless GUT tests in `res://tests/test_mech_movement.gd`, when run, then acceleration ramp, deceleration lag, gravity integration, and bounds clamping are all verified numerically with fixed `delta` values.

## Godot Changes Plan
- `res://scenes/entities/mech.tscn` — full mech node hierarchy per architecture §3.3
- `res://scripts/entities/mech.gd` — `CharacterBody2D` script; `_physics_process(delta)` reads InputMap actions, integrates velocity with `delta`, calls `move_and_slide()`, clamps to `bounds`; exposes `@export` tuning; `set_bounds(rect: Rect2)` called down by the level
- `res://tests/test_mech_movement.gd` — GUT tests: ramp-to-max-speed, release-lag decay, gravity integration, diagonal strafe, bounds clamp

## Tasks & Subtasks
- [ ] `res://scenes/entities/mech.tscn` — build the node tree with placeholder shapes/sprites
- [ ] `res://scripts/entities/mech.gd` — implement `_physics_process(delta)` movement with heavy/floaty parameters
- [ ] Bounds clamping against the level `Rect2` provided by the level scene
- [ ] `res://tests/test_mech_movement.gd` — numeric GUT tests for all four movement behaviors
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
