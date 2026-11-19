---
title: 'Weapon: Continuous Fire & Pooled Player Shots'
epic: '3'
story_key: '3.1'
forge_task_id: 'cmwm5ppl9002gistvndcu3iuw'
priority: 'HIGH'
story_points: 5
status: 'done'
engine: 'godot-4'
baseline_commit: 'bf1f986e25315871de51e828c0fca1457688e408'
---

# Story [3.1]: Weapon: Continuous Fire & Pooled Player Shots

## Intent & User Value
As a player, I want to hold the fire button and shoot a steady stream of projectiles toward the enemies on the right, so that the core shooter verb feels responsive and reliable.

## Acceptance Criteria
- Given `res://scripts/entities/weapon.gd` as a child `Weapon (Node2D)` of the mech with a `Muzzle (Marker2D)`, when `hold_fire(delta)` is called down from `mech._physics_process(delta)` while the `shoot` action is held, then a `player_shot` is spawned at the muzzle every `1 / fire_rate` seconds, traveling right.
- Given `res://scenes/entities/projectiles/player_shot.tscn` (an `Area2D`), when spawned, then it moves right at an `@export`ed speed inside `_physics_process(delta)` and is managed by `res://scripts/utils/object_pool.gd` (acquire/release, never `free()` mid-frame).
- Given a fired shot, when it is spawned, then `Events.shot_fired(muzzle_pos)` is emitted (signal up: Weapon -> Mech -> Events), and `AudioManager` can play the shot SFX (hook only; audio wiring lands in story 4.3).
- Given ~64 pooled projectiles, when more shots are fired than the pool holds, then the oldest/expired shots are released and reused instead of new instantiations (no per-frame `instantiate()` outside pools, per `docs/architecture.md` §6).
- Given a shot leaving the level bounds or hitting an enemy hitbox, when that happens, then the shot deals `base_damage * enemy_multiplier` and releases itself to the pool.
- Given `res://tests/test_weapon.gd`, when GUT runs, then fire-rate timing, muzzle emission, and pool reuse are verified.

## Godot Changes Plan
- `res://scripts/entities/weapon.gd` — `hold_fire(delta)` / `release_fire()`, fire-rate cooldown, muzzle spawn, `Events.shot_fired` relay
- `res://scenes/entities/projectiles/player_shot.tscn` + `res://scripts/entities/projectiles/player_shot.gd` — pooled `Area2D` projectile
- `res://scripts/entities/mech.gd` — reads `shoot` action in `_physics_process(delta)`, calls down `weapon.hold_fire(delta)`
- `res://tests/test_weapon.gd` — GUT tests for fire rate and pooling

## Tasks & Subtasks
- [x] `res://scenes/entities/projectiles/player_shot.tscn` + script — pooled projectile moving right
- [x] `res://scripts/entities/weapon.gd` — fire-rate logic, spawn at `Muzzle`, signal emission
- [x] `res://scripts/entities/mech.gd` — input reading + call down to weapon
- [x] `res://tests/test_weapon.gd` — GUT tests
- [x] Verify headless with `godot --headless --check-only` and run GUT

## Dev Agent Record
- **Review Record (bmgd-code-review, task cmwm5ppl9002gistvndcu3iuw):**
  - Diff inspected: `git diff bf1f986e25315871de51e828c0fca1457688e408..HEAD` on `feature/init/3-1-weapon-continuous-fire-pooled-player-shots-cmwm5ppl` (11 files, +386/-8): `weapon.gd`, `player_shot.gd`/`.tscn`, `mech.gd`/`.tscn`, `level_01.gd`, `test_weapon.gd`.
  - Lens 1 (physics & frame budget): PASS. All motion in `_physics_process(delta)` scaled by `delta` (`global_position += direction * speed * delta`); fire cooldown delta-scaled with remainder preserved (`_cooldown += 1.0 / fire_rate`); no per-frame allocations on the hot path; `instantiate()` only inside `ObjectPool`, capped at `pool_size` = 64 per `docs/architecture.md` §6.
  - Lens 2 (node lifecycle & memory): PASS after 1 auto-patch. No `free()` mid-frame anywhere; pool release reparents under `ShotPool` with `PROCESS_MODE_DISABLED`. Patch: `player_shot.release()` now sets `monitoring = false` so up to 64 parked shots stop participating in physics overlap queries; `weapon._fire()` re-releases the acquired node if `projectile_scene` ever yields a non-`PlayerShot` (previously leaked it outside the tree).
  - Lens 3 (signal decoupling): PASS. Call Down, Signal Up: `mech._physics_process` -> `weapon.hold_fire(delta)`; `weapon.shot_fired` -> `mech._on_weapon_shot_fired` -> `Events.shot_fired` (autoload, registered in `project.godot`); disconnects in `_exit_tree()` on both ends; `_on_area_entered` uses a single-level `area.get_parent()` guarded by `has_method("take_damage")` — no brittle multi-level chains.
  - Lens 4 (ACs & GUT): PASS. All 6 Given/When/Then ACs implemented and covered by `tests/test_weapon.gd` (11 tests: fire-rate timing 60/30 Hz with immediate first shot, muzzle spawn position, `shot_fired` -> Events relay via mech scene, rightward delta movement, out-of-bounds pool release, damage = `base_damage * enemy_multiplier`, pool-cap oldest-release reuse). godot-verify recorded 62/62 GUT tests green (332 asserts) on this diff.
  - Verification note: no `godot` binary in this review container, so patches were verified by static inspection only; `bmgd-merge` re-runs headless Godot checks. `repair_attempts`: 1 (within max 3). Patches are behavior-preserving for the green suite (no test asserts `monitoring`; the hit test emits `area_entered` manually, which works regardless of `monitoring`).
  - Status set to `done`.
