---
title: 'Gunship & Boss Enemies with Phase State Machine'
epic: '3'
story_key: '3.4'
forge_task_id: 'cmwm5r65f002listvg1t6hv67'
priority: 'MEDIUM'
story_points: 8
status: 'done'
engine: 'godot-4'
baseline_commit: 'c860d32fba19dd7f380a0817a6321dae97e34c3c'
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
- [x] `gunship.tscn` + `gunship.gd` — fast hit-and-run enemy
- [x] `boss.tscn` + `boss.gd` + phase state machine — thresholds and patterns
- [x] `res://resources/enemy_stats.tres` — gunship/boss stat entries present (scene paths, hp, fire_rate, score)
- [x] `res://tests/test_boss_phases.gd` — GUT tests
- [x] Verify headless with `godot --headless --check-only` and run GUT (deferred to the `godot-verify` board column, which owns the headless binary)

## Dev Agent Record
- **Debug Log:**
  - No Godot binary in the dev container; headless check + GUT run happen in the `godot-verify` column.
  - godot-verify environment probe (task cmwm5r65f002listvg1t6hv67, 2026-11-19): `which godot godot4` → not found; `godot --version` → `/usr/bin/bash: line 1: godot: command not found`; filesystem-wide `find / -iname "*godot*" -type f` (excluding workspace/skills) → no engine binary. `addons/gut/gut_cmdln.gd` and `tests/` (13 test files incl. `test_boss_phases.gd`) are present. Engine-based verification impossible in this container; prior human answer for task cmwm5qo5p002jistvcfhk5z0t (recorded in story-3-3 Dev Agent Record) established that no Godot binary exists here and authorized the static GDScript/scene verification fallback. `repair_attempts` = 0 (no failing command to repair).
  - Static verification fallback (godot-verify, task cmwm5r65f002listvg1t6hv67, 2026-11-19): engine-free checker over all 32 non-addon `.gd` files, 12 non-addon `.tscn` files, 6 `.tres` files — bracket balance (string/comment aware), tab-only indentation, `class_name` uniqueness (15 names), `extends "res://..."` target existence, named-class `extends` resolution (project class_names + GUT `GutTest` + engine builtins), `preload`/`load`/`ResourceLoader.exists` `res://` targets, `.tscn`/`.tres` `ext_resource` paths and `ExtResource`/`SubResource` id resolution, node parent ordering, `load_steps` sufficiency, `project.godot` autoload script paths. RESULT: PASS — 0 errors, 0 warnings. (`res://scenes/entities/projectiles/enemy_bullet.tscn` is referenced only via a `const` string guarded by `ResourceLoader.exists` in gunship/boss `_ready`; it lands in story 3.5.)
  - Story AC cross-check (static): gunship.gd `extends Enemy`, move_speed 380 > drone 240, attack_range 620 > drone 420, preferred_distance 480 > drone attack_range, gunship.tscn Weapon burst_count=3 spread_degrees=24.0, enemy_stats.tres gunship fire_rate 2.0 > drone 1.2 with wave multipliers applied in `setup_wave`; boss.tscn has BossPhases(Node) child with hp_thresholds [1.0, 0.5] and boss.gd updates phase at `hp / max_hp` in `take_damage` before the death check; charge_blast.gd applies raw `blast_damage` when `is_boss` else 100x destroy multiplier, boss 500 base HP means regular 10-damage shots cannot one-shot; `Events.enemy_destroyed('gunship'|'boss', pos, score)` fires only in `_die()` at 0 HP then pool-release/`queue_free()`; wave_05.tres (final wave) spawns 1 boss + 6 gunships; `tests/test_boss_phases.gd` covers all five ACs including phase transitions at 52%/48%/exactly-50% HP.
  - NOT EXECUTED (environment): `godot --headless --check-only` and the GUT runner `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` — no Godot 4.x binary exists in this container. Static parse/resource verification is recorded as the verification result for this column, per the authorized fallback.
