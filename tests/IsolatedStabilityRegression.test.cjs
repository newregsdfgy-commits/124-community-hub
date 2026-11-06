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
test("1: isolated v1.1.40 artifacts and launcher are paired",()=>{
 assert.equal(src,alias);
 assert.ok(src.includes('Version = "1.1.40"'));
 assert.ok(launcher.includes("v1.1.40-stability-frametime-test/Visuals.lua"));
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
 assert.ok(profile.includes("local function loadCustomSettings()"));
 assert.ok(profile.includes("return applySettings(values, true)"));
 assert.ok(profile.includes("return true"));
 assert.ok(src.includes('error("Профиль не был загружен полностью")'));
});
