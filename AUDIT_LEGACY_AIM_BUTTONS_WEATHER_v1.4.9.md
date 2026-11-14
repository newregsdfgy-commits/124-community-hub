# 124 Visuals v1.4.9 — Legacy AIM, Buttons and Weather

Base: v1.4.8 (last audited branch). The `main` branch remains unchanged.
Test branch: `v1.4.9-legacy-aim-controls-weather-fix-test`.

## 1. AIM reverted to v1.4.6

The entire AIM implementation in `src/04_lighting_and_booster.lua` is restored **byte-for-byte** from the original v1.4.6 source, original Git blob SHA `c67cbdfb6139adce856b7758bf821ddf03449a68`.

This restores v1.4.6 target lock, LOS checks, prediction and camera-smoothness behavior, including its original `Smoothness = 0` instantaneous mode. The experimental v1.4.7/v1.4.8 `aimStability`, `aimDeadzonePixels`, extra target-confirmation logic and camera-local steering are removed from source, configuration and UI. Prior Speed/Noclip/Fly, Booster, ESP and Player FX stability fixes are retained.

AIM still requires an equipped valid `Tool`; the `Only registered weapons` filter remains ON by default, including safe automatic profile loading. If no weapon was registered, an ON button cannot steer. New UI feedback explicitly explains that the player needs to equip/register a Tool or turn the filter OFF. This does not silently bypass an explicitly enabled filter.

## 2. GUI click/tap lifecycle

Previous `safeActivate()` relied indefinitely on a `pressNumber` advanced by each button's `InputBegan`, but some Roblox event routes emit a later `Activated` or `MouseButton1Click` with **no new `InputBegan` on the specific button**. Once `consumedPress == pressNumber`, every subsequent input was discarded. This directly explains how a toggle can appear permanently unresponsive after the first click.

The new handler:
- Still deduplicates `Activated` + legacy click callbacks for the same press.
- Always accepts a distinct physical `InputBegan` immediately.
- Allows a new fallback-only click after a short 140 ms duplicate window, even if Roblox did not deliver another `InputBegan`.
- Respects touch drag suppression and reuses the shared toggle error handler, rather than bypassing UI state.

## 3. Player Weather fallback

Previous `syncWeather()` directly raised an error if writing a game's `Atmosphere` or `Lighting.Fog*` was denied. The generic toggle then rolled the user action back to OFF, making the switch seem broken.

The new `syncWeather()` isolates world-property writes in a protected block. On refusal:
- It retains the user-selected weather mode and applies the owned local ColorCorrectionEffect and, for RAIN, the local rain overlay.
- It sets `playerFX.weatherFallback=true` and reports a fallback in the interface/Player diagnostics.
- It tries to undo any partial Fog/Atmosphere writes using preexisting owned snapshots and preserves pending snapshots if restoration fails.
- On OFF it removes owned tone/rain even if world-property rollback is pending; the existing maintenance worker retries pending Fog/Atmosphere restoration.

Fallback ColorCorrection **does not reproduce true distance fog** and cannot override a game that intentionally prohibits visual post-processing. This is a local rendering limitation, not a claim that a protected Atmosphere can be forced.

## 4. Automated verification

- `tests/build-controls144-runtime.py` now tests missing `InputBegan` after a consumed press ID.
- `tests/build-buttons149-runtime.cjs` extracts production `safeActivate`, `setAimEnabled`, `addToggle`, Aimbot and Weather callbacks into executable Luau mocks. Cases include click dedup, fast distinct presses, later fallback-only press, touch, Weather ON/OFF and a failed ColorCorrection constructor.
- `tests/build-player140-runtime.py` tests Fog and Atmosphere setters that mutate and then throw; fallback stays enabled and partial writes are restored.
- `tests/build-legacy-aim149-runtime.cjs` extracts the original v1.4.6 target selection, R6/R15 part filters, prediction cap, LOS grace and eight-candidate LOS cap.
- Node release regressions assert the exact original AIM source Git hash.
- The dedicated `v149-legacy-aim-buttons-ci.yml` also builds the official Luau parser/runtime and runs preserved ESP, Booster, Key, Player and Movement integration tests.

**Important:** these tests run the production source with deterministic Roblox API fakes, not a live Roblox client. For real confirmation, test the click hitboxes and actual weather rendering on PC and Android after restarting the client. Check Player FX diagnostics for `Fallback=true` and `Error=...` if the full Atmosphere effect cannot be applied.
