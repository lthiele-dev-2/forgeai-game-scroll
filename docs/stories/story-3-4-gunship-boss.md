---
title: 'Gunship & Boss Enemies with Phase State Machine'
epic: '3'
story_key: '3.4'
forge_task_id: ''
priority: 'MEDIUM'
story_points: 8
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [3.4]: Gunship & Boss Enemies with Phase State Machine

## Intent & User Value
As a player, I want tougher enemy types — a fast gunship and a multi-phase boss — so that later waves and the final wave demand the charge shot and feel like a climax.

## Acceptance Criteria
- Given `res://scenes/entities/enemies/gunship.tscn` + `gunship.gd` extending `enemy.gd`, when spawned, then it moves faster than the drone, keeps more distance, and fires a spread/burst pattern at a higher fire rate (stats from `enemy_stats.tres` × wave multiplier).
- Given `res://scenes/entities/enemies/boss.tscn`, when spawned (final wave), then it has a phase state-machine child (e.g. `BossPhases (Node)`) with phases that change behavior at HP thresholds (e.g. phase 2 below 50% HP: faster fire, new pattern).
- Given a charge blast hitting the boss, when `take_damage` runs with `blast_damage`, then the boss takes heavy damage but is not one-shot by regular shots; its HP bar/hud feedback flows through `Events.enemy_destroyed` only on death.
- Given any of these enemies dying, when `take_damage` reaches 0 HP, then `Events.enemy_destroyed(enemy_type, pos, score_value)` fires with the type string `'gunship'` or `'boss'` and the node is pool-released/`queue_free()`d.
- Given `res://tests/test_boss_phases.gd`, when GUT runs, then phase transitions at HP thresholds are verified.

## Godot Changes Plan
- `res://scenes/entities/enemies/gunship.tscn` + `res://scripts/entities/enemies/gunship.gd` — fast enemy, burst fire
- `res://scenes/entities/enemies/boss.tscn` + `res://scripts/entities/enemies/boss.gd` + phase child node — multi-phase boss
- `res://resources/enemy_stats.tres` — gunship/boss stat entries
- `res://tests/test_boss_phases.gd` — GUT tests

## Tasks & Subtasks
- [ ] `gunship.tscn` + `gunship.gd` — fast hit-and-run enemy
- [ ] `boss.tscn` + `boss.gd` + phase state machine — thresholds and patterns
- [ ] `res://resources/enemy_stats.tres` — add gunship/boss stats
- [ ] `res://tests/test_boss_phases.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
