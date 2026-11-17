"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const read=p=>fs.readFileSync(p,"utf8");
const cfg=read("src/00_config.lua");
const movement=read("src/08_ui_controls.lua");
const render=read("src/10_run_and_cleanup.lua");
const tracker=read("src/03_esp_tracker.lua");
const overlays=read("src/07_esp_overlays.lua");
const hub=read("Hub.lua");
test("v1.6.1 source bundles and loader are pinned to the same branch",()=>{
 assert.equal(hub,read("Visuals.lua"));
 assert.ok(hub.includes('Version = "1.6.1"'));
 assert.ok(read("Start.lua").includes("v1.6.1-stability-audit-test/Visuals.lua"));
});
test("ESP camera-motion boost cannot override long-distance AUTO budgets",()=>{
 assert.match(render,/and \(state\.performanceMode == "QUALITY"\s+or state\.espRangeMeters < CONFIG\.EspLongRangeMeters\)/);
 assert.match(render,/hz = math\.max\(hz, CONFIG\.EspCameraMotionVisualHz\)/);
 assert.match(render,/hz = math\.min\(hz, CONFIG\.EspExtremeVisualHz\)/);
 assert.match(render,/hz = math\.min\(hz, CONFIG\.EspLongVisualHz\)/);
 assert.match(render,/or perfCounters\.guard\.level == 0/);
});
test("Noclip part failures are isolated and retry readback recognizes post-write throws",()=>{
 assert.match(movement,/function movement\.recordPart\(obj\)/);
 assert.match(movement,/local readOK, collides = pcall\(function\(\) return obj\.CanCollide end\)/);
 assert.match(movement,/pcall\(function\(\) obj\.CanCollide = false end\)/);
 assert.match(movement,/return checked and after == false/);
 assert.match(movement,/movement\.collisionOriginals\[obj\] = collides/);
 assert.match(movement,/movement\.recordPart\(part\)/);
 assert.match(movement,/movement\.collisionOriginals\[part\] = nil/);
 assert.match(movement,/local existsOK, exists = pcall\(function\(\) return part\.Parent ~= nil end\)/);
});
test("Movement cleanup, speed, fly and pending snapshots remain implemented",()=>{
 for(const key of ["movement.restoreCollision","movement.restoreSpeed","movement.restoreFly",
   "movement.retryPending","movement.ensureFly","movement.startNoclip",
   "movement.disableAll"])assert.ok(movement.includes(key),key);
 assert.match(movement,/function movement\.sync\(\)/);
 assert.match(movement,/movement\.stepConnection = signal:Connect\(function\(\)/);
});
test("ESP, AIM and optional Player/Misc features remain intact",()=>{
 for(const tag of ["compactEspFlags","refreshESP","getPlayerColor",
 "bindLocalEspCharacter"]) assert.ok(tracker.includes(tag),tag);
 assert.match(overlays,/ensureShapeLines\(item, "box", 8\)/);
 assert.match(cfg,/EspCompactDetailsMaxMeters = 90/);
 assert.match(cfg,/EspCompactNameMaxMeters = 155/);
 for(const tag of ["aimFrame","recoil.frame","playerFX.syncWeather","privateMusic.play",
  "boosterPro.restoreGraphicsSliced"])assert.ok(hub.includes(tag),tag);
});
