"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const root=path.join(__dirname,"..");
const read=(p)=>fs.readFileSync(path.join(root,p),"utf8");
const ui=read("src/06_gui_runtime.lua");
const widgets=read("src/08_ui_controls.lua");
const hub=read("Hub.lua"), mirrored=read("Visuals.lua");
const start=read("Start.lua");

test("v1.4.2 branch and payload version align",()=>{
    assert.match(hub,/Version = "1\.4\.3"/);
    assert.match(start,/v1\.4\.3-booster-stability-test\/Visuals\.lua/);
    assert.match(start,/Version = "1\.4\.3"/);
});
test("12-module deterministic build remains byte-identical",()=>{
    const names=["00_config.lua","01_access_gate.lua","02_state_and_services.lua",
        "03_esp_tracker.lua","04_lighting_and_booster.lua",
        "05_weapons_and_recoil.lua","05_player_visuals.lua",
        "06_gui_runtime.lua","07_esp_overlays.lua","08_ui_controls.lua",
        "09_misc_and_diagnostics.lua","10_run_and_cleanup.lua"];
    assert.equal(hub,mirrored);
    assert.equal(hub,names.map(n=>read("src/"+n)).join(""));
});
test("safe margins explicitly budget both axes of desktop and touch viewports",()=>{
    assert.match(ui,/local marginX = mobile and 16 or 34/);
    assert.match(ui,/local marginY = mobile and 18 or 38/);
    assert.match(ui,/local preferredWidth = wide and 930/);
    assert.match(ui,/local height = math\.min\(wide and 505 or 590, availableHeight\)/);
});
test("two-column layout is selected only when usable content is >=720",()=>{
    const expr="width - contentX - contentRight < 720";
    assert.ok(ui.includes(expr));
    assert.match(ui,/local singleColumn = \(not wide\) or page == pages\.ESP/);
    assert.match(ui,/info\.right\.Visible = false/);
    assert.match(ui,/info\.left\.Size = UDim2\.fromScale\(1, 1\)/);
});
test("five actual tabs and scrollable navigation are supported",()=>{
    for(const name of ["ESP","AIM","PLAYER","MISC","MEMORY"]){
        assert.ok(ui.includes('key = "'+name+'"'),name);
    }
    assert.match(ui,/buttons == 5/);
    assert.match(ui,/local navSlots = mk\("ScrollingFrame"/);
    assert.match(ui,/local buttonHeight = wide and 49 or 44/);
    assert.match(ui,/local bottomReserve = wide and 39/);
});
test("section accent cannot cross non-hero heading text",()=>{
    assert.match(widgets,/Size = UDim2\.fromOffset\(hero and 4 or 3, hero and 23 or 19\)/);
    assert.match(widgets,/Position = UDim2\.fromOffset\(18, hero and 5 or 3\)/);
    assert.doesNotMatch(widgets,/Size = UDim2\.fromOffset\(hero and 4 or 19, hero and 23 or 2\)/);
});
test("header labels include Player and match narrow layout visibility",()=>{
    assert.match(ui,/PLAYER = "Player", MISC = "Misc"/);
    assert.match(ui,/PLAYER = "Local aura, glow, weather and environment"/);
    assert.match(ui,/wide and width >= 850/);
});
test("stale GUI cleanup is scoped to the exact menu name, not arbitrary UIs",()=>{
    assert.match(ui,/existing\.Name == "Army124CommunityVisualsGUI"/);
    assert.match(ui,/existing:IsA\("ScreenGui"\)/);
    assert.match(ui,/existing\.Enabled = false/);
    assert.match(ui,/existing:Destroy\(\)/);
    assert.doesNotMatch(ui,/for _, existing in ipairs\(PlayerGui:GetChildren\(\)\) do[\s\S]{0,250}existing\.Name:find/);
});
test("UI root still includes clipping and independent native scrollers",()=>{
    assert.match(ui,/Name = "CommunityVisualsPanel"/);
    assert.match(ui,/ClipsDescendants = true, ZIndex = 2/);
    assert.match(ui,/Name = "PremiumContentPlate"/);
    assert.match(ui,/AutomaticCanvasSize = Enum\.AutomaticSize\.Y/);
    assert.match(ui,/ScrollingDirection = Enum\.ScrollingDirection\.Y/);
});
test("legacy screenshot ESP preview and header overlay are entirely removed",()=>{
    for(const term of ["Поиск ESP...", "ReferenceSearch", "ReferenceSafe",
                        "ReferenceTimer", "ReferenceActive", "ScreenshotESP",
                        "buildReferenceMenu()", "referenceESP"]){
        assert.equal(hub.includes(term),false,term);
    }
    assert.match(ui,/Name = "BrandTitle"/);
    assert.match(ui,/Name = "CurrentPageTitle"/);
    assert.match(ui,/Name = "CloseHub"/);
    assert.match(ui,/Name = "Minimize"/);
});
test("retiring the duplicate ESP preview keeps all actual native controls",()=>{
    const widgets=read("src/08_ui_controls.lua");
    for(const title of ["ESP подсветка", "Линия над игроками", "2D Box",
          "Имена", "Здоровье", "Дистанция", "Цвет ESP", "Локальный прицел"]){
       assert.ok(widgets.includes(title),title);
    }
    assert.ok(!read("src/09_misc_and_diagnostics.lua").includes("buildReferenceMenu"));
});
test("previous actual Player, ESP and diagnostics code not replaced by a mock",()=>{
    for(const token of ["local playerFX = (function()",
       "local function refreshESP()", "function controller.restoreSpread()",
       "function boosterPro.restoreGraphicsSliced(", "local function aimFrame(dt)",
       "boosterPro.uiAudit = function()", 'Text = "124 VISUALS"']){
       assert.ok(hub.includes(token),token);
    }
});
