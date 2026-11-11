# 124 Visuals v1.1.65 — Purple Neon UI implementation and audit

Date: 2026-11-11  
Baseline: `v1.1.64-lifecycle-key-race-audit-test` (loader hotfix, v1.1.63 core)  
Test branch: `v1.1.65-purple-neon-ui-test`

## Implemented

- **Purple Neon visual identity:** deeper charcoal/violet palette, luminous static accent (no full-screen blur or new render loops), header title `124 VISUALS` and `PURPLE NEON • v1.1.65`.
- **Header overlap fixed:** left navigation is anchored below the 76-pixel header. This removes overlap with the hub's brand/header text. On wide layouts, current page title/subtitle is visible.
- **Left-hand navigation:** ESP → Aim → Misc → Memory; hidden existing Overview/Dashboard feature remains reachable through its original code. Selected tab has purple background, underline, stroke, and bold font.
- **Compact switches:** 34×18-pixel control aligned right in each toggle card. A 0.14-second ease-out knob transition is applied on a real click only; programmatic state refreshes remain instantaneous, and TweenService failure falls back to direct assignment.
- **Mobile responsiveness:** screens with effective width under 340 pixels get a 78-pixel sidebar instead of 92 pixels. Page positions, content panel, and footer use the same `contentX` calculation, preventing drift.
- **Small landscape devices:** only touch viewports of at least 760×350 use the 950×520 scaled layout; smaller touch viewports use the readable compact layout.
- **Very short screens:** the left navigation container is a `ScrollingFrame` with automatic Y canvas sizing. Scrolling is included in the pre-existing touch-gesture/tap-suppression logic.
- **All original gameplay controllers preserved:** no changes to core AIM, ESP, No Recoil/Spread, Booster, Fly, movement, music, user configuration, or key verification. Core source between `local state` and `initializeHubUI` is identical to baseline.
- `Hub.lua` and `Visuals.lua` are byte-for-byte equivalent. Loader `Start.lua` is updated to fetch the exact new branch and verify version 1.1.65 while retaining its guard against concurrent loader invocation.

## Final static verification

- **69/69 targeted assertions passed:** 13 files/integrity, 14 visuals, 14 navigation, 14 control interactions, 14 regression checks.
- **Source structure scan:** 8,391 Lua lines, 39,331 lexical tokens, no unmatched brackets, short/long strings, comments or begin/end blocks.
- **Layout calculations:** 7/7 simulated screen scenarios passed (Android 873×393 landscape, 640×360 small landscape, 480×260 very short landscape, 393×873 portrait, 320×568 narrow portrait, desktop 1366×768 wide, desktop 700×500 compact). Scrolling is expected on the 480×260 scenario and fits navigation.
- No additional `RunService:BindToRenderStep`, `task.spawn`, or expensive per-frame GUI effects. Numbers of toggle, slider, and button factories and startup/cleanup handlers match the baseline.
- Latest Git blob: `Hub.lua` / `Visuals.lua` `8d5de300e14b8cd4ec18fd4d3598346ed5ea838d`. `Start.lua`: `3daa4572d7a130a8b9dc9d8d383df580695af8dc`.

## Limitations and manual QA

**Not performed:** real Luau compiler check, Roblox Studio/gameplay execution, Delta/Xeno UI touch test, screenshots of the actual rendered GUI, device FPS measurements. A static source audit cannot guarantee a perfect appearance or reliable execution on every screen.

Suggested real-device QA:
1. Enter `124HUB` via keyboard and mobile on-screen button; close and re-open.
2. ESP, Aim, Misc, Memory navigation with taps and narrow-screen scrolling.
3. Toggle twice quickly; ensure knob matches stored state and function action.
4. Rotate Android landscape ↔ portrait. Make sure header remains readable and page widgets are all reachable.
5. Drag window, minimize, use floating restore button, hotkey RightShift, and Safety Stop.
6. Check source game's actual ESP/AIM and booster states. These modules have been retained, not independently rewritten or certified.

**Security:** the key is checked locally and exists in client Lua, so it is not a secure licensing system. Existing unresolved direct-load concurrency issues in core remain out of scope for this UI-only revision.

## Installation

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/newregsdfgy-commits/124-community-hub/v1.1.65-purple-neon-ui-test/Start.lua"))()
```

Key: `124HUB`.
