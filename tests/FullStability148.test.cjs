"use strict";
const test=require("node:test"),assert=require("node:assert/strict");
const fs=require("node:fs"),path=require("node:path");
const root=path.resolve(__dirname,"..");
const read=p=>fs.readFileSync(path.join(root,p),"utf8");
const ui=read("src/08_ui_controls.lua"),runtime=read("src/06_gui_runtime.lua");
const cleanup=read("src/09_misc_and_diagnostics.lua"),worker=read("src/10_run_and_cleanup.lua");
const aim=read("src/02_state_and_services.lua");
test("v1.4.8 launch and 12-module bundles remain in sync",()=>{
 assert.match(read("Start.lua"),/v1\.4\.8-full-stability-audit-test\/Visuals\.lua/);
 assert.match(read("Hub.lua"),/Version = "1\.4\.8"/);
 assert.equal(read("Hub.lua"),read("Visuals.lua"));
});
test("failed Speed, Noclip, Fly setters retain exact original snapshots",()=>{
 assert.match(ui,/pendingSpeeds = setmetatable/);
 assert.match(ui,/pendingAutoRotates = setmetatable/);
 assert.match(ui,/movement\.pendingSpeeds\[movement\.speedHumanoid\]/);
 assert.match(ui,/movement\.collisionOriginals\[part\] = nil/);
 assert.match(ui,/movement\.pendingAutoRotates\[humanoid\] = nil/);
 assert.match(ui,/movement\.lastAppliedSpeed = state\.speedValue\s+humanoid\.WalkSpeed = state\.speedValue/);
 assert.match(ui,/movement\.flyHumanoid, movement\.flyRoot = humanoid, root\s+humanoid\.AutoRotate = false/);
});
test("recovery runs all independent rollback layers and never starts new render loop",()=>{
 assert.match(ui,/local speedOK = movement\.retrySpeeds\(\)/);
 assert.match(ui,/local autoRotateOK = movement\.retryAutoRotates\(\)/);
 assert.match(ui,/local collisionOK = movement\.restoreCollision\(\)/);
 assert.match(worker,/pcall\(boosterPro\.movement\.retryPending\)/);
 assert.match(cleanup,/or \(boosterPro\.movement and boosterPro\.movement\.pending\(\)\) then/);
 assert.match(cleanup,/movementOK and movementRestored == true/);
 assert.match(runtime,/return movementOK and graphicsOk and graphicsRestored == true/);
});
test("AIM toggles and profile changes erase stale prediction cache and lock identity",()=>{
 assert.match(aim,/aimPro\.leadPart = nil/);
 assert.match(aim,/aimPro\.switchCandidate = nil/);
 assert.match(runtime,/local function setAimEnabled\(enabled, activateKeyAim\)[\s\S]*?aimPro\.reset\(\)/);
 for(const marker of [
 'addToggle(pages.AIM, "Prediction"',
 'addToggle(pages.AIM, "Visible Check"',
 'addToggle(pages.AIM, "Target Lock"'])
 assert.ok(ui.includes(marker),marker);
 assert.match(ui,/addToggle\(pages\.AIM, "Prediction"[\s\S]*?function\(\)\s+aimPro\.reset\(\)/);
 assert.match(ui,/function\(\) aimPro\.reset\(\); refreshFovRing\(\) end/);
});
test("preserve key-gate, current ESP, Booster, Aura and weapon systems",()=>{
 for(const marker of [
 'local function aimFrame(dt)','function boosterPro.restoreGraphicsSliced(',
 'function controller.restoreSpread()','function controller.syncAvatar()',
 'local function refreshESP()','local function setAimEnabled(enabled, activateKeyAim)',
 'function movement.retryAutoRotates()'
 ])assert.ok(read("Hub.lua").includes(marker),marker);
});
