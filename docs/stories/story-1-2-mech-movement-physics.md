---
title: 'Mech Scene & Heavy/Floaty Movement Physics'
epic: '1'
story_key: '1.2'
forge_task_id: 'cmwm5n3nv0027istv8j93vwz6'
priority: 'HIGH'
story_points: 8
status: 'in-progress'
engine: 'godot-4'
baseline_commit: '8ea0236cd6e278f4e2ce6c5a098f9b96330a5383'
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
- [x] `res://scenes/entities/mech.tscn` — build the node tree with placeholder shapes/sprites
- [x] `res://scripts/entities/mech.gd` — implement `_physics_process(delta)` movement with heavy/floaty parameters
- [x] Bounds clamping against the level `Rect2` provided by the level scene
- [x] `res://tests/test_mech_movement.gd` — numeric GUT tests for all four movement behaviors
- [x] Verify headless with `godot --headless --check-only` and run GUT (deferred to `godot-verify` board column; no godot binary or `addons/gut` in this container, same as story 1.1)

## Dev Agent Record
- **Debug Log:**
  - 2026-11-18: baseline_commit 8ea0236cd6e278f4e2ce6c5a098f9b96330a5383 recorded; story resolved via `forge_get_task` description; implemented `scripts/entities/mech.gd`, `scenes/entities/mech.tscn`, `tests/test_mech_movement.gd` on taskBranch `feature/init/1-2-mech-scene-heavy-floaty-movement-physics-cmwm5n3n`.
- **Completion Notes:**
  - All motion confined to `_physics_process(delta)`: per-axis `move_toward` with `acceleration * delta` while input is held and `deceleration * delta` lag on release; `gravity * delta` added to `velocity.y` while airborne (`not is_on_floor()`); `move_and_slide()`; `position` clamped to `bounds: Rect2` after the slide. Tuning `@export`ed: `max_speed` 420, `acceleration` 1400, `deceleration` 650, `gravity` 2400, `bounds`; `set_bounds(rect)` is the call-down API the level uses.
  - `mech.tscn` matches architecture §3.3: `Mech (CharacterBody2D)` with `CollisionShape2D`, `Visual (Node2D)` containing `AnimatedSprite2D` + hidden `ChargeGlow`, `Weapon (Node2D)` with `Muzzle (Marker2D)`, `Hitbox (Area2D)` with its own shape, and `Camera2D` (`position_smoothing_enabled`).
  - `tests/test_mech_movement.gd` verifies scene hierarchy, `@export` presence, ramp-to-max-speed, release deceleration lag, gravity integration, independent diagonal axes, and min/max bounds clamping numerically with fixed `delta = 1/60`, using `Input.action_press/release` and `set_physics_process(false)` for deterministic manual ticks.
  - Headless `godot --headless --check-only` and the GUT runner could not execute here (no godot binary, no `addons/gut/` addon in the container); runtime verification is owed to the `godot-verify` column.
