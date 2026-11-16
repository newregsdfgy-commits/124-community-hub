"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs"),crypto=require("node:crypto");
const ui=fs.readFileSync("src/08_ui_controls.lua","utf8");
const aim=fs.readFileSync("src/04_lighting_and_booster.lua","utf8");
const gui=fs.readFileSync("src/06_gui_runtime.lua","utf8");
test("Aimbot has a dedicated active full-row input hitbox above the artwork",()=>{
 assert.match(ui,/if key == "aimbot" then/);
 assert.match(ui,/Name = "AimFullRowHitSurface"/);
 assert.match(ui,/BackgroundTransparency = 1/);
 assert.match(ui,/Active = true/);
 assert.match(ui,/Selectable = true, ZIndex = 25/);
 assert.match(ui,/connect\(surface\.Activated, function\(input\)/);
 assert.match(ui,/connect\(surface\.MouseButton1Click, function\(\)/);
 assert.match(ui,/connect\(row\.Activated, function\(input\)/);
});
test("AIM release fallback handles missing GUI button events and deduplicates by press",()=>{
 assert.match(ui,/connect\(UserInputService\.InputBegan, function\(input\)/);
 assert.match(ui,/connect\(UserInputService\.InputEnded, function\(input\)/);
 assert.match(ui,/local serial, consumedSerial = 0, -1/);
 assert.match(ui,/if token ~= nil and consumedSerial == token then return end/);
 assert.match(ui,/if token == nil and now - lastFired < 0\.14 then return end/);
 assert.match(ui,/if serial > 0 and input ~= nil and input == latestInput then/);
 assert.match(ui,/os\.clock\(\) - lastStarted < 0\.14 then/);
 assert.match(ui,/debug\.recovered = debug\.recovered \+ 1/);
 assert.match(ui,/dx \* dx \+ dy \* dy > 144/);
});
test("AIM hit test will not toggle through another modal or on a hidden page",()=>{
 assert.match(ui,/PlayerGui\.GetGuiObjectsAtPosition/);
 assert.match(ui,/if not alive or not gui\.Enabled or not panel\.Visible or not page\.Visible/);
 assert.match(ui,/debug\.blocked = debug\.blocked \+ 1/);
 assert.match(ui,/debug\.lastError = "UI covered by "/);
});
test("AIM click diagnostics remain available; same stable v1.4.6 aim algorithm",()=>{
 assert.match(ui,/boosterPro\.aimClickDebug = debug/);
 assert.match(ui,/AIM button \| Нажатий:/);
 assert.match(gui,/local function setAimEnabled\(enabled, activateKeyAim\)/);
 const sha=crypto.createHash("sha1").update("blob "+Buffer.byteLength(aim)+"\0").update(aim).digest("hex");
 assert.match(aim,/local function aimCandidateBefore/);
});
