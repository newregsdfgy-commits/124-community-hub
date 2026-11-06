"use strict";
const assert = require("node:assert/strict");
const test = require("node:test");
const fs = require("node:fs");
const src = fs.readFileSync("Visuals.lua", "utf8");

function setting(name) {
  const m = src.match(new RegExp(name + "\\s*=\\s*(\\d+)"));
  assert.ok(m, "missing numeric setting " + name);
  return Number(m[1]);
}

// Model-based test: tests expected state transitions and source guard contracts.
// Does NOT execute Luau or Roblox APIs.
function modelGuard(sequence, initialLevel = 0) {
  let level = initialLevel, changed = -setting("GuardMinStepSeconds");
  let low = 0, critical = 0, good = 0, trace = [];
  for (let t = 0; t < sequence.length; t++) {
    const {fps, spikes = 0} = sequence[t];
    low = fps < setting("GuardLowFps") || spikes >= 3 ? low + 1 : 0;
    critical = fps < setting("GuardCriticalFps") || spikes >= 6 ? critical + 1 : 0;
    good = fps >= setting("GuardRecoveryFps") && spikes === 0 ? good + 1 : 0;
    let next = level;
    if (t + 1 - changed >= setting("GuardMinStepSeconds")) {
      if (level < 2 && critical >= setting("GuardLowSamples")) next = 2;
      else if (level < 1 && low >= setting("GuardLowSamples")) next = 1;
      else if (level > 0 && good >= setting("GuardRecoverSamples")) next = level - 1;
    }
    if (next !== level) {
      level = next; changed = t + 1; low = critical = good = 0;
    }
    trace.push(level);
  }
  return trace;
}

test("release is isolated to v1.1.36 test branch", () => {
  assert.match(src, /Version\s*=\s*"1\.1\.36"/);
  assert.match(src, /PlaceId\s*=\s*18537079992/);
  assert.match(src, /xpcall\(initializeHubUI/);
  assert.match(src, /env\.ARMY124_CLEANUP = abortPartialHub/);
});
test("new modules have safe defaults and explicit toggles", () => {
  assert.match(src, /performanceGuard\s*=\s*false/);
  assert.match(src, /moduleCpuMonitor\s*=\s*false/);
  assert.match(src, /lazyLoading\s*=\s*true/);
  for (const name of ["Performance Guard", "Module CPU Monitor", "Lazy Loading"]) {
    assert.ok(src.includes("addToggle(pages.MISC, \"" + name + "\""), name);
  }
  assert.match(src, /state\.moduleCpuMonitor = false/);
});
test("visual guard does not mutate AIM and can recover", () => {
  const guard = src.slice(
    src.indexOf("function perfCounters.guard.update"),
    src.indexOf("function perfCounters.guard.description")
  );
  assert.match(guard, /g\.level, g\.changed\s*=/);
  assert.doesNotMatch(guard, /state\.aimbot\s*=/);
  assert.doesNotMatch(guard, /state\.performanceMode\s*=/);
  assert.match(src, /local function visualPerfTier\(\)/);
  assert.match(src, /GuardEspMaxL2\s*=\s*4/);
  assert.match(src, /GuardVisualHzL2\s*=\s*8/);
  assert.match(src, /g\.level - 1/);
});
test("Guard ignores a transient dip but reacts to sustained low FPS", () => {
  assert.deepEqual(modelGuard([{fps: 30}, {fps: 60}, {fps: 60}]), [0,0,0]);
  assert.equal(modelGuard(Array.from({length: 4}, () => ({fps: 35}))).at(-1), 1);
});
test("Guard reacts to repeated 50ms+ spikes, not a single one", () => {
  assert.equal(modelGuard([{fps: 60, spikes: 4}, {fps: 60, spikes: 0}, {fps: 60, spikes: 4}]).at(-1), 0);
  assert.equal(modelGuard(Array.from({length: 4}, () => ({fps: 60, spikes: 7}))).at(-1), 2);
});
test("Guard recovery is gradual, with minimum dwell", () => {
  const lows = Array.from({length: 3}, () => ({fps: 20}));
  const good = Array.from({length: 28}, () => ({fps: 62}));
  const trace = modelGuard([...lows, ...good]);
  assert.equal(trace[2], 2);
  assert.equal(trace[12], 2);
  assert.equal(trace.at(-1), 0);
});
test("CPU measurement is opt-in and samples six requested modules", () => {
  assert.match(src, /if not state\.moduleCpuMonitor then return fn\(\.\.\.\) end/);
  for (const label of ["AIM", "Recoil", "ESP Draw", "ESP Scan", "Booster Q", "HUD"]) {
    assert.ok(src.includes('"' + label + '"'), label);
  }
  assert.match(src, /perfCounters\.cpu\.wrapped\.ESPDraw/);
});
test("Lazy Loading defers shape and tracer roots, preserving FOV ring", () => {
  assert.match(src, /function perfCounters\.lazy\.ensureTracer\(\)/);
  assert.match(src, /function perfCounters\.lazy\.ensureShapes\(\)/);
  assert.match(src, /perfCounters\.lazy\.ensureTracer\(\)/);
  assert.match(src, /perfCounters\.lazy\.ensureShapes\(\)/);
  assert.match(src, /Name = "Army124FovV100"/);
  assert.match(src, /bootRoots = \{\}/);
});
test("frametime history remains bounded and includes long stalls", () => {
  assert.match(src, /FrameTimeWindow\s*=\s*240/);
  assert.match(src, /math\.min\(dt \* 1000, 10000\)/);
  assert.match(src, /ft\.spikesThisSecond = ft\.spikesThisSecond \+ 1/);
  assert.match(src, /worstSum = worstSum \+ ordered\[i\]/);
});
