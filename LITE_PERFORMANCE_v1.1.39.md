# 124 Visuals v1.1.39 LITE — Reduced modules / lower frame-load

Base commit: `9c28b3fac8f6326a77aebd62121500ab86052792` from
`v1.1.38-frametime-stutter-guard-test`.
The original v1.1.38 and `main` remain unchanged.

## Removed completely
- **Spam Chat / Chat Timer / manual chat send**: all message/timer worker functions,
  TextChatService lookups, settings, text boxes, buttons and HUD indicators.
- **Bunny Hop**: speed modification, jumping loop, rollback/snapshot logic,
  settings, UI and lifecycle references.
- **Skeleton ESP**: R6/R15 bone lists, pose/projected-point processing,
  extra GUI lines, toggle and stored setting.
- **CFG tab**: profile/preset UI, manual LEGIT/RAGE selection and reset controls.

Automatic **CUSTOM configuration persistence remains** so ordinary ESP, AIM,
Booster, and performance settings survive upgrades. Unknown keys from old
configurations are ignored; legacy presets no longer auto-load.

## Performance corrections
- **Box only**: at most four 2D lines per player, not 4+14 skeleton bones.
- **Visibility before allocation**: players behind camera do not consume
  Box GUI resources. Incomplete boxes stay hidden until the next visual draw.
- **Allocation caps** reset only inside the existing rate-limited visual draw;
  repeated UI callbacks cannot reset the quota within one rendered frame.
- **ESP toggles and old mobile sliders** use queued scans, not immediate
  full-roster sort + geometry refresh. Box and tracers clear immediately
  when switched off; drawing uses the existing visual cadence.
- **ESP event scan** skips when a periodic scan recently processed a roster.
- **Configuration saves** use one debounce worker instead of creating one
  scheduled callback per slider tick; the final value is written after a quiet
  period. Explicit cleanup still calls `flushConfig()`.

## Preserved
ESP names, health, distance, enemy filter, 2D Box, tracers, AIM, recoil,
FullBright, Booster, FOV controls, performance modes, diagnostics,
Roblox-themed GUI and right-side tabs. No user data or profile files
are deleted. Existing external HTTP loader remains branch-specific.

## Verification before testing with users
Official Luau compilation, targeted automated tests for removed features,
prior compatible regression tests and mocked Luau runtime tests for the
retained Box allocation budget, UI sliders and Booster rollback.

These tests do not establish actual FPS or absence of stutters in Roblox.
Compare same server/player density and graphics with v1.1.38 and v1.1.39.
Check p99 frametime and 1% low, with ESP/Booster independently enabled.
