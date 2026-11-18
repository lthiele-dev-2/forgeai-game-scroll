---
title: 'Camera2D Follow Rig & Level Limit Clamping'
epic: '1'
story_key: '1.3'
forge_task_id: 'cmwm5nni00029istv1h3u3a29'
priority: 'MEDIUM'
story_points: 3
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [1.3]: Camera2D Follow Rig & Level Limit Clamping

## Intent & User Value
As a player, I want the camera to follow the mech horizontally with smoothing while staying inside the level edges, so that the side-view battlefield always frames the action at 1920x1080 without showing out-of-bounds space.

## Acceptance Criteria
- Given the mech's `Camera2D` child, when the scene loads, then `position_smoothing_enabled = true` with a tuned `position_smoothing_speed`, and the camera follows the mech's x position.
- Given the camera, when the mech moves vertically, then the camera's vertical position stays fixed at the level midline (horizontal follow only), per `docs/gdd.md` §1.
- Given the level bounds, when the camera is configured (via `set_bounds()` called down by the level), then `limit_left`, `limit_right`, `limit_top`, and `limit_bottom` are set from the level `Rect2`, so the camera never shows outside the level.
- Given the base resolution 1920x1080, when the camera zoom is set, then the visible area matches the design frame at zoom `1.0` (tuned via `@export` if needed).
- Given `res://tests/test_camera_rig.gd`, when GUT runs, then limit values equal the level bounds and smoothing is enabled.

## Godot Changes Plan
- `res://scenes/entities/mech.tscn` — `Camera2D` child with smoothing enabled and `limit_*` properties left to be set at runtime
- `res://scripts/entities/mech.gd` — `set_bounds(rect: Rect2)` configures `Camera2D.limit_*` from the level bounds; horizontal-only follow (y fixed to level midline)
- `res://tests/test_camera_rig.gd` — GUT test verifying limits and smoothing flags

## Tasks & Subtasks
- [ ] `res://scenes/entities/mech.tscn` — add/configure `Camera2D` with `position_smoothing_enabled = true`
- [ ] `res://scripts/entities/mech.gd` — implement bounds-to-camera-limit wiring
- [ ] `res://tests/test_camera_rig.gd` — GUT test for limits
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
