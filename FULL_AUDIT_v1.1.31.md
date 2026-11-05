# 124 Community Visuals v1.1.31 — independent full audit, recovery integrity

## Baseline and evidence
Audited connected GitHub repository `newregsdfgy-commits/124-community-hub` starting from `v1.1.30-full-stability-audit-test`, a build whose 93 JavaScript source-contract tests and official Luau parser/bytecode compiler passed. Compared startup, GUI, ESP range, event subscriptions, AIM/Recoil, Booster streaming, state snapshots, profiles, chat, camera FOV, spin pose, Unload, hot reload and early initialization error handling.

## Newly confirmed code defects
1. **Crash before normal cleanup leaves changed graphics (high).** The registered `abortPartialHub` was designed for UI initialization failure and did not traverse `savedGraphics`; it restored Terrain and lighting only. The ordinary `cleanup()` had graphics rollback, so the two failure paths disagreed. Fixed by providing an early sliced `boosterPro.restoreGraphicsEmergency()` and invoking it in the partial cleanup path. A failed read-back retains the original and installs an `ARMY124_RECOVERY` retry callback for next safe startup. Pending recovery of a preceding instance is chained.
2. **Camera FOV restore discarded snapshot without confirming read-back (medium).** `memoryFX.camera.restore` removed the saved FOV after a successful assignment pcall even if the engine did not retain the value. Fixed by reading the value again before releasing snapshot.
3. **Anti-Aim pose restoration discarded pending C0/AutoRotate after successful setter without confirming value (medium).** The pending retry loop and immediate `spin.reset` calls now verify that C0 and AutoRotate actually match the originals, preserving failed values for next recovery attempt.
4. **UI finished without its GUI could leave an invisible running hub (medium).** After a successful UI callback but missing ScreenGui the code showed a boot error and kept handlers enabled. This path now invokes registered normal cleanup or fallback abort before displaying the boot failure.
5. **ESP artifacts on failed partial startup (low/medium).** The emergency cleanup now clears per-player render objects before disposing UI roots.

These are static control-flow findings; no claim that a particular error occurred on the user's client. The fixes are defensive and do not change ESP's chosen radius/target cap or Booster mode speed.

## Audit inventory / source checks
| Subsystem | Assessment |
| --- | --- |
| GitHub launcher | Correct branch/version guard, pcall of network and compile steps, runtime xpcall and GUI-ready confirmation |
| ESP 200m | Uses avatar-relative studs-to-meters conversion, not the BillboardGui camera distance; explicit 8-96 target cap |
| ESP streaming | Supports partial rigs and coalesced event refresh with a minimum gap; still cannot locate an unreplicated character |
| AIM/Recoil | Source lifecycle and existing bind priorities preserved; actual aiming accuracy untested |
| FPS Booster | Bounded traversal, FIFO, scan-state and restoration snapshots unchanged except emergency rollback |
| Profile storage | Numeric and string validations, cautious feature autoload, saved state and profile migration retained |
| Chat | Manually gated by Roblox CanUserChatAsync. No attempt to call unknown custom chat remotes |
| GUI/Unload | Normal and early cleanup now align better; cannot prove PC/touch runtime behavior from source |

## Verification limits and remaining risks
CI is predominantly **static regression testing**, not Roblox engine simulation. Official Luau compiler checks parsing/bytecode, not runtime APIs. The early boot recovery and readback verification need fault-injection or in-game reproduction to confirm runtime behavior. Latency and frame stutters require A/B with in-game FPS/p99/1% Low and server/network context.

Try a fresh session with v1.1.31: verify screen appears, ESP 140/190/205m, PlayerAdded/resets, Booster WHITE→BALANCED→OFF restoration, camera FOV ON→OFF, spin ON→OFF, Unload/re-execute, and diagnostics with performance monitor off and on. If any restore stalls, capture `[124 START / RECOVERY]` and warnings. All previous branches remain available for rollback; `main` untouched.
