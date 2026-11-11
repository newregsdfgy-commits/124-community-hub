# 124 Visuals v1.1.66 — Deep Audit and Corrective Changes

Date: **2026-11-11**  
Baseline: `v1.1.65-purple-neon-ui-test`  
Candidate branch: `v1.1.66-deep-audit-race-spread-test`  
Core mirror: `Hub.lua` = `Visuals.lua`, SHA `82ec22bee0ef88fe3a0bba6ad0214f92e5633ce9`  
Boot loader: `Start.lua`, SHA `acd99220683700cc10e4d91b5859bbcec3188ad4`

## 1. Reproduced from code and fixed

### K-05: Parallel startup race during key entry (major lifecycle issue)
Previously, two copies of the Lua core shared `ARMY124_BOOT_PHASE` and `ARMY124_BOOT_ERROR` without an instance identity. A second launch destroys the first launch's `Army124AccessGate`; the first coroutine then wakes from `response.Event:Wait()` and could overwrite the second launch's phase with `key_denied`. It was also possible for an older error/ready completion to be mistaken for the current launch's result.

**Fix:** every invocation creates a unique table token in `CONFIG.BootToken` and publishes it to `env.ARMY124_BOOT_TOKEN`. After potentially yielding cleanup, recovery, key entry and UI initialization the old invocation checks ownership and exits without changing another launch's status. The final Lua result returns that token. `Start.lua` accepts a boot result only if its returned token matches the environment's token and then checks `ready`/key-denial normally. The pre-existing Start.lua mutex is retained.

Scope: guarantees ownership only within an executor environment sharing the same `getgenv()`/fallback `_G`. Two unrelated executor environments or an intentionally patched source are not secured.

### K-06: Previous error window above the next key window
The `Army124StartupError` ScreenGui has `DisplayOrder=10000`, higher than the key gate's 9999. On direct Lua reload, older errors could remain visible above the key dialog until a fully successful launch.

**Fix:** remove the previous error display at the beginning of main startup (in addition to Start.lua's earlier cleanup), and do not generate stale errors from non-owning invocations.

### S-05: Parameters added to an already equipped Tool are missed
The original spread candidate index was built once upon Tool equip and upon `DescendantAdded`. A pre-existing instance acquiring a matching attribute later, or an existing NumberValue renamed to a recognized spread name, could remain absent from that index indefinitely.

**Fix:** while No Spread is enabled, periodically discover newly matching candidates from the equipped Tool every three seconds. Following `GetDescendants()`, inspect at most 48 candidates per `controller.applySpread()` call, retaining a rolling index to avoid full attribute scanning in one frame. Dynamic `Value` and `AttributeChanged` watchers, queue coalescing, generation invalidation, saved-original restoration and complete Tool cleanup remain in place. No extra RenderStepped handlers added.

Note: `GetDescendants()` itself still allocates a list and can have a small cost on unusually large Tool hierarchies. No Spread still does not affect server-authoritative bullet trajectories or ModuleScript-local internals.

## 2. Audited areas

| Subsystem | Inspected |
|---|---|
| Bootstrap & Key | Download/size/version checks, compiler/runtime error handling, cancellation, UI cleanup, double startup, token ownership |
| Purple Neon UI | Brand/header, left navigation, ScrollingFrame, touch tap vs swipe, clickable right-aligned switches, responsive geometry |
| AIM | Input/key/touch controls, Tool guard, camera steering, scan pacing, LOS and cleanup |
| ESP | Player/character listeners, distance limit, screen overlays, streaming in/out, scan and rendering budgets |
| No Recoil | Tool events, physical mouse/touch/gamepad input, watchdogs, camera correction and shutdown |
| No Spread | Value/Attribute observers, object removal, indexed candidates, new discovery, original snapshots, retry |
| FPS Booster | Profile switch revisions, chunked scene scans, avatar protection, recovery and snapshot restoration |
| Lighting/Terrain | Owned-property restore and independent backoff/retry loop; no redundant new retry worker |
| Additional modules | Local music, flight, movement, saved preferences, HUD, diagnostics and Safety Stop |

## 3. Verification performed

- **135 / 135 targeted static assertions passed:** 119 source presence/invariant checks across Boot (14), Key (12), Spread (23), No Recoil/AIM (13), ESP (11), Booster (13), Purple Neon UI (20), Cleanup & profiles (13) plus 16 consistency/branch checks.
- Full `Hub.lua` lexical/balanced-structure scan before write: **8,442 lines / 39,577 parsed structural tokens**, zero unmatched blocks, quotes, long comments or brackets. This is a scanner, **not** a full Luau compiler.
- `Hub.lua` and `Visuals.lua` verified identical after GitHub writes (same content SHA).
- `Start.lua` points to this branch and verifies `Version = "1.1.66"` and the unchanged local `124HUB` key block.
- Diff from v1.1.65 before report addition: only Hub.lua, Visuals.lua and Start.lua modified. The `initializeHubUI()` body is byte-identical to v1.1.65.
- No additional `RunService:BindToRenderStep` calls, `task.spawn(function()` workers, or toggle/slider/button builders.
- Additional mathematical viewport tests on **12** screen configurations passed expected boundary/spacing checks, including a very short mobile landscape case that scrolls the left sidebar. These do not verify actual Roblox rendering.
- Official Roblox UI references consulted for `TextBox.ReturnPressedFromOnScreenKeyboard`, `GuiButton.Activated`, and `ScrollingFrame.AutomaticCanvasSize`:
  - https://create.roblox.com/docs/reference/engine/classes/TextBox
  - https://create.roblox.com/docs/reference/engine/classes/GuiButton
  - https://create.roblox.com/docs/ui/scrolling-frames

## 4. Not verified — required live QA

1. Real Luau compiler passes; no `luau-analyze`/Roblox runtime available in the current environment.
2. Roblox/Delta/Xeno launch, actual GUI rendering, orientation changes, mobile soft keyboard interaction and return key.
3. Simultaneous **direct** source launches and odd executor-specific global environment behavior.
4. No Spread with multiple actual weapons, dynamically attached attributes, auto-fire, reload and rapid Tool switches.
5. No Recoil on single and auto weapons, including actual camera ownership conflicts with the game.
6. ESP at high range, with StreamingEnabled and large servers.
7. FPS Booster profiles WHITE/ULTRA/BALANCED/OFF, real RAM/FPS metrics and full graphics/Terrain/Lighting restore after repeated switches.
8. Save/load, key cancellation, Safe Stop and fault recovery on an Android device.

## 5. Known boundaries

- This is a **client-local** key prompt; literal `124HUB` is visible in downloaded source. Old URLs or source modifications can bypass it. Secure licensing would require a separately deployed and managed server.
- Game server state, remote spread logic and certain game-specific weapon frameworks are outside this client's authority.
- Inability to run Roblox and measure a real session prevents any claim of absolute stability, FPS improvements or “zero bugs.”

## Launch test build

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/newregsdfgy-commits/124-community-hub/v1.1.66-deep-audit-race-spread-test/Start.lua"))()
```

Key: `124HUB`.

**Status:** Source audited and fixes saved in isolated test branch. Do not merge into stable/main before on-device smoke testing.
