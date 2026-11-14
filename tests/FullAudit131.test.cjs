"use strict";
const assert = require("node:assert/strict");
const test = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "..");
const read = name => fs.readFileSync(path.join(root, name), "utf8");
const esp = read("src/03_esp_tracker.lua");
const gate = read("src/01_access_gate.lua");
const overlay = read("src/07_esp_overlays.lua");
const frame = read("src/10_run_and_cleanup.lua");
const config = read("src/00_config.lua");
const hub = read("Hub.lua"), visuals = read("Visuals.lua"), start = read("Start.lua");

test("compiled release matches version and 12 modules", () => {
  assert.match(config, /Version = "1\.4\.9"/);
  assert.match(start, /v1\.4\.9-legacy-aim-controls-weather-fix-test\/Visuals\.lua/);
  assert.match(start, /Version = "1\.4\.9"/);
  assert.equal(hub, visuals);
  const names = ["00_config", "01_access_gate", "02_state_and_services",
    "03_esp_tracker", "04_lighting_and_booster", "05_weapons_and_recoil", "05_player_visuals",
    "06_gui_runtime", "07_esp_overlays", "08_ui_controls",
    "09_misc_and_diagnostics", "10_run_and_cleanup"];
  assert.equal(names.map(x => read("src/" + x + ".lua")).join(""), hub);
});

test("local respawn hides instead of destroying all ESP overlays", () => {
  const position = esp.indexOf("if not myRoot then");
  const end = esp.indexOf("-- Рисуем ближайших", position);
  const block = esp.slice(position, end);
  assert.ok(position > 0 && end > position);
  assert.match(block, /item\.highlight\.Enabled = false/);
  assert.match(block, /item\.billboard\.Enabled = false/);
  assert.match(block, /item\.tracer\.Visible = false/);
  assert.doesNotMatch(block, /deleteRender\(player\)/);
});

test("local root loss hides tracers without destroying their instances", () => {
  const begin = overlay.indexOf("if not myRoot then");
  const end = overlay.indexOf("local radiusStuds", begin);
  const block = overlay.slice(begin, end);
  assert.ok(begin > 0 && end > begin);
  assert.match(block, /item\.tracer\.Visible = false/);
  assert.doesNotMatch(block, /clearTracers\(\)/);
});

test("urgent scheduler coalesces latest events and skips superseded full scans", () => {
  assert.match(esp, /espUrgentDirtyAt = os\.clock\(\)/);
  assert.match(esp, /lastScanAt >= espUrgentDirtyAt/);
  assert.match(esp, /espUrgentQueued = true/);
  assert.match(esp, /urgentSkipped/);
});

test("session shutdown invalidates ESP timers and watcher ownership", () => {
  assert.match(esp, /espRefreshGeneration = espRefreshGeneration \+ 1/);
  assert.match(esp, /espUrgentQueued = false/);
  assert.match(esp, /espUrgentDirtyAt = -math\.huge/);
  assert.match(esp, /bindLocalEspCharacter\(nil\)/);
});

test("no ESP 2D features means no camera CFrame sampling", () => {
  const begin = frame.indexOf("perfCounters.espVisual.frame = function(dt)");
  const end = frame.indexOf("local motion = perfCounters.espVisual", begin);
  const block = frame.slice(begin, end);
  assert.match(block, /if not state\.tracers and not state\.espBox then/);
  assert.match(block, /motionFrame = nil/);
  assert.doesNotMatch(block, /camera\.CFrame/);
});

test("key decision is latched before async response notification", () => {
  assert.match(gate, /resolvedValue = accepted == true/);
  assert.match(gate, /if completed then\s*accepted = resolvedValue\s*else\s*accepted = response\.Event:Wait\(\)/);
  assert.match(gate, /screen\.AncestryChanged:Connect/);
  assert.match(gate, /screen\.Destroying:Connect/);
});

test("Android duplicate return cannot overwrite a wrong-key message", () => {
  const a = gate.indexOf("local function tryUnlock()");
  const b = gate.indexOf("submit.Activated:Connect(tryUnlock)", a);
  const block = gate.slice(a, b);
  assert.match(block, /if candidate == "" then[\s\S]*?KeySubmitDedupSeconds/);
  assert.match(block, /lastSubmitAt = now/);
  assert.ok(block.indexOf("lastSubmitAt = now") > block.indexOf('if candidate == "" then'));
  assert.match(gate, /input\.ReturnPressedFromOnScreenKeyboard/);
});

test("missing key and aborted screen stay fail closed", () => {
  assert.ok(gate.indexOf("if not ok or not accepted then") < gate.lastIndexOf("authorized"));
  assert.match(gate, /screen\.Destroying:Connect\(function\(\) resolve\(false\) end\)/);
  assert.match(gate, /cancelArmedAt <= CONFIG\.KeyCloseConfirmSeconds/);
});

test("AIM, Weapons, booster, profile and GUI systems retained", () => {
  for(const token of [
    "local function aimFrame(dt)", "local recoil = (function()",
    "function controller.restoreSpread()", "controller.diagnostics = function()",
    "function boosterPro.restoreGraphicsSliced(",
    "local function refreshESP()", "PURPLE NEON 2.0",
    "local function applyResponsiveLayout()", "cleanup = function(safeStop)",
    "env.ARMY124_CLEANUP = cleanup"
  ]) assert.ok(hub.includes(token), token);
});
