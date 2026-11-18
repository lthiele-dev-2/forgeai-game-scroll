---
title: 'ForgeAI Game Scroll Game Architecture'
engine: 'godot-4'
status: 'draft'
stepsCompleted: [1, 2]
---

# Technical Game Architecture: ForgeAI Game Scroll

## 1. Engine & Configuration
- **Godot Version:** 4.x
- **Language:** GDScript 4.x with static typing throughout
- **Renderer:** Mobile (broad PC GPU compatibility, stable 60 FPS on mid-range hardware)
- **Window & Display:**
  - Base resolution: 1920x1080
  - Stretch mode: `canvas_items`
  - Stretch aspect: `expand`
- **Frame budget:** 60 FPS locked, 16.6 ms per frame
- **Physics tick:** 60 Hz, all physics logic in `_physics_process(delta)`
- **Paths:** always `res://`; never hardcode filesystem paths
- **Naming:** files/dirs/functions/variables `snake_case`; classes `PascalCase` via `class_name`; constants `SCREAMING_SNAKE_CASE`; signals past-tense `snake_case`
- **Annotations:** `@export` for inspector-exposed values, `@onready` for node references
- **Memory:** remove nodes with `queue_free()`, never `free()` mid-frame

## 2. Autoload Singletons (`res://scripts/globals/`)
Registered in `project.godot` `[autoload]`, present before the main scene loads:
- `Events` — `res://scripts/globals/events.gd` — global EventBus, the only cross-scene broadcast channel
- `GameManager` — `res://scripts/globals/game_manager.gd` — state machine: `TITLE -> GAMEPLAY -> (PAUSE <-> GAMEPLAY) -> GAME_OVER | VICTORY`
- `AudioManager` — `res://scripts/globals/audio_manager.gd` — BGM on its own bus plus pooled SFX players (shot, hit, explosion, charge loop, blast, UI)

## 3. Scene Tree & Node Hierarchy (`res://scenes/`)

### 3.1 Root — `res://scenes/main.tscn`
```
Main (Node)
├── World (Node2D)          # container for the active level instance
└── UI (CanvasLayer)
    ├── HUD (Control)       # res://scenes/ui/hud.tscn
    └── MenuLayer (Control) # res://scenes/menus/*.tscn, one visible at a time
```

### 3.2 Level — `res://scenes/levels/level_01.tscn`
```
Level01 (Node2D)
├── ParallaxBackground
│   ├── ParallaxLayer (far)
│   ├── ParallaxLayer (mid)
│   └── ParallaxLayer (near)
├── Bounds (StaticBody2D)   # level-edge collision; defines strafe + camera limits
├── WaveSpawner (Node2D)    # wave_spawner.gd; Marker2D spawn points along the level length
├── Entities (Node2D)       # mech + spawned enemies
└── Projectiles (Node2D)    # pooled shots / blasts / enemy bullets
```

### 3.3 Player — `res://scenes/entities/mech.tscn`
```
Mech (CharacterBody2D)     # mech.gd; heavy/floaty strafe, gravity, bounds clamp
├── CollisionShape2D
├── Visual (Node2D)
│   ├── AnimatedSprite2D
│   └── ChargeGlow          # visible while the charge shot is held
├── Weapon (Node2D)         # weapon.gd; owns fire / charge / cooldown
│   └── Muzzle (Marker2D)
├── Hitbox (Area2D)         # damage intake, emits upward on hit
└── Camera2D                # position_smoothing_enabled, limit_* from level bounds, horizontal follow only
```

### 3.4 Enemies — `res://scenes/entities/enemies/`
One scene per type (`drone.tscn`, `gunship.tscn`, `boss.tscn`), each a `CharacterBody2D` running a shared `enemy.gd` base script (composition over deep inheritance; boss adds a phase state-machine child):
```
Drone (CharacterBody2D)
├── CollisionShape2D
├── Sprite2D
├── Hitbox (Area2D)
└── Weapon (Node2D) + Muzzle (Marker2D)   # per-type fire pattern
```

### 3.5 Projectiles — `res://scenes/entities/projectiles/`
`player_shot.tscn`, `charge_blast.tscn` (single reusable screen-clear instance), `enemy_bullet.tscn` — all `Area2D`, all pool-managed.

