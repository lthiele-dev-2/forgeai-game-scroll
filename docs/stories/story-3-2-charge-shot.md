---
title: 'Signature Move: Charge Shot (Hold / Charge / Release / Cooldown)'
epic: '3'
story_key: '3.2'
forge_task_id: ''
priority: 'HIGH'
story_points: 8
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
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
- [ ] `res://scripts/entities/weapon.gd` — implement charge accumulation, release, cooldown per formulas
- [ ] `res://scenes/entities/projectiles/charge_blast.tscn` + script — screen-clearing blast, one reused instance
- [ ] `res://scenes/entities/mech.tscn` — ChargeGlow hookup
- [ ] `res://tests/test_charge_formula.gd` — GUT tests for all three formulas
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
