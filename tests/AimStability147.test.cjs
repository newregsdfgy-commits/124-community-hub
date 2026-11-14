"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const read=p=>fs.readFileSync(path.join(__dirname,"..",p),"utf8");
const aim=read("src/04_lighting_and_booster.lua");
const state=read("src/02_state_and_services.lua");
const ui=read("src/08_ui_controls.lua");
const gui=read("src/06_gui_runtime.lua");
const config=read("src/00_config.lua");
test("v1.4.7 source and pinned launcher are consistent",()=>{
 assert.match(read("Start.lua"),/v1\.4\.7-aim-stability-deep-audit-test\/Visuals\.lua/);
 assert.match(read("Hub.lua"),/Version = "1\.4\.7"/);
 assert.equal(read("Hub.lua"),read("Visuals.lua"));
});
test("sticky FOV loss and occlusion retain identity without aiming through walls",()=>{
 assert.match(aim,/CONFIG\.AimLockLostGraceSeconds \* graceScale/);
 assert.match(aim,/CONFIG\.AimOcclusionGraceSeconds \* graceScale/);
 assert.match(aim,/CONFIG\.AimSwitchConfirmSeconds \* graceScale/);
 assert.match(aim,/blocked = true/);
 assert.match(aim,/if current\.blocked then return end/);
 assert.match(aim,/previous\.player\.Character == previous\.character/);
 assert.match(aim,/previous\.character:FindFirstChildOfClass\("Humanoid"\)/);
 assert.match(aim,/current\.player\.Character ~= current\.character/);
});
test("camera turn is local, time-bound, combined-axis capped and not teleported at speed zero",()=>{
 assert.doesNotMatch(aim,/camera\.CFrame = goal/);
 assert.doesNotMatch(aim,/camera\.CFrame:ToOrientation\(\)/);
 assert.match(aim,/camera\.CFrame:VectorToObjectSpace\(toTarget\.Unit\)/);
 assert.match(aim,/math\.atan2\(localLook\.Y, horizontal\)/);
 assert.match(aim,/if magnitude > maxStep then/);
 assert.match(aim,/camera\.CFrame = camera\.CFrame \* CFrame\.Angles\(pitchStep, yawStep, 0\)/);
 assert.match(aim,/smoothness == 0 and CONFIG\.AimSmoothnessBaseline \* 2/);
 assert.match(aim,/math\.clamp\(tonumber\(dt\) or 0, 0, 0\.05\)/);
});
test("prediction is finite and damped; deadzone stops microjitter",()=>{
 assert.match(aim,/distance ~= distance or distance == math\.huge/);
 assert.match(aim,/desired = aimPro\.leadPoint:Lerp\(desired, factor\)/);
 assert.match(aim,/aimPro\.leadPart, aimPro\.leadPoint = nil, nil/);
 assert.match(aim,/math\.abs\(projected\.X - viewport\.X \* 0\.5\) <= deadzone/);
 assert.match(aim,/if not ok then return false end/);
});
test("new aim tuning settings survive profile validation and appear in the UI",()=>{
 assert.match(state,/aimStability = 3/);
 assert.match(state,/aimDeadzonePixels = 2/);
 assert.match(gui,/aimStability = \{1, 5\}, aimDeadzonePixels = \{0, 12\}/);
 assert.match(gui,/"aimStability", "aimDeadzonePixels"/);
 assert.match(ui,/"aimStability", 1, 5, 1/);
 assert.match(ui,/"aimDeadzonePixels", 0, 12, 1/);
 assert.match(config,/AimSwitchConfirmSeconds = 0\.16/);
});
