---
title: 'Score System: Kill, Wave-Clear & Charge Multi-Kill Bonuses'
epic: '3'
story_key: '3.6'
forge_task_id: 'cmwm5s57t002pistvgugjwcpx'
priority: 'MEDIUM'
story_points: 3
status: 'in-progress'
engine: 'godot-4'
baseline_commit: '20fb159de94adb11959036ec7461a8481097cab7'
---

# Story [3.6]: Score System: Kill, Wave-Clear & Charge Multi-Kill Bonuses

## Intent & User Value
As a player, I want score to pay off for kills, wave clears, and big charge-shot multi-kills, so that aggressive play is rewarded with visible score feedback.

## Acceptance Criteria
- Given `Events.enemy_destroyed(enemy_type, pos, score_value)`, when GameManager (or a score component) handles it, then `score += enemy_base_score * wave_multiplier` where `enemy_base_score` comes from `enemy_stats.tres` and `wave_multiplier` from the current wave; `Events.score_changed(new_score)` is emitted.
- Given `Events.wave_cleared(n)`, when handled, then a wave-clear bonus (defined in the wave resource or a constant) is added and `Events.score_changed` re-emitted.
- Given a charge blast destroying multiple enemies, when the resulting `enemy_destroyed` events arrive, then an additional charge multi-kill bonus (e.g. per-kill bonus × number of kills in the blast) is added on top.
- Given score anywhere in the game, when read, then it is display-only — no fail state is tied to it (`docs/gdd.md` §2).
- Given `res://tests/test_score.gd`, when GUT runs, then kill score, wave bonus, and multi-kill bonus formulas are verified numerically.

## Godot Changes Plan
- `res://scripts/globals/game_manager.gd` — score accumulation on `enemy_destroyed` / `wave_cleared`, emits `Events.score_changed`
- `res://resources/waves/wave_0n.tres` — wave-clear bonus field; `res://resources/enemy_stats.tres` — base scores
- `res://tests/test_score.gd` — GUT tests for the three formulas

## Tasks & Subtasks
- [x] Score accumulation in GameManager with `Events.score_changed`
- [x] Wave-clear and charge multi-kill bonuses
- [x] `res://tests/test_score.gd` — GUT tests
- [x] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
  - 2026-11-19: baseline_commit 20fb159de94adb11959036ec7461a8481097cab7 recorded; story resolved via `forge_get_task` description (`Story file: docs/stories/story-3-6-score-system.md`); implemented on taskBranch `feature/init/3-6-score-system-kill-wave-clear-charge-multi-kill-bonuses-cmwm5s57`.
  - No Godot binary in this container (`godot: command not found`, consistent with prior columns); headless `--check-only` + GUT execution is owned by the `godot-verify` column.
- **Completion Notes:**
  - `game_manager.gd`: display-only `score` with `Events.score_changed(new_score)` emitted on every change via `_add_score()`; `enemy_destroyed` handler adds `enemy_stats.tres` base score * `WaveSpawner.wave_multiplier(current_wave)` (fallback to the event's `score_value` for unknown types); `current_wave` tracked from `Events.wave_started`; `wave_cleared(n)` adds the wave resource's `wave_clear_bonus` (fallback `DEFAULT_WAVE_CLEAR_BONUS = 250`); `charge_fired` opens a `blast_window_seconds` window (delta-ticked in `_physics_process`), kills inside it are counted, and on window close a multi-kill (>= 2 kills) adds `multi_kill_bonus_per_kill * kills` on top; `reset_score()` on TITLE/GAME_OVER -> GAMEPLAY; all new Events connections disconnected in `_exit_tree()`.
  - `tests/test_score.gd`: 10 GUT tests covering kill formula at waves 1/2/3, unknown-type fallback, wave-resource and default wave-clear bonus, multi-kill bonus on top of kill scores, single-kill no-bonus, timer-driven window close via `wait_physics_frames`, display-only guarantee (no state change / no `game_over`), and score reset on new run.
