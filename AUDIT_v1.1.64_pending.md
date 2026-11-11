# 124 Visuals — v1.1.64 audit findings (11 Nov 2026)

**Status:** review-only branch. The attempt to update the large `Hub.lua`, `Visuals.lua` and launcher was rejected by the GitHub tool. Files retain the v1.1.63 Git blobs; this document is NOT a claim that fixes were deployed.

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

The source files have not been modified in this branch due to a blocked write. The previous v1.1.63 test branch remains the runnable version. Do **not** advertise v1.1.64 as fixed or ready for live testing.

The above defects are based on source inspection. Roblox compilation, executor tests, actual FPS measurements and gameplay regression were not performed.
