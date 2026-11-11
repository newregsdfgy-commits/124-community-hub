# 124 Visuals v1.3.0 — Weapons 2.0: Compatibility Audit & Bug Fixes

Date: 2026-11-11  
Base: `v1.2.1-purple-neon-ui-2-test` (Purple Neon UI 2.0 and v1.2.0 performance layer)  
New isolated test branch: `v1.3.0-weapons-2-compat-test`  
Hub.lua / Visuals.lua SHA: `a13d1f6ec48fad02c56204f0c0b2a1233dd789c0`  
Start.lua SHA: `b93573d73e1d5bbae0ccb735d19bf090d19150d4`

## 1. Scope and fundamental limits

- **No Recoil / Control Recoil** observe local Tool activation and locally recognized fire inputs, then attempt to compensate upward camera movement through the client's `CurrentCamera.CFrame`. This is *not* a patch to server weapon physics. Weapon scripts that update camera later in the pipeline, use custom recoil movement, or require server-side changes may not respond as expected.
- **No Spread** can change only explicitly named numeric `NumberValue`/`IntValue` objects and numeric Attributes of the equipped Tool/its descendants that the client can read/write. ModuleScript local variables, remote/server spread and bullet trajectories are outside its reach. Discovery of a local field does not prove that the weapon's firing logic actually uses that field.
- **Compatibility must be checked per actual weapon/game.** Source inspection cannot certify every Roblox experience, executor, engine version, mobile input method or gun framework.

## 2. Confirmed source findings and patches

### W-01: No Spread restores stale dynamic gun settings (fixed)

The original `controller.applySpread()` saved `saved.value`/`saved.attributes[name]` only once. Suppose a weapon's own logic changes its bloom/spread from 2 to 7 while No Spread is active. A follow-up application would zero out the new 7 but leave the saved baseline as 2; disabling the feature then incorrectly restores 2.

**Patch:** whenever the game supplies a new positive numeric spread value, record it as the latest baseline before writing zero. Attribute values are treated the same way. This improves behavior when weapons change accuracy during movement, crouching, ADS or repeated shots. Unrelated names and server values are never edited.

**Boundary:** if the game's own later intended value is exactly zero, a local zero cannot always be distinguished from this script's zero. No algorithm operating solely on the current client value can guarantee perfect ownership in this ambiguity.

### W-02: A spread parameter leaving Tool may retain our zero (fixed)

The prior `unregisterSpreadCandidate()` disconnected signals and removed candidate indexing without immediately restoring a saved value. An object detached from Tool but still live in Backpack or another container could retain a modified parameter until a later full feature toggle.

**Patch:** central `restoreSpreadInstance(instance)` handles a single saved object. It restores only a currently zero value owned by this feature; if the game already changed it to a different value, that newer value is left untouched. The individual restore is used both in the main `restoreSpread()` and on detached candidates. Watchers are disconnected before restoration, preventing a deferred watcher from immediately scheduling a redundant re-zero. Failed Roblox property API calls preserve snapshots for later retries.

### W-03: Stale fire InputObject can over-extend camera correction (mitigated)

`InputEnded` may be missed during a UI focus transition or input interruption, leaving `recoilFireInput` non-nil until another event. The code already has an 8-second hold limit and a 0.55-second orphan limit, but a stale non-nil input could select the longer path.

**Patch:** in the existing recoil callback, inspect `InputObject.UserInputState` using `pcall`. If it is `End` or `Cancel`, discard the stale input. No new RenderStepped hooks are added. Other cases still depend on Roblox delivering expected state transitions.

### W-04: Diagnostics previously lacked compatibility context (fixed)

The old “Диагностика оружия” reported only equipped Tool name, cumulative changes and recoil pulses/correction.

**Patch:** a read-only `controller.inspectCompatibility()` reports known local numeric/attribute fields, saved pending spread snapshots, detected Tool/mouse/touch/gamepad events, count of camera-correction frames, last apply/restore status and accumulated errors. It scans the equipped Tool *on demand*, using a bounded DFS of at most 256 inspected objects / 512 queued children, marking a partial inventory when truncated. No background compatibility scans are added.

