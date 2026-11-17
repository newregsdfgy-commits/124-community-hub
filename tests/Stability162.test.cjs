"use strict";
const fs=require("node:fs"), assert=require("node:assert/strict"), test=require("node:test");
const read=p=>fs.readFileSync(p,"utf8");
const config=read("src/00_config.lua"), esp=read("src/03_esp_tracker.lua"),
 overlays=read("src/07_esp_overlays.lua"), aim=read("src/04_lighting_and_booster.lua"),
 state=read("src/02_state_and_services.lua"), recoil=read("src/05_weapons_and_recoil.lua"),
 run=read("src/10_run_and_cleanup.lua");
test("v1.6.2 bundles and pinned launcher",()=>{
 assert.ok(config.includes('Version = "1.6.2"'));
 assert.equal(read("Hub.lua"),read("Visuals.lua"));
 assert.ok(read("Start.lua").includes("v1.6.2-esp-aim-stability-test/Visuals.lua"));
});
test("ESP does not drop eligible players or boxes on Guard L1/L2",()=>{
 const limit=esp.slice(esp.indexOf("local function espLimit()"),esp.indexOf("-- StreamingEnabled may give us"));
 assert.match(limit,/return math.clamp\(math.floor\(state.espMaxTargets or CONFIG.EspMaxPlayers\), 8, 96\)/);
 assert.doesNotMatch(limit,/guard|Guard/i);
 assert.doesNotMatch(overlays,/budget = math.min\(budget, CONFIG.GuardShapeMaxL/);
 assert.ok(esp.includes("local createBudget = CONFIG.EspNewRendersPerScan"));
 assert.ok(run.includes("CONFIG.GuardVisualHzL2"));
});
test("No Spread discovers nested Tool descendants incrementally",()=>{
 assert.ok(recoil.includes("spread.discoveryList = {tool}"));
 assert.ok(recoil.includes("obj:GetChildren()"));
 assert.ok(recoil.includes("spread.discoveryIndex = last + 1"));
 assert.doesNotMatch(recoil,/tool:GetDescendants\(\)/);
 assert.ok(recoil.includes("spread.cleanupQueued"));
 assert.ok(recoil.includes("if spread.cleanupQueued then return end"));
});
test("AIM never writes a zero-length prediction and Recoil follows actual camera ownership",()=>{
 assert.ok(aim.includes("local look = predicted - origin"));
 assert.ok(aim.includes("lengthSquared <= 0.0025"));
 assert.ok(aim.includes("lengthSquared ~= lengthSquared"));
 assert.ok(aim.includes("aimPro.wroteCamera = true"));
 assert.ok(state.includes("aimPro.wroteCamera = false"));
 assert.ok(run.includes("local ok, err = pcall(aimFrame, dt)"));
 assert.ok(recoil.includes("if aimPro.wroteCamera then"));
});
