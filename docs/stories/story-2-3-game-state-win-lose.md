---
title: 'GameManager State Machine & Win/Lose Flow'
epic: '2'
story_key: '2.3'
forge_task_id: 'cmwm5p5wk002eistvvy4pdqa3'
priority: 'CRITICAL'
story_points: 8
status: 'in-review'
engine: 'godot-4'
baseline_commit: 'c8776954335b8609bdd9afdeadd60dd8b1521d34'
---

# Story [2.3]: GameManager State Machine & Win/Lose Flow

## Intent & User Value
As a player, I want clear game states — title, gameplay, pause, game over, victory — so that starting, pausing, losing (hull 0), and winning (final wave cleared) all transition predictably and drive the right scenes.

## Acceptance Criteria
- Given `res://scripts/globals/game_manager.gd`, when the game boots, then state is `TITLE`; `change_state(new_state)` validates transitions and emits `Events.game_state_changed(new_state)`.
- Given state `GAMEPLAY`, when `pause` input is pressed, then state becomes `PAUSE` and the scene tree pauses (`get_tree().paused = true`); pressing `pause` again returns to `GAMEPLAY`.
- Given `Events.player_died` emitted (hull reached 0), when GameManager handles it, then state becomes `GAME_OVER` and `Events.game_over` is emitted.
- Given `Events.wave_cleared(n)` with `n` equal to the final wave index, when GameManager handles it, then state becomes `VICTORY` and `Events.victory` is emitted.
- Given `Events.wave_cleared(n)` with `n` below the final wave, when GameManager handles it, then after a short breather it calls down `wave_spawner.spawn_wave(n + 1)` (call down, signal up — no `get_node()` across the tree; the spawner reference is injected by the level).
- Given `res://scenes/main.tscn` and the menus, when `game_state_changed` fires, then `MenuLayer` shows exactly one menu matching the state (title/pause/game over/victory) and `World` holds the active level only in `GAMEPLAY`/`PAUSE`.
- Given `res://tests/test_game_state_flow.gd`, when GUT runs, then all transitions (`TITLE->GAMEPLAY->PAUSE->GAMEPLAY`, `GAMEPLAY->GAME_OVER`, final-wave `GAMEPLAY->VICTORY`, breather then `spawn_wave(n+1)`) are verified.

## Godot Changes Plan
- `res://scripts/globals/game_manager.gd` — full state machine, `change_state()`, listeners on `Events.player_died` / `wave_cleared` / `victory`, breather timer for next wave
- `res://scenes/main.tscn` + `res://scripts/ui/menu_layer.gd` — one visible menu per state
- `res://tests/test_game_state_flow.gd` — GUT transition tests

## Tasks & Subtasks
- [x] `res://scripts/globals/game_manager.gd` — states, validated transitions, EventBus listeners, wave progression
- [x] `res://scripts/ui/menu_layer.gd` — menu visibility driven by `game_state_changed`
- [x] `res://tests/test_game_state_flow.gd` — GUT tests for every transition
- [x] Verify headless with `godot --headless --check-only` and run GUT (deferred to `godot-verify` column; no godot binary in this container)

## Dev Agent Record
- **Verify Record (godot-verify, task cmwm5p5wk002eistvvy4pdqa3):**
  - Environment: no `godot` binary in PATH; full filesystem search found none. Provisioned official `Godot_v4.7.2-stable_linux.x86_64` headless binary (`godot --version` -> `4.7.2.stable.official.ed1daf0bf`). GUT 9.7.1 present at `addons/gut/gut_cmdln.gd`; 8 test scripts in `tests/`.
  - `godot --headless --import` -> exit 0 (all `.tscn`/`.tres` parse and import cleanly).
  - `godot --headless --check-only -s <script>` for every `scripts/**/*.gd` and `tests/**/*.gd`: no parse/syntax errors; only expected `Identifier not found: Events/GameManager/AudioManager` autoload-resolution noise when compiling scripts outside the project tree (autoloads register only in-project). In-project compile is authoritative.
  - `godot --headless --quit-after 5` (main scene `res://scenes/main.tscn` smoke load) -> exit 0, no script errors.
  - GUT (`godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`): **51/51 tests passed, 296 asserts, exit 0, 0 repair attempts.** Includes all `test_game_state_flow.gd` transitions (TITLE boot, validated `change_state` + `game_state_changed`, PAUSE toggle with `get_tree().paused`, `player_died` -> GAME_OVER + `game_over`, final `wave_cleared` -> VICTORY + `victory`, breather then `spawn_wave(n+1)` via injected spawner).
  - `repair_attempts`: 0 (within the max-3 bound). Status set to `in-review`.
- **Debug Log:**
  - Implemented full state machine in `game_manager.gd` with validated transition table, `PROCESS_MODE_ALWAYS` for pause input while tree is paused, breather countdown in `_physics_process` guarded to GAMEPLAY, and injected `wave_spawner` reference (no cross-tree `get_node()`).
  - `level_01.gd` injects its `WaveSpawner` into `GameManager` on `_ready()` and clears it on `_exit_tree()`.
  - `main.gd` holds the active level under `World` only in GAMEPLAY/PAUSE and starts wave 1 when a fresh level is instanced.
  - `menu_layer.gd` shows exactly one menu per state (none in GAMEPLAY); four minimal menu scenes created under `scenes/menus/` for story 4.2 to enrich with buttons.
- **Completion Notes:** All acceptance criteria covered by `res://tests/test_game_state_flow.gd` (boot TITLE, validated transitions + `game_state_changed`, pause toggle with `get_tree().paused`, `player_died` -> GAME_OVER + `game_over`, final `wave_cleared` -> VICTORY + `victory`, breather then `spawn_wave(n+1)` via injected spawner, main.tscn menu/world behavior).
