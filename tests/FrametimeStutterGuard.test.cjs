"use strict";
const fs=require("node:fs"),test=require("node:test"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
const loader=fs.readFileSync("Start.lua","utf8");
function block(a,b){const x=src.indexOf(a),y=src.indexOf(b,x+a.length);assert.ok(x>=0&&y>x,"missing "+a);return src.slice(x,y)}
test("1: v1.1.39 files and loader agree",()=>{
 assert.ok(src.includes('Version = "1.1.39"'));
 assert.equal(src,fs.readFileSync("Hub.lua","utf8"));
 assert.ok(loader.includes("v1.1.39-lite-performance-test/Visuals.lua"));
 assert.ok(loader.includes('Version = "1.1.39"'));
});
test("2: ESP shape creation is bounded separately from display target limit",()=>{
 for(const needle of ["ShapeNewContainersPerDraw = 2","ShapeNewLinesPerDraw = 8",
  "shapeNewContainersLeft = CONFIG.ShapeNewContainersPerDraw",
  "shapeNewLinesLeft = CONFIG.ShapeNewLinesPerDraw"])assert.ok(src.includes(needle),needle);
 const s=block("local function shapeItem(player, character)","local function hideShape(item)");
 assert.ok(s.includes("if shapeNewContainersLeft <= 0 then return nil end"));
 assert.ok(s.includes("shapeNewContainersLeft = shapeNewContainersLeft - 1"));
 const l=block("local function ensureShapeLines(item, kind, count)","local function refreshShapes()");
 assert.ok(l.includes("while #lines < count and shapeNewLinesLeft > 0 do"));
 assert.ok(l.includes("shapeNewLinesLeft = shapeNewLinesLeft - 1"));
 assert.ok(l.includes("return #lines >= count"));
});
test("4: Max Distance slider does not synchronously sort player roster or create shapes",()=>{
 const s=block('makeSlider(top, "Max Distance"', 'mk("Frame", {Name = "ReferenceDivider"');
 assert.ok(s.includes("queueESPRefresh()"));
 assert.ok(!s.includes("refreshESP()"));
 assert.ok(!s.includes("refreshShapes()"));
 const q=block("local function queueESPRefresh()","local function isEspPart(obj)");
 assert.ok(q.includes("espRefreshQueued then return"));
 assert.ok(q.includes("task.delay(delaySeconds"));
});
test("5: Booster processes conservative batches without removing recovery rules",()=>{
 const b=block("local CONFIG = {","if game.PlaceId ~= CONFIG.PlaceId then");
 for(const v of ["BoosterBatch = 64","BoosterSliceMs = 0.65",
   "BoosterLowFpsSliceMs = 0.35","BoosterQueueBatch = 32",
   "BoosterQueueSliceMs = 0.45"])assert.ok(b.includes(v),v);
 assert.ok(src.includes("boosterPro.restoreGraphicsSliced()"));
 assert.ok(src.includes("boosterPro.repairRetryAt = os.clock() + CONFIG.BoosterRepairCooldown"));
});
test("6: no more per-frame render callbacks or network operations",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 assert.ok(!/:FireServer\s*\(/.test(src));
 assert.ok(!/:InvokeServer\s*\(/.test(src));
});
