"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const gui=fs.readFileSync("src/06_gui_runtime.lua","utf8");
const ui=fs.readFileSync("src/08_ui_controls.lua","utf8");
const hub=fs.readFileSync("Hub.lua","utf8");
const visuals=fs.readFileSync("Visuals.lua","utf8");
const launcher=fs.readFileSync("Start.lua","utf8");
test("v1.6.1 launcher and deterministic bundles match",()=>{
    assert.equal(hub,visuals);
    assert.ok(hub.includes('Version = "1.6.1"'));
    assert.ok(launcher.includes("v1.6.1-stability-audit-test/Visuals.lua"));
});
test("camera original values are stored per camera and overwritten only by our owned writes",()=>{
    assert.match(gui,/written = setmetatable\(\{\}, \{__mode = "k"\}\)/);
    assert.match(gui,/local imposed = controller\.written\[camera\]/);
    assert.match(gui,/if imposed ~= nil and math\.abs\(current - imposed\) <= 0\.01/);
    assert.match(gui,/controller\.saved\[camera\] = current/);
    assert.match(gui,/controller\.written\[camera\] = nil/);
    assert.match(gui,/controller\.written\[camera\] = degrees/);
});
test("local music re-creates unparented or replaced Sound even when Audio ID is unchanged",()=>{
    assert.match(ui,/local soundService = game:GetService\("SoundService"\)/);
    assert.match(ui,/privateMusic\.sound\.Parent ~= soundService/);
    assert.match(ui,/if privateMusic\.sound and \(privateMusic\.currentId ~= id/);
    assert.match(ui,/sound\.Parent = soundService/);
});
test("camera and audio recovery retain manual shutdown, crosshair and AIM source",()=>{
    assert.match(gui,/function memoryFX\.camera\.reset\(\)/);
    assert.match(ui,/function privateMusic\.shutdown\(\)/);
    assert.match(gui,/local function setAimEnabled\(enabled, activateKeyAim\)/);
    assert.match(hub,/local function aimFrame\(dt\)/);
});
