# 124 Visuals v1.5.7 — Compact ESP screenshot-driven fix

Date: 2026-11-15
Base: v1.5.6 `b752f64fff2aa74334eeb9625d791bf7baca8fc7`
Branch: `v1.5.7-compact-esp-ui-test`

## User report

Attached screenshot showed 176x49 ESP name/health/distance badges blocking
the middle of the screen, compounded by very wide text chips and long
tracer/corner segments. This release changes the actual implementation
in the repository, NOT a manual patch instruction.

## Appearance changed

- Original v1.5.6 billboard: **176x49 px**. Compact: **116x29 px**
  (~34% narrower and 41% shorter).
- Identity chip height: 25 -> 16; HP/distance chips: 21 -> 11.
  Text near 11 px; meta 9 px. HP label displays current numeric health
  without the long `HP 100/100` string, retaining the proportional HP strip.
- Slightly more transparent badge backgrounds/borders and reduced
  head offset from 2.65 to 1.95 studs.
- Distant text density changes by real player-relative range:
    - 0–90 m: name, HP and distance, respecting each independent toggle.
    - >90–155 m: name only when its toggle is ON.
    - >155 m: no Billboard label, but existing Highlight and optional
      corner Box/Tracer continue via their own toggles and range rules.
  Any normal ESP range up to 1000m remains configurable. No player is
  removed from target tracking by the new text presentation thresholds.
- New distance visibility mask is included in change detection to
  avoid stale hidden/visible labels when crossing 90/155m, including
  alongside the old text-refresh throttle.
- Highlight fill/outline 0.97 / 0.36; tracer alpha 0.74, 1px width.
  Corner lengths capped at 10px. Eight segments are still reused.

## Preserved systems

Master ESP, Team/Enemy filters, Names/Health/Distance toggles, Colors
TEAM/GOLD/GREEN/WHITE, full 1000m radius, box / tracer toggles, caching,
respawn + streaming, performance guards, cleanup, AIM/Weapons, Camera,
Music, Weather/Player, Booster and Key System. No added RenderStepped loop.

## Verification

- `Hub.lua` and `Visuals.lua` regenerated from all 12 source pieces;
  loader pinned to v1.5.7.
- `EspCompact157.test.cjs` verifies UI bounds, thresholds,
  independent controls and preserved scan/cleanup functionality.
- `build-esp157-runtime.cjs` extracts and runs the production
  compact-distance selector in official Luau with 0, 61, 90, 91, 120,
  155, 156, 294 and 1000m input and multiple toggle states.
- Existing v1.5.6 corner geometry runtime and cross-feature regressions
  retained. **Verified GitHub Actions success** on code commit `745c30132709980e796e08113512e73dfc679e24`:
  - Release integrity: [run #43719232823](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43719232823).
  - Complete CI: [run #43719232660](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43719232660).
  - 156/156 Node tests, 0 failures. Official Luau parser and binary
    compilation succeeded for Hub.lua, Visuals.lua and Start.lua.
  - Production Luau compact ESP 0/61/90/91/155/156/294/1000m visibility
    fault injection and retained v1.5.6 corner-box runtime passed.
  - Full live Roblox UI, Android layout and measured FPS remain untested.

## Known limitations

This repository is not attached to a live Roblox or Android session.
Automated tests establish code-path behavior and compilation, not
screenshot-perfect layout or measured FPS. Visual readability still needs
real-game confirmation. The threshold sizes are defaults, not user-facing
sliders; original per-feature toggles remain operative.

## Live QA checklist

At 61m verify name and tiny HP/distance badges. At 120m verify name-only,
at 294m no billboard, but optional outline/corners. Toggle Name/HP/Distance
separately; check TEAM/GOLD/GREEN/WHITE, R6/R15, Player respawn, Android,
camera motion, low-FPS guard, and full unload.
