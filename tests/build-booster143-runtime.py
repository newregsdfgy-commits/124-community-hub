#!/usr/bin/env python3
"""Execute exact Booster graphic/Terrain functions under the official Luau CLI.

Functions are extracted from production source, with only Roblox Instances and
property callbacks mocked. This does NOT claim Roblox device FPS improvements.
"""
from pathlib import Path
import tempfile

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / "src/04_lighting_and_booster.lua").read_text(encoding="utf-8")

def extract(start: str, end: str) -> str:
    pos = src.find(start)
    stop = src.find(end, pos + len(start))
    if pos < 0 or stop <= pos or src.find(start, pos+1) >= 0:
        raise ValueError(f"Cannot isolate unique production block: {start}")
    return src[pos:stop]

grass = extract("local function terrainAccessor(kind)", "-- Белая карта:")
terrain_colors = extract("local terrainMaterialNames = {", "-- FPS Booster Pro:")
graphics = extract("local graphicsWhite = Color3.new(1, 1, 1)", "-- Restore only a Booster-owned value.")
restore_prop = extract("function boosterPro.restoreBoosterProperty(obj, snapshot, key, original)",
                       "-- Original snapshots survive")
optimize = extract("local function optimizeObject(obj, alreadyScreened)",
                   "-- Проходим дерево")
restore_obj = extract("function boosterPro.restoreObject(obj, snapshot)",
                      "-- Hand an Atmosphere back")

