---
title: 'AudioManager: BGM Bus & Pooled SFX'
epic: '4'
story_key: '4.3'
forge_task_id: 'cmwm5ts3n002uistva0asgo5k'
priority: 'MEDIUM'
story_points: 5
status: 'ready-for-dev'
engine: 'godot-4'
baseline_commit: ''
---

# Story [4.3]: AudioManager: BGM Bus & Pooled SFX

## Intent & User Value
As a player, I want driving background music that escalates with the wave number plus punchy sound effects for shots, hits, explosions, and the charge blast, so that combat feels powerful.

## Acceptance Criteria
- Given `res://scripts/globals/audio_manager.gd`, when the autoload loads, then it creates/uses a dedicated BGM bus and a pool of `AudioStreamPlayer` SFX players (shot, hit, explosion, charge-up loop, charge blast, mech stomp, UI) on the SFX bus.
- Given gameplay events, when `Events.shot_fired`, `Events.player_hit`, `Events.enemy_destroyed`, `Events.charge_changed`, `Events.charge_fired`, `Events.wave_started`, `Events.victory`, or `Events.game_over` fire, then AudioManager (connected in `_ready`, disconnected in `_exit_tree`) plays the matching SFX from the pool — no per-event `instantiate()` churn.
- Given the charge loop, when `charge_changed(level)` rises above 0, then the loop player starts and its pitch/volume follows `level`; at release/cooldown it stops.
- Given `Events.wave_started(n)`, when emitted, then BGM intensity escalates with `n` (e.g. switches/intensity parameter of the BGM stream).
- Given `res://tests/test_audio_manager.gd`, when GUT runs (headless, no actual audio output required), then event->SFX mapping calls the right pooled player methods.

## Godot Changes Plan
- `res://scripts/globals/audio_manager.gd` — BGM player on its own bus, pooled SFX players, `Events` bindings, charge-loop control
- `res://audio/bgm/`, `res://audio/sfx/` — placeholder audio resource slots
- `res://tests/test_audio_manager.gd` — GUT tests for event mapping

## Tasks & Subtasks
- [ ] `res://scripts/globals/audio_manager.gd` — buses, pools, event bindings
- [ ] Charge-up loop tied to `charge_changed`
- [ ] BGM escalation on `wave_started`
- [ ] `res://tests/test_audio_manager.gd` — GUT tests
- [ ] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Debug Log:**
- **Completion Notes:**
