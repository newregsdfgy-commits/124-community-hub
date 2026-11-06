"use strict";
const fs=require("node:fs"),test=require("node:test"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
const hub=fs.readFileSync("Hub.lua","utf8"),start=fs.readFileSync("Start.lua","utf8");
function section(a,b){const i=src.indexOf(a),j=src.indexOf(b,i+a.length);assert.ok(i>=0&&j>i,"missing section "+a);return src.slice(i,j)}
test("v1.1.40 build uses canonical source and isolated test branch",()=>{
 assert.equal(src,hub);
 assert.ok(src.includes('Version = "1.1.40"'));
 assert.ok(start.includes("v1.1.40-stability-frametime-test/Visuals.lua"));
 assert.ok(start.includes('Version = "1.1.40"'));
});
test("nonessential chat, BHOP, Skeleton and CFG remain fully absent",()=>{
 for(const removed of ["spamChat","bunnyHop","espSkeleton","pages.CFG",'key = "CFG"',"utilityFX","chatPreferences","SendAsync","shapePairsR15"])assert.ok(!src.includes(removed),removed);
});
test("right-side ESP toggles defer full scans and redraws",()=>{
 const b=section("local controls = {","local function card(name, y, h)");
 assert.ok(b.includes("queueESPRefresh()"));
 assert.ok(b.includes("if not state.tracers then clearTracers() end"));
 assert.ok(b.includes("if not state.espBox then clearShapes() end"));
 assert.ok(!b.includes("refreshESP()"));
 assert.ok(!b.includes("refreshTracers()"));
 assert.ok(!b.includes("refreshShapes()"));
});
test("periodic scanner skips a roster scan just completed by the event queue",()=>{
 const b=section("task.spawn(function()\n    while alive do\n        -- Read the current mode","local espVisualElapsed = 0");
 assert.ok(b.includes("os.clock() - perfCounters.espVisual.lastScanAt >= interval"));
 assert.ok(b.includes("needsCleanup or (state.esp and due)"));
 assert.ok(b.includes("task.wait(interval)"));
 const q=section("local function queueESPRefresh()","local function isEspPart(obj)");
 assert.ok(q.includes("espRefreshQueued then return"));
 assert.ok(q.includes("CONFIG.EspEventMinSeconds - elapsed"));
});
test("protected character restoration early-outs with empty graphics snapshots",()=>{
 const b=section("function boosterPro.restoreProtectedTree(character)","local function setBooster(");
 assert.ok(b.includes("if not alive or not character or next(savedGraphics) == nil then return end"));
 assert.ok(b.includes("boosterPro.protectedRestoreSeen[character] then return"));
 assert.ok(b.includes("boosterPro.protectedRestoreRunning then return"));
 assert.ok(b.includes("local count, sliceStart = 0, os.clock()"));
 assert.ok(b.includes("if count >= 16"));
 assert.ok(b.includes("task.wait()"));
 assert.ok(b.includes("table.clear(boosterPro.protectedRestoreSeen)"));
 assert.ok(b.includes("boosterPro.protectedRestoreRunning = false"));
});
test("teardown unsubscribes event and render hooks before yielding rollback",()=>{
 const b=section("cleanup = function(safeStop)","env.ARMY124_CLEANUP = cleanup");
 const disabled=b.indexOf("alive = false"),unbound=b.indexOf("RunService:UnbindFromRenderStep");
 const disconnected=b.indexOf("for _, conn in ipairs(connections)");
 const graphics=b.indexOf("local graphicsOk, graphicsError = pcall(boosterPro.restoreGraphicsSliced)");
 assert.ok(disabled>=0&&unbound>disabled&&disconnected>unbound&&graphics>disconnected);
 for(const needle of ["pcall(releaseAntiAfk)","pcall(recoil.shutdown)",
 "pcall(perfCounters.session.setEnabled, false)","pcall(memoryFX.spin.reset)",
 "pcall(memoryFX.camera.reset)","pcall(boosterPro.stopWatchingPlayers)",
 "pcall(stopESPWatchers)","pcall(clearShapes)","pcall(hidePanelAnimation)",
 "pcall(deleteRender, player)","env.ARMY124_RECOVERY = pendingRecovery"])
 assert.ok(b.includes(needle),needle);
});
test("pending recovery never drops failed graphics, camera or pose snapshots",()=>{
 const b=section("pendingRecovery = function()","env.ARMY124_RECOVERY = pendingRecovery");
 for(const needle of ["pcall(boosterPro.restoreGraphicsSliced)","pcall(memoryFX.camera.reset)",
 "pcall(memoryFX.spin.restorePending)","next(savedGraphics) == nil",
 "next(memoryFX.camera.saved) == nil","next(memoryFX.spin.pending) == nil"])
 assert.ok(b.includes(needle),needle);
});
test("hot runtime hooks stay bounded and Box-only limits preserved",()=>{
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 assert.ok(src.includes("ShapeNewLinesPerDraw = 8"));
 assert.ok(src.includes("ShapeNewContainersPerDraw = 2"));
 assert.ok(!/:FireServer\s*\(/.test(src));
});