preamble = r'''
-- Deterministic local model for Roblox Terrain, PostEffect, BasePart.
local alive = true
local state = {booster = true, boosterMode = "BALANCED"}
local Enum = {Material = {Grass="Grass", Rock="Rock", SmoothPlastic="SmoothPlastic"},
    RenderFidelity = {Performance="Performance"}}
local Color3 = {new = function(r,g,b) return r == 1 and g == 1 and b == 1 and "white" or "color" end}
local savedGraphics = setmetatable({}, {__mode="k"})
local savedTerrainColors, savedTerrainDecoration = nil, nil
local boosterPro = {graphicsWritten = setmetatable({}, {__mode="k"}),
    restoreFailures = 0, changedProperties = 0, deniedWrites = 0,
    unverifiedWrites = 0, playerFxOwned = setmetatable({}, {__mode="k"})}
boosterPro.isProtected = function() return false end
local warnings = {}
local warn = function(message) warnings[#warnings+1] = message end
local terrain = {Parent = {}, colors = {Grass = "green", Rock = "gray"},
    Decoration = true, denyRockRestore = false, silentRock = false}
function terrain:GetMaterialColor(material) return self.colors[material] end
function terrain:SetMaterialColor(material, value)
    if material == "Rock" and value == "gray" and self.denyRockRestore then
        error("Roblox refused restore")
    end
    if material == "Rock" and self.silentRock and value == "white" then return end
    self.colors[material] = value
end
function terrain:IsA(class) return class == "Terrain" end
local Workspace = {FindFirstChildOfClass = function(_, cls)
    if cls == "Terrain" then return terrain end
    return nil
end}
local gethiddenproperty = function(obj, property)
    assert(property == "Decoration")
    return obj.Decoration
end
local sethiddenproperty = function(obj, property, value)
    assert(property == "Decoration")
    obj.Decoration = value
end
local function makeMock(className, initial, writeMode)
    local storage = table.clone(initial)
    local object = {Parent = {}, ClassName = className}
    function object:IsA(category)
        return category == className or
            (category == "BasePart" and className == "MeshPart")
    end
    setmetatable(object, {
        __index = function(_, key) return storage[key] end,
        __newindex = function(_, key, value)
            if writeMode == "ignore" then return end
            if writeMode == "deny" then error("Game denied write") end
            if writeMode == "clamp" and value == false then
                storage[key] = "clamped"
            else
                storage[key] = value
            end
        end,
    })
    return object, storage
end
'''
checks = r'''
-- BALANCED turns off post-effects with exact reversible snapshots.
local effect, raw = makeMock("PostEffect", {Enabled=true})
optimizeObject(effect, false)
assert(raw.Enabled == false and savedGraphics[effect].Enabled == true)
assert(boosterPro.graphicsWritten[effect].Enabled == false)
local prevWrites = boosterPro.changedProperties
optimizeObject(effect, false)
assert(boosterPro.changedProperties == prevWrites, "repeat write was not avoided")
boosterPro.restoreObject(effect, savedGraphics[effect])
assert(raw.Enabled == true and savedGraphics[effect] == nil)

-- A setter returning success but ignoring the write must not create a fake
-- snapshot. This was incorrectly counted in v1.4.2.
local ignored, ignoredData = makeMock("PostEffect", {Enabled=true}, "ignore")
local before = boosterPro.changedProperties
optimizeObject(ignored, false)
assert(ignoredData.Enabled == true)
assert(savedGraphics[ignored] == nil and boosterPro.changedProperties == before)

-- A clamped setter needs its ACTUAL value recorded for rollback.
local clamped, clampedData = makeMock("PostEffect", {Enabled=true}, "clamp")
optimizeObject(clamped, false)
assert(clampedData.Enabled == "clamped")
assert(boosterPro.graphicsWritten[clamped].Enabled == "clamped")
boosterPro.restoreObject(clamped, savedGraphics[clamped])
assert(clampedData.Enabled == true and savedGraphics[clamped] == nil)

local denied, deniedData = makeMock("PostEffect", {Enabled=true}, "deny")
local deniedBefore = boosterPro.deniedWrites
optimizeObject(denied, false)
assert(boosterPro.deniedWrites == deniedBefore + 1)
assert(deniedData.Enabled == true and savedGraphics[denied] == nil)

-- Switching WHITE -> BALANCED restores the BasePart instead of leaving
-- material/texture changes cached indefinitely.
state.boosterMode = "WHITE"
local part, partData = makeMock("BasePart", {
    CastShadow = true, Material = "Wood", MaterialVariant = "PBR",
    Color = "brown", Reflectance = 0.25,
})
optimizeObject(part, false)
assert(partData.Material == "SmoothPlastic" and partData.Color == "white")
assert(savedGraphics[part].Material == "Wood")
state.boosterMode = "BALANCED"
optimizeObject(part, false)
assert(partData.Material == "Wood" and partData.Color == "brown")
assert(savedGraphics[part] == nil)
-- When the game changes Color externally between modes, it becomes the latest
-- restore baseline, not the stale first read.
state.boosterMode = "WHITE"
optimizeObject(part, false)
partData.Color = "new-game-color"
optimizeObject(part, false)
assert(savedGraphics[part].Color == "new-game-color")
boosterPro.restoreObject(part, savedGraphics[part])
assert(partData.Color == "new-game-color")

-- Material color whiting is local: skip already-white, track only real writes.
terrain.colors.Grass = "green"
terrain.colors.Rock = "gray"
whitenTerrain()
assert(terrain.colors.Grass == "white" and terrain.colors.Rock == "white")
assert(savedTerrainColors and #savedTerrainColors.items == 2)
-- External game change to Rock survives OFF. Grass restores from Booster write.
terrain.colors.Rock = "red-from-game"
assert(restoreTerrainColors())
assert(terrain.colors.Grass == "green")
assert(terrain.colors.Rock == "red-from-game")
assert(savedTerrainColors == nil)

-- A write that silently does nothing never creates fake material snapshot.
terrain.colors.Grass, terrain.colors.Rock = "white", "gray"
terrain.silentRock = true
whitenTerrain()
assert(savedTerrainColors == nil and terrain.colors.Rock == "gray")
terrain.silentRock = false

-- Partial Terrain restoration retries only failed entries and does not
-- repaint already restored materials.
terrain.colors.Grass, terrain.colors.Rock = "green", "gray"
whitenTerrain()
terrain.denyRockRestore = true
assert(not restoreTerrainColors())
assert(savedTerrainColors and #savedTerrainColors.items == 1)
assert(savedTerrainColors.items[1][1] == "Rock")
assert(terrain.colors.Grass == "green" and terrain.colors.Rock == "white")
terrain.colors.Grass = "game-new-green"
terrain.denyRockRestore = false
assert(restoreTerrainColors())
assert(terrain.colors.Grass == "game-new-green")
assert(terrain.colors.Rock == "gray")
assert(savedTerrainColors == nil)

-- Re-whitening after a game-owned color update must preserve that update.
terrain.colors.Grass, terrain.colors.Rock = "green", "gray"
whitenTerrain()
terrain.colors.Grass = "autumn-red"
whitenTerrain()
assert(savedTerrainColors and terrain.colors.Grass == "white")
assert(restoreTerrainColors() and terrain.colors.Grass == "autumn-red")

-- Decoration uses the same ownership: no snapshot when the game already has
-- grass disabled; otherwise restore only if our false is still the latest.
terrain.Decoration = false
assert(hideTerrainGrass() and savedTerrainDecoration == nil)
terrain.Decoration = true
assert(hideTerrainGrass() and savedTerrainDecoration ~= nil)
assert(terrain.Decoration == false)
assert(restoreTerrainGrass() and terrain.Decoration == true)
terrain.Decoration = true
assert(hideTerrainGrass())
terrain.Decoration = true -- another controller changed it while ON
assert(restoreTerrainGrass() and terrain.Decoration == true)

print("PASS: actual Booster properties, failed/clamped writes, mode downgrade,"
    .. " Terrain external colors, partial restore, grass and no-op setters")
'''
path = Path(tempfile.gettempdir()) / "Army124-Booster143.luau"
path.write_text(preamble + "\n" + grass + "\n" + terrain_colors + "\n"
                + graphics + "\n" + restore_prop + "\n" + optimize
                + "\n" + restore_obj + "\n" + checks, encoding="utf-8")
print("Generated executable production Booster audit:",path)
