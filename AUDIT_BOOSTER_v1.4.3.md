# 124 Visuals — v1.4.3 FPS Booster deep stability audit

Audit date: 2026-11-14.
Source baseline: `v1.4.2-ui-layout-repair-test`.
Test branch: `v1.4.3-booster-stability-test`; **main untouched**.

## Scope and limits
Examined Booster's graphics ownership, mode transitions, scene hierarchy iteration, stream-queue handling, Terrain color/grass rollback, Lighting and Player FX ownership, deferred restoration, FPS measurements and guard, startup and shutdown paths. Also retained and reran historical regression suites for ESP, Key System, Weapons, Player FX and responsive UI. **Cannot run a real Roblox client, test executor APIs or benchmark a phone in this session.** Static tests and deterministic Luau mocks do not measure production FPS or guarantee all games.

## Findings and fixes

| ID | Severity | Source behavior in v1.4.2 | Code change in v1.4.3 |
|---|---|---|---|
| BOOST-143-00 | **Critical** | `restoreBoosterProperty` computed `lastWritten = written and written[key] or nil`; the Lua `or` operator discards a legitimate `false`, so PostEffect.Enabled=false and CastShadow=false could skip rollback | Read the last value with an explicit `if written then lastWritten = written[key] end`, preserving boolean `false`; executable Luau regression now asserts restoring Enabled from false to true |
| BOOST-143-01 | High | `restoreTerrainColors()` rewrote every cached material regardless of whether a game script had since changed its color | Track the last Booster-written value per Terrain material and restore only when it still owns that value |
| BOOST-143-02 | Medium | A partial Terrain restore retried *all* materials, even successful ones; repeated writes could cause small spikes and overwrite later game updates | Keep **only failed entries** in the retry list and drop successful/external-owned entries immediately |
| BOOST-143-03 | Medium | `whitenTerrain()` treated a successful setter call as a successful material change without a readback, including silent no-ops | Verify actual value, ignore originally white materials, create no new snapshot for a confirmed no-op; keep conservative snapshot if readback fails |
| BOOST-143-04 | High | `restoreTerrainGrass()` restored an old Decoration state even if another game controller had since modified it | Preserve newer game-owned Decoration, use readback, avoid a snapshot when Decoration was already disabled; keep pending snapshots on genuine failure |
| BOOST-143-05 | Medium | `optimizeObject()` tracked *requested* property value even when engine clamped or ignored it; restore could then skip a value that Booster actually changed | Track actual post-write value; don't count or snapshot confirmed ignored writes; preserve rollback when setter returned success but readback is inaccessible |
| BOOST-143-06 | Medium | WHITE/ULTRA initial full Workspace scan ran before Lighting effects, so visible effect changes could arrive late on very large maps | Process Lighting before full Workspace traversal. This changes early responsiveness, **not** the total number of map objects visited |
| BOOST-143-07 | Low | Player-owned effects could still be queued before the protected branch check (wasted queue work) | Reject explicitly owned Player FX instances before adding them to the streaming FIFO |
| BOOST-143-08 | Low | UI diagnostic did not distinguish engine-denied from unverifiable writes | Added `deniedWrites` and `unverifiedWrites` counters to Booster status and diagnostics |

## Preserved behavior
- BALANCED remains the default safe mode and does not perform a massive Workspace recoloring. WHITE and ULTRA are deliberate aggressive modes that alter lots of client graphics; their full scene scan is intentionally bounded by batches and yields.
- Per-object snapshot and rollback; asynchronous generation guards; tracking for streaming additions; protected character models; exact PlayerFX ownership; Atmosphere handoff; three modes; FPS Guard; Key and ESP controls remain.
- Terrain.Decoration is not directly available to ordinary game scripts; the hidden property path is optional, executor-dependent, and may have no effect. Failure here must not be described as successful grass removal.
- Changes are local client visuals; they cannot guarantee a higher FPS, stop every renderer stutter, or override every server-side game script.

## Verification
- `tools/build_visuals.py --check`: exact 12 ordered Lua fragments must equal both Hub.lua and Visuals.lua.
- `tools/verify_release.py`: release integrity plus 4 new Booster guards.
- `tests/BoosterDeep143.test.cjs`: 17 new regression checks against actual source, including the critical false-valued property restoration path.
- `tests/build-booster143-runtime.py`: extracts real production `optimizeObject`, `restoreBoosterProperty`, `restoreObject`, `whitenTerrain`, `restoreTerrainColors`, `hideTerrainGrass`, `restoreTerrainGrass`; executes in Luau with mocks for Roblox property read/write.
- The new runtime suite tests boolean false post-effects restoration, ignored setters, clamped setters, denied setters, normal mode downgrades, changed external colors, partial material restoration, repeated whiten, grass restoration, plus the existing Player/Booster Atmosphere and ESP/Key/UI fixtures.
- **Observed CI SUCCESS:** [GitHub Actions #43530511917](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43530511917): 12-module deterministic bundle, **75/75 release assertions**, **93/93 targeted Node regressions**, official Luau parser/binary compiler on Hub.lua, Visuals.lua and Start.lua, executed production Booster property/Terrain controller tests (including false-property rollback, clamped/denied/no-op writes, partial color restore, game-owned updates and grass), plus previous Atmosphere Player FX, ESP, Key and viewport behavior tests.
- Official CI definition: `.github/workflows/v143-booster-ci.yml`. Passing isolated Luau tests does **not** mean that the Roblox runtime or real device FPS has been benchmarked.

## Mandatory live QA before merging
1. In a fresh Roblox session, record before/after **FPS average and 1% low** on the same map/camera and run each mode over at least 1–2 minutes. Account for map streaming and client graphic settings; don't assume FPS rises.
2. Toggle BALANCED → WHITE → ULTRA → BALANCED → OFF; confirm original part colors, SurfaceAppearance textures, Atmosphere and Terrain materials return.
3. Trigger OFF while the WHITE/ULTRA scan is still progressing; ensure only the current generation remains active, no old scan continues mutating graphics.
4. With Player weather/Environment ON, change weather, turn Booster ON/OFF in both orders, inspect visual consistency.
5. Repeat respawns, game streaming and UI refresh; verify shutdown restores and extra booster worker tasks stop.
6. In Memory → Booster Diagnostics, inspect `deniedWrites`, `unverifiedWrites`, queue drops and restore-pending reports. A high denied count indicates an unsupported engine property rather than a verified optimization.
7. Test the target mobile device. CPU spikes can persist from Roblox shader/material recompilation, which source-level scheduling alone cannot eliminate.

Do **not** promote to main automatically. This test release is eligible for manual QA only after CI success.
