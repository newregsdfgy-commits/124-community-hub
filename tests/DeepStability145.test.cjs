"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const read=p=>fs.readFileSync(path.join(__dirname,"..",p),"utf8");
const player=read("src/05_player_visuals.lua");
const terrain=read("src/04_lighting_and_booster.lua");
const gui=read("src/06_gui_runtime.lua");
const launcher=read("Start.lua");
test("v1.4.6 launcher stays isolated from main",()=>{
 assert.match(read("src/00_config.lua"),/Version = "1\.4\.6"/);
 assert.ok(launcher.includes("v1.4.6-ultra-aura-glow-test/Visuals.lua"));
});
test("Fog and Atmosphere keep snapshots after partial writes",()=>{
 assert.match(player,/local writeOK, writeError = pcall\(function\(\) Lighting\[key\] = value end\)/);
 assert.match(player,/local writeOK, writeError = pcall\(function\(\) target\[key\] = value end\)/);
 assert.match(player,/slot\.last = applied/);
 assert.ok(player.indexOf("boosterPro.playerFxOwned[target] = true") < player.indexOf("local writeOK, writeError = pcall(function() target[key] = value end)"));
});
test("Terrain grass keeps recovery after setter throws following mutation",()=>{
 assert.match(terrain,/if \(checked and applied == false\) or not checked then/);
 assert.ok(terrain.indexOf("local checked, applied = pcall(getter, terrain, \"Decoration\")") < terrain.indexOf("savedTerrainDecoration = {"));
});
test("Real separate presses avoid the legacy 380ms UI lockout",()=>{
 assert.match(gui,/pressNumber = pressNumber \+ 1/);
 assert.match(gui,/if consumedPress == pressNumber then return end/);
 assert.match(gui,/pointer and 0\.38 or 0\.18/);
});
