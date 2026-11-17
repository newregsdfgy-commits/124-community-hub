"use strict";
const fs=require("node:fs"), assert=require("node:assert/strict"), test=require("node:test");
const read=p=>fs.readFileSync(p,"utf8");
const config=read("src/00_config.lua"), state=read("src/02_state_and_services.lua");
const esp=read("src/03_esp_tracker.lua"), weapons=read("src/05_weapons_and_recoil.lua");
const launcher=read("Start.lua"), bundle=read("Visuals.lua");
test("v1.6.1 release and launcher match the test branch",()=>{
 assert.ok(config.includes('Version = "1.6.1"'));
 assert.ok(launcher.includes("v1.6.1-stability-audit-test/Visuals.lua"));
 assert.equal(bundle,read("Hub.lua"));
});
test("Performance Guard applies bounded ESP caps only when opted in",()=>{
 assert.ok(esp.includes("CONFIG.GuardEspMaxL1"));
 assert.ok(esp.includes("CONFIG.GuardEspMaxL2"));
 assert.ok(esp.includes("return configured"));
 assert.ok(state.includes("CONFIG.GuardEscalateSeconds"));
 assert.ok(state.includes("nextLevel < g.level"));
});
test("ESP GUI creation is limited per scan and existing visuals still update",()=>{
 assert.ok(config.includes("EspNewRendersPerScan = 4"));
 assert.ok(esp.includes("if not allowCreate then return false end"));
 assert.ok(esp.includes("createBudget = createBudget - 1"));
 assert.ok(esp.includes("pcall(updatePlayer, player, myRoot, createBudget > 0)"));
 assert.ok(esp.includes("deferredCreates"));
});
test("No Spread discovery and periodic updates do not enumerate Tool on RenderStep",()=>{
 const frame=weapons.slice(weapons.indexOf("local function recoilFrame(dt)"),weapons.indexOf("-- END RECOIL CONTROL"));
 assert.ok(frame.includes("queueSpreadRefresh()"));
 assert.ok(!frame.includes("safeApplySpread()"));
 assert.ok(weapons.includes("spread.discoveryList = descendants"));
 assert.ok(weapons.includes("CONFIG.SpreadDiscoveryStepDelay"));
 assert.ok(weapons.includes("spread.generation == generation"));
});
test("No Recoil gates GUI queries behind actual firing",()=>{
 const frame=weapons.slice(weapons.indexOf("local function recoilFrame(dt)"),weapons.indexOf("-- END RECOIL CONTROL"));
 assert.ok(frame.indexOf("if not firing then") < frame.indexOf("if isRobloxMenuOpen()"));
 assert.ok(frame.includes("and aimPro.equippedTool() then"));
 assert.ok(frame.includes("if dt <= 0 or dt > CONFIG.RecoilMaxFrameSeconds"));
});
