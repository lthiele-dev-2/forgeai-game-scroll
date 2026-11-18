---
title: 'Menus: Title, Pause, Game Over & Victory Screens'
epic: '4'
story_key: '4.2'
forge_task_id: 'cmwm5t86c002sistvtp7pk3rp'
priority: 'MEDIUM'
story_points: 5
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [4.2]: Menus: Title, Pause, Game Over & Victory Screens

## Intent & User Value
As a player, I want title, pause, game over, and victory screens with working buttons, so that I can start, pause, and restart the run cleanly.

## Acceptance Criteria
- Given `res://scenes/menus/title.tscn`, `pause_menu.tscn`, `game_over.tscn`, `victory.tscn`, when loaded under `MenuLayer (Control)` in `main.tscn`, then exactly one menu is visible per `GameManager` state, driven by `Events.game_state_changed` (`res://scripts/ui/menu_layer.gd`).
- Given the title screen, when its Start button is pressed, then it calls down `GameManager.change_state(GAMEPLAY)` (call down, signal up — no cross-tree `get_node()`).
- Given the pause menu, when Resume is pressed, then `GameManager.change_state(GAMEPLAY)`; when Quit is pressed, then `GameManager.change_state(TITLE)`; the tree pause flag is toggled by GameManager (story 2.3).
- Given game over / victory screens, when their Retry button is pressed, then the run restarts into `GAMEPLAY` (level re-instanced); when Menu is pressed, then state returns to `TITLE`.
- Given `res://tests/test_menus.gd`, when GUT runs, then menu visibility follows `game_state_changed` and buttons invoke the right `change_state` calls.

## Godot Changes Plan
- `res://scenes/menus/title.tscn`, `pause_menu.tscn`, `game_over.tscn`, `victory.tscn` — one `Control` each with buttons
- `res://scripts/ui/menu_layer.gd` — shows one menu per state via `Events.game_state_changed`
- `res://scripts/ui/*.gd` menu scripts — button handlers calling down into `GameManager`
- `res://tests/test_menus.gd` — GUT tests

## Tasks & Subtasks
- [ ] Four menu scenes with buttons wired to their scripts
- [ ] `res://scripts/ui/menu_layer.gd` — state-driven visibility
- [ ] `res://tests/test_menus.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
