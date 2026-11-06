"use strict";
const fs=require("node:fs"),assert=require("node:assert/strict"),test=require("node:test");
const src=fs.readFileSync("Visuals.lua","utf8");
function between(start,end){
 const a=src.indexOf(start),b=src.indexOf(end,a+start.length);
 assert.ok(a>=0&&b>a,"missing region "+start);
 return src.slice(a,b);
}
const menu=between("local function buildReferenceMenu()","referenceESP = buildReferenceMenu()");
test("reference menu consists of screenshot's four panel sections",()=>{
 for(const name of ["ESPSettingsCard","DistanceAndBorder","ModSkinn","VisualControls"])
  assert.ok(menu.includes(name),name);
 for(const label of ["ESP SETTINGS","Max Distance","Text Border","MOD SKINN",
  "VISUALS","Enable Crosshair","FOV Circle"])assert.ok(menu.includes(label),label);
});
test("all eleven screenshot ESP rows are present",()=>{
 for(const label of ["ESP Master","Bone ESP","Box ESP","Line ESP",
  "Health Bar","Name","Distance","Weapon","Team ID","Enemy Count","Game Info"])
  assert.ok(menu.includes('"'+label+'"'),label);
});
test("working ESP toggles stay linked to old state, callbacks and persistence",()=>{
 for(const key of ["esp","espSkeleton","espBox","tracers","health","names","distance"])
  assert.ok(menu.includes('"'+key+'"'),key);
 for(const code of ["local previous = state[key]","state[key] = not previous",
  "local ok, err = pcall(function()","syncEspVisuals()","refreshShapes()",
  "refreshTracers()","refreshESP()","state[key] = previous",
  "refreshToggles[key] = function()","requestSave()"])
  assert.ok(menu.includes(code),code);
});
test("unsupported screenshot-only features explicitly do not mutate state",()=>{
 assert.ok(menu.includes('{"Weapon", nil}'));
 assert.ok(menu.includes('{"Team ID", nil}'));
 assert.ok(menu.includes('{"Enemy Count", nil}'));
 assert.ok(menu.includes('{"Game Info", nil}'));
 assert.ok(menu.includes('local skinOptions = {"XSuit", "Bag", "Helmet"}'));
 assert.ok(menu.includes('function() return false end, nil'));
 assert.ok(menu.includes("if not action then"));
});
test("reference sliders reuse validated real ranges and refresh old controls",()=>{
 assert.ok(menu.includes('makeSlider(top, "Max Distance", "espRangeMeters", 10, 200, 5'));
 assert.ok(menu.includes('makeSlider(visual, "FOV Circle", "aimFovPixels", CONFIG.AimFovMinPixels'));
 assert.ok(menu.includes("refreshSliders[key] = function()"));
 assert.ok(menu.includes("if old then pcall(old) end"));
 assert.ok(menu.includes("if onChanged then ok, err = pcall(onChanged) end"));
});
test("text-border toggle changes actual ESP label stroke",()=>{
 const update=between("local function updatePlayer(", "local function sameTeamESP(");
 assert.ok(src.includes("local referenceStrokeEnabled = true"));
 for(const label of ["item.nameLabel","item.healthLabel","item.distanceLabel"])
  assert.ok(update.includes('setIfDifferent('+label+', "TextStrokeTransparency", strokeAlpha)'));
 assert.ok(menu.includes("referenceStrokeEnabled = not referenceStrokeEnabled"));
});
test("search, session clock and vector Roblox icon require no HTTP or external assets",()=>{
 assert.ok(menu.includes('Name = "ReferenceSearch"'));
 assert.ok(menu.includes('connect(search:GetPropertyChangedSignal("Text")'));
 assert.ok(menu.includes("string.lower(item.label)"));
 assert.ok(menu.includes('Name = "ReferenceTimer"'));
 assert.ok(menu.includes('Name = "RobloxMark"'));
 assert.ok(menu.includes('Name = "RobloxCutout"'));
 assert.ok(!/rbxassetid?:|https?:\/\//.test(menu));
});
test("crosshair is an on-screen UI-only visual without game state mutation",()=>{
 assert.ok(menu.includes('Name = "124VisualsCrosshair"'));
 assert.ok(menu.includes("crosshair.Visible = crosshairEnabled"));
 assert.ok(menu.includes("ZIndex = 200"));
});

test("reference switches have right-anchored rails and white circular knobs",()=>{
 assert.ok(menu.includes("AnchorPoint = Vector2.new(1, 0.5)"));
 assert.ok(menu.includes("Position = UDim2.new(1, -4, 0.5, 0)"));
 assert.ok(menu.includes("Size = UDim2.fromOffset(36, 18)"));
 assert.ok(menu.includes("Size = UDim2.fromOffset(14, 14)"));
 assert.ok(menu.includes("corners(mk(\"Frame\", {Name = \"Knob\""));
 assert.ok(menu.includes("UDim2.new(1, -51, 0, 25)"));
});
test("desktop widgets are mirrored but mobile retains the old fallback",()=>{
 assert.ok(src.includes("tabs.Position = UDim2.new(1, -196, 0, 0)"));
 assert.ok(src.includes("page.Position = UDim2.fromOffset(14, 81)"));
 assert.ok(src.includes("tabs.Position = UDim2.new(0, 0, 1, -57)"));
 assert.ok(src.includes("espColumns.left.Visible = not wide"));
 assert.ok(src.includes("espColumns.right.Visible = false"));
});
test("top row stays to the left of the right sidebar",()=>{
 for(const code of [
 "Position = UDim2.fromOffset(17, 14), Size = UDim2.new(1, -593, 0, 45)",
 "Position = UDim2.new(1, -474, 0, 17)",
 "Position = UDim2.new(1, -356, 0, 17)",
 "Position = UDim2.new(1, -250, 0, 17)"
 ]) assert.ok(menu.includes(code),code);
});