### 3.6 UI — `res://scenes/ui/hud.tscn` and `res://scenes/menus/`
```
HUD (Control)
├── HullBar (ProgressBar)
├── ChargeMeter (ProgressBar)
├── WaveLabel (Label)
└── ScoreLabel (Label)
```
Menus: `title.tscn`, `pause_menu.tscn`, `game_over.tscn`, `victory.tscn` — each a `Control` whose buttons call down into `GameManager`.

## 4. Signal Architecture — Call Down, Signal Up
- **Call down:** parents invoke child methods (`wave_spawner.spawn_wave(n)`, `weapon.hold_fire(delta)`, `game_manager.change_state(...)`).
- **Signal up:** children notify parents via signals; anything cross-scene goes through the `Events` autoload only.
- No child reaches across the tree with `get_node()`; no mutable state outside the Autoloads.

### 4.1 `Events.gd` signal catalog
```
signal game_state_changed(new_state: int)
signal hull_changed(current: int, maximum: int)
signal player_died()
signal player_hit(damage: int, pos: Vector2)
signal shot_fired(muzzle_pos: Vector2)
signal charge_changed(level: float)          # 0..1 while held
signal charge_fired(level: float)
signal enemy_spawned(enemy_type: String)
signal enemy_destroyed(enemy_type: String, pos: Vector2, score_value: int)
signal wave_started(n: int)
signal wave_cleared(n: int)
signal score_changed(new_score: int)
signal victory()
signal game_over()
```

### 4.2 Flow examples
- `Mech._physics_process(delta)` reads InputMap actions (`move_left/right/up/down`, `shoot`, `charge_shot`, `pause`), integrates velocity with `delta`, calls `move_and_slide()`, clamps to level bounds; emits `Events.charge_changed` while charging.
- `Weapon` (child of Mech) is called down (`hold_fire(delta)` / `release_fire()`); it emits `shot_fired` up, Mech relays to `Events`.
- Enemy `Hitbox.area_entered` -> `take_damage()` -> on death emits `Events.enemy_destroyed(...)` then `queue_free()`.
- `WaveSpawner` counts alive enemies; at zero emits `Events.wave_cleared(n)`; `GameManager` listens and starts wave `n+1` or emits `victory()`.
- HUD binds to `Events.hull_changed`, `charge_changed`, `wave_started`, `score_changed`; it never polls gameplay nodes.
- **Lifecycle:** every dynamically spawned node is removed with `queue_free()`; Autoload connections are disconnected in `_exit_tree()`; pools reuse instances instead of instantiate/free churn.

## 5. Data-Driven Configuration (scale-adaptive)
- Wave and enemy stats live in `.tres` resources under `res://resources/` (`wave_01.tres` … `wave_n.tres`, `enemy_stats.tres`): enemy types, counts, spawn interval, HP/fire-rate multipliers, score values. Adding a wave means adding a resource, not code.
- `wave_multiplier = 1 + 0.25 * (n - 1)` computed by `WaveSpawner` from the wave resource.
- Mech tuning via `@export` on `mech.gd`: `max_speed`, `acceleration`, `deceleration`, `gravity`, strafe bounds. Weapon tuning via `@export` on `weapon.gd`: `base_damage`, `fire_rate`, `full_charge_time`, `base_blast_damage`, `base_cooldown`.
- Charge formula (per GDD): `charge_level = clamp(hold_time / full_charge_time, 0, 1)`; `blast_damage = base_blast * (0.5 + 0.5 * charge_level)`; `cooldown = base_cooldown * (1 - 0.5 * charge_level)`.

## 6. Performance Budgets (60 FPS hot path)
- **Frame:** 60 FPS locked, 16.6 ms; frame-critical work in `_physics_process(delta)`, UI/animation in `_process(delta)`
- **Draw calls:** < 200 per frame (few large parallax sprites, batched layers)
- **Physics:** 60 Hz tick; caps of ~24 concurrent enemies and ~64 pooled projectiles on screen
- **Pooling:** projectiles and regular enemies from `res://scripts/utils/object_pool.gd`; charge blast is one reused instance
- **Particles:** capped `CPUParticles2D` amounts; explosion effects pooled
- **Screen shake:** Camera2D `offset` decay in `_process`, no node churn
- **Memory:** `queue_free()` for all transient nodes; no per-frame `instantiate()` outside pools

## 7. Verification Hooks
- GUT tests under `res://tests/` covering movement math, the charge formula, wave multiplier, and damage/score formulas
- Headless verification pipeline: Godot `--headless` syntax check plus GUT runner (board `godot-verify` column)
