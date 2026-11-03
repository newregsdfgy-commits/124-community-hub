# 124 Community Visuals — Independent full-code audit v1.1.30

**Source:** GitHub repository `newregsdfgy-commits/124-community-hub`, based on successful v1.1.29 test branch. `main` unchanged. The deployed entrypoints `Visuals.lua` and `Hub.lua` must be identical; `Start.lua` must load this branch. The previous source consists of approximately 6,200 lines of Luau plus 82 mostly static JS regression tests.

## High-priority confirmed issues addressed

1. **ESP partial-construction orphan (moderate-high):** `createRender()` only set `renderData[player]` after all Highlight/Billboard/TextLabels had been created. If a later constructor/assignment threw, the per-player protected caller's `deleteRender()` had no tracked objects to clean. The new version registers Highlight immediately and Billboard before child labels. Failure now leaves tracked instances that the caller can destroy.
2. **ESP sparse-list cleanup (moderate):** `deleteRender()` used `ipairs({item.highlight, item.billboard, item.tracer})`. With missing first/second entries this could stop iteration early, leaking remaining instances. The new version iterates fixed field names and checks the instance directly.
3. **ESP character fallback type confusion (low/moderate):** A non-BasePart named Head previously prevented fallback to a valid Torso/Root. A shared type-safe helper now checks candidates before choosing an anchor. This does not fabricate positions for completely unreplicated characters.
4. **Repeated event-triggered full scans (moderate performance risk):** Character.DescendantAdded/Removing used 60ms batching, allowing a pathological churn of approximately 16 full candidate sorts/s. A configurable 180ms minimum scan interval now works with the existing coalesced event flag; normal periodic refresh stays 0.25/0.35/0.55s for QUALITY/BALANCED/ECO.
5. **Player watcher connection failure (moderate):** A failed :Connect on a player could abort `refreshESP` early and prevent all other players from updating. The new watcher initialization is protected; partial connections are disconnected and a throttled warning is recorded. Respawn watcher binding also isolates errors.
6. **Uncaught executor compile exception (moderate startup):** `Start.lua` previously called `loadstring(source)` without pcall; some loaders throw instead of returning nil,error. The new diagnostic launcher catches both failure modes and reports stage COMPILE.
7. **Uncaught GUI action error (low):** `safeActivate` now uses pcall and reports errors rather than propagating them in the input signal callback.

## Other audited modules — source-level status

- **ESP range:** the user-selectable radius is calculated from the local player's position (200m means ~714 Roblox studs with StudMeters=.28); `BillboardGui.MaxDistance=0` avoids camera-relative clipping. `EspFarDistanceMeters=150` only changes font size. An explicit 8–96 player cap (64 default) is separate from distance. Missing streamed-out character position cannot be reconstructed.
- **ESP shape overlays:** 2D Box and Skeleton have separate 10/18/32 shape budgets by tier; a highlight or name label may work while these optional overlays are absent. Higher target budgets can add render cost.
- **Performance/FPS Booster:** the engine may incur expensive graphics recompilation from large numbers of property writes; CPU timing in Lua does not account for all engine/GPU work. The initial scan and bounded Streaming FIFO logic, revision-cancelled jobs, saved original properties and mode restoration are unchanged. The FPS auto rollback is intentional when sustained FPS is at least 30% and 12 FPS below baseline after the scan.
- **AIM/Recoil:** existing render priority bindings and feature switches retained. No in-engine aim accuracy verification performed.
- **GUI/Touch:** existing five tabs, responsive layout, touch-slider guards and minimize/unload callbacks preserved. New safe activation error reporting.
- **Profiles:** saved keys are bounded/validated; ESP max targets remains persisted, dangerous features do not auto-activate after cold boot.
- **Chat:** `CanUserChatAsync` is checked before manual `TextChannel.SendAsync`. In a previous user-provided audit it was false; code does not attempt to invoke unknown custom-game remotes or bypass chat restrictions.
- **Lifecycle:** cleanup disconnects player and camera connections, cancels render subscriptions, tears down GUI and attempts rollback; source tests cover these paths. The server/client engine and Xeno/Delta runtime have not been exercised.

## Remaining limitations and next field tests

CI tests and official Luau parser/compiler catch source and contract regressions but are **not gameplay tests**. Test ESP 140/160/190/205m and missing Head/Root after respawn, rapidly joining players, 15+ targets near the radius, AUTO/ECO/QUALITY, GUI open/close and Unload/reload. Compare Booster OFF/BALANCED/WHITE with frame-time and 1% low readouts under the same camera and map scene.

Mutable GitHub branch URLs are not cryptographically pinned; users should inspect the exact commit for high-assurance provenance. Performance changes are not guaranteed to increase FPS. Prior v1.1.29 branch and main are unchanged.
