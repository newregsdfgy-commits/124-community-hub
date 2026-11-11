# 124 Visuals — Deep Stability Audit v1.4.1
Date: 2026-11-12
Baseline: `v1.4.0-player-visuals-test`
Fixed branch: `v1.4.1-deep-audit-fixes-test`
Main branch: unchanged.

## Scope
Reviewed all twelve compile-time Luau source modules and key file boundaries, launcher version/boot token handshake, GUI startup and emergency cleanup, validated profile auto-load, ESP respawn watchers, Weapons 2.0 rollback, FPS Booster graphics snapshot ownership, Player aura/glow/weather/rain/tint. The most detailed tracing concerned interactions with Lighting and character lifecycles. This is source and isolated runtime analysis, **not** a substitute for a real Roblox/Android test.

## Bugs confirmed and fixed
| ID | Severity | Source failure | Fix |
|---|---|---|---|
| 141-01 | High | Highlight parented under `PlayerGui`; on some engine builds this can fail to render | Parent local Highlight directly to its character Model and keep explicit `Adornee` |
| 141-02 | Medium | Aura Part/Attachment reparenting could replace the emitter pointer while leaving an old emitter behind | Destroy old emitter before replacing its attachment/parent |
| 141-03 | Medium | Replacing/removing `HumanoidRootPart` without full `CharacterRemoving` did not trigger immediate FX cleanup | Subscribe to `Character.ChildRemoved` and disconnect it during rebind/unload |
| 141-04 | Medium | Queued RenderStepped callback from old rain session could call `stopRain()` after a new rain session had started | Check `gui == controller.rainGui` before stopping or mutating any rain state |
| 141-05 | High | Player weather enabled after ULTRA Booster could snapshot `Atmosphere.Density=0` as the game's actual baseline | Release Booster's prior snapshots **before** Player edits the current Atmosphere |
| 141-06 | High | When Player weather was disabled before Booster, Booster's original snapshots could be lost/misaligned after concurrent ownership | Return Atmosphere to Booster's isolated targeted optimizer, creating a new correct baseline; Booster OFF later restores the real game values |
| 141-07 | Medium | Booster excluded any Atmosphere while playerWeatherEnabled, and any ColorCorrectionEffect with certain *names*, even if unrelated | Use weak-key exact-instance owner registry. Names never grant ownership |
| 141-08 | Medium | Previous ownership protection could be installed *after* parenting an effect, allowing a narrow `DescendantAdded` race | Register Player-owned instance before assigning `Parent`; unregister when destroyed |
| 141-09 | High | During intermediate v1.4.1 bump, Start.lua checked for payload v1.4.0 and would reject the new valid bundle | Align launcher marker to `Version = "1.4.1"` with release checker |

## Regression and executable QA
- `python3 tools/build_visuals.py --check`: 12 ordered source fragments must match generated `Hub.lua` and `Visuals.lua`.
- `python3 tools/verify_release.py`: version/launcher/key/ESP/Weapons/profiles/viewport/integrity assertions.
- `node --test tests/EspKeyArchitecture130.test.cjs tests/Weapons2Compatibility.test.cjs tests/FullAudit131.test.cjs tests/PlayerVisuals140.test.cjs tests/DeepAudit141.test.cjs`: historical focused tests + 14 new deep-audit guards.
- `tests/build-131-runtime-audit.py`: extract and execute actual ESP and Key handlers in official Luau with deterministic fake signals and time.
- `tests/build-player140-runtime.py`: execute current Player FX in official Luau with R6/R15-like character mock, Root removal, sessioned rain callbacks, Fog/Atmosphere restoration, external edits and live owner bookkeeping.
- `tests/build-booster141-runtime.py`: extract actual Booster restore, handoff and owner-check functions; test Booster ON → Player weather → Player OFF → Booster OFF as well as external property changes and a denied engine write.
- **Verified successful CI:** [GitHub Actions run #43120099593](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43120099593): 60/60 static release checks, 64/64 focused regression tests, exact 12-module bundle, real official Luau parse+compile for Hub.lua, Visuals.lua, Start.lua, executable Player FX + Booster handoff and ESP + Key isolated Luau tests. All steps passed. This certifies source/test behavior only, not actual device FPS or all games.
- Workflow: `.github/workflows/v141-ci.yml` is reproducible on this branch.

## Compatibility and limitations
- Existing Purple Neon UI, Player tab, Weapons 2.0, ESP 2.0, Key 2.0, AIM, FPS Booster, profiles, movement and music remain in the bundled source. No changes to server/other-player state.
- WEATHER: `Fog*` when there is no Atmosphere, game-owned `Atmosphere` otherwise; mode CLEAR restores only values last written by Player FX, retaining newer game-owned values.
- Highlight is subject to Roblox client renderer limits. Mobile FPS, third-party executors, and game-custom Atmosphere controllers need an actual live test.
- Rain is a bounded client ScreenGui overlay, not physical raindrops in the 3D game world.
- The access key still resides in the public Lua client. Wrong-key cooldown is UI behavior, **not** a secure server-side authentication solution.
- The 12 source files are *compile-time fragments*, not real ModuleScripts; deep runtime modularization remains a separate architectural project.

## Mandatory manual QA before merging main
1. Two player respawns with Root removal/re-add and client StreamingEnabled; watch old attachments and Highlights.
2. Player aura/glow toggles while switching R6/R15 games, mobile high/low settings; watch stale particles and glow.
3. Rapid weather OFF/RAIN/FOG/RAIN, camera resets and rapid toggle during respawn; verify no disappearing rain.
4. With and without `Atmosphere`, activate Booster BALANCED/ULTRA **before and after** weather; verify restoring the exact original Density/Haze/Color/Decay on both OFF orders.
5. Collect Roblox Output, FPS average and 1% low before/after enabling Player effects on Android. No fabricated FPS improvements.
6. Key on Android with bad key x5, keyboard Enter vs touch, exit, reconnect, duplicate launch and cleanup.
