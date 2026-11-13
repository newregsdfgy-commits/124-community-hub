"use strict";
const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "..");
const read = file => fs.readFileSync(path.join(root,file),"utf8");
const player = read("src/05_player_visuals.lua");
const booster = read("src/04_lighting_and_booster.lua");
const state = read("src/02_state_and_services.lua");
const gui = read("src/06_gui_runtime.lua");
const ui = read("src/08_ui_controls.lua");
const shutdown = read("src/09_misc_and_diagnostics.lua");
const hub = read("Hub.lua");
const visual = read("Visuals.lua");
const launcher = read("Start.lua");
test("both launchable Luau sources are exact mirrors of all 12 modules", () => {
    const modules = ["00_config.lua","01_access_gate.lua","02_state_and_services.lua",
      "03_esp_tracker.lua","04_lighting_and_booster.lua","05_weapons_and_recoil.lua",
      "05_player_visuals.lua","06_gui_runtime.lua","07_esp_overlays.lua",
      "08_ui_controls.lua","09_misc_and_diagnostics.lua","10_run_and_cleanup.lua"];
    assert.equal(hub,visual);
    assert.equal(modules.map(name=>read("src/"+name)).join(""),hub);
});
test("v1.4.1 launch and version locked to isolated stability branch", () => {
    assert.match(hub, /Version = "1\.4\.3"/);
    assert.match(launcher, /v1\.4\.3-booster-stability-test\/Visuals\.lua/);
    assert.match(launcher, /Version = "1\.4\.3"/);
});
test("Booster protects exact owner instances, never colliding object names", () => {
    assert.match(state, /playerFxOwned = setmetatable\(\{\}, \{__mode = "k"\}\)/);
    assert.match(booster, /if boosterPro\.playerFxOwned\[obj\] == true then return true end/);
    assert.doesNotMatch(booster, /obj\.Name == "Army124PlayerWeatherTone"/);
    assert.doesNotMatch(booster, /obj:IsA\("Atmosphere"\) and state\.playerWeatherEnabled/);
});
test("Player FX registers ownership before parenting new instances", () => {
    const start=player.indexOf("local function newOwned(");
    const end=player.indexOf("local function removeAvatar()",start);
    const block=player.slice(start,end);
    assert.ok(start>0 && end>start);
    assert.ok(block.indexOf("boosterPro.playerFxOwned[object] = true") <
              block.indexOf("object.Parent = parent"));
    assert.match(player, /boosterPro\.playerFxOwned\[instance\] = nil/);
});
test("Highlight created inside local character instead of unreliable PlayerGui", () => {
    assert.match(player,/controller\.glowHighlight\.Parent ~= character/);
    assert.match(player,/\}, character\)\s*end\s*controller\.glowHighlight\.Adornee = character/);
    assert.doesNotMatch(player,/controller\.glowHighlight\.Parent ~= PlayerGui/);
});
test("Root removal and respawn release watchers, aura and lights", () => {
    assert.match(player,/childRemovedConnection = character\.ChildRemoved:Connect/);
    assert.match(player,/controller\.childRemovedConnection:Disconnect\(\)/);
    assert.match(player,/safeDestroy\(controller\.auraEmitter\)\s*safeDestroy\(controller\.auraAttachment\)/);
    assert.match(player,/controller\.glowHighlight\.Adornee = character/);
});
test("reparented emitter is destroyed before allocating a replacement", () => {
    assert.match(player,/controller\.auraEmitter\.Parent ~= controller\.auraAttachment then\s*safeDestroy\(controller\.auraEmitter\)/);
});
test("rain callback cannot tear down a newer session", () => {
    const a=player.indexOf("RunService.RenderStepped:Connect(function(dt)");
    const b=player.indexOf("controller.rainElapsed = controller.rainElapsed",a);
    const code=player.slice(a,b);
    assert.ok(a>0 && b>a);
    assert.ok(code.indexOf("if gui ~= controller.rainGui then return end") <
              code.indexOf("stopRain()"));
    assert.match(player,/controller\.rainConnection:Disconnect\(\)/);
});
test("Booster releases its snapshots before Player changes Atmosphere", () => {
    assert.match(booster,/function boosterPro\.releaseAtmosphereToPlayer\(obj\)/);
    assert.match(booster,/if saved then boosterPro\.restoreObject\(obj, saved\) end/);
    assert.match(booster,/return savedGraphics\[obj\] == nil/);
    assert.match(player,/if not boosterPro\.releaseAtmosphereToPlayer\(atmosphere\) then/);
    assert.ok(player.indexOf("releaseAtmosphereToPlayer(atmosphere)") <
              player.indexOf('writeAtmosphere(atmosphere, "Density"'));
});
test("when weather ends Booster can recapture actual game baseline", () => {
    assert.match(player,/boosterPro\.playerFxOwned\[released\] = nil/);
    assert.match(player,/boosterPro\.reapplyAtmosphereAfterPlayer\(released\)/);
    assert.match(booster,/function boosterPro\.reapplyAtmosphereAfterPlayer\(obj\)/);
    assert.match(booster,/optimizeObject\(obj, false\)/);
});
test("No Player effects auto-enabled and cleanup keeps retryable weather", () => {
    for(const key of ["playerAuraEnabled", "playerGlowEnabled","playerWeatherEnabled",
                      "playerEnvironmentEnabled"]) {
       assert.ok(state.includes(key + " = false"));
    }
    assert.match(gui,/pcall\(playerFX\.shutdown\)/);
    assert.match(shutdown,/local playerFxOk, playerFxRestored = pcall\(playerFX\.shutdown\)/);
    assert.match(shutdown,/or playerFX\.pending\(\)/);
});
test("Player remains a fourth scrollable tab with separate controls and reset", () => {
    assert.match(gui,/key = "PLAYER", label = "Player"/);
    for(const label of ["PLAYER AURA", "PLAYER GLOW", "LOCAL WEATHER", "ENVIRONMENT COLOR"]) {
       assert.ok(ui.includes('addSection(pages.PLAYER, "'+label+'"'));
    }
    assert.match(ui,/"Выключить эффекты Player"/);
});
test("No server writes or local game movement changes added by Player FX", () => {
    assert.doesNotMatch(player,/FireServer|InvokeServer|GetPlayers|WalkSpeed|CanCollide|RemoteEvent/);
    assert.match(player,/LocalPlayer\.CharacterAdded/);
    assert.match(player,/LocalPlayer\.CharacterRemoving/);
});
test("Previous ESP, Weapons, FPS Booster and Purple Neon UI remain present", () => {
    for(const token of ["local function refreshESP()","local recoil = (function()",
       "function controller.restoreSpread()","local function aimFrame(dt)",
       "function boosterPro.restoreGraphicsSliced(", "PURPLE NEON 2.0",
       "cleanup = function(safeStop)"]) assert.ok(hub.includes(token),token);
});
