# 124 Visuals v1.2.1 — Purple Neon UI 2.0 QA

Date: 2026-11-11  
Baseline: `v1.2.0-stability-performance-test`  
Test branch: `v1.2.1-purple-neon-ui-2-test`  
Version in both Lua files: `1.2.1`.

## Implemented

1. **Purple Neon 2.0:** deeper graphite-purple palette, stronger active navigation border, low-cost static gradients. New subtitle `PURPLE NEON 2.0 • v1.2.1`.
2. **Readable mobile layouts:** compact panel up to 610 px wide on landscape phones, 460 px on portrait; compact sidebar dynamically 68/78/94 px. Full 950×520 wide layout only on touch viewports with safe size ≥960×540 px and sufficient aspect ratio; avoids shrinking small controls on common phones.
3. **Tap targets:** window minimize/close hit areas increased to 42×42 px. Navigation tabs remain ≥44 px high in compact layouts and use a scrollable sidebar if the viewport is too short. Scrollable content and footer positions are retained.
4. **UI controls:** switches get stronger active strokes. Before starting a new 0.14-second tween, the previous knob tween is cancelled, preventing an obsolete animation after fast taps. Programmatic refresh is immediate.
5. **Sliders:** drag area increased from 25 to 32 px and outer card from 74 to 83 px. Layout recalculation cancels an in-progress drag, avoiding stale track coordinates on device rotation.
6. **Read-only on-device diagnostics:** Memory → `Проверка адаптации UI 2.0` examines actual panel/content/nav sizes, all four navigation buttons, minimum hit heights and the active page. No new RenderStepped loops or polling.
7. **Verification:** `tools/verify_release.py` updated with new UI-specific assertions and 18 viewport cases; GitHub Actions branch filter expanded to versioned branches (`v*`).

## Invariants

- `Hub.lua` and `Visuals.lua` are identical, git blob SHA: `12a1222eb5e3d2e7236205a5010630ac110a9a37`.
- `Start.lua` SHA: `1a69cc6b314309fe27b491bd55966839036dfe98`. Points to this branch, requires version 1.2.1 and the original key gate.
- The entire source between `local state = {` and `local function initializeHubUI()` is byte-identical to the v1.2.0 baseline.
- The entire tail starting at `end -- initializeHubUI; isolates UI locals` is byte-identical to the v1.2.0 baseline.
- Number of runtime render bindings, task.spawn calls, toggles and slider definitions did not increase. Only one new Memory UI diagnostic button was added.
- Key System `124HUB`, AIM, ESP, No Recoil, No Spread, FPS Booster, Fly, movement, music, profile saving and cleanup logic were preserved.

## Executed checks

**46/46 source assertions and deterministic layout-scenario checks passed**, including **18/18 simulated viewports**. These are static source checks and a mathematical model, not screenshots or a live Roblox run.

| Viewport | Expected mode | Panel size (px) | Nav scrolling |
|---|---|---:|---|
| 873×393 Android landscape | Compact | 610×347 | No |
| 640×360 Android landscape | Compact | 610×314 | Yes |
| 480×260 Android very short | Compact | 458×214 | Yes |
| 393×873 Android portrait | Compact | 371×610 | No |
| 320×568 narrow portrait | Compact | 298×522 | No |
| 280×500 tiny portrait | Compact | 258×454 | No |
| 1280×800 Android tablet | Wide | 950×520 | No |
| 800×1280 Android portrait tablet | Compact | 460×610 | No |
| 1366×768 desktop | Wide | 950×520 | No |
| 700×500 desktop | Compact | 460×462 | No |
| 490×340 very small desktop | Compact | 458×302 | Yes |
| 960×540 Android | Compact | 610×494 | No |
| 1024×600 Android | Wide | 950×520 | No |
| 1000×580 Android | Wide | 950×520 | No |
| 760×520 Android | Compact | 610×474 | No |
| 360×720 Android | Compact | 338×610 | No |
| 1920×1080 desktop | Wide | 950×520 | No |
| 393×873 simulated post-rotation | Compact | 371×610 | No |

The complete Lua source (~8,593 lines) passed a limited lexical/bracket/block scan during preparation (zero structural findings). The scanner is **not a Luau compiler**.

## Not performed / remaining QA

- No live Roblox Studio/Delta/Xeno rendering or input test was available.
- No actual Android screenshots, touch keyboard, drag, rotation, scroll, FPS or memory measurements.
- GitHub workflow file is present, but GitHub connector returned no finished workflow/check runs for the latest commit. CI pass is **not** claimed.
- An extremely short screen may have very little visible content, although the page and navigation scroll. On screens narrower than ~280 px, longer labels will truncate; functionality should be verified visually.
- The key remains plaintext in client Lua and is not a secure server license.

## Device smoke-test matrix

1. Launch from `Start.lua`, enter `124HUB`, check main header and Purple Neon glow.
2. On the phone in landscape, tap ESP → Aim → Misc → Memory, then scroll each page.
3. Click `Проверка адаптации UI 2.0` in Memory and inspect Output; 7/7 is expected only if actual Roblox UI sizes meet checks.
4. Rapidly toggle an option twice, ensure knob ends in the actual state.
5. Drag a slider, rotate the device mid-drag and verify the gesture is cancelled rather than writing an unexpected value.
6. Minimize, restore, drag menu and repeat on portrait, landscape and a short viewport.
7. Test AIM, ESP, No Recoil, No Spread, FPS Booster and Safety Stop once to check unexpected regressions.

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/newregsdfgy-commits/124-community-hub/v1.2.1-purple-neon-ui-2-test/Start.lua"))()
```

Access key: `124HUB`.

**Status: saved test build. No claim of perfect runtime stability without device testing.**
