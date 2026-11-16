"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const read=p=>fs.readFileSync(p,"utf8");
const cfg=read("src/00_config.lua");
const state=read("src/02_state_and_services.lua");
const tr=read("src/03_esp_tracker.lua");
const ui=read("src/08_ui_controls.lua");
const save=read("src/06_gui_runtime.lua");
const overlays=read("src/07_esp_overlays.lua");
const hub=read("Hub.lua");
const keys=["espNameMaxMeters","espHealthMaxMeters","espDistanceMaxMeters","espBoxMaxMeters","espTracerMaxMeters"];
test("v1.6.0 bundles, launcher and source fragments aligned",()=>{
 assert.equal(hub,read("Visuals.lua"));
 assert.ok(hub.includes('Version = "1.6.0"'));
 assert.ok(read("Start.lua").includes("v1.6.0-aim-rework-test/Visuals.lua"));
});
test("Five independent slider inputs use canonical ESP bounds and persistence",()=>{
 for(const key of keys){
   assert.match(state,new RegExp("\\b"+key+"\\s*=\\s*CONFIG\\."));
   assert.ok(ui.includes('"'+key+'", CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters'),key+" slider");
   assert.ok(save.includes('"'+key+'"'),key+" persisted key");
   assert.ok(save.includes(key+" = {CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters}"),key+" numeric clamp");
 }
 assert.match(save,/local function validatedSettings\(values\)/);
 assert.match(save,/for _, key in ipairs\(storedKeys\) do snapshot\[key\] = state\[key\]/);
 assert.match(ui,/requestSave\(\)/);
});
test("Name, HP bar and distance labels independently obey user ranges",()=>{
 assert.match(tr,/meters <= state\.espNameMaxMeters/);
 assert.match(tr,/meters <= state\.espHealthMaxMeters/);
 assert.match(tr,/meters <= state\.espDistanceMaxMeters/);
 assert.match(tr,/compactEspFlags\(meters, state\.names, state\.health, state\.distance\)/);
 assert.match(tr,/item\.lastCompactVisibility ~= visibilityMask/);
 assert.match(tr,/setIfDifferent\(item\.nameChip, "Visible", showName\)/);
 assert.match(tr,/setIfDifferent\(item\.healthChip, "Visible", showHealth\)/);
 assert.match(tr,/setIfDifferent\(item\.distanceChip, "Visible", showDistance\)/);
 assert.match(tr,/setIfDifferent\(item\.healthFill, "Size", UDim2\.new\(hpFraction, 0, 1, 0\)\)/);
});
test("Boxes and tracers have separate radii capped by master ESP",()=>{
 assert.match(overlays,/local radiusStuds = math\.min\(state\.espRangeMeters, state\.espTracerMaxMeters\) \/ CONFIG\.StudMeters/);
 assert.match(overlays,/local radiusStuds = math\.min\(state\.espRangeMeters, state\.espBoxMaxMeters\) \/ CONFIG\.StudMeters/);
 assert.match(overlays,/perfCounters\.espWithinRange\(root, myRoot, radiusSquared\)/);
 assert.match(overlays,/ensureShapeLines\(item, "box", 8\)/);
});
test("Existing compact HUD, ESP state, colors and other systems preserved",()=>{
 assert.match(cfg,/EspLabelWidth = 116/);
 assert.match(cfg,/EspLabelHeight = 29/);
 assert.match(cfg,/EspCompactNameMaxMeters = 155/);
 assert.match(cfg,/EspCompactDetailsMaxMeters = 90/);
 for(const name of ['"Имена"','"Здоровье"','"Дистанция"','"2D Box"','"Линия над игроками"']){
   assert.ok(ui.includes(name),name);
 }
 assert.match(tr,/local function refreshESP\(\)/);
 assert.match(ui,/addSlider\(pages\.ESP, "Дальность ESP"/);
 for(const expr of ["aimFrame", "recoil.frame", "boosterPro.restoreGraphicsSliced",
                    "playerFX.syncWeather","privateMusic.play"])assert.ok(hub.includes(expr),expr);
});
