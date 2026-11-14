# 124 Visuals v1.4.5 — deep stability audit

Base commit: 5bfbfc1fd6a0d6459f2df91cc40cc711c0b64786 (v1.4.4). Branch: `v1.4.5-deep-stability-audit-test`. `main` is not modified.

## Confirmed defects and fixes

1. **Player Fog partial write**: a setter that mutates and then throws leaves `slot.last` unset. The next OFF discarded the snapshot instead of restoring Fog. v1.4.5 reads back the actual write, retains a recovery candidate when readback is unavailable, and reports failures without dropping ownership.
2. **Player Atmosphere partial write**: same ownership gap, with extra risk of Booster taking ownership of an incompletely modified Atmosphere. v1.4.5 claims exact Atmosphere ownership before write and records actual changes even after setter errors.
3. **Terrain grass partial write**: first-time `sethiddenproperty` error returned before `savedTerrainDecoration` was created; if setter had already mutated, rollback became impossible. v1.4.5 performs readback and retains the original when the write actually took effect or cannot be verified.
4. **UI fast physical taps**: the universal 0.38-second latch dropped intentional subsequent clicks. v1.4.5 tracks distinct InputBegan press IDs and consumes both Activated and MouseButton1Click under a single ID; legacy clients without press events retain timed duplicate protection.

## Test coverage

- Existing release integrity checks and source-bundle parity.
- Previous UI, ESP, Key, Weapons, Player and Booster regressions.
- Actual production callback extraction run with the official Luau VM: Terrain setter that mutates and throws; Fog and Atmosphere setter failure after mutation; fast consecutive physical UI clicks and duplicated Activated/MouseButton1Click.
- Official Luau parser and binary compiler for Hub.lua, Visuals.lua, Start.lua.

## Limitations

All automated tests are isolated mocks and CI, not a live Roblox client or Android rendering test. FPS, device touch delivery, and real graphics cannot be certified from CI. Do not merge to `main` before device testing.
