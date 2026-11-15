"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const read=x=>fs.readFileSync(x,"utf8");
const tracker=read("src/03_esp_tracker.lua");
const overlay=read("src/07_esp_overlays.lua");
const config=read("src/00_config.lua");
const ui=read("src/08_ui_controls.lua");
const launcher=read("Start.lua");
const hub=read("Hub.lua");
test("v1.5.9 compact release and exact branch-pinned loader",()=>{
 assert.equal(hub,read("Visuals.lua"));
 assert.match(hub,/Version = "1\.5\.9"/);
 assert.ok(launcher.includes("v1.5.9-esp-independent-range-controls-test/Visuals.lua"));
});
test("billboard bounds reduced by at least a third in each dimension",()=>{
 assert.match(config,/EspLabelWidth = 116/);
 assert.match(config,/EspLabelHeight = 29/);
 assert.ok(116/176 <= 0.68 && 29/49 <= 0.60);
 assert.match(tracker,/StudsOffsetWorldSpace = Vector3\.new\(0, 1\.95, 0\)/);
 assert.match(tracker,/Name = "Army124ESPIdentity", Size = UDim2\.new\(1, 0, 0, 16\)/);
 assert.match(tracker,/Name = "Army124ESPHealthBadge"[\s\S]*?0, 11/);
});
test("distance tiering hides unnecessary distant labels, never target tracking",()=>{
 assert.match(config,/EspCompactDetailsMaxMeters = 90/);
 assert.match(config,/EspCompactNameMaxMeters = 155/);
 assert.match(tracker,/local function compactEspFlags\(meters, namesEnabled, healthEnabled, distanceEnabled\)/);
 assert.match(tracker,/compactEspFlags\(meters, state\.names, state\.health, state\.distance\)/);
 assert.match(tracker,/item\.lastCompactVisibility ~= visibilityMask/);
 assert.match(tracker,/setIfDifferent\(item\.billboard, "Enabled", visibilityMask ~= 0\)/);
 assert.match(tracker,/setIfDifferent\(item\.nameChip, "Visible", showName\)/);
 assert.match(tracker,/setIfDifferent\(item\.healthChip, "Visible", showHealth\)/);
 assert.match(tracker,/setIfDifferent\(item\.distanceChip, "Visible", showDistance\)/);
 assert.match(tracker,/local function refreshESP\(\)/);
 assert.match(tracker,/local function espLimit\(\)/);
});
test("HP numeric label is short and original proportional bar remains",()=>{
 assert.match(tracker,/setIfDifferent\(item\.healthLabel, "Text",\s*tostring\(math\.ceil\(hum\.Health\)\)\)/);
 assert.match(tracker,/UDim2\.new\(hpFraction, 0, 1, 0\)/);
 assert.match(tracker,/Name = "HpTrack"/);
 assert.match(tracker,/Size = UDim2\.new\(1, -8, 0, 1\)/);
});
test("8-corner and slim tracer remain feature-controlled, without extra frame loops",()=>{
 assert.match(overlay,/ensureShapeLines\(item, "box", 8\)/);
 assert.match(overlay,/local cornerX = math\.max\(2, math\.min\(10, half \* 0\.48\)\)/);
 assert.match(overlay,/local cornerY = math\.max\(2, math\.min\(10, height \* 0\.12\)\)/);
 assert.match(overlay,/setIfDifferent\(data\.tracer, "Size", UDim2\.fromOffset\(length, 1\)\)/);
 assert.match(overlay,/BackgroundTransparency = 0\.74/);
 assert.doesNotMatch(tracker,/Heartbeat:Connect|RenderStepped:Connect/);
 assert.doesNotMatch(overlay,/Heartbeat:Connect|RenderStepped:Connect/);
});
test("all original ESP input functions and saved controls kept",()=>{
 for(const flag of ["esp","tracers","espBox","names","health","distance","teamColors",
    "espEnemyOnly","espRangeMeters","espMaxTargets","espColorPreset"]){
   assert.ok(tracker.includes("state."+flag)||ui.includes('"'+flag+'"'),flag);
 }
 for(const name of ['"ESP подсветка"','"Линия над игроками"','"2D Box"','"Имена"','"Здоровье"','"Дистанция"']){
   assert.ok(ui.includes(name),name);
 }
 assert.match(tracker,/local function deleteRender\(player\)/);
 assert.match(tracker,/local function bindLocalEspCharacter\(character\)/);
 assert.match(overlay,/local function refreshShapes\(\)/);
 assert.match(overlay,/local function refreshTracers\(\)/);
});
