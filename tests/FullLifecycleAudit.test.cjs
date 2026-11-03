"use strict";
const test=require("node:test");
const fs=require("node:fs");
const assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
const alias=fs.readFileSync("Hub.lua","utf8");
const start=fs.readFileSync("Start.lua","utf8");
function block(first,last){
 const begin=src.indexOf(first), end=src.indexOf(last,begin+first.length);
 assert.ok(begin>=0 && end>begin,"unmatched block: "+first);
 return src.slice(begin,end);
}
test("audit 1: canonical files and checked Start URL agree on v1.1.30",()=>{
 assert.equal(src,alias);
 assert.ok(src.includes('Version = "1.1.30"'));
 assert.ok(start.includes("v1.1.30-full-stability-audit-test/Visuals.lua"));
 assert.ok(start.includes("pcall(loadstring, source)"));
 assert.ok(start.includes('env.ARMY124_BOOT_PHASE ~= "ready"'));
});
test("audit 2: all documented core feature identifiers remain in source",()=>{
 for(const name of [
  "local function aimFrame", "local function findAimTarget",
  "local function refreshESP", "local function refreshTracers",
  "local function refreshShapes", "recoilFrame", "setBooster",
  "refreshFovRing", "applyLighting", "addSection(pages.MISC",
  "local function useProfile", "local function applySettings",
  "utilityFX.chat.sendOnce", "utilityFX.bunny.sync"
 ]) assert.ok(src.includes(name),name);
});
test("audit 3: mode downgrade checks actual restored property before deleting snapshot",()=>{
 const b=block("local function optimizeObject(", "-- Проходим дерево без GetDescendants()");
 const restore=b.indexOf('if obj[key] ~= original then error("mode restore mismatch") end');
 const forget=b.indexOf("snap[key] = nil",restore);
 assert.ok(restore>=0 && forget>restore);
 assert.ok(b.includes("boosterPro.restoreFailures = boosterPro.restoreFailures + 1"));
});
test("audit 4: successful setter alone cannot claim a graphics change",()=>{
 const b=block("local function optimizeObject(", "-- Проходим дерево без GetDescendants()");
 assert.ok(b.includes("if wrote then"));
 const save=b.indexOf("savedGraphics[obj] = snap");
 const read=b.indexOf("local checked, applied = pcall");
 const count=b.indexOf("boosterPro.changedProperties = boosterPro.changedProperties + 1");
 assert.ok(save>=0 && read>save && count>read);
 assert.ok(b.includes("if checked and applied == target then"));
});
test("audit 5: partial restore is reported for either graphics or terrain and failure reason persists",()=>{
 const b=block("local function setBooster(", "-- AIM: поиск объекта");
 assert.ok(b.includes("local terrainPending = savedTerrainDecoration ~= nil"));
 assert.ok(b.includes("or savedTerrainColors ~= nil"));
 assert.ok(b.includes('boosterPro.phase = restorePending and "RESTORE PENDING"'));
 assert.ok(b.includes('or (boosterPro.lastError and "FAILED" or "OFF")'));
 assert.ok(b.includes("boosterPro.lastError = boosterPro.failed"));
});
test("audit 6: effective FPS rollback waits until scan finishes",()=>{
 const b=block("boosterPro.autoRollback = function()", 'addSection(pages.MISC, "GRAPHICS QUALITY"');
 assert.ok(b.indexOf("if not boosterPro.complete then return end") <
           b.indexOf("local bad ="));
 assert.ok(b.includes("boosterPro.readyAt"));
 assert.ok(b.includes("guardLowSince"));
});
test("audit 7: all streaming events append to bounded queue, not spawn per object",()=>{
 const queue=block("function boosterPro.queueObject(", "for _, property in ipairs(lightingProperties)");
 assert.ok(queue.includes("boosterPro.queueCount >= boosterPro.queueCap"));
 const callback=block("connect(Workspace.DescendantAdded,", "connect(Lighting.DescendantAdded");
 assert.ok(callback.includes("boosterPro.queueObject(obj)"));
 assert.ok(!callback.includes("task.spawn("));
 assert.ok(queue.includes("revision ~= boosterRevision"));
 assert.ok(queue.includes("boosterPro.repairRetryAt = os.clock() + CONFIG.BoosterRepairCooldown"));
});
test("audit 8: cleanup unregisters handlers, restores state, and exposes recovery only when needed",()=>{
 const b=block("cleanup = function(safeStop)", 'env.ARMY124_CLEANUP = cleanup');
 for(const needle of ["alive = false", "boosterRevision = boosterRevision + 1",
  "boosterPro.restoreGraphicsSliced()", "table.clear(connections)",
  "RunService:UnbindFromRenderStep", "env.ARMY124_RECOVERY = pendingRecovery",
  "if env.ARMY124_CLEANUP == cleanup then env.ARMY124_CLEANUP = nil end"])
  assert.ok(b.includes(needle),needle);
});
test("audit 9: profile settings validated; chat checks account permission first",()=>{
 assert.ok(src.includes("local function validatedSettings(values)"));
 assert.ok(src.includes("local textRules = {"));
 const b=block("function chat.sendOnce()", "-- Сохраняем только ограниченный набор настроек");
 assert.ok(b.indexOf("TextChatService:CanUserChatAsync(LocalPlayer.UserId)") <
   b.indexOf("channel:SendAsync(message)"));
 assert.ok(!b.includes(":FireServer("));
});
test("audit 10: visible Lua source contains no external URLs, remote calls, or dynamic imports",()=>{
 for(const pattern of [/https?:\/\//, /\bloadstring\s*\(/, /game:HttpGet\s*\(/,
  /:FireServer\s*\(/, /:InvokeServer\s*\(/])
  assert.ok(!pattern.test(src),String(pattern));
});
test("audit 11: rendering is capped at preexisting render callbacks",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 assert.ok(src.includes("dash.drawnVersion ~= dash.historyVersion"));
 assert.ok(src.includes("if not alive or layoutPending then return end"));
});
test("audit 12: no gameplay mutation is performed in diagnostic Start before compilation",()=>{
 const p=start.indexOf("local compiled, chunk, compileError = pcall(loadstring, source)");
 const q=start.indexOf("xpcall(chunk");
 assert.ok(p>0 && q>p);
 assert.ok(start.includes("game:HttpGet(url)"));
 assert.ok(start.includes("return failure(\"COMPILE\", compileError)"));
});
