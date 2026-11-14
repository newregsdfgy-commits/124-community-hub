# 124 Visuals v1.4.7 — AIM stability deep audit

Parent: v1.4.6, commit 258423a7e670b11825a55f1d710ee5e6f8a7179d.
Isolated branch: v1.4.7-aim-stability-deep-audit-test. Main branch unchanged.

## Reproduced/identified structural problems in v1.4.6

1. Camera turn was calculated by splitting current/goal into Euler pitch, yaw, and roll; Euler angle singularities or yaw transitions near +/-pi could cause discontinuities. In particular, Smoothness=0 directly set camera.CFrame to the goal, causing intentional instantaneous snapping.
2. Target lock could be abandoned immediately when projected part briefly moved outside lock FOV or was temporarily missing due to streaming; retargeting to a new player could then happen in one scan.
3. In prediction mode, abnormal AssemblyLinearVelocity (NaN/Inf) could reach CFrame math. Spiky velocity samples caused unstable prediction offset updates.
4. Workspace:Raycast errors were unprotected in the AIM render callback, potentially aborting a frame. Visible Check must fail closed on errors.
5. Camera/character replacement did not explicitly flush old target and prediction smoothing state. Current target validation did not check whether the part remained a descendant of the selected character.
6. No configurable pixel deadzone or target-switch stability factor, making small camera corrections near the crosshair visible as jitter.

## v1.4.7 fixes

- Local-axis yaw/pitch correction with camera.CFrame:VectorToObjectSpace, signed atan2 errors and CFrame.Angles composition. Two-axis combined angular step is capped by AimMaxTurnDegreesPerSecond and frame delta is capped at 50 ms, including Smoothness=0.
- A locked player retains identity briefly across LOS loss, FOV exit and streaming gaps. During grace windows or switching confirmation, target.blocked prevents camera motion. Lost/dead/replaced character is not held. New target must remain best for an additional confirmation interval.
- Prediction lead is limited to AimPredictionMaxStuds, rejects NaN/Inf and is filtered with frame-time-independent exponential interpolation attached to exact BasePart identity.
- Raycast API failures return not visible rather than causing a render exception or falling back to through-wall tracking.
- Camera/character changes and invalid parts trigger state reset; inactive/no-Tool camera writes remain disabled.
- New persistent AIM controls: Stability 1..5 and Deadzone 0..12 pixels, default 3 and 2; slider copy explicitly clarifies Smooth=0 is fast but bounded.

## Scope and verification

The normal 12-source bundling system, key gate, ESP 2.0, Weapons 2.0, FPS Booster, v1.4.6 Aura/Glow and cleanup are unchanged outside versioned release metadata and AIM state/UI.

CI runs source-bundle parity, release invariants, Node regression tests, official Luau parser and bytecode compiler, previous extracted Player/UI/Booster/ESP/Key regression harnesses, and new extracted AIM production callbacks under deterministic Roblox API fakes. New AIM tests exercise lock restoration, FOV grace, switching delay, LOS failure, finite prediction, speed-0 angular cap, deadzone and invalid/dead targets.

### Limits

All automated runtime tests use mocked Roblox services. They cannot confirm actual camera feeling, FPS, phone touch performance or specific game weapon support. Real client tests remain necessary before merging into main.
