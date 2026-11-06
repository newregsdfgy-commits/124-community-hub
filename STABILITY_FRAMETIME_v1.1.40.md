# 124 Visuals v1.1.40 — targeted stability and frametime hotfix

Test branch `v1.1.40-stability-frametime-test` based on v1.1.39 LITE.
The older v1.1.39 and `main` remain untouched.

## Changes
1. New ESP menu: labels, health and distance toggles enqueue the shared
   coalesced roster refresh; enabling tracer drawing waits for the existing
   rate-limited visual callback, while turning it off clears lines immediately.
2. Periodic roster loop checks lastScanAt so it skips a full scan if an
   event-triggered scan just ran. Explicit OFF cleanup is still permitted.
3. Booster CharacterAdded / StreamingEnabled no longer traverse
   accessory-heavy characters when no graphics snapshots exist.
   When restoration is needed, one worker deduplicates characters and
   slices each tree into at most 16 descendants or a low-FPS time slice.
   Unexpected errors unlock the queue, leaving snapshots for retry.
4. Cleanup marks scripts inactive, cancels outstanding work, unbinds render
   and event connections and releases GUI **before** potentially yielding
   on graphics rollback. Operations are protected independently via pcall.
   Graphics, Terrain, camera and pose snapshots stay retryable across reloads.
5. Spam Chat, CFG, Skeleton ESP and Bunny Hop remain absent; CUSTOM settings
   persistence and existing ESP, AIM, Box, Booster, FOV GUI remain available.

## Verification
- Official Luau parser and compiler on `Visuals.lua`, `Hub.lua`,
  `Start.lua`; byte-identical script aliases
- All retained Node regression tests and new source invariants
- Existing Luau fault injections for GUI initialization, deferred Box
  instances and graphics snapshot restoration
- New **executable Luau lifecycle harness** extracting production functions
  to validate no idle Booster tree work, bounded single-worker queue,
  duplicate-character suppression and recovery after forced failures.
- New cleanup fault injection verifies that event/render hooks and GUI
  are released even when recoil, camera, session diagnostics, player
  watchers or graphics rollback fail.

## Limitations
Only static and mocked Luau/runtime tests run in GitHub Actions. No target
Roblox device frametime metrics have been collected; microfreezes can also
originate in game scripts, streaming assets, networking or GPU drivers.
Do not merge to `main` without client smoke tests and rollback verification.

Recommended smoke test: launch on a populated server, toggle labels and
Box repeatedly, enable/disable Booster, respawn during streaming,
close/reopen UI 3 times, and compare p99 frametime / 1%-low FPS to v1.1.39.
