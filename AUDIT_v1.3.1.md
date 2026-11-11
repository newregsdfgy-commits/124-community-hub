# 124 Visuals — Deep Audit v1.3.1
Date: 2026-11-11
Branch: `v1.3.1-deep-audit-stability-test`
Baseline: `v1.3.0-esp2-key2-modular-test`; `main` unchanged.

## Scope and evidence
Read and checked the 11 ordered source fragments, bootstrap `Start.lua`, compiler/static workflows, release assertions and maintained regression tests. Examined boot ownership, access gate, global state/roster, ESP watchers, remote/local respawn, 2D tracer/shape render, AIM/recoil, Booster ownership/rollback, UI inputs, and hot reload cleanup. Direct Roblox runtime, Android executor, all target games, production frame pacing, StreamingEnabled replication, and server-side trajectory behavior are **not available in this session**.

## Findings and fixes
| ID | Severity | Evidence in v1.3.0 | Fix in v1.3.1 |
|---|---|---|---|
| ESP-131-01 | Medium | `refreshESP()` deleted all rendered player objects whenever local Root was absent during respawn, forcing expensive GUI reconstruction | Hide existing Highlight/Billboard/Tracer, keep references and reuse on local Root return; still clear ordered list and active counter |
| ESP-131-02 | Medium | `refreshTracers()` called `clearTracers()` while local Root was temporarily missing, destroying cached 2D frames | Hide tracer frames instead; full cleanup still destroys on explicit disable/unload |
| ESP-131-03 | Medium | Urgent respawn timer could run a full roster scan although a newer periodic scan already handled the event | Record latest dirty event time; suppress obsolete urgent scan if latest full scan is newer and local Root is ready |
| ESP-131-04 | Low | Repeated urgent notifications while timer pending could conceal a new event arriving after periodic scan | Update dirty timestamp on **each** event, including while a timer is queued; keep latest event eligible for urgent scan |
| ESP-131-05 | Low | `stopESPWatchers()` was invoked again on disabled scans even when no watchers remained | Skip no-op watcher teardown if there is no watcher or local binding; invalidate queued generation on real stop |
| KEY-131-01 | Medium | Android `ReturnPressed`/FocusLost could submit again with an already cleared TextBox and replace actionable error with generic "enter key" | Empty duplicate within dedup interval returns without touching prior feedback; new candidate is not suppressed by previous empty input |
| KEY-131-02 | Medium | `BindableEvent:Fire()` was the only stored completion signal, so a completion before `Event:Wait()` could be lost | Latch accepted result before Fire; branch on completed before waiting, and fail closed on ScreenGui parent removal |
| PERF-131-01 | Low | `espVisual.frame` sampled camera CFrame even with Tracers and 2D Box both OFF | Early return before camera sampling and clear previous motion state |

These are source-observed flaws and their code fixes. Severity indicates expected impact, not a measured number of crashes/FPS drops.

## Compatibility retained
- Explicit OFF-by-default effect controls; key gate required before state initialization.
- Purple Neon UI, menu sections, AIM, ESP, FPS Booster, Weapons 2.0 diagnostics and No Spread rollback, movement, audio, profile and cleanup hooks remain present.
- No new worker running at a fixed interval. One dirty timestamp and lightweight key state; no additional remote requests or game/server modifications.
- Source remains **11 compile-time fragments**, bundled exactly into matching `Hub.lua` and `Visuals.lua`. It is not a runtime `require()` module conversion; such a conversion would require substantial restructuring of shared local closures.

## Reproducible tests
- `python3 tools/build_visuals.py --check`: verify exact byte-for-byte concatenation.
- `python3 tools/verify_release.py`: release, launcher, integrity, ESP/Key guards, 18 viewport models.
- `node --test tests/EspKeyArchitecture130.test.cjs tests/Weapons2Compatibility.test.cjs tests/FullAudit131.test.cjs`: 36 version-matched structural regressions.
- `python3 tests/build-131-runtime-audit.py`: extracts **actual production Luau callback bodies** (ESP urgent scheduler; Key submit/resolve) into temporary executable harness. Assertions cover burst coalescing, post-periodic dedup, new dirty events, old generation, OFF state, wrong/empty keys, fast re-entry, five failed attempts, local cooldown, and idempotent successful resolution.
- **Verified CI PASS**: [GitHub Actions run #43053577977](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43053577977): 11-part bundle exact; 60/60 release/integrity assertions; 36/36 focused Node regression tests; real Luau parse + binary compile for Hub.lua, Visuals.lua, Start.lua; both extracted production callbacks executed successfully in Luau (ESP 5 fault-injection scenarios + Key wrong/duplicate/cooldown/resolve scenarios). C++ warnings from building upstream Luau did not fail the build. This still does not test real Roblox engine behavior.
- Workflow `.github/workflows/v131-audit-ci.yml` contains all checks and remains reproducible.
- Earlier workflows on historical v1.1.x branches contain fixed expectations for old UI/version layouts; they are not treated as current production certification.

## Unverified and next manual QA
1. Roblox launch with desktop and Android; wrong key x5, keyboard return + focus, GUI close, two concurrent launch calls, hot reload and emergency stop.
2. Multiple nearby/distant players, repeated deaths of local and remote characters, late streamed Head/Torso/HumanoidRootPart; verify no stale labels and no orphaned overlays.
3. Check 200m / 700m / 1000m, still camera vs rapid movement, Tracer/Box on/off; sample FPS/frametime on actual device instead of assuming improvements.
4. Toggle No Recoil / No Spread with two weapon Tools, restore numeric values and attributes after switch and unload. Server-side effects and game-specific weapons not covered by compilation.
5. Record Roblox Output, device frame time, and errors before proposing merge into `main`.

## Trust boundary
The local access key remains in public client code. Attempt counting and 25-second cooldown are only UI measures, **not server-side access control**. No server authorization was added in this audit.
