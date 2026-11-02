"use strict";
const fs = require("node:fs");
const assert = require("node:assert/strict");
const test = require("node:test");
const src = fs.readFileSync("Visuals.lua", "utf8");
const hub = fs.readFileSync("Hub.lua", "utf8");
function setting(name) {
 const match = src.match(new RegExp(name + "\\s*=\\s*(\\d+(?:\\.\\d+)?)"));
 assert.ok(match, "missing setting " + name);
 return Number(match[1]);
}
test("booster test branch files and startup match",()=>{
 assert.equal(src,hub);
 assert.ok(src.includes('Version = "1.1.25"'));
 assert.ok(fs.readFileSync("Start.lua", "utf8").includes("v1.1.25-chat-permission-test"));
});
test("foreground traversal has smaller CPU and batch budgets",()=>{
 assert.ok(setting("BoosterBatch") <= 64);
 assert.ok(setting("BoosterSliceMs") <= 0.6);
 assert.ok(setting("BoosterLowFpsSliceMs") <= 0.25);
 assert.ok(setting("BoosterInitialDelay") >= 0.04);
 assert.ok(setting("BoosterLowFpsDelay") >= 0.08);
 assert.ok(src.includes("task.wait(measuredFps < 42 and CONFIG.BoosterLowFpsDelay"));
});
test("streaming worker does not run every 20ms or process 144 objects at once",()=>{
 assert.ok(setting("BoosterQueueBatch") <= 32);
 assert.ok(setting("BoosterQueueSliceMs") <= 0.4);
 assert.ok(setting("BoosterQueueDelay") >= 0.06);
 assert.ok(setting("BoosterQueueLowFpsDelay") >= 0.12);
 assert.ok(src.includes("and (measuredFps < 42 and CONFIG.BoosterQueueLowFpsDelay"));
});
test("repair waits for streaming quiet and enforces cooldown",()=>{
 assert.ok(setting("BoosterRepairCooldown") >= 30);
 assert.ok(setting("BoosterRepairIdleSeconds") >= 3);
 assert.ok(src.includes("boosterPro.queueLastAt = os.clock()"));
 assert.ok(src.includes("os.clock() - boosterPro.queueLastAt >= CONFIG.BoosterRepairIdleSeconds"));
 assert.ok(src.includes("boosterPro.repairRetryAt = os.clock() + CONFIG.BoosterRepairCooldown"));
});
test("graphics restore and original behavior preserved",()=>{
 for (const marker of ["boosterPro.restoreObject(obj, snapshot)", "savedGraphics[obj] = snap",
  "boosterPro.restoreGraphicsSliced()", "setBooster(false)", "optimizeHierarchy(Workspace, revision)"])
   assert.ok(src.includes(marker),marker);
 assert.ok(src.includes("CPU max init/queue:"));
});
test("no more renderstep bindings or new per-frame worker",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
});
