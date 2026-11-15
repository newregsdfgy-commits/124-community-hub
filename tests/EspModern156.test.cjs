"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const read=p=>fs.readFileSync(p,"utf8");
const tracker=read("src/03_esp_tracker.lua");
const overlays=read("src/07_esp_overlays.lua");
const cfg=read("src/00_config.lua");
const ui=read("src/08_ui_controls.lua");
const hub=read("Hub.lua");
const visuals=read("Visuals.lua");
const launcher=read("Start.lua");
test("v1.5.6 entrypoints, launcher and visual-only migration",()=>{
  assert.equal(hub,visuals);
  assert.ok(hub.includes('Version = "1.5.6"'));
  assert.ok(launcher.includes("v1.5.6-modern-esp-visual-redesign-test/Visuals.lua"));
  assert.match(tracker,/local function createRender\(player, character, head\)/);
  assert.match(tracker,/local function updatePlayer\(player, myRoot\)/);
  assert.match(overlays,/syncEspVisuals = function\(\)/);
});
test("new Tactical ESP chips preserve all independent label controls",()=>{
  for(const value of ["Army124ESPIdentity","Army124ESPHealthBadge","Army124ESPDistanceBadge",
      "HpTrack","HpFill","TeamAccent"]) assert.ok(tracker.includes(value),value);
  for(const field of ["item.nameChip","item.healthChip","item.distanceChip",
     "item.healthFill","item.identityBorder","item.identityRail"]) assert.ok(tracker.includes(field),field);
  assert.match(tracker,/setIfDifferent\(item\.nameChip, "Visible", state\.names\)/);
  assert.match(tracker,/setIfDifferent\(item\.healthChip, "Visible", state\.health\)/);
  assert.match(tracker,/setIfDifferent\(item\.distanceChip, "Visible", state\.distance\)/);
  assert.match(tracker,/math\.clamp\(hum\.Health \/ maxHp, 0, 1\)/);
  assert.match(tracker,/UDim2\.new\(hpFraction, 0, 1, 0\)/);
  assert.match(tracker,/state\.names and \(hasMeta and CONFIG\.EspLabelHeight or 25\) or 21/);
  assert.match(tracker,/setIfDifferent\(item\.billboard, "Adornee", head\)/);
  assert.match(tracker,/setIfDifferent\(item\.highlight, "OutlineColor", color\)/);
});
test("corner-box replaces four full edges with eight re-used partial segments",()=>{
  assert.match(overlays,/local function drawCornerBox\(item, top, bottom, thickness, color\)/);
  assert.match(overlays,/ensureShapeLines\(item, "box", 8\)/);
  assert.equal((overlays.match(/setLine\(item\.box\[\d+\]/g)||[]).length,8);
  assert.match(overlays,/drawCornerBox\(item, top, bottom, state\.espLineThickness, getPlayerColor\(player\)\)/);
  assert.match(cfg,/ShapeNewLinesPerDraw = 12/);
  assert.match(overlays,/local budget = tier == "ECO"/);
  assert.match(overlays,/if state\.performanceGuard and perfCounters\.guard\.level == 2/);
});
test("original ESP switches, team colors, range, tracer and cleanup remain",()=>{
  for(const flag of ["esp","tracers","espBox","names","health","distance",
    "teamColors","espEnemyOnly","espRangeMeters","espMaxTargets","espColorPreset"])
      assert.ok(ui.includes('"'+flag+'"')||tracker.includes('state.'+flag),flag);
  for(const label of ['"ESP подсветка"','"Линия над игроками"','"2D Box"','"Имена"',
    '"Здоровье"','"Дистанция"','"Цвет команд"']) assert.ok(ui.includes(label),label);
  assert.match(overlays,/local source = Vector2\.new\(viewportSize\.X \* 0\.5, 12\)/);
  assert.match(overlays,/clearTracers = function\(\)/);
  assert.match(overlays,/local function clearShapes\(\)/);
  assert.match(tracker,/local function deleteRender\(player\)/);
  assert.match(tracker,/local function refreshESP\(\)/);
  assert.match(tracker,/local function bindLocalEspCharacter\(character\)/);
});
test("new surfaces remain low-cost and no new per-player frame connections",()=>{
  assert.match(cfg,/EspFillTransparency = 0\.94/);
  assert.match(cfg,/EspLabelWidth = 176/);
  assert.doesNotMatch(tracker,/RenderStepped:Connect|Heartbeat:Connect|task\.spawn/);
  assert.doesNotMatch(overlays,/RenderStepped:Connect|Heartbeat:Connect|task\.spawn/);
  assert.match(overlays,/while #lines < count and shapeNewLinesLeft > 0 do/);
});
