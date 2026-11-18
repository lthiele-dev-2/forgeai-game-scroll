---
status: approved
step: 1 of 2
approved_by: user
---

# Project Context — ForgeAI Game Scroll

## Platform & Performance

- **Target platform**: PC only (Windows/macOS/Linux). Web, Mobile, and Console builds are out of scope.
- **Frame rate**: 60 FPS locked. Frame budget: 16.6 ms per frame.
- **Physics tick**: 60 Hz, handled in `_physics_process(delta)`.

## Renderer

- **Renderer**: Mobile — chosen for broad PC GPU compatibility and stable 60 FPS on mid-range hardware.

## Viewport & Scaling

- **Base resolution**: 1920x1080 — the viewport is designed around this resolution.
- **Stretch mode**: `canvas_items`
- **Stretch aspect**: `expand` — handles different window sizes and aspect ratios by expanding the viewport.

## Language & Conventions

- **Language**: GDScript 4.x with static typing.
- **Paths**: always use `res://` paths.
- **Exports**: use `@export` for inspector-exposed variables, `@onready` for node references.
- **Memory**: free nodes with `queue_free()`.
- **Architecture**: call-down / signal-up communication, coordinated through a central EventBus.
