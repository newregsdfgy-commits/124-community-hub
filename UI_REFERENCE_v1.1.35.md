# 124 Visuals — v1.1.35 right navigation and landscape scaling

This is a **UI-only** test branch based on the v1.1.34 reference-layout
test build. `main` and v1.1.34 remain untouched.

The user-supplied screenshot sets the graphite palette, rounded cards,
subtle outlines, compact ESP switches, small pill sliders and spacing.
The user's latest instruction overrides the screenshot's navigation side:
all four sidebar tabs appear on the **RIGHT**, while each ESP row has a label
on the left and its grey/white switch on the right. Search and status pills
stay along the left/top of the content.

- Layout: 950×520 design units, 196px right sidebar, ~45:55 split
  between ESP list and right control cards.
- Floating Roblox mark and `124 Visuals` branding in the right sidebar.
- All working existing controls remain wired to existing state and save logic.
  Missing original features remain visibly unavailable, not fake toggles.
- Landscape mobile (viewport >= 480×260, aspect >=1.35) now gets the same
  950×520 screenshot design at a single uniform scale, constrained to viewport.
  Touch gestures, scrollers and sliders use Roblox AbsoluteSize input.
- Portrait mobile and undersized desktop continue to receive original
  scrollable controls instead of a clipped screenshot view.
- Existing minimize/show animation scales relative to the responsive base
  factor. Window dragging clamps using scaled visual bounds.
- The ESP gameplay distance cap remains 200m, not the screenshot's 350m.
- Status `Safe` is a screenshot-style indicator, not a guarantee against
  game moderation or restrictions.

## QA required before promotion
Run both desktop and Android landscape: open ESP, switch ESP Master/Box/
Skeleton/Tracers, drag distance and FOV sliders, minimize/reopen, rotate device
to portrait and back, select each tab, check search filtering and UI overlap,
check settings persistence and correct unload/reload. Static Luau/Node tests
cannot independently confirm screenshot-level visual parity.
