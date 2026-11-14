"use strict";
const test=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs");
const read=p=>fs.readFileSync(p,"utf8");
const ui=read("src/08_ui_controls.lua");
const gui=read("src/06_gui_runtime.lua");
const weather=read("src/05_player_visuals.lua");
const aim=read("src/04_lighting_and_booster.lua");
test("AIM and Weather are real GUI buttons, not inert labels",()=>{
 assert.match(ui,/safeActivate\(row, onRowActivated\)/);
 assert.match(ui,/addToggle\(pages\.AIM, "Aimbot"/);
 assert.match(ui,/setAimEnabled\(enabled, enabled\)/);
 assert.match(ui,/addToggle\(pages\.PLAYER, "Изменить погоду"/);
 assert.match(ui,/playerFX\.syncWeather\)/);
 assert.match(ui,/message = message \.\. " \| Запомни оружие либо отключи фильтр оружия"/);
});
test("Consumed GUI press ID can recover without another InputBegan",()=>{
 assert.match(gui,/consumedPress ~= pressNumber/);
 assert.match(gui,/now - lastActivatedAt < 0\.14 then/);
 assert.doesNotMatch(gui,/if consumedPress == pressNumber then return end/);
 assert.match(gui,/connect\(control\.MouseButton1Click, function\(\) fire\(nil\) end\)/);
});
test("World weather setters fail without rejecting user weather toggle",()=>{
 assert.match(weather,/local ok, reason = pcall\(function\(\)/);
 assert.match(weather,/controller\.weatherFallback = true/);
 assert.match(weather,/pcall\(restoreFog\)/);
 assert.match(weather,/pcall\(controller\.restoreAtmosphere\)/);
 assert.match(weather,/local tone = ensureTone\("weatherTone", "Army124PlayerWeatherTone"\)/);
 assert.match(weather,/if mode == "RAIN" then startRain\(\) else stopRain\(\) end/);
 assert.match(weather,/Fallback=%s \| PendingWeather=%s/);
});
test("AIM matches original v1.4.6 behavior",()=>{
 assert.match(aim,/if state\.aimSmoothness == 0 then\s+camera\.CFrame = goal/);
 assert.match(aim,/local function findAimTarget\(camera\)/);
 assert.doesNotMatch(aim,/AimLockLostGraceSeconds|AimSwitchConfirmSeconds/);
});
