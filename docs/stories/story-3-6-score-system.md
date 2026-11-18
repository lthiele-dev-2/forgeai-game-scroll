---
title: 'Score System: Kill, Wave-Clear & Charge Multi-Kill Bonuses'
epic: '3'
story_key: '3.6'
forge_task_id: ''
priority: 'MEDIUM'
story_points: 3
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
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
- [ ] Score accumulation in GameManager with `Events.score_changed`
- [ ] Wave-clear and charge multi-kill bonuses
- [ ] `res://tests/test_score.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
