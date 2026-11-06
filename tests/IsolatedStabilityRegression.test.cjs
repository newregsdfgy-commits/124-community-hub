"use strict";
const fs = require("node:fs");
const assert = require("node:assert/strict");
const test = require("node:test");
const src = fs.readFileSync("Visuals.lua", "utf8");
const alias = fs.readFileSync("Hub.lua", "utf8");
const launcher = fs.readFileSync("Start.lua", "utf8");
function block(first,last){
 const a=src.indexOf(first),b=src.indexOf(last,a+first.length);
 assert.ok(a>=0 && b>a,"Cannot find block: "+first);
 return src.slice(a,b);
}
test("1: isolated v1.1.36 artifacts and launcher are paired",()=>{
 assert.equal(src,alias);
 assert.ok(src.includes('Version = "1.1.36"'));
 assert.ok(launcher.includes("v1.1.36-ui-polish-stability-test/Visuals.lua"));
});
test("2: Booster restores retry only in pending phase with a revision token",()=>{
 const b=block("function boosterPro.retryPendingGraphics()","cleanup = function(safeStop)");
 assert.ok(b.includes('boosterPro.phase ~= "RESTORE PENDING"'));
 assert.ok(b.includes('if not alive or state.booster'));
 assert.ok(b.includes("boosterPro.restoreRetryRunning"));
 assert.ok(b.includes("os.clock() + 20"));
 assert.ok(b.includes("local revision = boosterRevision"));
 assert.ok(b.includes("if revision ~= boosterRevision then return end"));
});
test("3: sliced restore halts if player re-enables Booster",()=>{
 const b=block("function boosterPro.restoreGraphicsSliced(expectedRevision)",
   "function boosterPro.retryPendingGraphics()");
 assert.ok(b.includes("expectedRevision ~= boosterRevision"));
 assert.ok(b.includes("or state.booster or not alive"));
 assert.ok(b.indexOf("expectedRevision ~= boosterRevision") < b.indexOf("boosterPro.restoreObject(obj, snapshot)"));
 assert.ok(b.includes("return next(savedGraphics) == nil"));
});
test("4: regular HUD retries pending graphics only after Terrain recovery",()=>{
 const b=block('if not state.booster or state.boosterMode == "BALANCED" then',
    "stats.Visible = state.hud");
 assert.ok(b.includes("if savedTerrainColors then restoreTerrainColors() end"));
 assert.ok(b.includes("if not state.booster then boosterPro.retryPendingGraphics() end"));
 assert.ok(b.indexOf("restoreTerrainColors()") < b.indexOf("retryPendingGraphics()"));
});
test("5: each new booster revision clears stale retry bookkeeping",()=>{
 const b=block("local function setBooster(enabled, keepBaseline)","-- AIM: поиск объекта");
 assert.ok(b.includes("boosterPro.restoreRetryAt = 0"));
 assert.ok(b.includes("boosterPro.restoreRetryRunning = false"));
 assert.ok(b.includes('boosterPro.phase = enabled and "SCANNING" or "RESTORING"'));
});
test("6: BHOP holds original WalkSpeed after a write/readback failure",()=>{
 const b=block("function bunny.restorePending()","function bunny.applySpeed()");
 for(const piece of [
 "bunny.pending[hum] = {",
 "original = bunny.originalSpeed, applied = bunny.appliedSpeed",
 "return math.abs(hum.WalkSpeed - record.original) < 0.05",
 "if ok and done then bunny.pending[hum] = nil",
 "bunny.queueRestoreRetry()"
 ])assert.ok(b.includes(piece),piece);
});
test("7: BHOP never overwrites a game's unrelated speed and backs off",()=>{
 const b=block("function bunny.restorePending()","function bunny.applySpeed()");
 assert.ok(b.includes("math.abs(current - record.applied) >= 0.05 then return true"));
 assert.ok(b.includes("while alive and next(bunny.pending) ~= nil do"));
 assert.ok(b.includes("task.wait(math.min(20, 2 ^ math.min(failures, 4)))"));
});
test("8: BHOP new speed assignment is verified",()=>{
 const b=block("function bunny.applySpeed()","function bunny.stop()");
 assert.ok(b.includes("return hum.WalkSpeed"));
 assert.ok(b.includes("math.abs(actual - speed) < 0.05"));
 assert.ok(!b.includes("if ok then bunny.appliedSpeed = speed end"));
});
test("9: exit preserves failed Bunny snapshots for next safe startup",()=>{
 const emergency=block("emergencyUIRollback = function()", "-- Сохраняем только ограниченный набор настроек");
 assert.ok(emergency.includes("pcall(utilityFX.bunny.restorePending)"));
 assert.ok(emergency.includes("bunnyRestored == true"));
 const cleanup=block("cleanup = function(safeStop)", "env.ARMY124_CLEANUP = cleanup");
 assert.ok(cleanup.includes("or next(utilityFX.bunny.pending) ~= nil"));
 assert.ok(cleanup.includes("utilityFX.bunny.restorePending()"));
 assert.ok(cleanup.includes("and next(utilityFX.bunny.pending) == nil"));
});
test("10: a profile failure cannot latch the restoring flag",()=>{
 const guard=block("local function applySettingsGuard(action)", "local function applySettings(incoming, autoLoad)");
 assert.ok(guard.includes("local ok, err = xpcall(action"));
 assert.ok(guard.indexOf("restoring = false")>guard.indexOf("xpcall(action"));
 assert.ok(guard.includes("return ok, err"));
});
test("11: failed profile sync cannot claim successful profile load",()=>{
 const profile=block("local function applySettings(incoming, autoLoad)","local viewport =");
 assert.ok(profile.includes("if not ok then"));
 assert.ok(profile.includes("return false"));
 assert.ok(profile.includes("local synced, syncErr = pcall(syncEspVisuals)"));
 assert.ok(profile.includes("if not applySettings(values, autoLoad) then"));
 assert.ok(profile.includes("profileName = previousProfileName"));
 assert.ok(profile.includes("return true"));
 assert.ok(src.includes('error("Профиль не был загружен полностью")'));
});
test("12: no extra RenderStep work or unreviewed remotes were introduced",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 assert.ok(src.includes("local function aimFrame(dt)"));
 assert.ok(src.includes("function chat.sendOnce()"));
 assert.ok(!/:FireServer\s*\(/.test(src));
 assert.ok(!/:InvokeServer\s*\(/.test(src));
});
