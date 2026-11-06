# 124 Visuals v1.1.37 — UI:INITIALIZATION hotfix

## User-reported startup failure (2026-11-07)

In v1.1.36, the new screenshot-reference slider implementation contains:
```luau
local function update()
    if not container.Parent then return end
```
However, `container` is not declared in that slider factory. The actual
Slider's GUI hit area is named `area` (and is a child of the supplied
`parent`). Running the initial `update()` in `makeSlider` throws
`attempt to index nil with 'Parent'`, aborting `initializeHubUI`.
Original report: line 5664, `makeSlider` -> `buildReferenceMenu`.

## The fix

Replace the stale variable with `area.Parent`. No gameplay behavior,
ESP algorithms, UI geometry, saved profiles, feature flags, or animation
timings are altered. Both `Visuals.lua` and `Hub.lua` are byte-identical.
`Start.lua` points specifically at this test branch and verifies v1.1.37.

## Regression prevention

- New source-contract tests verify both slider call sites, declared hit-area,
  correct guard, and canonical launcher/Hub parity.
- **New actual Luau runtime test** extracts the production `makeSlider`
  implementation and executes it using UI-instance/event mocks. Verifies:
  first slider creation and initial paint, mouse pointer click and drag
  with commit on release, vertical-scroll immunity for touch, tap-to-set,
  second FOV slider creation, and external refresh.
- Existing integration/static and fault-injection tests retained.
- This is still not an in-game Roblox end-to-end UI test. Validate loading
  in the target client before merging to `main`.

Rollback: prior `v1.1.35-reference-right-sidebar` is unchanged.
