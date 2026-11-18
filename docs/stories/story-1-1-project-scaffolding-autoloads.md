---
title: 'Project Scaffolding, Autoloads, EventBus & InputMap'
epic: '1'
story_key: '1.1'
forge_task_id: 'cmwm5mjjm0026istv3183v85z'
priority: 'CRITICAL'
story_points: 8
status: 'in-progress'
engine: 'godot-4'
baseline_commit: '71249ddd60b56e33bc2af23c9fb395001d25a1ba'
---

# Story [1.1]: Project Scaffolding, Autoloads, EventBus & InputMap

## Intent & User Value
As a developer, I want the Godot 4.x project skeleton with registered Autoloads, the global EventBus signal catalog, the InputMap actions, and the root `main.tscn` scene tree, so that every later story has a stable foundation (autoloads present before the main scene, one cross-scene broadcast channel, and named input actions) to build on.

## Acceptance Criteria
- Given a fresh Godot 4.x project, when `project.godot` is opened, then the `[autoload]` section registers `Events`, `GameManager`, and `AudioManager` pointing at `res://scripts/globals/events.gd`, `res://scripts/globals/game_manager.gd`, `res://scripts/globals/audio_manager.gd`.
- Given the project settings, when the InputMap is inspected, then actions `move_left`, `move_right`, `move_up`, `move_down`, `shoot`, `charge_shot`, and `pause` exist with keyboard and gamepad bindings as specified in `docs/gdd.md` §2.
- Given `res://scripts/globals/events.gd`, when it is read, then it declares exactly the signal catalog from `docs/architecture.md` §4.1 (`game_state_changed`, `hull_changed`, `player_died`, `player_hit`, `shot_fired`, `charge_changed`, `charge_fired`, `enemy_spawned`, `enemy_destroyed`, `wave_started`, `wave_cleared`, `score_changed`, `victory`, `game_over`), each with static typing.
- Given `res://scripts/globals/game_manager.gd`, when the game starts, then the initial state is `TITLE` and the state machine enum covers `TITLE`, `GAMEPLAY`, `PAUSE`, `GAME_OVER`, `VICTORY` with a `change_state()` method that emits `Events.game_state_changed`.
- Given `res://scenes/main.tscn`, when it is instanced, then the tree is `Main (Node)` with children `World (Node2D)` and `UI (CanvasLayer)` containing `HUD (Control)` and `MenuLayer (Control)`, matching `docs/architecture.md` §3.1.
- Given `res://scripts/utils/object_pool.gd`, when a pool is created with a packed scene, then `acquire()` returns an inactive instance (instantiating only when empty) and `release()` deactivates and re-parents the instance under the pool.
- Given headless verification, when `godot --headless --check-only` runs on all new scripts and GUT tests under `res://tests/` pass, then the scaffolding is syntax-clean and signal wiring works.

## Godot Changes Plan
- `project.godot` — register autoloads; define InputMap actions `move_left/right/up/down`, `shoot`, `charge_shot`, `pause`; base resolution 1920x1080, stretch `canvas_items`/`expand`, Mobile renderer, 60 Hz physics (per `docs/project-context.md`)
- `res://scripts/globals/events.gd` — EventBus Autoload with the full typed signal catalog
- `res://scripts/globals/game_manager.gd` — state machine Autoload (`TITLE -> GAMEPLAY -> (PAUSE <-> GAMEPLAY) -> GAME_OVER | VICTORY`)
- `res://scripts/globals/audio_manager.gd` — BGM bus + pooled SFX player skeleton (fully wired in story 4.3)
- `res://scenes/main.tscn` — root scene with `World` and `UI` (HUD + MenuLayer) placeholders
- `res://scripts/utils/object_pool.gd` — generic pool (`acquire()`/`release()`, no mid-frame `free()`)
- `res://tests/test_events.gd`, `res://tests/test_game_manager.gd`, `res://tests/test_object_pool.gd` — GUT tests

## Tasks & Subtasks
- [x] `project.godot` — autoload registration, InputMap actions, display/renderer settings from `docs/project-context.md`
- [x] `res://scripts/globals/events.gd` — implement the full signal catalog with static typing
- [x] `res://scripts/globals/game_manager.gd` — implement state enum, `change_state()`, `Events.game_state_changed` emission
- [x] `res://scripts/globals/audio_manager.gd` — skeleton with bus layout and pool fields
- [x] `res://scenes/main.tscn` — build the `Main / World / UI(HUD, MenuLayer)` tree
- [x] `res://scripts/utils/object_pool.gd` — implement generic pooling
- [x] `res://tests/` — GUT tests for signal roundtrip, initial state, pool acquire/release
- [x] Verify headless with `godot --headless --check-only` and run GUT (deferred to `godot-verify` board column; no godot binary in this container)

## Dev Agent Record
- **Debug Log:**
  - 2026-11-18: baseline_commit 71249ddd60b56e33bc2af23c9fb395001d25a1ba recorded; implemented project.godot, autoloads, main.tscn, object_pool.gd, and GUT tests on taskBranch.
- **Completion Notes:**
  - InputMap: move_* bound to WASD + arrows + gamepad left stick; shoot/charge_shot share Space + gamepad A (hold-threshold share per GDD §2); pause = Esc + Start.
  - Events declares exactly the 14 signals from architecture §4.1; GameManager initial state TITLE, change_state() emits Events.game_state_changed.
  - Headless godot binary is absent in this container; syntax/GUT execution belongs to the godot-verify column.
