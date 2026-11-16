"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const gui=fs.readFileSync("src/06_gui_runtime.lua","utf8");
const hub=fs.readFileSync("Hub.lua","utf8");
const visuals=fs.readFileSync("Visuals.lua","utf8");
const launcher=fs.readFileSync("Start.lua","utf8");
test("generic UI actions reject disabled and hidden Roblox ancestors",()=>{
    const region=gui.slice(gui.indexOf("local function safeActivate(control, callback)"),gui.indexOf("-- Dashboard доступен"));
    assert.match(region,/typeof\(control\) == "Instance" and not uiVisibleThroughParents\(control\)/);
    assert.match(gui,/if current:IsA\("GuiObject"\) and not current.Visible then return false end/);
    assert.match(gui,/if current:IsA\("ScreenGui"\) then return current.Enabled end/);
});
test("v1.6.0 bundles and launcher are aligned",()=>{
    assert.equal(hub,visuals);
    assert.ok(hub.includes('Version = "1.6.0"'));
    assert.ok(launcher.includes("v1.6.0-aim-rework-test/Visuals.lua"));
});
