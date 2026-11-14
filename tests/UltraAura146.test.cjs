"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const fs=require("node:fs"),path=require("node:path");
const read=p=>fs.readFileSync(path.join(__dirname,"..",p),"utf8");
const player=read("src/05_player_visuals.lua");
const ui=read("src/08_ui_controls.lua");
const state=read("src/02_state_and_services.lua");
const gui=read("src/06_gui_runtime.lua");
test("three distinct aura layers remain client-owned",()=>{
 for(const x of ["Army124PlayerAura","Army124PlayerAuraMist","Army124PlayerAuraSparks","Army124PlayerAuraUpper"])
   assert.ok(player.includes('Name = "'+x+'"'),x);
 assert.match(player,/DepthMode = Enum\.HighlightDepthMode\.Occluded/);
 assert.match(player,/safeDestroy\(controller\.auraSparks\)/);
 assert.doesNotMatch(player,/FireServer|InvokeServer|GetPlayers/);
});
test("mobile budget, heartbeat guard and glow pulse",()=>{
 assert.match(player,/fps >= 52/);
 assert.match(player,/fps > 0 and fps < 38/);
 assert.match(player,/local multiplier = eco and 0\.42 or 1/);
 assert.match(player,/controller\.auraAnimationElapsed < 0\.14 then return end/);
 assert.match(player,/controller\.auraAnimationConnection ~= animationConnection then return end/);
 assert.match(player,/controller\.auraAnimationConnection:Disconnect\(\)/);
});
test("new settings are saved, validated and editable",()=>{
 assert.match(state,/playerAuraQuality = "AUTO"/);
 assert.match(state,/playerGlowPulse = true/);
 assert.match(gui,/playerAuraQuality = \{AUTO = true, ECO = true, ULTRA = true\}/);
 assert.match(gui,/"playerAuraQuality", "playerGlowPulse"/);
 assert.match(ui,/"playerAuraQuality", function\(\) playerFX\.syncAvatar\(\) end/);
 assert.match(ui,/"playerGlowPulse", function\(\) playerFX\.syncAvatar\(\) end/);
});
test("v1.4.9 launcher and source bundles are consistent",()=>{
 assert.match(read("Start.lua"),/v1\.4\.9-legacy-aim-controls-weather-fix-test\/Visuals\.lua/);
 assert.equal(read("Hub.lua"),read("Visuals.lua"));
 assert.match(read("Hub.lua"),/Version = "1\.4\.9"/);
});
