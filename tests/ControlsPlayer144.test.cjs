"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const root=path.resolve(__dirname,"..");
const read=p=>fs.readFileSync(path.join(root,p),"utf8");
const gui=read("src/06_gui_runtime.lua");
const ui=read("src/08_ui_controls.lua");
const player=read("src/05_player_visuals.lua");
const state=read("src/02_state_and_services.lua");
const hub=read("Hub.lua");
const visuals=read("Visuals.lua");
const launcher=read("Start.lua");

test("v1.4.8 launcher and 12-source bundle match",()=>{
    assert.match(hub,/Version = "1\.4\.8"/);
    assert.match(launcher,/v1\.4\.8-full-stability-audit-test\/Visuals\.lua/);
    assert.equal(hub,visuals);
    const files=["00_config.lua","01_access_gate.lua","02_state_and_services.lua",
       "03_esp_tracker.lua","04_lighting_and_booster.lua","05_weapons_and_recoil.lua",
       "05_player_visuals.lua","06_gui_runtime.lua","07_esp_overlays.lua",
       "08_ui_controls.lua","09_misc_and_diagnostics.lua","10_run_and_cleanup.lua"];
    assert.equal(hub,files.map(f=>read("src/"+f)).join(""));
});
test("initial single-column is honored when controls are created afterward",()=>{
    assert.match(gui,/if info\.singleColumn then return info\.left end/);
    assert.match(gui,/info\.singleColumn = singleColumn/);
    assert.match(gui,/local desired = singleColumn and info\.left or info\[item\.side\]/);
    assert.match(gui,/local function registerWidget\(page, widget\)/);
});
test("weather modes are actual one-tap actions and CLEAR disables weather",()=>{
    assert.match(ui,/state\.playerWeatherEnabled = mode ~= "CLEAR"/);
    assert.match(ui,/state\.playerWeatherMode = "FOG"/);
    assert.match(ui,/local ok, err = pcall\(playerFX\.syncWeather\)/);
    assert.match(ui,/if refreshToggles\.playerWeatherEnabled then refreshToggles\.playerWeatherEnabled\(\) end/);
    assert.match(ui,/if refreshChoices\.playerWeatherMode then refreshChoices\.playerWeatherMode\(\) end/);
});
test("weather failures roll back enabled state and selected mode",()=>{
    assert.match(ui,/state\.playerWeatherEnabled = previousEnabled\s+error\(err\)/);
    assert.match(ui,/state\.playerWeatherMode = previousMode\s+error\(err\)/);
    assert.match(ui,/-- Возвращаем предыдущий выбор при сбое обработчика/);
});
test("choice widgets refresh automatically on profile changes",()=>{
    assert.match(state,/local refreshChoices = \{\}/);
    assert.match(ui,/refreshChoices\[key\] = repaint/);
    assert.match(gui,/for _, update in pairs\(refreshChoices\) do pcall\(update\) end/);
});
test("all switches use one central activation handler",()=>{
    assert.match(ui,/row\.Active = true\s+-- One centralized input path/);
    assert.match(ui,/safeActivate\(row, onRowActivated\)/);
    assert.doesNotMatch(ui,/connect\(row\.MouseButton1Click, onRowActivated\)/);
    assert.doesNotMatch(ui,/lastMouseActivation/);
});
test("safeActivate handles Activated and click fallback once",()=>{
    assert.match(gui,/local lastActivatedAt = -1e8/);
    assert.match(gui,/if consumedPress == pressNumber then return end/);
    assert.match(gui,/connect\(control\.InputBegan, function\(input\)/);
    assert.match(gui,/pointer and 0\.38 or 0\.18/);
    assert.match(gui,/connect\(control\.Activated, fire\)/);
    assert.match(gui,/connect\(control\.MouseButton1Click, function\(\) fire\(nil\) end\)/);
});
test("touch interaction is per gesture, not blocked by inertial scrolling",()=>{
    assert.match(gui,/if touch then touch\.endedAt = os\.clock\(\) end/);
    assert.match(gui,/if info and info\.dragged then return false end/);
    assert.doesNotMatch(gui,/suppressTapUntil = os\.clock\(\) \+ 0\.24/);
    assert.doesNotMatch(gui,/return os\.clock\(\) >= suppressTapUntil/);
});
test("AIM mouse click and hotkey continue to share a single state setter",()=>{
    assert.match(gui,/local function setAimEnabled\(enabled, activateKeyAim\)/);
    assert.match(ui,/setAimEnabled\(enabled, enabled\)/);
    assert.match(gui,/if refreshToggles\.aimbot then refreshToggles\.aimbot\(\) end/);
});
test("three independent aura layers and an occluded Highlight",()=>{
    assert.match(player,/Rate = 18 \+ strength \* 8/);
    assert.match(player,/Rate = 8 \+ strength \* 4/);
    assert.match(player,/Rate = 6 \+ strength \* 2/);
    assert.match(player,/Name = "Army124PlayerAuraMist"/);
    assert.match(player,/Name = "Army124PlayerAuraSparks"/);
    assert.match(player,/if state\.playerGlowEnabled or state\.playerAuraEnabled then/);
    assert.match(player,/DepthMode = Enum\.HighlightDepthMode\.Occluded/);
});
test("Glow light is independent, bounded and pulsing",()=>{
    assert.match(player,/if state\.playerGlowEnabled then\s+if not controller\.glowLight/);
    assert.match(player,/Range = 11 \+ strength \* 1\.8/);
    assert.match(player,/local base = 0\.85 \+ strength \* 0\.55/);
    assert.match(player,/animationConnection = RunService\.Heartbeat:Connect/);
});
test("weather remains local, reversible and compatible with Booster Atmosphere handoff",()=>{
    for (const marker of [
        'function controller.restoreWeather()',
        'boosterPro.releaseAtmosphereToPlayer(atmosphere)',
        'boosterPro.reapplyAtmosphereAfterPlayer(released)',
        'Lighting:FindFirstChildOfClass("Atmosphere")',
        'Name = "Army124PlayerRain"',
    ])assert.ok(player.includes(marker),marker);
    assert.doesNotMatch(player,/FireServer|InvokeServer|GetPlayers/);
});
test("ESP and Weapons 2.0, Key, Booster, menu remain bundled",()=>{
    for(const marker of ["local function refreshESP()","local recoil = (function()",
        "function boosterPro.restoreGraphicsSliced(", "PURPLE NEON 2.0",
        "function controller.restoreSpread()", "local function aimFrame(dt)",
        "local function windowMetrics(view)"])assert.ok(hub.includes(marker),marker);
});
