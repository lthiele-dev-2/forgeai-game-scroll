---
title: 'HUD: Hull Bar, Charge Meter, Wave & Score Labels'
epic: '4'
story_key: '4.1'
forge_task_id: ''
priority: 'HIGH'
story_points: 5
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [4.1]: HUD: Hull Bar, Charge Meter, Wave & Score Labels

## Intent & User Value
As a player, I want a HUD that always shows my hull, charge meter, current wave, and score, so that I can make decisions (dodge vs. charge) from live information.

## Acceptance Criteria
- Given `res://scenes/ui/hud.tscn`, when instanced under `UI (CanvasLayer)` in `main.tscn`, then its tree is `HUD (Control)` with `HullBar (ProgressBar)`, `ChargeMeter (ProgressBar)`, `WaveLabel (Label)`, `ScoreLabel (Label)`, per `docs/architecture.md` §3.6.
- Given the HUD script (`res://scripts/ui/hud.gd`), when it enters the tree, then it connects to `Events.hull_changed`, `Events.charge_changed`, `Events.wave_started`, and `Events.score_changed` — and never polls gameplay nodes (`docs/architecture.md` §4.2).
- Given `Events.hull_changed(current, maximum)`, when emitted, then `HullBar.max_value = maximum` and `HullBar.value = current`.
- Given `Events.charge_changed(level)`, when emitted, then `ChargeMeter.value = level * 100` (0..100 display).
- Given `Events.wave_started(n)` / `Events.wave_cleared(n)`, when emitted, then `WaveLabel` shows the current wave number.
- Given `Events.score_changed(new_score)`, when emitted, then `ScoreLabel` shows the score.
- Given connections, when the HUD exits the tree, then all `Events` connections are disconnected in `_exit_tree()`.
- Given `res://tests/test_hud.gd`, when GUT runs, then each signal updates the correct control.

## Godot Changes Plan
- `res://scenes/ui/hud.tscn` — HUD layout anchored for 1920x1080
- `res://scripts/ui/hud.gd` — signal-only bindings, `_exit_tree()` cleanup
- `res://tests/test_hud.gd` — GUT tests per signal

## Tasks & Subtasks
- [ ] `res://scenes/ui/hud.tscn` — four controls laid out
- [ ] `res://scripts/ui/hud.gd` — EventBus bindings + cleanup
- [ ] `res://tests/test_hud.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
