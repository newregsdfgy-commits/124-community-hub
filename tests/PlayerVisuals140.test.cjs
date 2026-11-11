"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "..");
const read = name => fs.readFileSync(path.join(root, name), "utf8");
const visuals = read("src/05_player_visuals.lua");
const ui = read("src/08_ui_controls.lua");
const booster = read("src/04_lighting_and_booster.lua");
const runtime = read("src/06_gui_runtime.lua");
const shutdown = read("src/09_misc_and_diagnostics.lua");
const config = read("src/02_state_and_services.lua");
const hub = read("Hub.lua");
const loader = read("Start.lua");

test("Player nav and all four independent visual sections exist", () => {
  assert.match(runtime, /key = "PLAYER", label = "Player"/);
  for (const title of ["PLAYER AURA", "PLAYER GLOW", "LOCAL WEATHER", "ENVIRONMENT COLOR"])
    assert.ok(ui.includes('addSection(pages.PLAYER, "' + title + '"'), title);
});
test("new feature switches are OFF by default", () => {
  for (const key of ["playerAuraEnabled", "playerGlowEnabled", "playerWeatherEnabled", "playerEnvironmentEnabled"])
    assert.ok(config.includes(key + " = false"), key);
});
test("colors and intensities are validated when loading profiles", () => {
  assert.match(runtime, /playerGlowPower = \{1, 5\}/);
  assert.match(runtime, /playerEnvironmentStrength = \{0, 100\}/);
  assert.match(runtime, /playerAuraColor = \{PURPLE = true/);
  assert.match(runtime, /playerWeatherMode = \{CLEAR = true/);
  assert.match(runtime, /playerEnvironmentColor = \{VIOLET = true/);
  assert.match(runtime, /state\.playerAuraEnabled = false[\s\S]*?state\.playerGlowEnabled = false[\s\S]*?state\.playerWeatherEnabled = false/);
});
test("no server RemoteEvent or other-character modifications", () => {
  assert.doesNotMatch(visuals, /FireServer|InvokeServer|GetPlayers|SetPrimaryPartCFrame|WalkSpeed|CanCollide/);
  assert.match(visuals, /LocalPlayer\.Character/);
  assert.match(visuals, /LocalPlayer\.CharacterRemoving/);
  assert.match(visuals, /LocalPlayer\.CharacterAdded/);
});
test("aura and glow are explicitly owned and update only local character", () => {
  assert.match(visuals, /Name = "Army124PlayerAuraAttachment"/);
  assert.match(visuals, /Name = "Army124PlayerAura"/);
  assert.match(visuals, /Name = "Army124PlayerGlow"/);
  assert.match(visuals, /Name = "Army124PlayerLight"/);
  assert.match(visuals, /DepthMode = Enum\.HighlightDepthMode\.Occluded/);
  assert.match(visuals, /controller\.glowHighlight\.Adornee = character/);
});
test("respawn and streaming late Root never retain old avatar objects", () => {
  assert.match(visuals, /local function bindCharacter\(character\)/);
  assert.match(visuals, /removeAvatar\(\) -- Old R6\/R15/);
  assert.match(visuals, /character\.ChildAdded:Connect/);
  assert.match(visuals, /root and not root:IsA\("BasePart"\)/);
  assert.match(visuals, /controller\.childConnection:Disconnect\(\)/);
});
test("weather has four choices and bounded local rain GUI work", () => {
  for(const token of ['value = "CLEAR"', 'value = "FOG"', 'value = "RAIN"', 'value = "NIGHT"'])
    assert.ok(ui.includes(token), token);
  assert.match(visuals, /for index = 1, 24 do/);
  assert.match(visuals, /if controller\.rainElapsed < 0\.055 then return end/);
  assert.match(visuals, /controller\.rainConnection:Disconnect\(\)/);
  assert.match(visuals, /ResetOnSpawn = false, DisplayOrder = 8/);
});
test("independent environment tint blends toward neutral", () => {
  assert.match(visuals, /local environmentColors = \{/);
  assert.match(visuals, /white:Lerp\(color, t\)/);
  assert.match(visuals, /controller\.environmentTone = nil/);
});
test("world weather only touches three fog properties and own effects", () => {
  assert.match(visuals, /local fogKeys = \{"FogEnd", "FogStart", "FogColor"\}/);
  assert.match(visuals, /if Lighting\[key\] == slot\.last then/);
  assert.match(visuals, /slot\.original = old/);
  assert.match(visuals, /function controller\.restoreWeather\(\)/);
  assert.doesNotMatch(visuals, /Lighting\.ClockTime\s*=|Lighting\.Brightness\s*=/);
});
test("Booster protects exactly the two local tone effects", () => {
  assert.match(booster, /obj\.Name == "Army124PlayerWeatherTone"/);
  assert.match(booster, /obj\.Name == "Army124PlayerEnvironmentTone"/);
  assert.match(visuals, /"Army124PlayerWeatherTone"/);
  assert.match(visuals, /"Army124PlayerEnvironmentTone"/);
});
test("partial bootstrap and hot-unload explicitly shutdown player effects", () => {
  assert.match(runtime, /pcall\(playerFX\.shutdown\)/);
  assert.match(runtime, /playerFX\.restoreWeather/);
  assert.match(shutdown, /local playerFxOk, playerFxRestored = pcall\(playerFX\.shutdown\)/);
  assert.match(shutdown, /or playerFX\.pending\(\)/);
  assert.match(shutdown, /weatherOK and weatherRestored == true/);
});
test("Player reset and diagnostic controls exist", () => {
  assert.match(ui, /"Выключить эффекты Player"/);
  assert.match(ui, /"Диагностика Player FX"/);
  assert.match(ui, /playerFX\.diagnostics\(\)/);
  for (const key of ["playerAuraEnabled", "playerGlowEnabled", "playerWeatherEnabled", "playerEnvironmentEnabled"])
    assert.ok(ui.includes('"' + key + '"'));
});
test("existing weapons and ESP/UI modules stay in place", () => {
  for (const token of ["local recoil = (function()", "function controller.restoreSpread()",
    "local function refreshESP()", "PURPLE NEON 2.0", "cleanup = function(safeStop)",
    "addSection(pages.MISC, \"WEAPONS 2.0\""])
    assert.ok(hub.includes(token), token);
});
test("release and current branch are correct", () => {
  assert.match(hub, /Version = "1\.4\.0"/);
  assert.match(loader, /v1\.4\.0-player-visuals-test\/Visuals\.lua/);
  assert.match(loader, /Version = "1\.4\.0"/);
});
