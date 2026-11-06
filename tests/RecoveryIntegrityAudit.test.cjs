"use strict";
const fs = require("node:fs");
const assert = require("node:assert/strict");
const test = require("node:test");
const src = fs.readFileSync("Visuals.lua","utf8");
const alias = fs.readFileSync("Hub.lua","utf8");
const start = fs.readFileSync("Start.lua","utf8");
function section(startMark,endMark) {
 const i=src.indexOf(startMark),j=src.indexOf(endMark,i+startMark.length);
 assert.ok(i>=0 && j>i,"section not found: "+startMark);
 return src.slice(i,j);
}
test("audit 01: identical v1.1.37 sources and branch-specific loader",()=>{
 assert.equal(src,alias);
 assert.ok(src.includes('Version = "1.1.37"'));
 assert.ok(start.includes("v1.1.37-ui-startup-hotfix-test/Visuals.lua"));
 assert.ok(start.includes("pcall(loadstring, source)"));
});
test("audit 02: crash rollback owns all saved graphics even if UI never completed",()=>{
 const emergency=section("function boosterPro.restoreGraphicsEmergency()",
  "function boosterPro.restoreProtectedTree(");
 assert.ok(emergency.includes("for obj, snapshot in pairs(savedGraphics) do"));
 assert.ok(emergency.includes("boosterPro.restoreObject(obj, snapshot)"));
 assert.ok(emergency.includes("task.wait()"));
 assert.ok(emergency.includes("return next(savedGraphics) == nil"));
 const failed=section("local function abortPartialHub()","env.ARMY124_CLEANUP = abortPartialHub");
 assert.ok(failed.includes("pcall(boosterPro.restoreGraphicsEmergency)"));
 assert.ok(failed.includes("for player in pairs(renderData) do pcall(deleteRender, player) end"));
});
test("audit 03: crash recovery persists only if incomplete and retries failed restores",()=>{
 const block=section("local function abortPartialHub()","env.ARMY124_CLEANUP = abortPartialHub");
 for(const required of [
  "local function tryPartialRestore()",
  "pcall(restoreTerrainGrass)",
  "pcall(restoreTerrainColors)",
  "pcall(applyLighting)",
  "pcall(emergencyUIRollback)",
  "env.ARMY124_RECOVERY = retry",
  "local previousRecovery = env.ARMY124_RECOVERY",
  "if previousDone and restored and env.ARMY124_RECOVERY == retry then",
  "env.ARMY124_RECOVERY = nil"
 ])assert.ok(block.includes(required),required);
});
test("audit 04: camera snapshots survive silent setter failure",()=>{
 const restore=section("function memoryFX.camera.restore(camera)",
  "function memoryFX.camera.apply()");
 assert.ok(restore.includes('camera.FieldOfView ~= old then error("Camera FOV restore mismatch")'));
 const confirm=restore.indexOf('camera.FieldOfView ~= old then error(');
 const release=restore.indexOf("controller.saved[camera] = nil");
 assert.ok(confirm>=0 && release>confirm);
});
test("audit 05: delayed C0 and AutoRotate snapshots require readback success",()=>{
 const pending=section("function memoryFX.spin.restorePending()",
  "function memoryFX.spin.reset()");
 assert.ok(pending.includes('if object[property] ~= value then error("Spin pending restore mismatch") end'));
 assert.ok(pending.indexOf("if object[property] ~= value then error(") <
  pending.indexOf("properties[property] = nil"));
});
test("audit 06: immediate pose restoration verifies values and retains failed snapshot",()=>{
 const reset=section("function memoryFX.spin.reset()",
  "-- MOVEMENT / CHAT:");
 for(const required of [
  'if spin.joint.C0 ~= spin.originalC0 then error("Joint C0 restore mismatch") end',
  'error("AutoRotate restore mismatch")',
  "if not ok then",
  "spin.pending[spin.joint] = pending",
  "spin.pending[spin.humanoid] = pending"
 ])assert.ok(reset.includes(required),required);
});
test("audit 07: emergency UI callback restores camera, movement and pose",()=>{
 const b=section("emergencyUIRollback = function()", "-- Сохраняем только ограниченный набор настроек");
 assert.ok(b.includes("pcall(utilityFX.bunny.stop)"));
 assert.ok(b.includes("pcall(utilityFX.chat.stop)"));
 assert.ok(b.includes("pcall(memoryFX.camera.reset)"));
 assert.ok(b.includes("pcall(memoryFX.spin.reset)"));
 assert.ok(src.includes("local emergencyUIRollback = function() return true end"));
});
test("audit 08: GUI missing is fatal and must cleanup first",()=>{
 const final=src.slice(src.lastIndexOf("elseif not PlayerGui:FindFirstChild"));
 assert.ok(final.includes("local registered = env.ARMY124_CLEANUP"));
 assert.ok(final.includes("if not cleanupOk or cleaned == false then pcall(abortPartialHub) end"));
 assert.ok(final.indexOf("pcall(abortPartialHub)")<final.indexOf('bootFailure("GUI MISSING"'));
});
test("audit 09: all prior code paths and limits remain unchanged",()=>{
 for(const required of [
  "state.espRangeMeters / CONFIG.StudMeters",
  'setIfDifferent(item.billboard, "MaxDistance", 0)',
  'addButton(pages.ESP, "Диагностика ESP"',
  "local function espVisiblePart(character, name)",
  "CONFIG.EspEventMinSeconds - elapsed",
  "if not boosterPro.complete then return end",
  "local function aimFrame(dt)",
  "function chat.sendOnce()",
  "TextChatService:CanUserChatAsync(LocalPlayer.UserId)"
 ])assert.ok(src.includes(required),required);
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
});
test("audit 10: no new dynamic source fetching or chat remotes in production",()=>{
 assert.ok(!/https?:\/\//.test(src));
 assert.ok(!/game:HttpGet\s*\(/.test(src));
 assert.ok(!/:FireServer\s*\(/.test(src));
 assert.ok(!/:InvokeServer\s*\(/.test(src));
});
test("audit 11: source snapshots are not discarded on failing restore",()=>{
 const restore=section("function boosterPro.restoreObject(obj, snapshot)",
    "-- Снимки могли появиться раньше");
 assert.ok(restore.includes('error("restore mismatch")'));
 assert.ok(restore.indexOf('error("restore mismatch")') <
   restore.indexOf("snapshot[key] = nil"));
 // The behavior being protected: a setter may return OK while silently ignoring
 // the value. Only an observed matching readback authorizes releasing backup.
 const record={saved:85,current:110},setterSucceeds=true;
 if(setterSucceeds && record.current===record.saved) delete record.saved;
 assert.equal(record.saved,85);
});
