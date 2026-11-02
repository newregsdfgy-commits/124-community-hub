# v1.1.20 Performance Budget — test branch

Base: v1.1.19-community-visuals-ui-test. Main remains unchanged.

- Event-maintained player roster shared by AIM, ESP, Air Watch, Booster player registration.
- Cache validated Head / HumanoidRootPart / Humanoid for expensive 2D ESP frames.
- Balanced ESP 24 Hz; ECO 12 Hz; AUTO caps at 12 Hz below 42 FPS and 8 Hz below 30 FPS. AIM unchanged.
- FPS scheduler retains fractional time for more stable intervals.
- Dashboard bars painted only once per fresh FPS sample, not twice.
- Tracer position, angle, size and visibility avoid unchanged GUI writes.

Risks and checks:
- Swap-delete changes roster order after removal. Nearest ESP selection is sorted. Air Watch's cursor rotates.
- Stale character parts are hidden until ESP refresh; camera updates remain unaffected.
- CI: node regression tests and official Luau compile. Real-game FPS gains require comparative measurement.
- Test both Android Delta and PC Xeno with same server/settings, compare average FPS and 1% low, enable shapes and streaming while observing FPS drops.
