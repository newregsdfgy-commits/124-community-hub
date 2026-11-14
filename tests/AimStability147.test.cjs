"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs"),crypto=require("node:crypto"),path=require("node:path");
const read=p=>fs.readFileSync(path.join(__dirname,"..",p),"utf8");
const aim=read("src/04_lighting_and_booster.lua");
const config=read("src/00_config.lua");
const state=read("src/02_state_and_services.lua");
const ui=read("src/08_ui_controls.lua");
const gui=read("src/06_gui_runtime.lua");
test("v1.4.9 restored the exact v1.4.6 AIM source, not a partial hybrid",()=>{
 const checksum=crypto.createHash("sha1")
   .update("blob "+Buffer.byteLength(aim)+"\\0".replace("\\0","\0"))
   .update(aim).digest("hex");
 assert.equal(checksum,"c67cbdfb6139adce856b7758bf821ddf03449a68");
});
test("v1.4.6 instant mode and original smooth pitch/yaw preserved",()=>{
 assert.match(aim,/if state\.aimSmoothness == 0 then/);
 assert.match(aim,/camera\.CFrame = goal/);
 assert.match(aim,/local maxStep = math\.rad\(CONFIG\.AimMaxTurnDegreesPerSecond\) \* dtSafe/);
 assert.match(aim,/local function findAimTarget\(camera\)/);
 assert.match(aim,/CONFIG\.AimOcclusionGraceSeconds/);
 assert.doesNotMatch(aim,/AimLockLostGraceSeconds|AimSwitchConfirmSeconds/);
});
test("new AIM tuning widgets removed while original settings and key gate stay",()=>{
 assert.doesNotMatch(state,/aimStability =|aimDeadzonePixels =/);
 assert.doesNotMatch(config,/AimLockLostGraceSeconds =/);
 assert.doesNotMatch(gui,/"aimStability", "aimDeadzonePixels"/);
 assert.doesNotMatch(ui,/"aimStability", 1, 5/);
 assert.match(ui,/addToggle\(pages\.AIM, "Aimbot"/);
 assert.match(ui,/addToggle\(pages\.AIM, "Target Lock"/);
});
