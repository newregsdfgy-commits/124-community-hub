# 124 Visuals v1.5.8 — full source audit and targeted stability fixes

Date: 2026-11-15
Base: v1.5.7 `6005ed702a0ca03ec16621e3f4e73e1e46ebb62c`
Patch branch: `v1.5.8-full-audit-stability-fix-test`

## Audit coverage

Inspected all 12 interdependent Luau source modules (load + Key UI, state and
configuration, ESP tracker/render and 2D box/tracers, FPS Booster and Lighting/
Terrain restoration, Player aura/weather, recoil/No Spread, UI input and
responsive layout, Movement/Speed/Noclip/Fly, local music, diagnostics and
startup/teardown). Inspected active v1.5.7 GitHub Actions, preserved the
current official Luau compilation and prior regression harnesses.

This is a **source inspection plus automated tests**, not a claim that every
game-specific or Android runtime defect can be found without a client.

## Confirmed bugs and fixes

### AUDIT-158-01 — ESP long-range frame-rate budget bypass
`perfCounters.espVisual.frame` first limited visual updates at long-range
350–699 m to 18 Hz and 700+ m to 10 Hz in AUTO/BALANCED, then unconditionally
restored >=36 Hz whenever the camera was turning and client FPS was high.
On large ranges, the intended bounded workload was violated, risking jitter.
**Fixed:** motion boost only applies below long-range threshold, or when
the user explicitly selected QUALITY (which already targets 60Hz).
Performance Guard and ECO still have precedence. Range and player inclusion
remain unchanged.

### AUDIT-158-02 — One denied Noclip part disables unrelated Movement modes
`movement.recordPart` and the 30Hz Noclip recheck directly wrote
`BasePart.CanCollide` with no per-instance isolation. A protected/streaming
instance raising an exception in Noclip propagated to the main
`movement.step` error handler, which called `movement.disableAll`,
switching **Speed, Noclip and Fly** OFF together.
**Fixed:** protect per-part CanCollide reads/writes, check actual readback
(including a setter that changes the property then throws), preserve
pre-write collision baseline, retry accessible parts independently and
prune destroyed snapshots. An inaccessible accessory can remain collidable,
but no longer disables unrelated movement controls.

## Changes deliberately avoided

- All v1.5.7 Compact ESP badges / distance tiers (90/155m) remain the same.
- AIM targeting / weapons mechanics, state and files, key gate, profile
  format, Booster ownership, Player aura, weather and music are untouched.
- No artificial performance claims; the long-range limit reduces rendering
  frequency but does not imply a measured FPS improvement.
- Existing historical legacy tests remain archived, excluded from the
  version-specific production CI.

## Verification suite

- `tools/build_visuals.py --check` and `tools/verify_release.py`
- Current v1.5.7 suites preserved; added `tests/DeepAudit158.test.cjs`
  to assert source invariants and explicit version alignment.
- `tests/build-stability158-runtime.cjs` extracts **actual production Luau**
  `movement.recordPart`, Noclip retry loop and ESP motion boost logic.
  It tests denied CanCollide setters, post-write exceptions, independent
  accessories, destroyed snapshot pruning, near/350/700/1000m AUTO
  motion, explicit QUALITY, ECO, low FPS and Guard.
- Both bundled entrypoints rebuilt identically from twelve modules;
  `Start.lua` pinned to v1.5.8.
- **Verified GitHub Actions success on implementation commit `b121429e4fe98558157a1bafc4d94638aca74c21`:**
  - Release integrity: [run 43721490644](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43721490644) — SUCCESS.
  - Full regression: [run 43721490709](https://github.com/newregsdfgy-commits/124-community-hub/actions/runs/43721490709) — SUCCESS.
  - 161/161 Node regression tests, 0 failures.
  - Official Luau parser and binary compiler passed Hub.lua, Visuals.lua, Start.lua.
  - Source-extracted Luau fault injection passed denied/mutating CanCollide writes, independent-part retry, destroyed snapshot cleanup, 10/18 Hz long-range ESP camera-motion budgets, explicit QUALITY, ECO and Guard.
  - No real Roblox/Android GUI testing or measured FPS was performed.

## Manual regression checklist (not tested here)

Desktop + Android, use the same user screenshot scene if possible.
Check ESP 90/155m transitions and 700–1000m camera turning, Speed+Fly
while one locked CanCollide part exists, Noclip on/off rollback,
respawn/streaming, Weather and full script cleanup, UI AIM button click,
FPS Booster disable/restore and output warnings.

Do not merge the test branch into main until live client QA passes.
