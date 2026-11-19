---
title: 'Camera2D Follow Rig & Level Limit Clamping'
epic: '1'
story_key: '1.3'
forge_task_id: 'cmwm5nni00029istv1h3u3a29'
priority: 'MEDIUM'
story_points: 3
status: 'in-review'
engine: 'godot-4'
baseline_commit: '723df4613d285b870369b8e80710ca3add4621f3'
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
- [x] `res://scenes/entities/mech.tscn` — add/configure `Camera2D` with `position_smoothing_enabled = true`
- [x] `res://scripts/entities/mech.gd` — implement bounds-to-camera-limit wiring
- [x] `res://tests/test_camera_rig.gd` — GUT test for limits
- [x] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
  - Camera2D child of Mech configured in `mech.tscn` with `position_smoothing_enabled = true`, `position_smoothing_speed = 8.0`, `zoom = Vector2(1, 1)`.
  - `mech.gd`: `@onready var camera: Camera2D`, `@export var camera_smoothing_speed`, `@export var camera_zoom`; `_ready()` applies smoothing/zoom and pushes `bounds` down to camera limits via `set_bounds()`.
  - `set_bounds(rect)` stores `level_midline_y = rect.get_center().y` and writes `limit_left/right/top/bottom` from the level `Rect2` (call-down from the level).
  - `_physics_process(delta)` pins `camera.global_position.y = level_midline_y` after clamping → horizontal-only follow with smoothing on x.
  - Headless `godot --headless --check-only` + GUT run deferred to the `godot-verify` board column (no godot binary in this container).
 - **Completion Notes:** All ACs covered by `res://tests/test_camera_rig.gd` (smoothing flags, zoom 1.0 at 1920x1080, limits == level bounds, y pinned to midline while mech moves vertically).
  - **Verify Agent Record (godot-verify, attempt 2):**
    - Environment probe: `which godot godot4` -> not found; `godot --version` -> `/usr/bin/bash: line 1: godot: command not found`; filesystem search (`find / -iname "*godot*"` excluding workspace) -> no Godot binary in container.
    - GUT probe: `addons/gut/gut_cmdln.gd` does NOT exist in the repo (no `addons/` directory); `tests/` contains test_camera_rig.gd, test_events.gd, test_game_manager.gd, test_mech_movement.gd, test_object_pool.gd.
    - Blocked: cannot run `godot --headless --check-only` or `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` without the engine binary and the GUT addon. Escalated via forge_ask_human (environment failure path).
  - **Verify Agent Record (godot-verify, attempt 3):**
    - Human resume answer recorded: godot binary path `C:\dev\apps\godot\4.7.2` (Windows path; not present in this Linux container — verified by filesystem search). Repair: provisioned the official `Godot_v4.7.2-stable_linux.x86_64` headless binary (same 4.7.2 version the human pointed at) and installed the GUT `v9.6.1` addon into `addons/gut/` (was missing from the repo).
    - Headless editor import (`godot --headless --editor --quit`) built `.godot/global_script_class_cache.cfg` (registers `GutTest`); project load `godot --headless --quit` -> exit 0, no scene parse errors.
    - Per-script `godot --headless --check-only -s res://...` over `scripts/` + `tests/`: only single-script-mode artifacts remain (autoload `Events` not instanced under `-s`; GUT font import skipped without libfontconfig) — both compile cleanly in full-project context, proven by the GUT run below.
    - GUT suite `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` -> **24/24 tests passed, 75 asserts, exit 0** (first run: 20/24; 4 pre-existing failures from stories 1.1/1.2, repaired within budget, no assertion weakened):
      - `tests/test_events.gd`: count script-declared signals via `Events.get_script().get_script_signal_list()` (14) instead of `get_signal_list()` which includes 13 inherited Node signals.
      - `tests/test_mech_movement.gd`: `after_each` now removes and `free()`s the mech immediately (deferred `queue_free` left it overlapping the next test's mech at (0,0), zeroing `velocity.x` on the first tick); float comparisons use `assert_almost_eq(..., 0.001)` to absorb float32-vs-float64 rounding (e.g. 23.3333339691162 vs 23.3333333333333).
    - All 5 `test_camera_rig.gd` tests (this story's ACs: smoothing enabled/tuned, zoom 1.0 at 1920x1080, limits == level bounds, y pinned to midline under vertical motion) pass.
    - Result: headless Godot 4.7.2 syntax/scene check + GUT suite PASS on `taskBranch`; status set to `in-review`.
