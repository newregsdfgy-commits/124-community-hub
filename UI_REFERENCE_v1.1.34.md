# 124 Visuals — screenshot-inspired UI v1.1.34
Branch: `v1.1.34-reference-ui-test`
Base: v1.1.33 stability-isolation branch. Both v1.1.33 and main are untouched.

## UI-only changes
- Near-black rounded panel with 950x520 desktop layout and four sidebar tabs (ESP, Aim, Memory, Settings).
- Top search field filtering ESP rows, uptime display, reference-style status indicators, and Active pill that opens the existing dashboard.
- Replaced ESP desktop page with compact grouped controls matching the provided screenshot: ESP Settings, Max Distance / Text Border, Mod Skinn, and Visuals.
- "124 Visuals" brand in place of 403VIP; a vector Roblox tilted-square emblem replaces PUBG Mobile branding.
- Existing ESP/Box/Skeleton/Tracers/name/health/distance, ESP range, FOV circle and profile callbacks stay wired. Text Border adjusts actual ESP label stroke. The optional crosshair is a UI-only four-line mark.
- Weapon, Team ID, Enemy Count, Game Info and the skin options are **disabled/unsupported** because no matching features existed in production. Clicking tells the user; they are never represented as functioning modifications.
- Existing pages and dashboard remain accessible. Narrow/mobile displays use the original scrolling controls and four-tab bottom bar to prevent clipping.
- No remote asset, HTTP call, invented Roblox image ID, new RenderStep bind or custom chat remote.
## Verification
CI checks Luau compilation, regression tests, and exact entrypoint equality. Screenshot-level runtime appearance, DPI scaling and real device interaction require a Roblox client test before merging to main.
## Important constraints
The ESP range cap is **200 meters**, retained from working source; the 350 m label in the reference screenshot is cosmetic and was **not** adopted silently.
"Safe" is only a visual UI label copied from the provided design and is not an anti-ban guarantee.
