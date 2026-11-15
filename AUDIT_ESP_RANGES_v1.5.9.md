# 124 Visuals v1.5.9 — Editable ESP visibility distance per element

Date: 2026-11-15
Base: v1.5.8 `cf6722be1561db3790ba6462fb81626f1681d18e`
Feature/test branch: `v1.5.9-esp-independent-range-controls-test`

## User request

Allow changing **independent maximum display distances** for health bars,
distance badges, nicknames and similar ESP visuals, instead of hardcoding
HP/distance at 90m and names at 155m. Preserve Compact ESP quality, toggles,
overall ESP radius, performance budgets and all other features.

## Changes to application

Five new controls under ESP > ДАЛЬНОСТЬ ЭЛЕМЕНТОВ:

| Control | Saved CUSTOM key | Default | Range | Purpose |
|---|---|---:|---:|---|
| Дальность ника | `espNameMaxMeters` | 155m | 10–1000m, 5m steps | Name badge visibility |
| Дальность HP | `espHealthMaxMeters` | 90m | 10–1000m, 5m steps | Health number and proportional bar |
| Дальность расстояния | `espDistanceMaxMeters` | 90m | 10–1000m, 5m steps | Distance badge visibility |
| Дальность 2D Box | `espBoxMaxMeters` | 1000m | 10–1000m, 5m steps | Corner frame visibility |
| Дальность линий | `espTracerMaxMeters` | 1000m | 10–1000m, 5m steps | Screen-to-target tracers |

All retain the original independent ON/OFF toggles. Effective display range
is always `min(state.espRangeMeters, elementMaxMeters)`; increasing an element's
distance never searches new targets beyond the master ESP range.

Defaults match the previous v1.5.8 behavior (global radius 200m,
labels 90/155m; Box and Tracer follow global limit). Previous JSON profiles
missing new keys inherit these defaults via state snapshot. All five keys
participate in validatedSettings, saved CUSTOM profiles and normal
requestSave debounce. No new RenderStepped/Heartbeat loops.

When crossing a label threshold, updatePlayer's compact visibility mask
invalidates the far-label throttling cache. Box and tracer radius calculations
apply in the existing bounded visual refresh loops and hide cached
elements when the player goes outside the selected overlay range.

## Verification

- Bundle/launcher/release checker updated to v1.5.9.
- `tests/EspRanges159.test.cjs`: verifies source wiring, five sliders,
  persistence, independent label visibility and overlay caps.
- `tests/build-esp159-runtime.cjs` extracts the **actual production** Luau
  compact selector, saved setting validator and overlay effective-radius
  expressions; runs edge thresholds, independent sliders, malformed values,
  10/1000m clamps and overall radius cap.
- v1.5.7 compact ESP and v1.5.8 performance/Movement suites retained.
- **Verified CI success** on code commit `b99d9ec0bc141fdb9a35988fc0f8fb2adfa7444d`:
  - Release integrity: [run 43726646008](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43726646008), SUCCESS.
  - Full v1.5.9 regression: [run 43726646036](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43726646036), SUCCESS.
  - 166/166 Node tests, zero failures. Luau parser + compiled bytecode passed Hub, Visuals and Start.
  - Source-extracted Luau tests passed independent Nick/HP/Distance thresholds,
    stored profile numeric validation including invalid input, and global
    Box/Tracer caps; historical runtime harnesses also passed.
  - Real Roblox/Android visual rendering and measured FPS not tested.

## Remaining live-client checks

Check desktop, Android and crowded servers. Move the nickname slider from
155 to 300m while overall ESP >=300m, independently set HP to 100m and
distance to 200m, verify thresholds on moving targets, change Box and
Tracer ranges, disable labels individually, test respawn and relaunch with
saved CUSTOM settings. No client/Android screenshots or FPS profiling
have been performed by automated checks.
