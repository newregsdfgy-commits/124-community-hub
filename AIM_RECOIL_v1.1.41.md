# 124 Visuals v1.1.41 — AIM / Control Recoil reliability

Source: v1.1.40 stability-frametime hotfix. Separate test branch
`v1.1.41-aim-recoil-stability-test`, no changes to `main`.

## AIM changes
- Validate that the first named rig part is a BasePart before selecting it;
  malformed, unstreamed R15 names no longer shadow R6/Torso fallbacks.
- Target Lock tolerates a **0.12s** intermittent LOS miss. During this
  grace interval the locked target is marked `blocked` and **camera movement
  stops**, so this does not enable aiming through a wall. It reacquires the
  same target when visible again; a sustained obstruction releases the lock.
- Visible Check scans at most eight screen-closest candidate players per
  interval to limit camera-frame raycast spikes on crowded servers.
  This cap may defer visible targets when more than eight nearer candidates
  are occluded: it is a deliberate performance tradeoff.
- Prediction is limited to 10 studs to avoid extreme extrapolation caused
  by unusual AssemblyLinearVelocity readings.
- In Smooth modes, a long frame is capped to 50ms of interpolation and
  360 degrees/second of camera rotation. The user's Smooth 0 / maximum
  behavior is unchanged.
- Recoil detection and game-state tracking are untouched except for the
  explicit controller arbitration below.

## Control Recoil changes
- Every actual Tool.Activated pulse refreshes the firing watchdog.
  If an automatic weapon only fires Activated once and fails to fire a
  Deactivated event, the 6-second fallback still ends compensation.
- AIM holds exclusive camera ownership while its mouse, touch or key aiming
  is active, including when target acquisition briefly fails. No competing
  recoil write in the same render pass.
- A max 120-degree/s correction rate (and preexisting 1.6-degree/frame cap)
  avoids large per-frame recoil jumps on 120/144+Hz devices.
- The force slider 0–100% remains unchanged, default 75%; without the
  equipped Tool, a shot signal or supported camera frame, the feature
  must not write CFrame. New diagnostics expose last local correction.
- No networking, RemoteEvents, aim-through-wall bypasses or added
  RenderStepped handlers.

## Validation and limitations
Run official Luau parse + compilation, existing regression tests, and
new executable Luau mocks for real extracted targetPart, predictedPoint,
findAimTarget, markRecoilShot and recoilFrame. Mock tests cover LOS loss,
candidate bound, malformed rigs, 60/144Hz recoil clamps, exclusive camera
ownership, repeated firing and no-Tool safety.

This is not a Roblox in-game or specific weapon integration test. Game
weapons can use custom camera recoil not represented by Tool.Activated;
local camera compensation cannot guarantee actual ballistic accuracy.
Compare with v1.1.40 on the same server, weapon and FPS setting.

Rollback: v1.1.40 test branch and main are unchanged.
