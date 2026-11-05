# 124 Community Visuals v1.1.33 — isolated stability fixes and QA
## Scope
Base SHA: `4e4e0fcedd905b1d93d9c5f99eb3556996a9dc44` (v1.1.32 test branch).
The original version and `main` remain unchanged. This release fixes only verified
error-handling paths; visuals, aim, recoil, UI layout, ESP range and chat are not deliberately modified.
## Changes
1. **Booster off restore:** If setter verification fails, preserve property snapshots and retry with a 20-second backoff. Retry runs only while OFF and RESTORE PENDING, uses a revision token, and is sliced to avoid a single-frame mass restore. Pending Terrain restoration is checked by existing HUD loop; state transitions to OFF only after all applicable snapshots clear.
2. **BHOP WalkSpeed:** Preserve failed revert per Humanoid; verify readback; avoid overwriting speed that another game script changed; retry asynchronously with bounded delay; preserve unresolved snapshots in cleanup recovery and early UI abort.
3. **Profile application:** Scoped xpcall guard ensures `restoring` never remains latched after a failure; prevents reporting a successful profile selection on failure. Failed profile autoload now fails initialization instead of leaving an apparently ready GUI.
4. **Test coverage:** Add JS invariants and actual Luau fault injection for profile guard, BHOP blocked/ignored setter, booster failed/stale revision restore.
## Runtime QA matrix — not substituted by CI
- Cold start and reload on target PlaceId 18537079992.
- Booster BALANCED → WHITE → ULTRA → OFF; compare visuals before and after, including a rapid OFF → ON switch.
- Toggle BHOP, cause a game-side WalkSpeed change during BHOP, turn BHOP off, respawn, and check speed restoration.
- Switch CUSTOM / LEGIT / RAGE; restart; try a malformed profile in a copy, verify visible failure and no stuck saving.
- Test ESP 140m / 190m / 205m, respawn/streaming and more than shape budget players.
- Compare baseline FPS and p99 frametime with Booster OFF and ON in comparable scenes.
## Limits
Automated Luau compilation and mocks do not demonstrate in-game FPS, executor permissions, camera behavior, or that every possible defect is removed. Requires Roblox runtime verification before merging `main`.
