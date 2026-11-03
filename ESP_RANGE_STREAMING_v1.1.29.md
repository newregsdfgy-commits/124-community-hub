# 124 Community Visuals v1.1.29 — ESP range / streaming reliability

Based on v1.1.28; previous branch and main remain unchanged.

## Confirmed causes of "200m ESP disappears near 150m"
1. `BillboardGui.MaxDistance` measured the distance **from the camera**, but the main ESP selected targets based on the distance **from the local character**. A camera placed behind the character could cause names/HP/distance labels to vanish before a target reached the configured 200m player-relative range. Official Roblox docs verify the camera-based MaxDistance rule. The fix sets MaxDistance=0 (no engine distance clip); the roster scan still enforces the configured meter radius.
2. Hidden performance caps were 6 players in ECO and 12 in BALANCED, regardless of slider range. The new explicit `espMaxTargets` setting defaults to 64 and can be set between 8 and 96; performance modes no longer silently reduce this selection budget.
3. `refreshESP` previously required `Head`, `HumanoidRootPart` and `Humanoid` all at once. With partial replication/StreamingEnabled, missing any single part deleted the previous ESP and delayed displaying a target until the next 0.75–1.25 second scan. The new `espParts` uses the available Head/Torso/Root and upgrades the label Adornee once Head arrives. HP is marked unknown until Humanoid loads.
4. Join, respawn, character-part arrival/removal schedule one coalesced 60ms ESP refresh rather than always waiting for the periodic scan. The fallback polling cadence is 0.25s QUALITY / 0.35s BALANCED / 0.55s ECO.
5. A failed `updatePlayer` for one character is now isolated with pcall so other players still populate.
6. ESP diagnostic button reports eligible targets in range, rendered count, omitted by explicit cap, incomplete avatar models, and age of last scan.

## Performance and limitations
- Extended maximum of 96 Highlight/labels may use more GPU/CPU than v1.1.28's 6–12 targets. If frame rate declines, lower the explicit target cap or select fewer optional shapes. ESP shapes still have per-tier budgets of 10/18/32, with QUALITY limited to 60Hz, AUTO/ECO lower.
- StreamingEnabled decides what Instances the Roblox client actually receives. The script cannot render the position or complete avatar of a character that has **not replicated to the client at all**; the new diagnostic identifies missing rigs and the fallback handles partially present models. It does not invoke remotes or bypass engine streaming.
- Roblox Highlight currently supports up to 255 client-side instances, but each incurs render cost; this implementation intentionally caps the number well below that for performance.
- 150m in the original code is a typography breakpoint only (`EspFarDistanceMeters`), not a separate cutoff.
- No claims of FPS improvement or successful Roblox runtime execution without user/device measurements.

## Test checklist
Start `Start.lua` from the v1.1.29 branch in a fresh session. Enable ESP, set radius 200m, cap 64. Test target at 140m, 160m, 195m, 205m, with default and offset camera; 205m should be excluded based on local character position, not camera. Test 10+ nearby players, ECO/AUTO/QUALITY toggling, respawns, joining and stream-in events. Click ESP diagnostics. For unknown player positions when streaming omits a model, expect missing rig stats.

Verify 2D Box / Skeleton shape limits separately (they intentionally cap costly geometry).
Previous v1.1.28 is the rollback branch.
