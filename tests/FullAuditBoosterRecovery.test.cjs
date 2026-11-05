"use strict";
const test = require("node:test");
const fs = require("node:fs");
const assert = require("node:assert/strict");
const src = fs.readFileSync("Visuals.lua","utf8");
const alias = fs.readFileSync("Hub.lua","utf8");
const loader = fs.readFileSync("Start.lua","utf8");
function region(a,b){
 const start=src.indexOf(a),end=src.indexOf(b,start+a.length);
 assert.ok(start>=0 && end>start,a+" .. "+b);
 return src.slice(start,end);
}
function setting(name){
 const m=src.match(new RegExp(name+"\\s*=\\s*(\\d+(?:\\.\\d+)?)"));
 assert.ok(m, name);
 return Number(m[1]);
}
test("complete audit: identical entries, launcher, no hidden version gap",()=>{
 assert.equal(src,alias);
 assert.ok(src.includes('Version = "1.1.33"'));
 assert.ok(loader.includes("v1.1.33-stability-isolation-test/Visuals.lua"));
 assert.ok(loader.includes('ARMY124_BOOT_PHASE ~= "ready"'));
});
test("recover from excessively slow v1.1.23 traversal; bounded slices remain",()=>{
 assert.ok(setting("BoosterBatch") >= 64 && setting("BoosterBatch") <= 128);
 assert.ok(setting("BoosterSliceMs") <= 1.2);
 assert.ok(setting("BoosterLowFpsSliceMs") < setting("BoosterSliceMs"));
 assert.ok(setting("BoosterInitialDelay") <= 0.020);
 assert.ok(setting("BoosterLowFpsDelay") <= 0.040);
 assert.ok(src.includes("task.wait(measuredFps < 42 and CONFIG.BoosterLowFpsDelay"));
});
test("streaming queue and repair remain bounded and relevance-gated",()=>{
 assert.ok(setting("BoosterQueueBatch") <= 64);
 assert.ok(setting("BoosterQueueLowFpsDelay") >= setting("BoosterQueueDelay"));
 const queue=region("function boosterPro.queueObject","connect(Workspace.DescendantAdded");
 assert.ok(queue.indexOf("if not graphicsProperty(obj) then return end")<
            queue.indexOf("boosterPro.queueLastAt = os.clock()"));
 assert.ok(src.includes("boosterPro.queueCount >= boosterPro.queueCap"));
 assert.ok(src.includes("os.clock() - boosterPro.queueLastAt >= CONFIG.BoosterRepairIdleSeconds"));
 assert.ok(src.includes("revision ~= boosterRevision"));
});
test("FPS auto rollback is never triggered during an incomplete scan",()=>{
 const guard=region("boosterPro.autoRollback = function()","addSection(pages.MISC, \"GRAPHICS QUALITY\"");
 assert.ok(guard.includes("if not boosterPro.complete then return end"));
 assert.ok(guard.indexOf("if not boosterPro.complete then return end") < guard.indexOf("local bad ="));
 const scan=region("local function setBooster(","-- AIM: поиск объекта");
 assert.ok(scan.includes("boosterPro.afterFPS = {}"));
 assert.ok(scan.includes('boosterPro.phase = "READY"'));
 assert.ok(scan.includes('boosterPro.phase = enabled and "SCANNING" or "RESTORING"'));
});
test("graphics changes track real writes; restore verifies actual property value",()=>{
 const apply=region("local function optimizeObject(","-- Проходим дерево без GetDescendants()");
 assert.ok(apply.includes("if checked and applied == target then\n                    boosterPro.changedProperties = boosterPro.changedProperties + 1"));
 const restore=region("function boosterPro.restoreObject(","-- Снимки могли появиться раньше");
 assert.ok(restore.includes("if obj[key] ~= original then error(\"restore mismatch\") end"));
 assert.ok(restore.includes("if ok or not obj.Parent then"));
 assert.ok(src.includes("savedGraphics = setmetatable({}, { __mode = \"k\" })"));
});
test("manual booster diagnostics available without new render callbacks",()=>{
 assert.ok(src.includes('addButton(pages.MISC, "Диагностика Booster"'));
 assert.ok(src.includes('Записано свойств: '));
 assert.ok(src.includes('boosterPro.lastError'));
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
});
test("lifecycle manages references and retains all main functions",()=>{
 for (const term of [
  "env.ARMY124_CLEANUP = abortPartialHub",
  "env.ARMY124_CLEANUP = cleanup",
  "boosterPro.restoreGraphicsSliced()",
  "table.clear(connections)",
  "RunService:UnbindFromRenderStep",
  'Name = "Army124CommunityVisualsGUI"',
  "local function aimFrame",
  "local function refreshESP",
  "local function refreshShapes",
  "local function refreshTracers"
 ]) assert.ok(src.includes(term),term);
});
test("chat permission is checked before optional SendAsync",()=>{
 const send=region("function chat.sendOnce()","-- Сохраняем только ограниченный набор настроек");
 const i=send.indexOf("TextChatService:CanUserChatAsync(LocalPlayer.UserId)");
 const j=send.indexOf("channel:SendAsync(message)");
 assert.ok(i>=0 && j>i);
 assert.ok(!send.includes(":FireServer("));
 assert.ok(!send.includes(":InvokeServer("));
});
