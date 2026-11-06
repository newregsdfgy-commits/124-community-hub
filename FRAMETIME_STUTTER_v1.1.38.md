# 124 Visuals v1.1.38 — frametime / microstutter mitigation

Base: v1.1.37 UI-startup-hotfix-test, commit b88f43e013bd7ccb617b537bd9882d3667e50a93.
Only changes in isolated test branch; main and rollback versions remain unchanged.

## Static bottlenecks identified
1. ESP Box and Skeleton line Instances were created en masse inside
   refreshShapes(), invoked from the camera render callback. Initial
   activation of many nearby players could allocate 4 box lines and up to
   15 skeleton lines per player in a single expensive frame.
2. Max Distance slider synchronously called both refreshESP (roster sort,
   character scanning, billboard properties) and refreshShapes (projection,
   geometry) on each effective drag update, up to about 9 times/sec.
3. Booster first-scan and streaming queues had comparatively large batches;
   even with clock slices, large batches can cause intermittent frame spikes.

## Low-risk mitigation
- Two new shape containers and at most eight new 2D lines are constructed
  on any individual refreshShapes call. Partially constructed figures are
  hidden until complete and reattempted on later draws. Existing shapes
  continue updating; 200m filter, actual ESP target limit and AIM are unchanged.
- Max Distance slider schedules via the existing coalesced queueESPRefresh
  rather than immediately sorting the player roster and drawing shapes in
  the input handler. Visual shape clipping still checks the updated distance
  on the next regular visual tick. The queue is revocable on ESP disable.
- BoosterBatch 96→64, BoosterSliceMs 0.90→0.65 ms,
  BoosterLowFpsSliceMs 0.45→0.35 ms,
  BoosterQueueBatch 48→32, BoosterQueueSliceMs 0.65→0.45 ms.
  This can slow the initial Booster completion but reduces peak work.
- No extra RenderStep callbacks, network operations, external code or
  Gameplay/ESP shader settings.

## QA
New static contracts and a Luau-executed mock of the actual shape
constructor/line-builder verify allocation caps, deferred construction
and later completion. All earlier static tests and UI-slider Luau runtime
mock remain in the workflow.

## Limitations and practical test
This is a targeted mitigation, **not proof that every microfreeze is solved**.
A Roblox client is required to profile the real frametime and network
conditions. Compare the same scene/player density/settings between versions:
FPS, stutters >50ms per 60s, 1% low FPS, ESP on/off, shapes on/off,
Booster on/off, and window open/closed. Initially, incomplete shapes may
take several frames to become fully visible: this is intentional to avoid
single-frame mass allocation.

If stutters remain with ESP and Booster both OFF, this patch may have
little effect: inspect Roblox MicroProfiler and other game scripts.
