"use strict";
const fs = require("node:fs");
const assert = require("node:assert/strict");
const test = require("node:test");
const visuals = fs.readFileSync("Visuals.lua", "utf8");
const compat = fs.readFileSync("Hub.lua", "utf8");

test("both entrypoints are byte-for-byte identical", () => {
  assert.equal(visuals, compat);
  assert.match(visuals, /Version = "1\.1\.20"/);
});
test("old executor state keys and cleanup remain compatible", () => {
  assert.match(visuals, /env\.ARMY124_CLEANUP = abortPartialHub/);
  assert.match(visuals, /env\.ARMY124_CLEANUP = cleanup/);
  assert.match(visuals, /xpcall\(initializeHubUI/);
  assert.match(visuals, /function boosterPro\.restoreGraphicsSliced\(/);
});
test("branding uses 124 Community Visuals and violet visual palette", () => {
  assert.match(visuals, /124 Community Visuals/);
  assert.match(visuals, /Name = "Army124CommunityVisualsGUI"/);
  assert.match(visuals, /Accent = Color3\.fromRGB\(161, 46, 255\)/);
  assert.match(visuals, /Text = "VISUALS  \/  v" \.. CONFIG\.Version/);
});
test("five destinations preserve working AIM ESP MISC CFG and add HOME", () => {
  const start = visuals.indexOf("local navigation = {");
  const end = visuals.indexOf("local function makeColumn", start);
  assert.ok(start >= 0 && end > start);
  const region = visuals.slice(start, end);
  const found = [...region.matchAll(/\{key = "([A-Z]+)", label = /g)].map(m => m[1]);
  assert.deepEqual(found, ["HOME", "ESP", "AIM", "MISC", "CFG"]);
  for (const target of ["ESP","AIM","MISC","CFG"]) {
    assert.ok(visuals.includes("addSection(pages." + target + ","),target);
  }
});
test("desktop gets real sidebar; mobile retains five-button bottom bar", () => {
  assert.match(visuals, /tabs\.Size = UDim2\.new\(0, 188, 1, 0\)/);
  assert.match(visuals, /navigationLayout\.FillDirection = Enum\.FillDirection\.Vertical/);
  assert.match(visuals, /navigationLayout\.FillDirection = Enum\.FillDirection\.Horizontal/);
  assert.match(visuals, /button\.Size = UDim2\.new\(0\.2, -9, 0, 40\)/);
  assert.match(visuals, /if info then/);
  assert.match(visuals, /showPage\("HOME"\)/);
});
test("Dashboard uses real FPS, network ping, frametime and ESP count", () => {
  assert.match(visuals, /Name = "DashboardScroll"/);
  assert.match(visuals, /Name = "PerformanceHistory"/);
  assert.match(visuals, /Name = "QuickActions"/);
  assert.match(visuals, /for i = 1, 16 do/);
  assert.match(visuals, /dash\.cards\.fps\.value\.Text = tostring\(measuredFps\)/);
  assert.match(visuals, /dash\.cards\.esp\.value\.Text = tostring\(perfCounters\.espCount\)/);
  assert.match(visuals, /LocalPlayer:GetNetworkPing\(\)/);
  assert.match(visuals, /perfCounters\.frametime\.summary\(\)/);
  assert.match(visuals, /boosterPro\.dashboard\.push\(measuredFps\)/);
});
test("Quick Actions perform real reversible Hub operations", () => {
  for (const label of ["Open Performance","Enable ECO","Toggle Guard","Safety Stop"]) {
    assert.ok(visuals.includes('action("' + label + '"'), label);
  }
  assert.match(visuals, /state\.performanceMode = "ECO"/);
  assert.match(visuals, /state\.performanceGuard = not state\.performanceGuard/);
  assert.match(visuals, /if cleanup then cleanup\(true\) end/);
  for (const fake of ["Flush DNS Cache","Restart Audio Driver","Optimize TCP/IP","Upgrade Now"]) {
    assert.equal(visuals.includes(fake), false, fake);
  }
});
test("Dashboard has no new per-frame signal and updates on existing workers", () => {
  assert.match(visuals, /if boosterPro\.dashboard then boosterPro\.dashboard\.push\(measuredFps\) end/);
  assert.match(visuals, /if boosterPro\.dashboard then boosterPro\.dashboard\.update\(\) end/);
  assert.ok((visuals.match(/RunService:BindToRenderStep\(/g)||[]).length === 4);
  const dash = visuals.slice(visuals.indexOf("-- Dashboard visual reference"), visuals.indexOf("-- Каждый элемент сохраняет свой логический столбец."));
  assert.doesNotMatch(dash,/RenderStepped:Connect|BindToRenderStep|Heartbeat:Connect/);
});
