---
title: 'Signature Move: Charge Shot (Hold / Charge / Release / Cooldown)'
epic: '3'
story_key: '3.2'
forge_task_id: 'cmwm5q7nh002histvfj79bw9b'
priority: 'HIGH'
story_points: 8
status: 'done'
engine: 'godot-4'
baseline_commit: '74fa1692b5cf78a1e733224645e3a41f0f46a5b3'
---

# Story [3.2]: Signature Move: Charge Shot (Hold / Charge / Release / Cooldown)

## Intent & User Value
As a player, I want to hold fire to charge a screen-clearing heavy blast and release it at the right moment, with a cooldown that scales with charge, so that the charge shot becomes the mastery layer of the combat loop.

## Acceptance Criteria
- Given the `charge_shot` action held (sharing the `shoot` button via hold-threshold), when `weapon.hold_fire(delta)` runs, then `hold_time` accumulates and `charge_level = clamp(hold_time / full_charge_time, 0, 1)`; while held, `Events.charge_changed(charge_level)` is emitted each tick and the mech's `ChargeGlow` becomes visible.
- Given the charge released, when `release_fire()` runs, then if `charge_level` is below the minimum threshold a normal shot fires; otherwise the single reusable `charge_blast` instance (`res://scenes/entities/projectiles/charge_blast.tscn`) is fired, `Events.charge_fired(charge_level)` is emitted, and `hold_time` resets.
- Given a charge blast fired at `charge_level`, when it hits enemies, then it destroys all regular enemies on screen and deals heavy damage to bosses with `blast_damage = base_blast * (0.5 + 0.5 * charge_level)`.
- Given a charge shot released, when the cooldown elapses, then `cooldown = base_cooldown * (1 - 0.5 * charge_level)` must pass before charging again; the charge meter reads 0 during cooldown and `charge_changed` is not emitted.
- Given `res://tests/test_charge_formula.gd`, when GUT runs, then for `charge_level` in {0.0, 0.25, 0.5, 1.0} the blast damage and cooldown match the formulas exactly, and `clamp(hold_time / full_charge_time, 0, 1)` saturates at 1.0.
- Given headless verification, when `godot --headless --check-only` and GUT run, then all charge-shot scripts parse and formulas pass.

## Godot Changes Plan
- `res://scripts/entities/weapon.gd` — charge state (`hold_time`, `charging`, `cooldown_timer`), `@export` `full_charge_time`, `base_blast_damage`, `base_cooldown`, `base_damage`, `fire_rate`; `hold_fire(delta)` / `release_fire()`; emits `charge_changed` / `charge_fired` up to Events
- `res://scenes/entities/projectiles/charge_blast.tscn` + script — single reusable screen-clearing `Area2D`
- `res://scenes/entities/mech.tscn` — `ChargeGlow` node visibility driven by charge state
- `res://tests/test_charge_formula.gd` — GUT tests for charge/blast/cooldown formulas

## Tasks & Subtasks
- [x] `res://scripts/entities/weapon.gd` — implement charge accumulation, release, cooldown per formulas
- [x] `res://scenes/entities/projectiles/charge_blast.tscn` + script — screen-clearing blast, one reused instance
- [x] `res://scenes/entities/mech.tscn` — ChargeGlow hookup
- [x] `res://tests/test_charge_formula.gd` — GUT tests for all three formulas
- [x] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
  - 2026-11-19: baseline_commit 74fa1692b5cf78a1e733224645e3a41f0f46a5b3 recorded; story resolved via `forge_get_task` description (`Story file: docs/stories/story-3-2-charge-shot.md`); implemented on taskBranch `feature/init/3-2-signature-move-charge-shot-hold-charge-release-cooldown-cmwm5q7n`.
  - No Godot binary in this container (`godot: command not found`, consistent with prior columns); headless `--check-only` + GUT execution is owned by the `godot-verify` column.
