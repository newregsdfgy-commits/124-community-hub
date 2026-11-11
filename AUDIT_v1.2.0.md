# 124 Visuals v1.2.0 — Stability & Performance Update

Date: 2026-11-11  
Base: `v1.1.66-deep-audit-race-spread-test`  
Test branch: `v1.2.0-stability-performance-test`

## Implemented in the Lua source

### P-01: Frame-friendly FPS Booster budgets

The old default scan budget used `BoosterBatch=96`, nominal `BoosterSliceMs=0.90`, `BoosterLowFpsSliceMs=0.45`. The new profile uses:
- `BoosterBatch=64` (fewer processed instances before a yield).
- `BoosterSliceMs=0.75` and `BoosterLowFpsSliceMs=0.35` milliseconds as best-effort CPU slice targets.
- Check elapsed CPU time after every four (rather than eight) objects during the full scene hierarchy pass.
- `BoosterQueueBatch=24` and `BoosterQueueSliceMs=0.35` for streaming updates.

This intentionally favors fewer in-session processing bursts over faster completion. It may take longer to apply WHITE/ULTRA. **Do not claim an FPS increase or zero microstutters:** FPS/device measurements were not possible.

### L-01: Reject stale event registrations and GUI creation

The core previously used a per-instance `CONFIG.BootToken` at bootstrap but did not check it inside the central UI/event factories. During overlapping direct loads a cancelled old initialization could, after a yield, attempt to build more GUI or register callbacks even after the newer instance had started.

- `connect()` now refuses subscriptions if `alive` is false or `ARMY124_BOOT_TOKEN` does not belong to that instance.
- `mk()` now refuses creation of new GUI objects in those same stale circumstances.
- Old status and key rejection guards remain; the serializing `Start.lua` mutex is unchanged.
- Shutdown now records `boosterPro.cleanupStartedAt` before potentially yielding restore operations.

### D-01: Read-only Stability Diagnostics in Memory

Added to **Memory**:
- **Аудит ресурсов / восстановления:** reports Booster phase, saved object/property counts (capped at 2,048 inspected objects on request), pending Terrain/Lighting restore, streaming queue/drops, worker counts, restore failure count, and total tracked global connections.
- **Самопроверка стабильности:** runs seven read-only checks on the current live instance and reports failures. Checks: alive flag, boot-token ownership, cleanup registration, queue bounds, nonnegative worker counters, existence of the hub ScreenGui, and Booster revision consistency.

The four Booster worker classes (initial scan, restore, queue repair and avatar restoration) are now tracked with start/end counters, without a new timer or RenderStepped handler. Failed/cancelled work decrements its counter after the protected worker call. Sliced graphics restoration also stores the time and completion flag after a finished pass.

These are **in-app probes**: they must be clicked in the real Roblox client to count as runtime test results. A 7/7 result would not prove every feature works.

### A-01: Release Verification Architecture

Added `tools/verify_release.py`: Python standard-library script checking matching Hub/Visuals, version/branch, key gate and boot token, original feature markers, Booster budget/worker diagnostics, source string/comment/bracket structure, and 12 mathematically simulated responsive layouts.

Added `.github/workflows/visuals-static-checks.yml` which can run the script on pushes and pull requests, if GitHub Actions is enabled in the repository.

**Important:** The Python script/CI workflow were created and the contents inspected. Their real execution on a CI runner is **not confirmed**; GitHub connector did not expose any completed status/check results for the workflow creation commit. Static source checks are not a Luau compiler or an Android/Roblox runtime.

## Scope preservation

Retained without intentional functional changes:
- ESP, labels, tracers, boxes, FOV distance options and visual render throttling.
- AIM with touch/keyboard/weapon guard, FOV editor and targeting checks.
- No Recoil / Control Recoil, No Spread and weapon-specific cleanup.
- Movement, Fly, camera, FullBright, AntiAFK and private music.
- Purple Neon sidebar UI, compact right-side toggles and responsive touch navigation.
- Custom settings, safe boot, Safety Stop, hot reload and `124HUB` key prompt.
- Existing recovery snapshots and backoff retry logic.

The release does **not** split the 8.5k-line game runtime into multiple `require` modules. That would add network/dependency failure modes without Roblox integration tests; the current architecture improvement is centralized diagnosis, ownership guards and reproducible release tests.

## Verification performed in this environment

- 30/30 focused source assertions passed after the GitHub commits; Hub and Visuals content SHA identical.
- Full single-source structural lexical scan: 8,528 source lines and 39,999 tokens; no unmatched blocks, comments, short/long strings or brackets. This is not a full Luau parse.
- Preserved number of RenderStep bindings and `while alive` task loops relative to v1.1.66.
- Changed production files: `Hub.lua`, `Visuals.lua`, `Start.lua`. Verification files: `tools/verify_release.py`, `.github/workflows/visuals-static-checks.yml`.
- On-device actual draw/FPS, user input, executor API and Luau compilation: **not performed**.
- The previously designed viewport smoke matrix covers twelve desktop/mobile screen shapes, but these mathematical checks do not replace visual inspection.

## Live test plan, in order

1. Start v1.2.0 using the loader; enter wrong key and `124HUB`, close and repeat. Load again while the previous key prompt is open.
2. Enter Memory, click **Самопроверка стабильности** and **Аудит ресурсов / восстановления**; inspect the Output messages.
3. Measure frame time, 1% low and FPS on the same map/player count with Booster OFF, BALANCED, WHITE, ULTRA. Change one mode at a time and wait for READY.
4. Turn Booster OFF; confirm that saved graphics count decreases to zero, Terrain/Lighting return to normal, and worker counters settle.
5. Repeat Booster ON/OFF quickly and trigger streaming or a character respawn; inspect whether queue drops/restore pending appear.
6. Toggle No Spread/No Recoil on several real weapons. Verify original values after switching tools or disabling features.
7. Test ESP/AIM reactivity and GUI drag/scroll/orientation on a phone.
8. Perform Safety Stop, hot reload and intentional GUI removal. Recheck flags, snapshots and connections.

## Known limitations

- Client-local key `124HUB` is visible in source and does not provide tamper-resistant licensing.
- Some Roblox weapon/streaming behaviors are server-authoritative and cannot be guaranteed by client-side code.
- Without a Roblox/Delta/Studio run there is no basis to claim the new Booster is faster or that every bug is fixed.
- Commit/CI status must be checked before promoting from a test branch to `main`.

## Test loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/newregsdfgy-commits/124-community-hub/v1.2.0-stability-performance-test/Start.lua"))()
```

Key: `124HUB`.
