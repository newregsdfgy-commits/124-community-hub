# v1.1.28 — New full audit: long-session lifecycle and memory

Base: `v1.1.27-full-lifecycle-audit-test`. Old branches and `main` unchanged.

## Verified new findings
1. `watchPlayer` previously stored every new `CharacterAdded` subscription in global `connections`, leaving its disconnected/old-player connection entries alive until all of Visuals is unloaded. `protectedNames` also retained the name of a user who had already left. This is a long-session memory growth path, even though Roblox may automatically disconnect some signals.
2. Every new `Workspace.CurrentCamera` previously called `connect(camera:GetPropertyChangedSignal("ViewportSize"), ...)` and put an otherwise disconnected listener into the global registry. Camera switches could increase that registry monotonically before a full Unload.

## Fixes
- Separate `boosterPro.playerConnections` table holds at most one CharacterAdded connection for each currently watched player.
- The PlayerRemoving event disconnects that connection, releases its Player key, and removes the player's name from the protected-name set.
- Both partial initialization cleanup and ordinary Unload disconnect any remaining character handlers.
- Camera ViewportSize connection is now owned directly by `boosterPro.layoutCameraConnection` instead of the global connections registry. It is disconnected on camera replacement, partial boot failure, and normal Unload.
- All FPS Booster graphic settings, traversal budgets, queue and rollback logic, permission-aware chat, AIM and ESP behavior retained.

## Scope and remaining risks
CI compiles `Visuals.lua`, `Hub.lua`, `Start.lua` and runs source-based regressions. These tests do not simulate Roblox Engine or executor events. Actual long-session heap trends, rapid player join/leave, repeated camera replacement, GUI resizing and clean hot reload still require an in-game test. ScreenGui and FPS Booster stutter should be checked with the same settings before/after.
