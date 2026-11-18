---
title: 'ForgeAI Game Scroll Game Design Document'
engine: 'godot-4'
status: 'approved' # draft | approved
stepsCompleted: [1, 2, 3]
approved_by: user
---

# Game Design Document: ForgeAI Game Scroll

## 1. Game Overview
- **Genre:** 2D side-view mounted mech shooter (horizontal action shooter, single level)
- **Engine:** Godot 4.x, GDScript 4.x (static typing)
- **Camera perspective:** 2D side-view; `Camera2D` follows the mech horizontally with smoothing, vertical position fixed to the level midline, `limit_*` bounds clamped to the level edges
- **Dominant player emotion:** power fantasy — overwhelming firepower, explosions, score payoff
- **Core Loop:** `Strafe the mech (heavy, deliberate movement) to dodge enemy fire -> hold fire to shoot down incoming waves -> charge and release a screen-clearing heavy blast at big threats -> explosions, score, and feedback -> next, harder wave arrives -> level ends after the final wave`
- **Win condition:** survive and clear the final (Nth) enemy wave
- **Lose condition:** the mech's hull integrity reaches 0 (game over)
- **Structure:** exactly one level; challenge comes from escalating enemy waves across the level's length, kept replayable

## 2. Mechanics & Systems
### Primary Mechanics
- **Movement / strafe (core verb, user-selected emphasis):** the mech moves in 2D (horizontal + vertical) inside the level bounds. Feel is **heavy / floaty**: high effective mass, slow acceleration ramp, long deceleration lag after input release, strong downward gravity when airborne. All motion is physics-based in `_physics_process(delta)` at 60 Hz; parameters exposed via `@export` (max speed, acceleration, deceleration, gravity, strafe bounds).
- **Aim & shoot (genre baseline):** continuous fire while the fire button is held; projectiles travel toward the right (enemy side).
- **Signature move — Charge shot:** hold fire to charge (charge meter fills 0->100% over a hold time); release to fire a screen-clearing heavy blast that destroys all regular enemies and heavy damage to bosses. After release, a cooldown must elapse before charging again. The cooldown decision is the mastery layer of the loop.
- **InputMap actions:** `move_left`, `move_right`, `move_up`, `move_down` (8-way strafe, keyboard + gamepad left stick), `shoot` (hold), `charge_shot` (hold/release; can share the `shoot` button with hold-threshold), `pause` (Esc / Start).

### Game Systems
- **Health / damage:** the mech has Hull Integrity (HP, e.g. 100). Enemy bullets and contact deal damage (`damage = base_damage * enemy_multiplier`). No healing baseline; optional wave-clear repair pickup (design hook for later). Hull at 0 -> Game Over state.
- **Charge shot formula:** `charge_level = clamp(hold_time / full_charge_time, 0, 1)`; blast damage scales with `charge_level` (`blast_damage = base_blast * (0.5 + 0.5 * charge_level)`); minimum charge fires a normal shot. `cooldown = base_cooldown * (1 - 0.5 * charge_level)`.
- **Score:** per-kill score (`kill_score = enemy_base_score * wave_multiplier`), wave-clear bonus, charge-shot multi-kill bonus. Score is display-only (no fail state tied to it).
- **Wave / progression system:** waves spawn sequentially along the level length; each wave `n` has `wave_multiplier = 1 + 0.25 * (n - 1)` scaling enemy HP, count, and fire rate. Clearing wave `n` triggers wave `n+1` after a short breather. Clearing the final wave -> Victory state.
- **Game state manager:** `Title -> Gameplay -> (Pause <-> Gameplay) -> Game Over | Victory`. Coordinated through the `EventBus` Autoload (call down, signal up).

## 3. World & Level Design
- **Scene flow:**
  - `res://scenes/main.tscn` — root, holds Autoloads (EventBus, GameState) and the active scene
  - `res://scenes/menus/title.tscn`, `res://scenes/menus/pause_menu.tscn`, `res://scenes/menus/game_over.tscn`, `res://scenes/menus/victory.tscn`
  - `res://scenes/levels/level_01.tscn` — the single level: parallax background layers, level bounds, wave spawn markers along the length
  - `res://scenes/entities/mech.tscn` — player mech (CharacterBody2D, `mech.gd`)
  - `res://scenes/entities/enemies/` — wave enemy scenes (e.g. `drone.tscn`, `gunship.tscn`, `boss.tscn`)
  - `res://scenes/entities/projectiles/` — player shots, charge blast, enemy bullets
- **Camera behavior:** one `Camera2D` child of the mech (or level-follow rig); `position_smoothing_enabled = true`, horizontal follow only, `limit_left/limit_right/limit_top/limit_bottom` set from level bounds; zoom tuned for 1920x1080 base resolution.

## 4. Art & Audio Direction
- **Visual style:** stylized 2D mech/industrial — bold silhouettes, chunky explosions with screen shake on charge-shot release, hit-flash on enemies, visible charge glow on the mech's weapon while charging. Mobile renderer, 60 FPS locked (16.6 ms frame budget, physics in `_physics_process`).
- **Screen resolution & aspect ratio:** base 1920x1080, stretch mode `canvas_items`, stretch aspect `expand` (per `docs/project-context.md`).
- **Audio layers:** BGM (driving, escalates with wave number), SFX (shot, hit, explosion, charge-up loop, charge blast, mech footsteps/stomp, UI), ambience (level hum). All routed through an Audio Autoload bus.

## 5. Development Epics Breakdown
- **Epic 1:** Mech Controller & Movement Physics — heavy/floaty strafe, gravity, level bounds, `Camera2D` follow
- **Epic 2:** Wave System & Level Flow — level_01 scene, escalating wave spawner, win (final wave cleared) / lose (hull 0) conditions, game state manager
- **Epic 3:** Combat — weapon fire, charge shot (hold/charge/release/cooldown), enemy types & AI, projectiles, damage & score formulas
- **Epic 4:** Polish, UI & Audio — HUD (hull, charge meter, wave counter, score), menus (Title/Pause/Game Over/Victory), BGM/SFX, screen shake and feedback
