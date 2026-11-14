# 124 Visuals — v1.4.4 controls, weather, aura and UI stability audit

Audit date: 2026-11-14.
Base: `v1.4.3-booster-stability-test`.
Working branch: `v1.4.4-controls-player-ui-fix-test`; **`main` unchanged**.

## Reported reproduction symptoms
- Player tab: weather buttons seemed to do nothing.
- Player: visible aura too weak even at increased intensity.
- Aim: button sometimes did not engage the toggle despite working keyboard hotkey.
- Main window: inconsistent responsiveness and disappearing controls, especially after scrolling/resizing.

## Source-confirmed findings and changes

| ID | Severity | v1.4.3 source defect | v1.4.4 fix |
|---|---|---|---|
| UI-144-01 | **High** | `applyResponsiveLayout()` ran before the entire UI module created widgets. The later `columnFor()` ignored the already-selected `singleColumn` state. New controls assigned to the right section stayed in `info.right` even when the right column was hidden | Store `info.singleColumn` during layout and route new widgets to `info.left` while single-column is selected; original side retained for next wide-layout resize |
| UI-144-02 | **Medium** | Global `suppressTapUntil` was extended by any `ScrollingFrame.CanvasPosition` change, including inertial scrolling after the finger was released | Classify each Touch InputObject as a tap or drag, retain the classification through Activated, and remove blanket CanvasPosition suppression |
| AIM-144-01 | **Medium** | Aimbot row registered `Activated` through `safeActivate` AND a separate `MouseButton1Click`. Its own 0.12s debounce could still allow a delayed duplicate action that flips AIM ON then OFF | One central `safeActivate` for switches and buttons with shared 0.38s duplicate latch; `MouseButton1Click` is fallback for clients that omit Activated |
| WEATHER-144-01 | **Medium** | The master weather toggle was enabled with `state.playerWeatherMode == "CLEAR"` by default, resulting in no visible change. Clicking RAIN/FOG/NIGHT while master OFF also did nothing | First ON from CLEAR selects FOG; selecting FOG/RAIN/NIGHT directly enables local weather; selecting CLEAR immediately disables/restores it |
| WEATHER-144-02 | **Low** | Choice widgets had no central refresh registry, so programmatically changed weather choice/profile could show a stale selected button | Registered `refreshChoices[key]` and repaint choices on profile load / master weather toggle |
| AURA-144-01 | **Medium** | Aura particles were only 0.14–0.27 studs, about 25 per second at default intensity and visually hard to see near body | Increased to 24 + 10×intensity (54/sec default, 74/sec max), broadened particles and lifetime, improved transparency and emission |
| AURA-144-02 | **Medium** | Aura alone lacked a body contour; the Highlight was only created under independent Glow mode | Shared Highlight now appears for either Aura or Glow; Glow remains independently responsible for PointLight, avoiding a duplicate Highlight |
| UI-144-03 | **Low** | Programmatic refreshes from profiles updated toggles/sliders but not choice state | New `refreshChoices` refresh pass in `applySettings`; no auto-enabling effects on profile load |

## Preserved systems
- 12 compile-time source fragments, Hub.lua and Visuals.lua exact byte-identical.
- FPS Booster v1.4.3 fix for boolean false rollback, Terrain restore and Atmosphere handoff unchanged.
- ESP 2.0, Weapons 2.0, Key 2.0, profiles, Purple Neon UI, Memory diagnostics and cleanup remain.
- New effects are local only. Aura particle increase can add workload on low-end devices; measure it in Roblox before declaring a performance improvement.
- Aimbot enabled state is independent of the configured "Только отмеченное оружие" filter, which can still block targeting if no real Tool has been registered.

## Verified automated validation
- **GitHub Actions run #43588549310:** https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43588549310 — full success.
- `python3 tools/build_visuals.py --check`: exact 12-source compilation to both bundles.
- `python3 tools/verify_release.py`: **80/80 release integrity checks passed**.
- All preserved and new Node tests: **106/106 passed**.
- Official Luau parser and binary compiler: Hub.lua, Visuals.lua, Start.lua passed.
- `tests/build-controls144-runtime.py`: executed extracted production `allowTap`, `safeActivate`, `columnFor`, weather master-toggle and preset-choice callbacks. Simulated simultaneous Activated+MouseButton1Click, click-only fallback, true touch after scroll, touch drag rejection, hidden initial column, weather AUTO-ON, CLEAR/OFF and error rollback.
- `tests/build-player140-runtime.py`: executed real Player FX callbacks and checked increased aura particle rate, outline with Glow OFF, respawn, rain, external Atmosphere/Fog baseline and shutdown.
- Existing actual Luau callback suites for Booster/Terrain, Atmosphere handoff, ESP, Key and screenshot viewport dimensions passed.

## Still unverified outside CI
No Roblox Studio/play client, executor, live game screenshot or Android GPU/FPS test was performed here. Automatic assertions and isolated engine stand-ins cannot prove every click is delivered in Roblox or that particles render identically on all graphics settings. For a live check:
1. Start a new Roblox session, load only v1.4.4 and open Player at both desktop and mobile/landscape dimensions.
2. Click RAIN directly without enabling the main weather toggle first; verify rain overlay and local tint, then CLEAR and confirm restoration. Repeat FOG and NIGHT.
3. Turn Aura on without Glow; verify particles and outline after local respawn. Compare particle load and FPS on the target device.
4. Click Aimbot once on desktop and tap once on Android; verify ON state stays ON rather than double toggling. If targeting itself is inactive, inspect `Только отмеченное оружие` and whether the equipped Tool has been registered.
5. Resize while on Player/Memory, scroll and tap immediately on a control, switch tabs and return. No items should be stranded in the hidden right column.
6. Repeat FPS Booster BALANCED/WHITE/ULTRA and OFF, preserving prior rollback and UI functionality.
7. Capture Output errors and actual before/after FPS/frametime if issues recur.

Do not merge `main` automatically. Test release only until live QA confirms.