- **Completion Notes:**
  - `enemy_weapon.gd` (EnemyWeapon): new `@export burst_count` (default 1) and `@export spread_degrees` (default 0) — `_fire()` now spawns a centered spread/burst of `Vector2.LEFT.rotated(offset)` bullets; defaults keep the drone's single leftward bullet unchanged.
  - `gunship.gd` (Gunship extends Enemy): `move_speed` 380 > drone 240, `attack_range` 620 and `preferred_distance` 480 keep more standoff than the drone; approaches at full speed outside `attack_range`, closes at half speed down to `preferred_distance`, then strafes vertically (hit-and-run) while firing at the wave-scaled `fire_rate`; `gunship.tscn` Weapon runs a 3-round 24° spread burst.
  - `boss_phases.gd` (BossPhases, Node): HP-ratio threshold state machine (`hp_thresholds` [1.0, 0.5] descending), `get_phase_for_ratio`, `update_phase` emitting `phase_changed(phase)` only on actual transitions, `reset()` for pool reuse.
  - `boss.gd` (Boss extends Enemy): `is_boss = true` so `charge_blast.gd` applies raw `blast_damage` instead of the 100x destroy multiplier; `take_damage` updates `BossPhases` at `hp / max_hp` before the death check, so `Events.enemy_destroyed('boss', ...)` fires only on death; high HP (500 base × wave multipliers) means regular 10-damage shots cannot one-shot; `_on_phase_changed` re-applies per-phase weapon config (phase 2: fire rate ×2, 5-round 60° spread); slow approach to `preferred_distance`, fires in range.
  - `boss.tscn`: Boss(CharacterBody2D) + CollisionShape2D + Sprite2D + Hitbox(Area2D, layer 2) + Weapon(Node2D)+Muzzle(Marker2D) + BossPhases(Node) child.
  - `resources/enemy_stats.tres`: gunship (hp 60, fire_rate 2.0, score 250) and boss (hp 500, fire_rate 1.0, score 1000) entries already present and now backed by real scenes; wave_04/wave_05 reference them.
   - `tests/test_boss_phases.gd`: stats/scene-path resolution, gunship tuning vs drone + standoff/strafe/burst directions, gunship death signal + queue_free, boss scene tree + BossPhases child + is_boss, phase transitions at 52%/48%/exactly-50% HP with per-phase weapon config, BossPhases ratio boundaries + idempotent emission, blast-vs-regular damage on boss with enemy_destroyed only on death, charge_blast raw damage on boss vs destroy damage on gunship, WaveSpawner spawning real boss/gunship scenes.
- **Review Report (bmgd-code-review, task cmwm5r65f002listvg1t6hv67, 2026-11-19):**
  - Diff inspected: `git diff c860d32..HEAD` on taskBranch — 12 files (boss/gunship scenes+scripts, boss_phases.gd, enemy_weapon.gd burst/spread, test_boss_phases.gd, story file).
  - Lens 1 (physics & frame budget): PASS — all motion in `_physics_process(delta)`; `move_toward(..., deceleration * delta)` and `_strafe_timer -= delta` are delta-scaled; movement via velocity + `move_and_slide()`; burst loop bounded by `burst_count` (≤5) with pool `acquire()`, no per-frame `instantiate()` on the hot path.
  - Lens 2 (node lifecycle & memory): PASS — `_die()` uses `pool.release(self)`/`queue_free()`, never `free()` mid-frame; `boss.gd::_exit_tree` disconnects `BossPhases.phase_changed`, base disconnects hitbox; `.uid` files present for new scripts.
  - Lens 3 (signal decoupling): PASS — call down (`_weapon.hold_fire(delta)`, `set_fire_rate`), signal up (`phase_changed` child→parent, `Events.enemy_destroyed` emitted only in `_die()`); no `get_parent().get_parent()` chains; `bullet_fired` has no external listeners so once-per-burst emit is behavior-neutral.
  - Lens 4 (ACs & GUT coverage): PASS — all 5 Given/When/Then ACs verified against code: gunship 380 > drone 240 speed, 620/480 standoff, fire_rate 2.0 > 1.2 × wave multiplier via `setup_wave`, 3-round 24° burst; boss BossPhases child with [1.0, 0.5] thresholds updated in `take_damage` before the death check; `is_boss` → raw `blast_damage` from charge_blast, 500 HP not one-shottable by 10-dmg shots, `enemy_destroyed('gunship'|'boss', pos, score)` only on death; `test_boss_phases.gd` covers all ACs incl. 52%/48%/exactly-50% phase transitions.
  - Auto-patch (1 repair attempt): `boss.gd::_apply_phase()` indexed `phase_fire_rate_multipliers[rate_idx]` without a size guard (unlike the burst/spread arrays) — an emptied export array would cause an index-out-of-bounds; added `if phase_fire_rate_multipliers.size() > 0:` guard. Statically verified (bracket balance, tab indentation); no Godot binary in container per prior authorized fallback.
  - Result: review PASSED, `status: 'done'`.
