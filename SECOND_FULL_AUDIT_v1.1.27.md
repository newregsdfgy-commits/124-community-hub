# 124 Community Visuals — second full audit, v1.1.27

## Verification basis and scope
Audit conducted against connected GitHub repository `newregsdfgy-commits/124-community-hub`, using `v1.1.26-booster-recovery-audit-test` as the tested baseline (Git commit `52ee75a5b2331bb4b088079986b6ffeefaf7ceb2`). Inspected all major runtime and UI paths in `Visuals.lua` (~6000 lines), the identical `Hub.lua`, the diagnostics launcher `Start.lua`, the test suite and Actions workflow. Reference versions v1.1.20, v1.1.22, v1.1.23 and v1.1.25 were compared where relevant. `main` remains a distinct older release.

## Confirmed additional defects found
**R1 — Incomplete verification during graphics MODE switches (moderate).** v1.1.26 verified a property on full OFF/Unload, but `optimizeObject()` discarded the saved original after a successful Lua property setter with no getter validation while going ULTRA/WHITE → BALANCED. On environments where a setter does not retain the value, this can lose the original graphics snapshot. Fixed in v1.1.27 by checking read-back before deleting the key; the failed snapshot is retained.

**R2 — Overstated applied-property count (minor to moderate).** `changedProperties` counted `pcall` setter success, not actual property application. Fixed by re-reading and counting only values equal to the requested target; the original snapshot is still retained after a successful setter in case a delayed mutation needs later rollback.

**R3 — Misleading phase after restoration (minor).** RESTORING could become OFF even while Terrain grass/colors still had an un-restored snapshot. An error-triggered rollback also masked FAILED as OFF. Fixed to label RESTORE PENDING whenever graphics or Terrain originals remain, and FAILED if a captured fatal error caused a fully completed rollback. New activation clears the previous error.

**R4 — Stale FPS guard comment (maintenance).** Removed contradictory comment claiming that FPS Guard is active during the initial scan. Actual code has the correct `if not boosterPro.complete then return end`.

## Findings from other modules
**Startup (source contract verified).** `Start.lua` downloads and verifies exact version, compiles, executes protected by `xpcall`, and checks `ARMY124_BOOT_PHASE == "ready"`. GUI writes on initialization failure are separate; no production runtime success is inferred solely from syntax checks.

**FPS Booster/streaming (static checks passed).** Initial traversal, queue, revision cancellation, quiet-window repair and throttling are bounded; note that engine-driven GPU reprocessing and rendering work are not measured by os.clock, and no FPS increase can be guaranteed. Auto rollback waits for the scan to complete. BALANCED mostly suppresses shadows/effects and does not necessarily whiten materials. `savedGraphics` and Terrain snapshots are retained when restore cannot be verified.

**GUI (static checks passed).** Five page identifiers, mobile scroll protection, window tween cancellation, stale-camera listener disconnection and cleanup exist. Cannot assert touch/resize reliability without actually running PC/Android.

**ESP/AIM/recoil (static checks passed).** Player-roster caching, limited ESP update frequency, read-only character search and camera render priority structure are retained. Aim and recoil continue to use render callbacks and are not instrumented by this static pass for actual aiming quality.

**Profiles (static checks passed).** Keys and numerical ranges are validated; auto load forces Booster OFF until deliberate activation. A saved OFF state is intentional and can explain apparent failure to auto-start.

**Chat (static checks passed).** Manual send is guarded by account-wide `CanUserChatAsync` before `RBXGeneral.SendAsync`; game-specific remotes are not called. User's observed `CanUserChatAsync=false` means custom UI cannot authorize messaging.

**Security / provenance (limited).** The visible production `Visuals.lua` has no external URL, `HttpGet`, dynamic code load or remote calls. `Start.lua` does deliberately fetch executable Lua from GitHub. The branch URL is mutable; using a verified commit hash instead reduces source substitution risk, but executor and in-game privileges cannot be audited from source alone.

## Tests
- GitHub Actions uses official Luau compiler `--only-parse` and bytecode compilation on Visuals.lua, Hub.lua and Start.lua.
- JavaScript tests are mainly static source-contract tests, not mocked Roblox engine execution. No previous claim of 51/51 passing should be interpreted as end-to-end gameplay verification.
- v1.1.27 adds 12 audit regression checks for permission order, mutation provenance, restoration, queue bounds, cleanup, source URLs and UI boot.

## Remaining risks / test plan
1. PC/Android A/B on same scene, graphics settings and network. Compare Booster OFF, BALANCED and WHITE, and watch FPS, 1% Low and >50ms frametime spikes.
2. Confirm `SCANNING → READY` and a nonzero verified `changedProperties` count in a scene where suitable properties exist.
3. Switch WHITE → BALANCED → OFF and verify map colors/materials, Terrain colors and grass recover. Run twice in one session then hot reload with FPS Booster active.
4. Test minimize/reopen, touch slider vs scroll, window resize and camera respawn.
5. Check `FAILED` or `RESTORE PENDING` and saved recovery after a failing property assignment; no direct fault injection was performed.

Rollback: all prior test branches remain unchanged. `main` untouched.
