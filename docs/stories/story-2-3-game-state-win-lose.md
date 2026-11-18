---
title: 'GameManager State Machine & Win/Lose Flow'
epic: '2'
story_key: '2.3'
forge_task_id: ''
priority: 'CRITICAL'
story_points: 8
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
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
- [ ] `res://scripts/globals/game_manager.gd` — states, validated transitions, EventBus listeners, wave progression
- [ ] `res://scripts/ui/menu_layer.gd` — menu visibility driven by `game_state_changed`
- [ ] `res://tests/test_game_state_flow.gd` — GUT tests for every transition
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
