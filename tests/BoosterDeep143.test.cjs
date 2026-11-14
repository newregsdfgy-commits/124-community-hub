"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const ROOT=path.resolve(__dirname,"..");
const read=(p)=>fs.readFileSync(path.join(ROOT,p),"utf8");
const booster=read("src/04_lighting_and_booster.lua");
const worker=read("src/09_misc_and_diagnostics.lua");
const ui=read("src/08_ui_controls.lua");
const state=read("src/02_state_and_services.lua");
const config=read("src/00_config.lua");
const release=read("Hub.lua");
const launcher=read("Start.lua");

test("version and bundle remain aligned",()=>{
    assert.match(release,/Version = "1\.4\.6"/);
    assert.match(launcher,/v1\.4\.6-ultra-aura-glow-test\/Visuals\.lua/);
    assert.equal(release,read("Visuals.lua"));
});
test("Booster monitors actual writes instead of assuming success",()=>{
    assert.match(booster,/local checked, applied = pcall\(function\(\) return obj\[key\] end\)/);
    assert.match(booster,/if checked and applied ~= current then/);
    assert.match(booster,/written\[key\] = applied/);
    assert.match(booster,/elseif wrote and not checked then/);
    assert.match(booster,/elseif not wrote then/);
});
test("writes denied by engine do not become fake graphics snapshots",()=>{
    const a=booster.indexOf("local function optimizeObject(obj, alreadyScreened)");
    const b=booster.indexOf("-- Проходим дерево",a);
    const body=booster.slice(a,b);
    assert.ok(a>0 && b>a);
    assert.ok(body.indexOf("if checked and applied ~= current then") <
        body.indexOf("if not snap then snap = {}; savedGraphics[obj] = snap end"));
    assert.match(body,/boosterPro\.deniedWrites = boosterPro\.deniedWrites \+ 1/);
});
test("boolean false writes are preserved in rollback metadata",()=>{
    assert.match(booster,/local lastWritten = nil\s+if written then lastWritten = written\[key\] end/);
    assert.doesNotMatch(booster,/local lastWritten = written and written\[key\] or nil/);
    assert.match(booster,/if lastWritten ~= nil and current == lastWritten then/);
});
test("clamped setter snapshots are restored using last actually applied value",()=>{
    assert.match(booster,/written\[key\] = applied/);
    assert.match(booster,/if lastWritten ~= nil and current == lastWritten then/);
    assert.match(booster,/obj\[key\] = original/);
});
test("BALANCED preserves map and prioritizes Lighting effects",()=>{
    const start=booster.indexOf("local function setBooster(enabled, keepBaseline)");
    const end=booster.indexOf("-- AIM: поиск",start);
    const snippet=booster.slice(start,end);
    assert.ok(start>0 && end>start);
    assert.ok(snippet.indexOf("optimizeHierarchy(Lighting, revision)") <
        snippet.indexOf("optimizeHierarchy(Workspace, revision)"));
    assert.match(snippet,/state\.boosterMode ~= "BALANCED"/);
    assert.match(booster,/if level == "BALANCED" then[\s\S]*?PostEffect/);
});
test("terrain color ownership uses a last written value per material",()=>{
    assert.match(booster,/local terrainWhite = Color3\.new\(1, 1, 1\)/);
    assert.match(booster,/local item = known\[material\]/);
    assert.match(booster,/if item and current ~= item\[3\] then/);
    assert.match(booster,/item\[2\] = current/);
    assert.match(booster,/item\[3\] = applied/);
});
test("Terrain color no-op setters never create snapshots",()=>{
    assert.match(booster,/if \(checked and applied ~= current\) or \(wrote and not checked\) then/);
    assert.match(booster,/if #items > 0 then savedTerrainColors =/);
});
test("Terrain restoration retains external game edits",()=>{
    assert.match(booster,/if current == imposed and current ~= original then/);
    assert.match(booster,/data\.terrain:SetMaterialColor\(material, original\)/);
    assert.match(booster,/-- If changed externally, leave the game's newer color untouched/);
});
test("Terrain retries only failed material snapshots",()=>{
    assert.match(booster,/local pending = \{\}/);
    assert.match(booster,/pending\[#pending \+ 1\] = item/);
    assert.match(booster,/data\.items = pending/);
    assert.match(booster,/savedTerrainColors = nil/);
});
test("Terrain already game-white isn't needlessly modified",()=>{
    assert.match(booster,/if okRead and current and current ~= terrainWhite then/);
});
test("Terrain grass restoration preserves external ownership and checks readbacks",()=>{
    assert.match(booster,/if original == false then return true/);
    assert.match(booster,/if current == false and current ~= saved\.original then/);
    assert.match(booster,/if saved\.getter\(saved\.terrain, "Decoration"\) ~= saved\.original then/);
});
test("Booster ignores its own client FX in streamed object queue",()=>{
    assert.match(worker,/if boosterPro\.playerFxOwned\[obj\] then return end/);
    assert.match(worker,/if not graphicsProperty\(obj\) then return end/);
});
test("Booster diagnostics expose denied and uncertain properties",()=>{
    assert.match(state,/unverifiedWrites = 0, deniedWrites = 0/);
    assert.match(ui,/boosterPro\.deniedWrites/);
    assert.match(ui,/boosterPro\.unverifiedWrites/);
    assert.match(booster,/boosterPro\.deniedWrites, boosterPro\.unverifiedWrites/);
});
test("older cleanup/worker callbacks and safe rollback retained",()=>{
    for(const name of [
        "function boosterPro.restoreGraphicsSliced(expectedRevision)",
        "function boosterPro.retryPendingGraphics()",
        "function boosterPro.restoreObject(obj, snapshot)",
        "function boosterPro.releaseAtmosphereToPlayer(obj)",
        "function boosterPro.reapplyAtmosphereAfterPlayer(obj)",
        "function boosterPro.restoreGraphicsEmergency()",
        "function boosterPro.restoreProtectedTree(character)",
        "local function setBooster(enabled, keepBaseline)",
    ])assert.ok(release.includes(name),name);
});
test("GUI retains FPS Booster modes and non-Booster features",()=>{
    for(const token of ['"FPS Booster Pro"','{value = "BALANCED"', 
        '{value = "WHITE"','{value = "ULTRA"',
        "local playerFX = (function()", "local function refreshESP()",
        "function controller.restoreSpread()", "PURPLE NEON 2.0"])
        assert.ok(release.includes(token),token);
});
test("new executable fault injection harness isolates source functions",()=>{
    const py=read("tests/build-booster143-runtime.py");
    assert.match(py,/extract\("local function optimizeObject\(obj, alreadyScreened\)"/);
    assert.match(py,/extract\("local terrainMaterialNames = \{"/);
    assert.match(py,/extract\("local function terrainAccessor\(kind\)"/);
});
