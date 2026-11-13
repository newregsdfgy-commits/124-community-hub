"use strict";
const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");
const test = require("node:test");

const root = path.join(__dirname, "..");
const hub = fs.readFileSync(path.join(root, "Hub.lua"), "utf8");
const visuals = fs.readFileSync(path.join(root, "Visuals.lua"), "utf8");
const launcher = fs.readFileSync(path.join(root, "Start.lua"), "utf8");
const recoil = hub.slice(hub.indexOf("local recoil = (function()"),
    hub.indexOf("-- Bootstrap registered BEFORE"));

test("mirrors, launch version, previous functions retained", () => {
    assert.equal(hub, visuals);
    assert.match(hub, /Version = "1\.4\.2"/);
    assert.match(launcher, /v1\.4\.2-ui-layout-repair-test\/Visuals\.lua/);
    for (const expected of ["local function aimFrame(dt)", "local function refreshESP()",
        "function boosterPro.restoreGraphicsSliced(", "PURPLE NEON 2.0",
        "local function shutdownRecoilControl()", "local function recoilFrame(dt)",
        "local ACCESS_KEY = \"124HUB\""]) {
        assert.ok(hub.includes(expected), expected);
    }
});
test("no spread only mode counts shot signals and differentiates sources", () => {
    const counter = recoil.indexOf("controller.shots = controller.shots + 1");
    const enabledGuard = recoil.indexOf("if not (state.controlRecoil or state.noRecoil) then return end");
    assert.ok(counter > 0 && enabledGuard > counter);
    assert.match(recoil, /inputSignals = \{tool = 0, mouse = 0, touch = 0, gamepad = 0\}/);
    assert.match(recoil, /markRecoilShot\(kind == Enum\.UserInputType\.Touch/);
});
test("spread restores latest observed external value and verifies writes", () => {
    assert.match(recoil, /rememberSpreadBaseline\(instance, nil, value\)/);
    assert.match(recoil, /rememberSpreadBaseline\(instance, name, value\)/);
    assert.match(recoil, /instance\.Value ~= 0 then error/);
    assert.match(recoil, /instance:GetAttribute\(name\) ~= 0 then/);
    assert.ok(recoil.indexOf("rememberSpreadBaseline(instance, nil, value)") <
        recoil.indexOf("instance.Value = 0"));
    assert.match(recoil, /if instance\.Value == 0 then\s*instance\.Value = saved\.value/);
    assert.match(recoil, /if instance:GetAttribute\(attr\) == 0 then\s*instance:SetAttribute\(attr, before\)/);
});
test("delayed callbacks belong to current weapon generation", () => {
    assert.match(recoil, /controller\.spread\.generation == generation/);
    assert.match(recoil, /if spread\.generation ~= generation then return end/);
    assert.match(recoil, /if recoilTool == tool then return end/);
    assert.match(recoil, /equipRecoilTool\(character:FindFirstChildOfClass\("Tool"\)\)/);
});
test("watcher shutdown and nested container removal cleanup", () => {
    assert.match(recoil, /clearSpreadIndex\(\)/);
    assert.match(recoil, /connection:Disconnect\(\)/);
    assert.match(recoil, /candidate:IsDescendantOf\(tool\)/);
    assert.match(recoil, /unregisterSpreadCandidate\(candidate\)/);
    assert.match(recoil, /shutdownRecoilControl\(\)/);
});
test("reactive and periodic spread updates are fault-isolated", () => {
    assert.match(recoil, /safeApplySpread = function\(\)/);
    assert.match(recoil, /pcall\(controller\.applySpread\)/);
    assert.match(recoil, /spread\.stats\.errors = spread\.stats\.errors \+ 1/);
    assert.match(recoil, /spread\.stats\.restoreFailures = controller\.spread\.stats\.restoreFailures \+ 1/);
    assert.match(recoil, /controller\.safeApplySpread = safeApplySpread/);
});
test("recoil respects camera owner and only corrects during fire", () => {
    assert.match(recoil, /recoilTool == nil or recoilTool\.Parent ~= LocalPlayer\.Character/);
    assert.match(recoil, /if state\.aimbot and \(aimHeldMouse or aimHeldTouch or aimHeldKey\)/);
    assert.match(recoil, /if not firing then/);
    assert.match(recoil, /if dt <= 0 or dt > CONFIG\.RecoilMaxFrameSeconds then/);
    assert.match(recoil, /camera\.CFrame = camera\.CFrame \* CFrame\.Angles/);
    assert.match(recoil, /controller\.correctionFrames = controller\.correctionFrames \+ 1/);
});
test("UI diagnosis says found parameters not validated hit trajectory", () => {
    assert.match(hub, /addSection\(pages\.MISC, "WEAPONS 2\.0"/);
    assert.match(hub, /"Диагностика Weapons 2\.0"/);
    assert.match(hub, /controller\.diagnostics = function\(\)/);
    assert.match(hub, /влияние на траекторию не подтверждено/);
    assert.match(hub, /lastError=/);
    assert.match(hub, /pendingRestore=/);
});
test("auto profile load never enables modifying features", () => {
    assert.match(hub, /if autoLoad then[\s\S]*?state\.noRecoil = false[\s\S]*?state\.noSpread = false/);
});
