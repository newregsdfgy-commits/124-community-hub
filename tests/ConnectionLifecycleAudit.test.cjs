"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const test = require("node:test");
const src = fs.readFileSync("Visuals.lua","utf8");
const hub = fs.readFileSync("Hub.lua","utf8");
const start = fs.readFileSync("Start.lua","utf8");
function region(a,b) {
 const i=src.indexOf(a), j=src.indexOf(b,i+a.length);
 assert.ok(i>=0 && j>i, "Missing boundaries: "+a+" to "+b);
 return src.slice(i,j);
}
test("1.1.28 new branch is self-contained with identical executables",()=>{
 assert.equal(src,hub);
 assert.ok(src.includes('Version = "1.1.28"'));
 assert.ok(start.includes("v1.1.28-lifecycle-memory-test/Visuals.lua"));
});
test("new players have one dedicated character listener, not an eternal global registry item",()=>{
 const b=region("boosterPro.protectedCharacters =","-- Проверять каждую родительскую модель");
 assert.ok(b.includes("boosterPro.playerConnections = {}"));
 assert.ok(b.includes("if not alive or boosterPro.playerConnections[person] then return end"));
 assert.ok(b.includes("boosterPro.playerConnections[person] = person.CharacterAdded:Connect("));
 assert.ok(!b.includes("connect(person.CharacterAdded"));
});
test("PlayerRemoving disconnects character listener and removes stale protected name",()=>{
 const b=region("function boosterPro.unwatchPlayer(person)", "function boosterPro.stopWatchingPlayers()");
 assert.ok(b.includes("connection:Disconnect()"));
 assert.ok(b.includes("boosterPro.playerConnections[person] = nil"));
 assert.ok(b.includes("boosterPro.protectedNames[person.Name] = nil"));
 assert.ok(src.includes("connect(Players.PlayerRemoving, boosterPro.unwatchPlayer)"));
});
test("bulk unwatch is safe on unload and partial GUI initialization failure",()=>{
 const unwatch=region("function boosterPro.stopWatchingPlayers()", "for _, person in ipairs(perfCounters.roster) do boosterPro.watchPlayer");
 assert.ok(unwatch.includes("for person, connection in pairs(boosterPro.playerConnections) do"));
 assert.ok(unwatch.includes("connection:Disconnect()"));
 assert.ok(unwatch.includes("table.clear(boosterPro.protectedNames)"));
 const partial=region("local function abortPartialHub()", "env.ARMY124_CLEANUP = abortPartialHub");
 assert.ok(partial.includes("pcall(boosterPro.stopWatchingPlayers)"));
 const unload=region("cleanup = function(safeStop)", "env.ARMY124_CLEANUP = cleanup");
 assert.ok(unload.includes("boosterPro.stopWatchingPlayers()"));
});
test("camera change uses one actively owned viewport listener without global accumulation",()=>{
 const camera=region("local currentLayoutCamera = nil", "-- Линии сверху экрана");
 assert.ok(camera.includes('camera:GetPropertyChangedSignal("ViewportSize"):Connect(queueResponsiveLayout)'));
 assert.ok(!camera.includes('connect(camera:GetPropertyChangedSignal("ViewportSize")'));
 assert.ok(camera.includes("if camera == currentLayoutCamera then return end"));
 assert.ok(camera.includes("cameraLayoutConnection:Disconnect()"));
 assert.ok(camera.includes("boosterPro.layoutCameraConnection = cameraLayoutConnection"));
});
test("camera listeners disposed both on startup failure and normal Unload",()=>{
 const partial=region("local function abortPartialHub()", "env.ARMY124_CLEANUP = abortPartialHub");
 const unload=region("cleanup = function(safeStop)", "env.ARMY124_CLEANUP = cleanup");
 for(const b of [partial,unload]){
   assert.ok(b.includes("boosterPro.layoutCameraConnection:Disconnect()"));
   assert.ok(b.includes("boosterPro.layoutCameraConnection = nil"));
 }
});
test("no additional renderstep hooks or chat remotes introduced by memory fix",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 assert.ok(!/:FireServer\s*\(/.test(src));
 assert.ok(!/:InvokeServer\s*\(/.test(src));
});
test("FPS Booster and GUI core code remain intact",()=>{
 for(const phrase of ["function boosterPro.queueObject(obj)",
  "boosterPro.restoreGraphicsSliced()",
  "local function optimizeHierarchy(root, revision)",
  "function boosterPro.restoreObject(obj, snapshot)",
  'addButton(pages.MISC, "Диагностика Booster"',
  "if not boosterPro.complete then return end",
  "queueResponsiveLayout()", "hidePanelAnimation()",
  "TextChatService:CanUserChatAsync(LocalPlayer.UserId)"])
  assert.ok(src.includes(phrase), phrase);
});
