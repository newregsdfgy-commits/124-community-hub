"use strict";
const {test}=require("node:test");
const fs=require("node:fs");
const assert=require("node:assert/strict");
const crypto=require("node:crypto");
const ui=fs.readFileSync("src/08_ui_controls.lua","utf8");
const gui=fs.readFileSync("src/06_gui_runtime.lua","utf8");
const aim=fs.readFileSync("src/04_lighting_and_booster.lua","utf8");
test("new AIM button is outside scrolls and the old toggle is preserved",()=>{
    assert.match(ui,/Name = "AimPinnedControlDock"/);
    assert.match(ui,/Name = "AimPinnedSwitch"/);
    assert.match(ui,/ZIndex = 31/);
    assert.match(gui,/if page == pages\.AIM then\s+local reserved = 52/);
    assert.match(gui,/scroll\.Position = UDim2\.new\(pos\.X\.Scale, pos\.X\.Offset, 0, reserved\)/);
    assert.match(ui,/addToggle\(pages\.AIM, "Aimbot"/);
    assert.ok(ui.indexOf('addToggle(pages.AIM, "Aimbot"')<ui.indexOf('Name = "AimPinnedControlDock"'),
        "Pinned callback must be installed after original toggle initializer");
});
test("separate AIM button calls shared state setter and refreshes original row",()=>{
    assert.match(ui,/local previousAimUpdate = refreshToggles\.aimbot/);
    assert.match(ui,/refreshToggles\.aimbot = function\(\.\.\.\)/);
    assert.match(ui,/if previousAimUpdate then previousAimUpdate\(\.\.\.\) end/);
    assert.match(ui,/local ok, err = pcall\(setAimEnabled, desired, desired\)/);
    assert.match(ui,/boosterPro\.pinnedAimClickDebug = counter/);
    assert.match(ui,/AIM PINNED \| Нажатий:/);
});
test("input release fallback ignores drags, another modal and hidden GUI",()=>{
    assert.match(ui,/connect\(directButton\.Activated, function\(input\)/);
    assert.match(ui,/connect\(directButton\.MouseButton1Click, function\(\)/);
    assert.match(ui,/connect\(UserInputService\.InputEnded, function\(input\)/);
    assert.match(ui,/PlayerGui\.GetGuiObjectsAtPosition/);
    assert.match(ui,/pages\.AIM\.Visible/);
    assert.match(ui,/dx \* dx \+ dy \* dy > 144/);
});
test("v1.4.6 AIM algorithm is untouched",()=>{
    const sha=crypto.createHash("sha1").update("blob "+Buffer.byteLength(aim)+"\0").update(aim).digest("hex");
    assert.equal(sha,"c67cbdfb6139adce856b7758bf821ddf03449a68");
});
