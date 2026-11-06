# 124 Visuals v1.1.36 — Graphite polish / UI interaction reliability

## Scope
UI-only test branch based on v1.1.35 (right sidebar and screenshot-like design).
No change to main, v1.1.35, gameplay values, ESP range, AIM target logic,
Booster graphics algorithms, network operations or feature permissions.

## Visual refinements
- Restrained gradient top bar and right-hand graphite cards, subtle outlines
  and hover responses only on mouse events; no perpetual visual effects
- Premium rounded grey/white switches, softened contrast, cleaner labels
- Current actual version shown in sidebar (instead of hard-coded v1.0)
- Status pill reads "Ready", not an anti-ban "Safe" guarantee
- Clear "PREVIEW" for screenshot-only unsupported skin controls
- Empty ESP-search feedback when the filter finds no rows

## Reliability changes
- Scroll-hit test checks every ancestor (including ScreenGui.Enabled) instead
  of just direct parent, avoiding touch suppression by invisible scrollers
- Touch identities are released on InputEnded
- Screenshot ESP sliders distinguish horizontal drag from vertical scrolling;
  touch-down alone does not change values
- An outstanding slider drag is finalized on pointer-up, tab switch and window
  resize/orientation change; it cannot remain latched in another page
- While dragging, expensive visual callbacks are limited to approx. 9/sec and
  final snapped value is always applied at release
- Failed slider callbacks revert to their last committed state and report error
- The reference ESP switches roll their state back if a refresh errors, instead
  of silently saving an inconsistent state
- Existing mobile portrait fallback, landscape scaling, UI cleanup, profile
  storage and feature handler identifiers are preserved

## Validation limits
GitHub CI checks Luau parse+compile and regression/static/source-contract
tests with isolated mocked failures. This does not prove visual pixel parity or
runtime device interaction without testing on a Roblox client.

## Suggested in-game QA
1. PC: open ESP, switch 10 times, drag distance rapidly and release
2. Mobile: scroll ESP list vertically while touching near slider; verify no
   unintended changes; drag horizontally deliberately
3. Change orientation while dragging, change tabs, minimize/reopen
4. Search for unknown text and clear it; verify labels restore
5. Load profiles and reopen UI; confirm game and UI states match
6. Compare FPS with menu open/closed and baseline v1.1.35
