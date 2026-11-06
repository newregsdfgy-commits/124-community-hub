"use strict";
const fs=require("node:fs"),test=require("node:test"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
const hub=fs.readFileSync("Hub.lua","utf8");
const start=fs.readFileSync("Start.lua","utf8");
const fragment=(first,last)=>{
 const a=src.indexOf(first),b=src.indexOf(last,a+first.length);
 assert.ok(a>=0&&b>a,"missing "+first);
 return src.slice(a,b);
};
test("lite: canonical 1.1.39 source and launcher",()=>{
 assert.equal(src,hub);
 assert.ok(src.includes('Version = "1.1.39"'));
 assert.ok(start.includes("v1.1.39-lite-performance-test/Visuals.lua"));
 assert.ok(start.includes('Version = "1.1.39"'));
});
test("lite: chat, Bunny Hop, Skeleton ESP and CFG backend/UI are absent",()=>{
 for(const removed of [
 "utilityFX","bunnyHop","bhopSpeedMultiplier","bhopJumpInterval",
 "spamChat","chatInterval","chatMessage","chatPreferences",
 "TextChatService","CanUserChatAsync","SendAsync","espSkeleton",
 "shapePairsR15","shapePairsR6","item.bones","pages.CFG",
 'key = "CFG"',"useProfile(","presetData",
 '"Bone ESP"','"Skeleton ESP"','"BUNNY HOP"','"CHAT TOOLS"'
 ]) assert.ok(!src.includes(removed),"found removed feature: "+removed);
});
test("lite: previously saved removed keys are not loaded or written",()=>{
 const keys=fragment("local storedKeys = {","local numericRules = {");
 for(const removed of ["bunnyHop","spamChat","espSkeleton","chatInterval","chatMessage"])
 assert.ok(!keys.includes(removed));
 assert.ok(src.includes('local profiles = {CUSTOM = {}}'));
 assert.ok(src.includes("local function loadCustomSettings()"));
 assert.ok(src.includes("return applySettings(values, true)"));
 assert.ok(src.includes("profiles.CUSTOM = validatedSettings(loaded.profiles.CUSTOM)"));
});
test("lite: visible page navigation has only ESP, Aim and Memory",()=>{
 const nav=fragment("local navigation = {","local function makeColumn");
 for(const key of ['key = "ESP"','key = "AIM"','key = "MISC"'])assert.ok(nav.includes(key));
 assert.ok(!nav.includes('key = "CFG"'));
 assert.ok(src.includes('button.Size = UDim2.new(1 / 3, -8, 0, 40)'));
 assert.ok(src.includes('showPage("ESP")'));
});
test("lite: all retained feature modules are present",()=>{
 for(const fragmentName of ["local function refreshESP()","local function refreshTracers()",
 "local function refreshShapes()","local function aimFrame(dt)","local function recoilFrame(dt)",
 "local function setBooster(","memoryFX.camera.apply", "memoryFX.spin.frame",
 "local function queueESPRefresh()","local function applySettings(incoming, autoLoad)"])
 assert.ok(src.includes(fragmentName),fragmentName);
});
test("lite: source does not introduce new per-frame callbacks",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 assert.ok(!/:FireServer\s*\(/.test(src));
 assert.ok(!/:InvokeServer\s*\(/.test(src));
});
test("performance: Box visibility is checked before allocating player GUI",()=>{
 const body=fragment("local function refreshShapes()","syncEspVisuals = function()");
 const allocation=body.indexOf("local item = shapeItem(player, char)");
 const projected=body.indexOf("camera:WorldToViewportPoint(");
 const visible=body.indexOf("if onTop and onBottom and top.Z > 0 and bottom.Z > 0 then");
 assert.ok(projected>=0 && projected<visible && visible<allocation);
 assert.ok(body.includes('ensureShapeLines(item, "box", 4)'));
 assert.ok(!body.includes("bones"));
});
test("performance: only the throttled visual render callback resets new-object budget",()=>{
 assert.equal((src.match(/shapeNewContainersLeft = CONFIG.ShapeNewContainersPerDraw/g)||[]).length,1);
 assert.equal((src.match(/shapeNewLinesLeft = CONFIG.ShapeNewLinesPerDraw/g)||[]).length,1);
 const renderer=fragment("perfCounters.espVisual.frame = function(dt)","perfCounters.cpu.wrapped.ESPDraw =");
 assert.ok(renderer.includes("shapeNewContainersLeft = CONFIG.ShapeNewContainersPerDraw"));
 assert.ok(renderer.includes("shapeNewLinesLeft = CONFIG.ShapeNewLinesPerDraw"));
});
test("performance: input actions queue scans instead of synchronous full redraw",()=>{
 const callbacks=fragment('addSection(pages.ESP, "VISUALS"', 'addSection(pages.AIM, "TARGETING"');
 assert.ok(callbacks.includes("queueESPRefresh()"));
 assert.ok(!callbacks.includes("refreshESP(); refreshShapes()"));
 assert.ok(!callbacks.includes("refreshShapes()"));
 const skin=fragment('local controls = {','local function card(name, y, h)');
 assert.ok(!skin.includes("refreshShapes()"));
});
test("performance: deferred saves use at most one outstanding worker",()=>{
 const save=fragment("local saveWorkerPending = false","local function readProfileFile()");
 assert.ok(save.includes("if saveWorkerPending then return end"));
 assert.ok(save.includes("saveWorkerPending = true"));
 assert.ok(save.includes("saveWorkerPending = false"));
 assert.ok(save.includes("storeCustomSnapshot()"));
 assert.ok(save.includes("writeProfileFile()"));
 assert.ok(!save.includes("task.delay(1.4"));
});
test("performance: coalesced event scans avoid recent periodic scan",()=>{
 const events=fragment("local function queueESPRefresh()","local function isEspPart(obj)");
 assert.ok(events.includes("espRefreshQueued then return"));
 assert.ok(events.includes("espRefreshGeneration"));
 assert.ok(events.includes("os.clock() - perfCounters.espVisual.lastScanAt"));
 assert.ok(events.includes(">= CONFIG.EspEventMinSeconds"));
});
