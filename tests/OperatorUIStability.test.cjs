"use strict";
const fs=require("node:fs"),test=require("node:test"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8"),hub=fs.readFileSync("Hub.lua","utf8");
test("identical 1.1.21 entrypoints",()=>{assert.equal(src,hub);assert.ok(src.includes('Version = "1.1.27"'));});
test("operator tabs retain function ids",()=>{
 const t=src.slice(src.indexOf("local navigation = {"),src.indexOf("local function makeColumn"));
 for(const k of ["HOME","ESP","AIM","MISC","CFG"])assert.ok(t.includes('key = "'+k+'"'));
 for(const glyph of ["⌂","▣","ϟ"])assert.ok(!t.includes(glyph));
});
test("camera change and resize events do not create repeated layout work",()=>{
 const b=src.slice(src.indexOf("local currentLayoutCamera = nil"),src.indexOf("-- Линии сверху экрана"));
 assert.ok(b.includes("layoutPending then return"));assert.ok(b.includes("task.defer(function()"));
 assert.ok(b.includes("cameraLayoutConnection:Disconnect()"));
});
test("panel animation unload cancellation",()=>{
 assert.ok(src.includes("if panelTween then panelTween:Cancel(); panelTween = nil end"));
 assert.ok(src.includes("hidePanelAnimation()\n    pcall(function() gui:Destroy() end)"));
});
test("mobile drag safety",()=>{
 assert.ok(src.includes("bar.AbsoluteSize.X - 100"));
 assert.ok(src.includes("if not sliderDrag or sliderDrag.cancelled then return end"));
 assert.ok(src.includes("button.Text = short"));
});
test("original per-frame feature bindings unchanged",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 for(const name of ["local function refreshESP","local function aimFrame","local function refreshShapes","function boosterPro.restoreGraphicsSliced"])
 assert.ok(src.includes(name));
});
