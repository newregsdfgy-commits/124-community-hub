# 124 Visuals v1.4.8 — Full Stability and Rollback Audit

**Base:** v1.4.7 `bbc0a6dd32f692413b9e97250b32495190f5ecc7`
**Test branch:** `v1.4.8-full-stability-audit-test`
**Production main:** not changed

## Scope reviewed

AIM lock and input state, ESP renderer/roster lifecycle, Weapons 2.0 and No Spread recovery, FPS Booster snapshots and terrain protection, Player Aura/Glow/Weather, Purple Neon UI, profile serialization, Flight/Speed/Noclip, emergency startup/shutdown/relaunch recovery.

## Corrected failure modes

1. **WalkSpeed restore could permanently lose the original value.** Previous `movement.restoreSpeed()` wrapped the write in `pcall`, discarded `originalSpeed` and the humanoid even if Roblox rejected the write or changed the value before throwing. New weak-key `pendingSpeeds` records the original and last script-written value, retries later and respects newer external values. Before an *applied* Speed write, the tentative last-applied value is now recorded, so even a partial setter error remains reversible.
2. **Noclip collision snapshot could be dropped on a failed restore.** `restoreCollision()` discarded every entry regardless of `pcall` success. Now the snapshot persists on failed setter or getter, with readback verification. Missing/deleted parts and externally changed values are handled without unnecessary writes.
3. **Fly AutoRotate and Humanoid Physics could be left modified after failed teardown.** `restoreFly()` previously discarded the captured AutoRotate if a setter failed, and an exception prevented the independent `GettingUp` transition. New weak-key `pendingAutoRotates` plus owner registration before writing `AutoRotate=false` preserves rollback intent across partially failed startup, respawn and unload. Physics teardown runs independently. A second fallback failure in `ensureFly` keeps the true original baseline.
4. **Multiple rollback failures could block unrelated cleanup.** `movement.retryPending()` attempts Speed, Fly, and (when Noclip is OFF) collisions independently, and reports incomplete restoration without discarding snapshots.
5. **Movement rollback was not wired into all recovery paths.** The existing HUD maintenance worker retries restoration without adding a new physics/render loop; both regular unload recovery and early UI abort recovery now include pending Movement snapshots.
6. **AIM configuration changes could retain old lock/lead data.** Menus and profile logic previously used only `aimTarget=nil; aimNextScan=0`. They now call the existing `aimPro.reset()`, which also clears previous LOS, switch candidate and prediction lead state on toggling Target Lock, Visible Check, team check, Prediction, FOV, range, aim mode and AIM activation.

## Verified

- CI run: https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43603863904 — **success**.
- Source builder verification: both production bundles are byte-identical and match the 12 ordered sources.
- Release integrity: **80/80**.
- Node regression tests: **124/124**, no failures.
- Official Luau parser and bytecode compiler: **success** for `Hub.lua`, `Visuals.lua`, and `Start.lua`.
- Production-source behavioral harnesses: **success**, including AIM lock/FOV/LOS/camera safety, input, Player FX weather recovery, ESP, Booster terrain/partial-write recovery, Key System, and new Movement setter fault injection.
- New Move fault cases: setter denied before mutation; setter mutated then threw; third-party change; multiple simultaneous failures; active-Noclip protection; retry after successful recovery; independent Humanoid Physics teardown.

## Not verified / future real-client testing

This audit executes production Lua source in deterministic Roblox API fakes but **does not run a real Roblox client, Android device, or actual game-server weapon framework**. It cannot prove real GPU/FPS improvements, in-game appearance, no unexpected anticheat action, or complete compatibility with every experience. Production branch `main` stays untouched pending a voluntary in-game check.
