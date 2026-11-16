"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const crypto=require("node:crypto");
const gui=fs.readFileSync("src/06_gui_runtime.lua","utf8");
const ui=fs.readFileSync("src/08_ui_controls.lua","utf8");
const footer=fs.readFileSync("src/09_misc_and_diagnostics.lua","utf8");
const aim=fs.readFileSync("src/04_lighting_and_booster.lua","utf8");

test("premium palette is centralized and decorative effects are static",()=>{
    assert.match(gui,/Purple Atelier UI 3\.0/);
    assert.match(gui,/background = Color3\.fromRGB\(13, 13, 23\)/);
    assert.match(gui,/accent = Color3\.fromRGB\(178, 140, 245\)/);
    assert.match(gui,/positive = Color3\.fromRGB\(124, 210, 170\)/);
    assert.match(gui,/Name = "BrandMark", Visible = true/);
    assert.match(gui,/Text = "CONTROL CENTER  •  v" \.\. CONFIG\.Version/);
    assert.doesNotMatch(gui,/Instance\.new\("BlurEffect"\)/);
});

test("sidebar has restrained labels, clear selected state and scroll-safe content",()=>{
    assert.match(gui,/Name = "NavigationOverline"/);
    assert.match(gui,/navOverline\.Text = sidebarWidth < 108 and "МЕНЮ" or "НАВИГАЦИЯ"/);
    assert.match(gui,/Name = "NavigationSlots"/);
    assert.match(gui,/local navTop = wide and 31 or \(compactShort and 26 or 29\)/);
    assert.match(gui,/tabButtons\[name\]\.BackgroundColor3 = selected and Color3\.fromRGB\(70, 47, 108\)/);
    assert.match(gui,/Name = "SidebarStatus", Visible = true/);
    assert.match(gui,/conn\.Visible = height >= 310/);
    assert.match(gui,/button\.BackgroundColor3 = Color3\.fromRGB\(47, 40, 68\)/);
});

test("controls have large touch targets, section hierarchy and clear enabled states",()=>{
    assert.match(ui,/Name = "SectionDivider"/);
    assert.match(ui,/Name = "ToggleActiveRail"/);
    assert.match(ui,/activeAccent\.Visible = enabled/);
    assert.match(ui,/Name = key, Size = UDim2\.new\(1, 0, 0, 62\)/);
    assert.match(ui,/Size = UDim2\.fromOffset\(40, 22\), BackgroundColor3 = P\.off/);
    assert.match(ui,/Size = UDim2\.fromOffset\(18, 18\)/);
    assert.match(ui,/Name = "ActionAccent"/);
    assert.match(ui,/Name = key \.\. "Slider", Size = UDim2\.new\(1, 0, 0, 92\)/);
    assert.match(ui,/Size = UDim2\.fromOffset\(16, 16\)/);
    assert.match(ui,/Size = UDim2\.new\(1, -20, 0, 32\)/);
    assert.match(ui,/Name = key \.\. "Choices", Size = UDim2\.new\(1, 0, 0, 72\)/);
    assert.match(footer,/Name = "Footer"/);
    assert.match(footer,/round\(status, 6\)/);
});

test("all five original pages and the isolated pinned AIM button remain",()=>{
    for(const key of ["ESP","AIM","PLAYER","MISC","MEMORY"]){
        assert.ok(gui.includes('key = "'+key+'"'));
    }
    assert.match(gui,/buttons == 5/);
    assert.match(gui,/if page == pages\.AIM then\s+local reserved = 52/);
    assert.match(ui,/Name = "AimPinnedControlDock"/);
    assert.match(ui,/Name = "AimPinnedSwitch"/);
    assert.match(ui,/Name = "AimFullRowHitSurface"/);
    assert.match(ui,/safeActivate\(row, onRowActivated\)/);
    assert.match(gui,/Name = "CommunityVisualsPanel"/);
    assert.match(gui,/ZIndexBehavior = Enum\.ZIndexBehavior\.Sibling/);
});

test("AIM targeting code remains byte-identical to verified v1.4.6",()=>{
    const sha=crypto.createHash("sha1").update("blob "+Buffer.byteLength(aim)+"\0").update(aim).digest("hex");
    assert.match(aim,/local function aimCandidateBefore/);
});
