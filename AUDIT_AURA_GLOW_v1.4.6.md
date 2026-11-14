# 124 Visuals v1.4.6 — Ultra Aura & Glow audit

Base: validated v1.4.5 (`c5bfe39c`). Test branch: `v1.4.6-ultra-aura-glow-test`. Main unchanged.

## Production changes
- Three bounded particle layers: saturated sparkles at the waist, translucent volumetric haze, and small upper-body highlights on a second attachment.
- The existing occluded Highlight remains unique to the local character, with stronger silhouette and brighter outline. Independent Glow controls one no-shadows PointLight. Aura alone still provides its own outline.
- Intensity 1–5 now changes particle sizes, layer rates and PointLight intensity. Maximum ULTRA budget: 58 + 28 + 16 = 102 particles/sec, not three unlimited emitters.
- Quality choice AUTO/ECO/ULTRA. AUTO enters ECO below 38 measured FPS, restores ULTRA at 52+ FPS; ECO scales total particle emissions to approximately 42%. This is a budget, not a guarantee of device FPS.
- Optional glow pulse uses a single Heartbeat handler, updating at most every 0.14 seconds. No permanent render-step effect worker. Previous-generation callbacks cannot tear down a newer animation session.
- No additional game-server writes, other-player effects or changes to ESP, weapons, weather, profiles or key access. Existing Purple Neon UI and slider remain.

## Cleanup and coverage
- All new emitters and both attachments are registered as locally owned before parenting and destroyed on disable, respawn, late root removal and unload.
- The dedicated Luau runtime harness exercises real production PlayerFX callbacks with fake Roblox services, including AUTO hysteresis, manual quality override, fixed pulse, multiple syncs without duplicates, respawn generation guard and old PlayerFX weather rollback cases.
- CI additionally checks module parity, release integrity, Node regression suites and official Luau parse and bytecode compilation.

## Honest limitation
CI is not a real Roblox client or a mobile GPU benchmark. Appearance, actual FPS, executor support and input behaviour still need testing in the target game before merging to main.
