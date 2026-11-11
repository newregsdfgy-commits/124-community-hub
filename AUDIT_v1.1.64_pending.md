# 124 Visuals — v1.1.64 audit findings (11 Nov 2026)

**Status:** partial fix, test-only branch. The attempt to replace the large `Hub.lua` and `Visuals.lua` was blocked; their Git blobs remain at v1.1.63. A small patch to `Start.lua` DID succeed. Do not claim that all Lua core fixes were deployed.

## Applied loader fixes

- `Start.lua` now serializes launch operations using `getgenv().ARMY124_START_RUNNING` and refuses another loader invocation while the first is awaiting a key or initializing. The flag is released on normal success, key cancellation and caught errors.
- The loader removes a previous `Army124StartupError` overlay when attempting a new launch.
- The loader refuses to execute a download that lacks the exact `local ACCESS_KEY = "124HUB"` marker. This is a release sanity check and **not** secure authentication.
- 18/18 focused static assertions passed. A lexical scan of the 99-line loader detected no unmatched quotes, comments or brackets.
- Patched loader blob SHA: `7626b1d3da65abae097da798b9276fadcc4d3d99`.
- Current payload remains v1.1.63 via the same validated raw URL; Hub/Visuals blob SHA `02c2e68c861f8ed249d5dc7880324402c06d17a8`.
- The loader mutex covers only concurrent use of this specific `Start.lua` in a shared executor environment; direct loading of Hub/Visuals and distinct executor environments remain outside this fix.


## Reproducible issues visible in v1.1.63 source

1. **Concurrent key gates share a mutable boot status.** Every launch writes `env.ARMY124_BOOT_PHASE` and `env.ARMY124_BOOT_ERROR` without ownership markers. If run A is waiting for its key and run B starts, run B destroys A's key screen; A's resumed coroutine can later write `key_denied` after B has set `key_required` or `ready`. The loader may report an error for B or falsely assess another instance's ready status.
   - **Fix:** allocate a unique per-invocation token inside `CONFIG`, put it in `env.ARMY124_BOOT_TOKEN`, check it after yields (cleanup, recovery, key entry and UI initialization), and have `Start.lua` validate the token returned by the chunk before accepting the global `ready` state.
2. **Stale startup error overlays key UI.** The prior `Army124StartupError` screen is only removed at the end of a successful initialization. Its `DisplayOrder=10000` is greater than the key gate's `DisplayOrder=9999`, so a new attempt may display an old red error above the key form.
   - **Fix:** remove stale startup error UI at the beginning of the new attempt, and preserve only errors owned by the current launch token.
3. **New spread parameters can go undetected.** `registerSpreadCandidate` scans an equipped Tool's current descendants and subscribes to numeric candidates or existing spread attributes. A descendant with a *newly added* spread attribute, or a numeric value renamed to a recognized spread name later, will not be indexed unless it is already in a watched container or is re-added to the tool.
   - **Fix option:** a low-frequency, bounded discovery pass for candidate additions (not a full scan every frame), or a selectively attached watcher for relevant configuration descendants. Avoid subscribing to every rendered part because of FPS cost.
4. **Local weapon compatibility cannot be proven statically.** `No Recoil` compensates observed pitch only while firing is inferred. `No Spread` touches explicit client-local values/attributes, not server physics or ModuleScript internals. A truthful verification needs real weapon-specific tests.
5. **Client key gate is not secure licensing.** Key `124HUB` is present in the downloadable Lua sources. This is a UI gate, not tamper-resistant authorization; older branch URLs remain callable.

## Modules inspected

- Start.lua bootstrap and version check; error reporting, key window and cancellation.
- Equip/unequip and character respawn callbacks for weapon controllers.
- No Recoil / No Spread event handling and restore snapshots.
- ESP player watchers and scan pacing.
- FPS Booster snapshot, sliced rollback, retry scheduling, and scene/terrain recovery.
- UI toggle activation, touch scroll suppression, responsive layout.
- Saved config and safety stop/cleanup paths.

## Limits and next action

The two full Lua source files have not been modified in this branch due to a blocked write. The **launcher** was modified and may be tested with its existing v1.1.63 payload. Do **not** advertise the core as v1.1.64 or claim all defects resolved.

The above defects are based on source inspection. Roblox compilation, executor tests, actual FPS measurements and gameplay regression were not performed.