- **Verify Record (godot-verify, task cmwm5ppl9002gistvndcu3iuw):**
  - Environment: no `godot` binary in the container. Human resume answer: Godot binary is 4.7.2 (`C:\dev\apps\godot\4.7.2` on the human's Windows host, not mounted in this Linux container); provisioned the official `Godot_v4.7.2-stable_linux.x86_64` headless binary instead (`godot --version` -> `4.7.2.stable.official.ed1daf0bf`). GUT 9.7.1 at `addons/gut/gut_cmdln.gd`; 9 test scripts in `tests/`.
  - `godot --headless --import` -> exit 0 (all `.tscn`/`.tres` parse and import cleanly).
  - `godot --headless --check-only -s <script>` for every `scripts/**/*.gd` and `tests/**/*.gd`: no parse/syntax errors (only expected autoload-resolution noise when compiling outside the project tree; `addons/gut/version_numbers.gd` standalone check fails in GUT's own `utils.gd` static initializer, a third-party artifact, not project code).
  - `godot --headless --quit-after 5` (main scene `res://scenes/main.tscn` smoke load) -> exit 0, no script errors.
  - GUT (`godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`): **62/62 tests passed, 332 asserts, exit 0.** Includes all 11 `test_weapon.gd` tests (fire-rate timing, muzzle spawn, `shot_fired` -> Events relay, rightward delta movement, out-of-bounds pool release, enemy-hit damage formula, pool-cap reuse, mech scene wiring).
  - `repair_attempts`: 2 (within the max-3 bound). Attempt 1: `test_weapon.gd:174` passed the message text as the 4th arg of `assert_signal_emitted_with_parameters`, which GUT 9.7.1 treats as the emission index (`String == int` engine error, params resolved to null). Attempt 2: removed the text arg and passed index `-1` explicitly -> parse-clean and green. No assertions were weakened; the implementation was correct, the test call signature was wrong.
  - Status set to `in-review`.
- **Debug Log:**
  - No Godot binary exists in the dev container (`godot: command not found`); headless syntax check + GUT run are delegated to the `godot-verify` board column, which owns that gate.
  - **godot-verify probe (task cmwm5ppl9002gistvndcu3iuw):** `godot --version` -> `/usr/bin/bash: line 1: godot: command not found` (exit 127); `which godot godot4` -> not found; exhaustive `find / -xdev -maxdepth 7 -type f -iname "godot*" -perm -u+x` -> no binary anywhere in the container. `addons/gut/gut_cmdln.gd`, `tests/` (incl. `test_weapon.gd`), and `project.godot` are present. Environment failure path: `forge_ask_human` called to decide static fallback vs. waiting for environment fix.
- **Completion Notes:**
  - `weapon.gd` (Weapon/Node2D): `hold_fire(delta)`/`release_fire()`, cooldown = `1/fire_rate` with immediate first shot, owns an `ObjectPool` child (`ShotPool`, cap `pool_size` = 64); when the cap is reached the oldest active shot is released and reused before `acquire()`.
  - `player_shot.gd` (PlayerShot/Area2D, layer 4 / mask 2): moves `direction * speed * delta` in `_physics_process`, releases to pool on `max_lifetime` expiry or leaving `level_bounds`, on `area_entered` deals `damage * enemy_multiplier` via `take_damage` and releases. Never `free()` mid-frame.
  - `mech.gd`: reads `shoot` in `_physics_process`, calls down `weapon.hold_fire(delta)` / `release_fire()`, relays `weapon.shot_fired` to `Events.shot_fired`; `set_bounds` pushes level bounds down to the weapon; `set_projectiles_container` (called by `level_01.gd`) provides the world-level Projectiles parent for active shots.
  - `tests/test_weapon.gd`: GUT coverage for fire-rate timing (60 Hz -> every tick, 30 Hz -> 31 shots/s incl. immediate first), muzzle spawn position, `shot_fired` signal + Events relay, rightward delta movement, out-of-bounds pool release, enemy-hit damage formula, and pool-cap reuse (4 unique instances over 10 fires).
