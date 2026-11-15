# 124 Visuals v1.5.4 — deep audit and bounded stability patch
Date: 2026-11-15

## Baseline and provenance
- Base branch: `v1.5.3-premium-interface-redesign-test`
- Base commit: `1ac82f682367ae39bfb0f6f88d5609d96b42347f`
- Baseline GitHub Actions runs: 43662336786 (release integrity SUCCESS), 43662336810 (premium interface CI SUCCESS).
- Patched branch: `v1.5.4-deep-audit-visibility-stability-test`. Main and v1.5.3 are unchanged.

## Findings
- UI-154-01 (fixed): `safeActivate` verified only `alive` and per-input motion. Queued `Activated` or `MouseButton1Click` callbacks could execute when their control's ScreenGui had been disabled, the page had been hidden, or the control was detached. AIM dedicated handlers already had page/GUI checks; generic controls did not.
- TEST-154-02 (documented): historical `tests/*.test.cjs` includes tests for the intentionally removed v1.1.41 reference UI and v1.1.41 loader. Running every historical test as if it applied to the current UI gives false failures. The branch CI runs the current compatible suites explicitly.
- Architecture: 12 concatenated source fragments share one lexical scope; the builder must regenerate both entrypoints exactly. Original AIM algorithm source fragment remains untouched.
- Review areas: GUI/input, startup/key ownership, Player FX/Weather, ESP, FPS Booster, Weapons, lifecycle/cleanup, source-bundle and CI boundaries. Absence of client-access evidence prevents certifying all runtime behavior.

## Change and test
- Generic `safeActivate` calls existing ancestor visibility helper for actual Roblox Instances. No callback executes through hidden pages, disabled ScreenGuis, or detached hierarchy. Synthetic table fakes retain previous behavior.
- New visibility fault injection in `tests/build-controls144-runtime.py` checks disabled screen, invisible control and successful recovery.
- New static regression `tests/VisibilityGuard154.test.cjs`.
- Bump release version/launcher/checker and create v1.5.4 workflow with current UI, Player, ESP, Booster, Key, AIM and Luau compile/runtime smoke checks.
- No changes to aim mechanics, weapons, ESP or other gameplay features.
- **Observed CI success:** release integrity run [43712640897](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43712640897) and extended Luau/UI input regression run [43712640815](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43712640815), both SUCCESS on source/test commit `cc978aaad03e733e65808edeadb3e54db975053c`.
- Extended CI verified 141/141 Node tests, real Luau parsing and bytecode compilation of Hub/Visuals/Start, 11 executable source-callback harnesses (input visibility, AIM, Weather, Player FX, ESP, Key, Booster and layout).
- Initial extended CI was red on 10 inherited v1.5.3 version/branch assertions; these expectations were corrected before the successful rerun.
- Real Roblox desktop/Android rendering, weapon behavior, touch-device experience and measured FPS are **not** verified by CI.

## Live QA still required
Desktop and Android: open/close during input, rapid page changes, delayed taps, AIM pinned and legacy switch, rain/clear transition, Booster on/off restoration, scroll and touch, respawn, clean unload and relaunch. Observe Roblox Output and client FPS, not inferred improvements.
