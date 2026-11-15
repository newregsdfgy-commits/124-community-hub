# 124 Visuals v1.5.5 — deep reliability audit

Date: 2026-11-15
Base: `v1.5.4-deep-audit-visibility-stability-test`, commit `c9708a34538b0882fdb4e10e33b6a1537a12139f`
Test branch: `v1.5.5-deep-audit-camera-music-reliability-test`. Main and all previous versions remain unchanged.

## Scope of this independent pass

Reviewed startup/key gate, event connection lifetime, generic + AIM-specific UI input,
profile persistence/restore, ESP scan/overlay lifecycle, FPS Booster snapshot/restore
and retry scheduling, Weapons/Recoil, local Player weather and aura, camera FOV,
Movement and local music. This is a **source audit**, not live Roblox testing.

## Two confirmed code-path defects corrected

1. **FOV external-ownership rollback:** `memoryFX.camera` previously recorded
the first camera FOV and unconditionally restored that stale value when toggled OFF,
even after a game animation/zoom had changed it. Introduced weak-key
`camera.written` ownership tracking. External camera FOV changes update the
restore baseline while the feature is ON. During OFF/Unload restore only the
last confirmed script-owned value. A post-write exception uses readback rather
than falsely claiming failure.
2. **Local Sound reused after external removal:** `privateMusic.play` reused an
existing Sound for the same ID without checking whether it was still parented
under SoundService. After Roblox destroyed or removed that instance, Play
could run on a dead/unparented instance. The code now discards and recreates it
if the parent or ID differs, disconnecting its previous listeners.

## Regression checks

- Source rebuilt from 12 fragments; exact Hub.lua / Visuals.lua aliases.
- Start.lua pinned to v1.5.5 branch; builder, release checker, active regression
  suites, GitHub workflow updated.
- Added OwnershipRecovery155.test.cjs structural regression assertions.
- Added build-ownership155-runtime.cjs: official Luau execution of actual
  Camera FOV and local music methods with deterministic Roblox service mocks.
- Camera scenarios: original restore, external change before OFF, external
  change while ON, camera replacement, rejected setter, mutating-then-throwing
  setter.
- Audio scenarios: normal play, same ID after external Sound removal,
  new ID, resume and cleanup.
- The previous v1.5.4 UI visibility guard and AIM targeting code are preserved.

## Limits

Automated compile/tests do not establish real Android hitbox behavior,
Roblox engine integration, FPS improvements, audio asset permissions or
compatibility across every game. Historical tests for removed v1.1.41 UI
remain archived and are excluded from modern CI. No server anti-cheat
bypass or remote authorization is implemented.

## Required real-client QA

Run v1.5.5 on desktop and Android. Check sound after respawn/reload/Stop,
FOV while in-game camera animation/zoom changes, native key screen,
rapid AIM toggles, ESP respawn, Booster restore, Player weather reset,
Movement on/off and whole-script unload. Capture Roblox Output before
considering a merge to main.

## CI status

**Verified CI SUCCESS** on source commit `5ed732196f982edcd23ef25e23715e13a6c7351f`:
- Release integrity: https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43716341918
- Extended regression: https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43716341929
- 145/145 Node tests, 0 failures; official Luau parser/bytecode compiler passed Hub, Visuals and Start; production Camera and Music fault-injection harnesses passed alongside preserved input/Weather/Player/ESP/Key/Booster/Movement runtime suites.
- **Not** a real-client or Android live test. No measured FPS or audio permission claims.
