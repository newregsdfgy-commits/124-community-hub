# 124 Community Visuals v1.1.26 — Full code audit and FPS Booster regression fix

## Scope and evidence
Compared 1.1.25 and 1.1.23 against 1.1.22 and 1.1.20 in the connected GitHub repository. Code review across initial startup, profiles, UI, ESP/AIM, recoil/FOV, Booster hierarchy traversal, streaming FIFO, restoration, FPS guard and chat permissions. Regression tests validate source contracts and official Luau compiler parses both entrypoints and diagnostic launcher.

### Confirmed regression
- v1.1.23 changed initial traversal from a maximum 320 objects / 2.2 ms to 48 objects / 0.55 ms with 50 ms pauses, and 0.22 ms / 100 ms pauses when FPS was low. Thousands of objects therefore took disproportionately long, during which the GUI still indicated Booster ON.
- The automatic FPS rollback logic could evaluate before the initial traversal finished, using early FPS samples polluted by the traversal itself. That could turn Booster OFF without ever completing optimization.
- There was no count of successful graphics property writes. Scanned object count alone did not prove work done.

### Code changes v1.1.26
1. Rebalanced initial hierarchy traversal to 96 objects / 0.9 ms, reduced to 0.45 ms at low FPS, with 15/35 ms waits, not the extreme 50/100 ms cadence.
2. Streaming queue uses 48 objects / 0.65 ms, 40/75 ms wait; retains existing 8192 capacity, 3s quiet-time rescan gate and 45s cooldown.
3. Only apply FPS autoguard after Booster scan has completed and 6 seconds after the ready time; reset after-FPS samples when the scan completes.
4. Expose SCANNING, READY, RESTORING/OFF stages; count actual successful property writes, alongside scanned objects, queue drops and last reported error.
5. Snapshot recovery now checks that each original graphics property value was actually restored before removing its saved original. Do not silently discard data on a write mismatch.
6. Streaming activity timestamp is updated only for relevant graphics objects, so unrelated instance creation doesn't indefinitely postpone a repair rescan.

### Additional audit outcomes
- Two public entrypoints Visuals.lua and Hub.lua must have identical content; diagnostic Start.lua must target this exact test branch. Main stays untouched.
- UI overlay and responsive camera listeners are cleaned up on Unload; hooks have existing regression coverage.
- FPS, ping, 1% low, ESP scanning and AIM have instrumentation; module CPU monitor is opt-in.
- Chat manually checks account-wide CanUserChatAsync and does not invoke unknown Roblox game remotes. The user's earlier audit showed CanUserChatAsync false, so this feature cannot deliver messages in that environment.
- BALANCED mode may not visibly whiten the map: it primarily disables local shadows/effects; WHITE/ULTRA are visibly stronger. A test on BALANCED alone should not be taken as proof Booster is broken.
- FPS Booster cannot guarantee higher FPS. On some maps graphic-property writes and GPU reprocessing cost more than the savings; remaining stutters require controlled A/B in Roblox.

### Outstanding verification
GitHub Actions does static Node regression checks and official Luau compiler parsing; it does NOT execute within Roblox, Delta or Xeno. A real device test in the same map, same graphics mode, and stable scene should check (1) phase becomes READY, (2) changed property count is >0 when eligible properties exist, (3) 1% Low and stutters before and after, and (4) restoration when switched OFF. If FPS is consistently worse, keep Booster off.

### Rollback
v1.1.25-chat-permission-test, v1.1.23-booster-stutter-test, and v1.1.22-startup-check-test remain unchanged; main unchanged.
