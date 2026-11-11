# 124 Visuals — Player Visuals v1.4.0 (test release)
Date: 2026-11-12
Base: `v1.3.1-deep-audit-stability-test`
Branch: `v1.4.0-player-visuals-test`
Main: unchanged.

## Delivered
- New **Player** navigation tab in Purple Neon UI 2.0, still scrollable on Android portrait and landscape.
- **Aura:** Local `Attachment` + one `ParticleEmitter` on the current HumanoidRootPart. Four colors (PURPLE/CYAN/GOLD/GREEN), five bounded intensity levels, rebinds on character respawn / late Root streaming.
- **Glow:** Local `Highlight` with Occluded depth and local `PointLight` on the same root. Uses same player color/intensity; does not edit materials, collision, health, WalkSpeed or other players.
- **Weather:** CLEAR (restores original weather), FOG, RAIN, NIGHT (color filter, does not set ClockTime). Rain is a lightweight 24-streak client ScreenGui at ~18 Hz, not server precipitation. ColorCorrectionEffect adds per-preset grading.
- **Environment tint:** independent own ColorCorrectionEffect with VIOLET/CYAN/WARM/GREEN and intensity 0-100%; no terrain recoloring.
- Manual reset button and read-only diagnostic status. All four toggles default OFF and are disabled on automatic profile load. Color and numeric choices persist via existing validated CUSTOM profile.
- New `src/05_player_visuals.lua` module placed before UI startup; 12 ordered source modules compile to identical Hub.lua/Visuals.lua. Start.lua points to v1.4.0.
- Explicit `playerFX.shutdown` in startup abort and normal shutdown, status tracked through existing retryable env.ARMY124_RECOVERY. No new uncontrolled background loop.

## Compatibility and restoration
- Weather owns only its own post-effects and the few properties it actually alters. Latest external game updates are respected if they differ from last local write.
- A critical Roblox API nuance: `Lighting.FogStart/FogEnd/FogColor` are ignored/hidden while Lighting contains `Atmosphere`. The controller therefore modifies an **existing** Atmosphere's `Density`, `Haze`, `Color`, `Decay` when present and restores it carefully; otherwise it uses Fog values.
- Atmosphere instance is never deleted. Existing Atmosphere insertion/removal is followed using event listeners, not frame polling.
- FPS Booster protects the two owned ColorCorrectionEffects and an actively weather-controlled Atmosphere, while continuing to optimize unrelated effects.
- Combined automatic hot-reload and manual unload restore owned weather attributes, destroy rain GUI and disconnect its render callback, delete aura/glow, and preserve retryable snapshots if restoration fails.

## Quality and validation
- `python3 tools/build_visuals.py --check`: byte-for-byte integrity of 12 modules and both generated entrypoints.
- `python3 tools/verify_release.py`: base 60 assertions including version, launcher, UI, key, ESP, spread, integrity and viewport models.
- `node --test tests/EspKeyArchitecture130.test.cjs tests/Weapons2Compatibility.test.cjs tests/FullAudit131.test.cjs tests/PlayerVisuals140.test.cjs`: 36 previous focused regressions + 14 Player-specific tests.
- `tests/build-131-runtime-audit.py`: actual ESP/Key callbacks executed with fake local Roblox clocks.
- `tests/build-player140-runtime.py`: actual Player Lua controller executed in Luau with deterministic stand-ins for signals, characters, Lighting, Rain, Atmosphere, ColorCorrection and owned Instances; asserts respawn, toggle, external weather update and cleanup.
- `.github/workflows/v140-ci.yml`: builds official Luau compiler and CLI; parses/compiles Hub.lua, Visuals.lua, Start.lua; runs both isolated behavior suites.
- **The compiler and simulations are not a real Roblox/Android runtime.** Before production, test player respawns, dark maps, game with/without Atmosphere, FPS Booster in all modes, performance impact on a phone, portrait/landscape and app-specific UI conflicts.

## Known constraints
- Existing `Highlight` rendering may be restricted when a game uses many simultaneous Highlights; PointLight is separate.
- Some game scripts continuously impose lighting values. The weather module preserves newer external values on rollback, but local and game visual effects can compete; no claim of universal compatibility.
- Client effects are visible only to the local user, not other players.
- No server key authorization was added. Key System remains local and cannot secure a public client script.
- None of these changes affects the actual server weather or time of day.
