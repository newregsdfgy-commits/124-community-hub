# 124 Visuals — v1.4.2 UI repair after 1237×683 screenshot

Test branch: `v1.4.2-ui-layout-repair-test` (base: `v1.4.1-deep-audit-fixes-test`). Main unchanged.

## Evidence from supplied screenshot
- The top bar contains `Поиск ESP...`, `Ready`, `00:00:09`, `Active`, while the native page heading and controls remain visible underneath. This is **not evidence of another app**: source audit identified the exact `buildReferenceMenu()` block in `src/09_misc_and_diagnostics.lua` which created those controls on the global `DragBar`.
- The legacy `ScreenshotESP` pane was hidden by `applyResponsiveLayout`, but its `ReferenceSearch`, `ReferenceSafe`, `ReferenceTimer`, and `ReferenceActive` parents were the *shared header*, so they stayed visible on all pages. It also hid `BrandTitle` and `BrandCaption` and reparented/repositioned Close and Minimize.
- Headings such as `ADVANCED` had a horizontal accent bar overlapping the first few letters.
- Large windows overused small viewports; page columns and navigation were allowed to become cramped.

## Fixes
1. **Removed the obsolete screenshot menu, not its actual features.** The legacy builder, its header search/status, clock, multiple extra widgets, dead callbacks and optional timer were deleted. The single native ESP controls remain in `src/08_ui_controls.lua`: ESP, lines, 2D Box, enemy filter, range, max targets, names, health, distance, team color, local crosshair and diagnostics.
2. **Restored the original owned header**: title/subtitle are visible and close/minimize buttons stay inside the actual `DragBar`; no legacy reparenting.
3. **Safer size math**: desktop margins 34px horizontally / 38px vertically in viewport coordinates; mobile 16px / 18px. Desktop preference 930×505, otherwise reduce as required. Touch landscape keeps 950×520 reference coordinate system but scales down to respect margins.
4. **Readable columns**: fewer than 720px of usable content forces a single native scrollable column; wide displays retain two approximately 350px+ columns. For the supplied 1237×683 desktop screenshot, the size model yields 930×505 with generous margins; actual Roblox UI scaling remains engine-dependent.
5. **Navigation**: five visible sections (ESP, Aim, Player, Misc, Memory), compact 49px desktop tabs, 6px list padding, reduced unused bottom reservation. Short screens can still scroll.
6. **Heading collision**: all sections have a vertical accent bar with 18px of left title padding; labels truncate rather than paint over the edge.
7. **Old duplicate window guard**: only existing `ScreenGui` instances with the exact known name `Army124CommunityVisualsGUI` are destroyed before creating the new instance. No broad PlayerGui cleanup or foreign HUD deletion.
8. **UI audit fixed**: now expects five tabs, not four; Player title/subtitle included.

## Quality gates
- Deterministic build from 12 source fragments into identical Hub.lua/Visuals.lua.
- `tools/verify_release.py` exercises screenshot resolution and many desktop/mobile cases with updated geometry rather than stale fixed 950×520 expectations.
- `tests/UI142Layout.test.cjs` asserts exact legacy overlay removal, native ESP control preservation, no unsafe GUI sweeping, readable section headings, 5-section nav and full module integrity.
- `tests/build-ui142-runtime.py` extracts actual production `windowMetrics` Luau code and runs 11 deterministic viewport cases, including 1237×683.
- `.github/workflows/v142-ui-ci.yml` runs source checks, regression suites, official Luau compiler on Hub.lua/Visuals.lua/Start.lua and actual isolated Player/Booster/ESP/Key and viewport functions.

## Not yet verified
No live Roblox renderer or screenshot comparison of the rebuilt UI has been run here. A pass in CI does not prove every display scale, executor, OS DPI setting or touch gesture. If the overlaid `Поиск ESP` bar remains visible in a *fresh session* with v1.4.2, capture Roblox PlayerGui children and the loaded branch/version: that would indicate another script instance not participating in the current cleanup.

Do not merge into main until visual checking on Roblox client: open Aim / ESP / Player, resize from 1237×683 to 950×600 and phone landscape, scroll both columns, drag/close/minimize, verify touch activation, inspect for duplicate UI windows.
