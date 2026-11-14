# 124 Visuals v1.5.0 — Aimbot Button Click Recovery

Base: v1.4.9 `c44fba2c42b00525fd17eb935d7a5cd36df13c41`.
Production `main` is unchanged.

## Actual changes

The AIM algorithm, camera movement, prediction, LOS and target selection remain **byte-identical to v1.4.6**. `src/04_lighting_and_booster.lua` Git blob: `c67cbdfb6139adce856b7758bf821ddf03449a68`.

Only the AIM input control path was refactored in `src/08_ui_controls.lua`:

- A full-width active transparent `AimFullRowHitSurface` TextButton (`ZIndex=25`) sits above the original decorated toggle row, covering its text and switch visuals.
- The surface listens to `Activated` and `MouseButton1Click`. The original row's `Activated` remains an independent fallback.
- `UserInputService.InputBegan` + `InputEnded` on the full row provide a direct source-level fallback when neither GuiButton event fires.
- Every physical press gets a serial token. The same press cannot activate twice even when multiple event paths fire. Distinct rapid presses remain independent.
- If a legacy callback has no input identity, it is associated with an old press for at most 140 ms, not indefinitely or for a half-second. A fresh click can work even without a new `InputBegan`.
- The global fallback requires the AIM tab to be visible, GUI enabled, pointer release inside the row, and no drag longer than 12 pixels. `PlayerGui:GetGuiObjectsAtPosition` checks that the topmost GUI belongs to the AIM row, so it does not click through another modal.
- An input diagnostic counter is available via AIM > **Управление**: successful presses, source, surface activations, fallback releases, blocked hits, and last error.

No generic controls, weather fallback, ESP, Player FX, Booster, weapons, key gate or Movement code changed.

## Verification

- GitHub Actions `43650409111`: **completed / success** on commit `63171ed2643d93ec6f4329ee58e198af61458d9e`.
- Both production bundles match the 12 ordered source modules and each other.
- Release integrity: **80/80 checks**.
- Node regression tests: **130/130 passed**.
- Official Luau parser and binary compiler: **passed** for both bundles and `Start.lua`.
- Executable production-source Luau harness: **passed**, including AIM click release without `Activated`, mouse/touch, fast separate presses, repeated legacy-only clicks, one-click deduplication, UI-modal protection, drag suppression, hidden-page prevention, old targeting/LOS behavior and Weather callbacks.
- Previous UI, ESP, Player FX, Terrain, Booster, Key and Movement tests remain green.

## Honest limitation

No live Roblox client or Android input device was available to click the real UI. Thus the above is a tested source-code correction, **not proof that the button now works in every Roblox client/executor combination**. When testing in Roblox, fully restart the client and use the pinned v1.5.0 `Start.lua` rather than reusing an older loaded bundle. If the AIM toggle still does not respond, collect **Управление > AIM button** diagnostics plus a screenshot of the visible toggle and its surrounding UI; the counters distinguish an unreached hitbox from a callback that received the click but left its state unchanged.
