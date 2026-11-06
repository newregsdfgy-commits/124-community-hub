"use strict";
const fs=require("node:fs"),test=require("node:test"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8"),hub=fs.readFileSync("Hub.lua","utf8");
test("canonical entrypoints are identical and use v1.1.40",()=>{
 assert.equal(src,hub);
 assert.ok(src.includes('Version = "1.1.40"'));
});
test("prior cleanup, startup, render and GUI identifiers remain compatible",()=>{
 for(const needle of [
  "env.ARMY124_CLEANUP = abortPartialHub",
  "env.ARMY124_CLEANUP = cleanup",
  "xpcall(initializeHubUI",
  "function boosterPro.restoreGraphicsSliced(",
  'Name = "Army124CommunityVisualsGUI"',
 ]) assert.ok(src.includes(needle),needle);
});
test("new title and Roblox vector replace original screenshot branding",()=>{
 const ui=src.slice(src.indexOf("-- 124 VISUALS / UI FROM SUPPLIED REFERENCE."),src.indexOf("-- v1.1.6 Air Motion Reliability Fix."));
 for(const needle of ['"124 Visuals"','Name = "RobloxMark"',
  'Name = "RobloxCutout"','"ROBLOX"','"ReferenceBrand"'])
  assert.ok(ui.includes(needle),needle);
 assert.ok(!src.includes("403VIP")&&!src.includes("PUBG"));
});
test("desktop uses reference proportions; mobile controls stay reachable",()=>{
 assert.ok(src.includes("local preferredWidth = wide and 950"));
 assert.ok(src.includes("local height = math.min(wide and 520"));
 assert.ok(src.includes("tabs.Size = UDim2.new(0, 196, 1, 0)"));
 assert.ok(src.includes("tabs.Position = UDim2.new(1, -196, 0, 0)"));
 assert.ok(src.includes("page.Position = UDim2.fromOffset(14, 81)"));
 assert.ok(src.includes("search.Visible, safe.Visible"));
 assert.ok(src.includes("close.Position = wide and UDim2.new(1, -218, 0, 22)"));
 assert.ok(src.includes("button.Size = UDim2.new(1 / 3, -8, 0, 40)"));
 assert.ok(src.includes("referenceESP.root.Visible = wide"));
 assert.ok(src.includes("espColumns.left.Visible = not wide"));
 assert.ok(src.includes("navigationLayout.FillDirection = Enum.FillDirection.Vertical"));
 assert.ok(src.includes("navigationLayout.FillDirection = Enum.FillDirection.Horizontal"));
});
test("no new per-frame UI loops or unrelated network operations",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 const ui=src.slice(src.indexOf("local function buildReferenceMenu()"),
  src.indexOf("referenceESP = buildReferenceMenu()"));
 assert.ok(ui.includes("connect(UserInputService.InputChanged"));
 assert.ok(!ui.includes("RenderStepped"));
 assert.ok(!ui.includes(":FireServer("));
 assert.ok(!ui.includes("game:HttpGet("));
});