- **Completion Notes:**
  - `weapon.gd`: static formula helpers `compute_charge_level` / `compute_blast_damage` / `compute_cooldown`; `@export` `full_charge_time`, `base_blast_damage`, `base_cooldown`, `min_charge_level`; `hold_fire(delta)` keeps 3.1 continuous fire and additionally accumulates `hold_time`, updates `charge_level`, emits `charge_changed(level)` each tick — skipped while `cooldown_timer` runs (meter 0, no emission); `release_fire()` below `min_charge_level` fires a normal shot, at/above fires the single reusable `ChargeBlast`, sets `cooldown_timer = base_cooldown * (1 - 0.5*level)`, emits `charge_fired(level)`, resets `hold_time`/`charge_level` and emits `charge_changed(0.0)`; new signals `charge_changed` / `charge_fired` go up to the mech.
  - `charge_blast.gd` / `charge_blast.tscn`: single reusable `Area2D` (layer 4 / mask 2), `top_level` child of the weapon, `fire(pos, dmg, bounds)` covers the level bounds, deactivates after `blast_duration`; `area_entered` destroys regular enemies and deals exactly `blast_damage` to bosses (`is_boss` flag).
  - `mech.gd`: relays `weapon.charge_changed`/`charge_fired` to `Events.charge_changed`/`Events.charge_fired`, drives `Visual/ChargeGlow` visibility (`level > 0`), reads `shoot` or `charge_shot` (shared button), disconnects in `_exit_tree()`.
   - `tests/test_charge_formula.gd`: 9 GUT tests covering formula levels {0.0, 0.25, 0.5, 1.0}, clamp saturation, per-tick `charge_changed`, release below/at threshold, cooldown blocking, blast reuse, boss/regular damage, and mech glow + Events relay integration. `tests/test_weapon.gd` release test updated for the new below-threshold release shot.
   - 2026-11-19 godot-verify (task cmwm5q7nh002histvfj79bw9b, attempt 2): no `godot` binary in the container (deep `find / -xdev -iname 'godot*'` -> none); provisioned the official `Godot_v4.7.2-stable_linux.x86_64` headless binary (same 4.7.2 the human previously pointed at) -> `godot --version` = `4.7.2.stable.official.ed1daf0bf`. GUT v9.7.1 present at `addons/gut/gut_cmdln.gd`; 10 test scripts in `tests/`.
     - `godot --headless --import` -> exit 0; `godot --headless --quit` (main-scene smoke load) -> exit 0, no script errors.
     - Per-script `godot --headless --check-only -s res://...` over all 24 `scripts/**/*.gd` + `tests/**/*.gd`: no parse/syntax errors; only the known single-script-mode autoload noise (`Identifier not found: Events/GameManager`, autoloads register only in-project). In-project compile is authoritative and passed via the smoke load + GUT run.
     - `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`, attempt 1: 72/73 passed; `test_release_at_full_charge_fires_single_reusable_blast_and_starts_cooldown` (test_charge_formula.gd:141) failed `[0.0] expected [1.0]` — the test held only 60 ticks (1.0 s) after release, but the level-1.0 cooldown is `4.0 * (1 - 0.5*1.0) = 2.0 s`, so no correct implementation could resume charging; test arithmetic repaired to `_hold(180)` (120 ticks elapse the 2.0 s cooldown, 60 more saturate the 0.5 s charge), assertion `charge_level == 1.0` unchanged. Repair attempt 1 of max 3.
      - Attempt 2: GUT exit 0 — **73/73 tests passed, 408/408 asserts**, 0 failures (16 orphan warnings only, pre-existing across suites). Headless verification PASS.
- **Adversarial Code Review (bmgd-code-review, task cmwm5q7nh002histvfj79bw9b, 2026-11-19):**
   - Diff inspected: `git diff 74fa1692b5cf78a1e733224645e3a41f0f46a5b3..HEAD` on `feature/init/3-2-signature-move-charge-shot-hold-charge-release-cooldown-cmwm5q7n` — 9 files, +472/-13 (weapon.gd, mech.gd, charge_blast.gd/.tscn/.uid, test_charge_formula.gd/.uid, test_weapon.gd, this story).
   - Lens 1 (Physics & Frame Budget): PASS — all charge logic is delta-scaled inside the `_physics_process` path (`hold_time += delta`, `cooldown_timer -= delta` in weapon.gd:77-83; blast `_timer += delta` in charge_blast.gd:44-47); no per-frame allocations on the 60fps hot path; `charge_changed` emitted per tick with no array growth.
   - Lens 2 (Node Lifecycle & Memory): PASS — single reusable `ChargeBlast` instantiated once in `weapon._ready()` (weapon.gd:57-61), `top_level = true`, never freed mid-frame; tests use `queue_free()`; `@export`/`@onready` annotations correct (`mech.gd:14` matches `Visual/ChargeGlow` Sprite2D in mech.tscn:24); `_exit_tree()` disconnects all three weapon signals in mech.gd:33-38 and `area_entered` in charge_blast.gd:29-30.
   - Lens 3 (Signal Decoupling): PASS — Call Down (mech.gd:73-76 calls `weapon.hold_fire/release_fire`), Signal Up (weapon -> mech -> `Events` autoload, events.gd:8-9); `charge_shot` InputMap action shares Space/joypad button 0 with `shoot` (project.godot:56-67) per the hold-threshold AC; no `get_parent().get_parent()` chains (single-level `area.get_parent()` in charge_blast.gd:58).
   - Lens 4 (AC & GUT coverage): PASS — all 6 Given/When/Then ACs implemented and covered: clamp/accumulate/per-tick `charge_changed`/ChargeGlow (test_hold_fire..., test_mech_shows_charge_glow...), below-threshold normal shot vs single reusable blast + `charge_fired` + reset (test_release_below..., test_release_at_full_charge...), screen-clear vs boss formula damage (test_blast_destroys...), cooldown gating with meter 0 and no emission (test_cooldown_blocks...), formula levels {0.0, 0.25, 0.5, 1.0} (test_blast_damage_and_cooldown..., test_charge_level_formula...), headless parse + GUT (godot-verify: 73/73, 408/408 asserts).
   - Auto-patches applied: none — 0 defects found, 0 repair attempts used. No godot binary in this fresh review container; headless parse + GUT results from the `godot-verify` column (commits e8e777d, 6c541d8) cover exactly this diff and passed.
   - Verdict: APPROVED, `status: 'done'`.
