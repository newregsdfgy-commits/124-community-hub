# 124 Visuals v1.5.6 — Modern Tactical ESP (visual-only redesign)

Base: `v1.5.5-deep-audit-camera-music-reliability-test` @ `0edb58df06767dc8c88b490d9fa759e421a27d9c`
Test branch: `v1.5.6-modern-esp-visual-redesign-test`

## Requested scope

Replace the old ESP *appearance*, not its functions or target tracking. Preserve
ESP master, player roster/distance checks, team/enemy filtering, respawn support,
performance throttles, toggles for Name/Health/Distance/2D Box/Tracer, all four
color presets and user profile persistence. No AIM, weapons, Booster, movement,
key or persistence logic was modified.

## Rendering changes

- Rebuilt each ESP BillboardGui as a compact translucent dark identity badge
  with a team/preset-colored border and thin team rail.
- Separate HP badge with a real proportional green-to-red 2px health strip.
- Separate distance badge; either meta badge expands to full width if its
  sibling toggle is OFF. Name-only and meta-only layouts stay compact.
- Kept the existing per-player Highlight but reduced fill to 0.94 and refined
  outline to 0.24 rather than covering much of the character.
- 2D Box now uses **eight short corner segments** instead of four complete box
  edges. Existing Box toggle and line-thickness setting drive the new renderer.
- Existing top-origin tracers retained, now a subtler, 2px line.
- No new RenderStepped/Heartbeat connections, external assets or networking.
  Bounded new-line allocation increased from 8 to 12 per pass for the eight
  segments; the previous ECO/QUALITY, shape and FPS guard limits remain.

## Compatibility and verification

- Twelve ordered source fragments, exact `Hub.lua` / `Visuals.lua` bundle.
- Launcher, version checker and current CI suite pinned to v1.5.6 test branch.
- `tests/EspModern156.test.cjs` validates preservation of feature toggles,
  new badge objects, visibility and camera/respan lifetime hooks.
- `tests/build-esp156-runtime.cjs` extracts actual production
  `drawCornerBox` and exercises it in official Luau with 8-segment geometry,
  color/width, reversed Y and tiny projected-height guards.
- Baseline v1.5.5 CI passed 145 Node tests; new CI status to be confirmed.
- Eight box segments may cost more than four edges. This is bounded but real
  client FPS/visibility must be checked, especially on Android/low FPS.

## Manual Roblox QA still necessary

Toggle only Name / only HP / only Distance; toggle Box and tracer separately;
switch TEAM/GOLD/GREEN/WHITE, team membership, high player counts and FPS guard;
check local/remote respawn with streaming, fast camera movement, body scaling,
screen rotation, mobile controls, cleanup/relaunch and Roblox Output.

## CI

**Verified CI success on code commit `9b23e7e59f1de20b2dd5c9a6751025ec44c10392`**
- Release integrity: [run #43717367794](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43717367794) — SUCCESS.
- Extended ESP and system regression: [run #43717367789](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43717367789) — SUCCESS.
- 150/150 Node tests; 0 failures.
- Official Luau parser/bytecode compilation of Hub.lua, Visuals.lua and Start.lua.
- New production corner-box fault injection in Luau passed eight segments, team color/thickness, camera point inversion, and short geometry hiding.
- Preserved existing AIM, UI, Weather, Player, Booster, Key, Movement and music runtime harnesses all passed.
- Actual Roblox engine visual fidelity, Android UI and FPS were not tested.