Two buttons under **Misc → Weapon Control**:
- **Диагностика оружия** — compact summary of current Tool, detected fields, pending originals, event pulses and last correction.
- **Weapons 2.0 — проверка совместимости** — separate source-by-source input counters, correction count, rollback state and explicit warnings if known client spread fields are absent. Warnings explicitly say this cannot prove or disprove server-controlled spread.

### W-05: Diagnostic event sources are ambiguous (fixed)

`Tool.Activated` and physical input can arrive in the same game action. The existing 40ms dedup still governs `controller.shots`, but now there are separate telemetry counters for Tool, mouse, touch and gamepad sources and timestamps for observed activation and correction. These counters are *input-event observations*, not a statement that bullets were fired.

## 3. Static regression verification

- **104/104 source-level integrity/feature checks passed:** 18 integrity/boot, 27 Spread, 21 Recoil, 15 diagnostics, 17 preserved-module, six release-test checks.
- **Whole-file lexical/balanced-block scan:** 8,730 lines / 40,854 parsed structural tokens, no unmatched quotes, comments, brackets or block delimiters in the standalone scanner. This is *not* a full Luau compiler.
- Confirmed `Hub.lua` and `Visuals.lua` byte-identical; loader checks `Version = "1.3.0"`, validates the `124HUB` key block and points to this new branch.
- Confirmed the main source regions before the Recoil module, between the module and Misc Weapon Control section, and after the weapon UI are unchanged relative to v1.2.1. No new render bindings, `task.spawn(function()` workers, or background polling loops.
- Extended `tools/verify_release.py` with 11 additional Weapons 2.0 source assertions, preserving existing Purple Neon UI and viewport checks. CI execution cannot be confirmed with the available tools (no workflow runs returned). Container was unable to resolve GitHub to download and run the Python script independently; the in-chat source-level checks were executed against GitHub connector content.
- No measured FPS/latency or in-game visual/weapon tests have been performed.

## 4. Live test matrix (not yet executed)

| Scenario | Test | Expected behavior |
|---|---|---|
| Standard Tool | Equip, activate, stop firing, unequip | Tool-event count increases; tracked input returns to idle; no stale correction |
| Mouse framework | Fire mouse button; release outside game GUI | Mouse input count increments; stale InputObject is not held forever |
| Mobile | Fire using named on-screen button + Tool.Activated | Touch or Tool counters increase; ordinary camera touches are not mistaken for firing |
| Controller | R2 firing followed by release | Gamepad events recognized when input is delivered |
| Dynamic bloom | Game changes numeric spread from 2 to 7; disable No Spread | Latest client value 7 restored if accessible |
| Dynamic Attribute | Tool config sets Spread attribute during firing | New number indexed/reactively zeroed and eventually restored |
| Child moved | Move spread NumberValue from Tool into another live container | Client-owned zero restored on candidate removal |
| Tool switch | Change weapons rapidly with No Spread ON | Old tool snapshots restored; new tool indexed |
| Server-authoritative spread | Weapon sends projectile server-side | Client may not alter actual bullets; diagnostics must report limitations |
| Custom Camera recoil | Game writes camera after this script | UI may show events without effective correction; no universal workaround |
| Abort / reset | Safety Stop, reset character, reload Hub | No lingering inputs, subscriptions or snapshots where APIs allow restore |

**Do not treat this branch as production-stable until the live matrix is exercised with actual target games and logs.**

## 5. Preserved features and design

Purple Neon UI 2.0, left-hand navigation, touch scaling, AIM, ESP, FOV, FPS Booster with snapshot/worker diagnostics, Fly, movement, FullBright, private music, saved settings, key gate `124HUB`, Safety Stop, cleanup and earlier per-launch token all remain present. No UI redesign outside Weapon Control was attempted.

## Installation

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/newregsdfgy-commits/124-community-hub/v1.3.0-weapons-2-compat-test/Start.lua"))()
```

Key: `124HUB`  
Status: **saved test build, static checks passed, live behavior unverified**.
