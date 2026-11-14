#!/usr/bin/env python3
"""Run the real Player FX Luau source with deterministic local Roblox stand-ins.

This is isolated behavioral validation, NOT a Roblox engine or Android device test.
"""
from pathlib import Path
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "src/05_player_visuals.lua").read_text(encoding="utf-8")
if not source.startswith("-- PLAYER VISUAL FX:") or "local playerFX = (function()" not in source:
    raise SystemExit("Unexpected Player source header")

preamble = r'''
local function signal()
    local value = {connections = {}}
    function value:Connect(callback)
        local conn = {active = true, callback = callback}
        function conn:Disconnect() self.active = false end
        self.connections[#self.connections + 1] = conn
        return conn
    end
    function value:Fire(...)
        for _, entry in ipairs(self.connections) do
            if entry.active then entry.callback(...) end
        end
    end
    return value
end
local function color(r, g, b)
    local v = {R = r, G = g, B = b}
    function v:Lerp(other, t)
        return color(self.R + (other.R - self.R) * t,
            self.G + (other.G - self.G) * t,
            self.B + (other.B - self.B) * t)
    end
    return v
end
local Color3 = {new = color, fromRGB = function(r, g, b) return color(r/255, g/255, b/255) end}
local ColorSequence = {new = function(c) return {color = c} end}
local Vector2 = {new = function(x, y) return {X = x, Y = y} end}
local Vector3 = {new = function(x, y, z) return {X = x, Y = y, Z = z} end}
local UDim2 = {fromOffset = function(x, y) return {X = x, Y = y} end}
local NumberRange = {new = function(a, b) return {a = a, b = b} end}
local NumberSequenceKeypoint = {new = function(time, value) return {time, value} end}
local NumberSequence = {new = function(x) return x end}
local Enum = {HighlightDepthMode = {Occluded = "Occluded"},
    ZIndexBehavior = {Sibling = "Sibling"}}
local instances = {}
local Instance = {}
function Instance.new(class)
    local value = {ClassName = class, ChildAdded = signal(), ChildRemoved = signal(), Parent = nil}
    function value:Destroy()
        self.destroyed = true
        self.Parent = nil
    end
    function value:IsA(name)
        return name == self.ClassName or
            (name == "BasePart" and self.ClassName == "Part")
    end
    function value:FindFirstChild(name)
        return self.children and self.children[name] or nil
    end
    instances[#instances + 1] = value
    return value
end
local rootOne = Instance.new("Part")
rootOne.Name = "HumanoidRootPart"
local charOne = Instance.new("Model")
charOne.children = {HumanoidRootPart = rootOne}
local LocalPlayer = {Character = charOne, CharacterAdded = signal(),
    CharacterRemoving = signal()}
local Lighting = {
    FogEnd = 1000, FogStart = 0, FogColor = color(0.4, 0.5, 0.6),
    ChildAdded = signal(), ChildRemoved = signal(),
}
function Lighting:FindFirstChildOfClass(name)
    if name == "Atmosphere" then return self.currentAtmosphere end
    return nil
end
local originalFogColor = Lighting.FogColor
local PlayerGui = {}
local Workspace = {CurrentCamera = {ViewportSize = Vector2.new(900, 500)}}
local RunService = {RenderStepped = signal(), Heartbeat = signal()}
local measuredFps = 60
local CONFIG = {BootToken = {}}
local env = {ARMY124_BOOT_TOKEN = CONFIG.BootToken}
local alive = true
local state = {
    playerAuraEnabled = false, playerGlowEnabled = false,
    playerAuraColor = "PURPLE", playerGlowPower = 3,
    playerAuraQuality = "AUTO", playerGlowPulse = true,
    playerWeatherEnabled = false, playerWeatherMode = "CLEAR",
    playerEnvironmentEnabled = false, playerEnvironmentColor = "VIOLET",
    playerEnvironmentStrength = 40,
}
-- Production PlayerFX calls these Booster-owner methods. The integration
-- test verifies the call order and ownership; the separate static gates ensure
-- the project uses the real Booster methods with full snapshot restoration.
local boosterCalls = {released = 0, reapplied = 0}
local boosterPro = {
    playerFxOwned = setmetatable({}, {__mode = "k"}),
    releaseAtmosphereToPlayer = function(obj)
        boosterCalls.released = boosterCalls.released + 1
        return obj ~= nil
    end,
    reapplyAtmosphereAfterPlayer = function(obj)
        boosterCalls.reapplied = boosterCalls.reapplied + 1
    end,
}
local hooks = {}
local function connect(event, fn)
    local conn = event:Connect(fn)
    hooks[#hooks + 1] = conn
    return conn
end
local warn = function(message) error("Unexpected warning: " .. tostring(message)) end
'''
checks = r'''
-- Default state must allocate no effects and mutate no lighting.
playerFX.sync()
assert(#instances == 2 and Lighting.FogEnd == 1000)
assert(not playerFX.pending())

-- Aura and glow must attach only to the current local root.
state.playerAuraEnabled = true
state.playerGlowEnabled = true
playerFX.syncAvatar()
assert(playerFX.auraAttachment.Parent == rootOne)
assert(playerFX.auraEmitter.Rate == 42)
assert(playerFX.auraMist.Rate == 20)
assert(playerFX.auraSparks.Rate == 12)
assert(playerFX.auraUpperAttachment.Parent == rootOne)
assert(playerFX.lastQuality == "ULTRA")
assert(playerFX.auraAnimationConnection ~= nil)
assert(playerFX.glowLight.Parent == rootOne)
assert(playerFX.glowHighlight.Adornee == charOne)
assert(playerFX.glowHighlight.Parent == charOne, "Highlight must not be in PlayerGui")
-- Aura alone must have an outline even with Glow light OFF.
state.playerGlowEnabled = false
playerFX.syncAvatar()
assert(playerFX.glowLight == nil and playerFX.glowHighlight.Parent == charOne)
assert(playerFX.glowHighlight.FillTransparency >= 0.78
    and playerFX.glowHighlight.FillTransparency <= 0.88)
state.playerGlowEnabled = true
playerFX.syncAvatar()
assert(playerFX.glowLight.Parent == rootOne)
assert(playerFX.glowHighlight.FillTransparency >= 0.60
    and playerFX.glowHighlight.FillTransparency <= 0.70)
assert(boosterPro.playerFxOwned[playerFX.glowHighlight] == true)
local oldPulseCallback = playerFX.auraAnimationConnection.callback
local oldAura = playerFX.auraAttachment
local oldGlow = playerFX.glowHighlight

state.playerGlowPower = 5
state.playerAuraColor = "CYAN"
playerFX.syncAvatar()
assert(playerFX.auraEmitter.Rate == 58)
assert(playerFX.auraMist.Rate == 28)
assert(playerFX.auraSparks.Rate == 16)
measuredFps = 30
RunService.Heartbeat:Fire(0.20)
assert(playerFX.lastQuality == "ECO")
assert(playerFX.auraEmitter.Rate == 24)
assert(playerFX.auraMist.Rate == 12)
assert(playerFX.auraSparks.Rate == 7)
measuredFps = 60
RunService.Heartbeat:Fire(0.20)
assert(playerFX.lastQuality == "ULTRA")
assert(playerFX.auraEmitter.Rate == 58)
state.playerAuraQuality = "ECO"
playerFX.syncAvatar()
assert(playerFX.auraEmitter.Rate == 24)
state.playerAuraQuality = "ULTRA"
playerFX.syncAvatar()
assert(playerFX.auraEmitter.Rate == 58)
state.playerAuraQuality = "AUTO"
state.playerGlowPulse = false
playerFX.syncAvatar()
local stableLight = playerFX.glowLight.Brightness
RunService.Heartbeat:Fire(0.20)
assert(playerFX.glowLight.Brightness == stableLight)
state.playerGlowPulse = true
playerFX.syncAvatar()
local oldMist = playerFX.auraMist
local oldSparks = playerFX.auraSparks
playerFX.syncAvatar()
assert(playerFX.auraMist == oldMist and playerFX.auraSparks == oldSparks)
assert(playerFX.glowLight.Brightness > 1)

-- New character should own new particles and old ones must be destroyed.
local rootTwo = Instance.new("Part")
rootTwo.Name = "HumanoidRootPart"
local charTwo = Instance.new("Model")
charTwo.children = {HumanoidRootPart = rootTwo}
LocalPlayer.Character = charTwo
LocalPlayer.CharacterAdded:Fire(charTwo)
assert(oldAura.destroyed and oldGlow.destroyed)
local newPulseConnection = playerFX.auraAnimationConnection
oldPulseCallback(0.20)
assert(playerFX.auraAnimationConnection == newPulseConnection and newPulseConnection.active)
assert(playerFX.auraAttachment.Parent == rootTwo)
assert(playerFX.glowHighlight.Adornee == charTwo)
assert(playerFX.glowHighlight.Parent == charTwo)
-- A late Root removal is not a CharacterRemoving event and must still clean
-- orphan attachments, light and highlight. A new Root should recreate them.
charTwo.children.HumanoidRootPart = nil
charTwo.ChildRemoved:Fire(rootTwo)
assert(playerFX.auraAttachment == nil and playerFX.glowLight == nil)
local rootThree = Instance.new("Part")
rootThree.Name = "HumanoidRootPart"
charTwo.children.HumanoidRootPart = rootThree
charTwo.ChildAdded:Fire(rootThree)
assert(playerFX.auraAttachment.Parent == rootThree)
assert(playerFX.glowLight.Parent == rootThree)
assert(playerFX.glowHighlight.Parent == charTwo)

-- Fog and rain belong to client visual layer only.
state.playerWeatherEnabled = true
state.playerWeatherMode = "RAIN"
playerFX.syncWeather()
assert(Lighting.FogStart == 20 and Lighting.FogEnd == 250)
assert(playerFX.pending())
assert(playerFX.weatherTone.Parent == Lighting)
assert(playerFX.rainGui.Parent == PlayerGui)
assert(#playerFX.rainLines == 24)
RunService.RenderStepped:Fire(0.066)
assert(playerFX.rainLines[1].Position ~= nil)
local previousGui = playerFX.rainGui
local previousConnection = playerFX.rainConnection

state.playerEnvironmentEnabled = true
state.playerEnvironmentColor = "CYAN"
state.playerEnvironmentStrength = 100
playerFX.syncEnvironment()
assert(playerFX.environmentTone.Parent == Lighting)
local tint = playerFX.environmentTone.TintColor
assert(tint.R ~= 1 and tint.G ~= 1)

-- An external game update to FogColor must NOT be overwritten on restore.
local externalFog = color(0.2, 0.3, 0.4)
Lighting.FogColor = externalFog
state.playerWeatherEnabled = false
playerFX.syncWeather()
assert(Lighting.FogStart == 0 and Lighting.FogEnd == 1000)
assert(Lighting.FogColor == externalFog)
assert(not playerFX.pending())
assert(previousGui.destroyed and not previousConnection.active)
assert(playerFX.weatherTone == nil and playerFX.rainGui == nil)
-- Even if a previously queued callback sneaks in after rapid OFF/ON,
-- it must not disconnect or destroy the newest rain session.
state.playerWeatherEnabled = true
state.playerWeatherMode = "RAIN"
playerFX.syncWeather()
local newestRainGui = playerFX.rainGui
local newestRainConnection = playerFX.rainConnection
previousConnection.callback(0.066)
assert(playerFX.rainGui == newestRainGui and not newestRainGui.destroyed)
assert(playerFX.rainConnection == newestRainConnection and newestRainConnection.active)
state.playerWeatherEnabled = false
playerFX.syncWeather()

-- New external FogEnd during weather mode becomes the next restore baseline.
state.playerWeatherEnabled = true
state.playerWeatherMode = "FOG"
playerFX.syncWeather()
Lighting.FogEnd = 750 -- game-owned change while the filter is active
state.playerWeatherMode = "NIGHT"
playerFX.syncWeather()
assert(Lighting.FogEnd == 380)
state.playerWeatherEnabled = false
playerFX.syncWeather()
assert(Lighting.FogEnd == 750 and not playerFX.pending())

-- The game may already have Atmosphere, in which case Fog* is NOT rendered.
local existingAtmo = Instance.new("Atmosphere")
existingAtmo.Density = 0.12
existingAtmo.Haze = 0.35
existingAtmo.Color = color(0.9, 0.8, 0.7)
existingAtmo.Decay = color(0.5, 0.6, 0.7)
existingAtmo.Parent = Lighting
Lighting.currentAtmosphere = existingAtmo
local originalSkyColor = existingAtmo.Color
local originalSkyDecay = existingAtmo.Decay
state.playerWeatherEnabled = true
state.playerWeatherMode = "FOG"
playerFX.syncWeather()
assert(existingAtmo.Density == 0.56 and existingAtmo.Haze == 2.8)
assert(existingAtmo.Color ~= originalSkyColor)
assert(boosterCalls.released >= 1)
assert(boosterPro.playerFxOwned[existingAtmo] == true)
assert(playerFX.pending())
-- A change from the original game must become the next restoration baseline.
existingAtmo.Haze = 6
state.playerWeatherMode = "NIGHT"
playerFX.syncWeather()
assert(existingAtmo.Haze == 1.3)
state.playerWeatherEnabled = false
playerFX.syncWeather()
assert(existingAtmo.Density == 0.12 and existingAtmo.Haze == 6)
assert(existingAtmo.Color == originalSkyColor and existingAtmo.Decay == originalSkyDecay)
assert(boosterPro.playerFxOwned[existingAtmo] == nil)
assert(boosterCalls.reapplied >= 1)
assert(not playerFX.pending())
-- If an Atmosphere is added after Player weather was already active,
-- the ChildAdded listener switches from Fog to Atmosphere.
Lighting.currentAtmosphere = nil
existingAtmo.Parent = nil
state.playerWeatherEnabled = true
state.playerWeatherMode = "RAIN"
playerFX.syncWeather()
assert(Lighting.FogEnd == 250)
existingAtmo.Parent = Lighting
Lighting.currentAtmosphere = existingAtmo
Lighting.ChildAdded:Fire(existingAtmo)
assert(Lighting.FogEnd == 750 and existingAtmo.Density == 0.40)
state.playerWeatherEnabled = false
playerFX.syncWeather()
assert(not playerFX.pending())

-- Explicit user-off / unload removes owned objects, never changes the game avatar.
local weatherCount = #instances
assert(playerFX.shutdown())
assert(playerFX.auraAttachment == nil and playerFX.glowHighlight == nil)
assert(playerFX.auraMist == nil and playerFX.auraSparks == nil)
assert(playerFX.auraAnimationConnection == nil)
assert(playerFX.environmentTone == nil)
assert(playerFX.childConnection == nil and playerFX.childRemovedConnection == nil)
assert(not playerFX.pending())
assert(playerFX.shutdown())
assert(#instances == weatherCount)
-- A Roblox setter can change Fog and then throw: OFF must still restore it.
local fogData={FogEnd=910,FogStart=0,FogColor=originalFogColor}
local fogFail=true
Lighting=setmetatable({ChildAdded=signal(),ChildRemoved=signal(),
    FindFirstChildOfClass=function() return nil end}, {
    __index=function(_,key) return fogData[key] end,
    __newindex=function(_,key,value)
        fogData[key]=value
        if key=="FogEnd" and fogFail then
            fogFail=false
            error("FogEnd write failed after mutation")
        end
    end,
})
state.playerWeatherEnabled=true
state.playerWeatherMode="FOG"
assert(not pcall(playerFX.syncWeather),"injected Fog setter failure expected")
assert(Lighting.FogEnd==150 and playerFX.pending(),"partial Fog write must be tracked")
state.playerWeatherEnabled=false
assert(pcall(playerFX.syncWeather),"Fog restore must not throw")
assert(Lighting.FogEnd==910 and not playerFX.pending(),"Fog baseline was lost")
-- The same failure mode for Atmosphere must preserve ownership for Booster.
local atmoData={Density=0.12,Haze=0.4,Color=color(0.8,0.7,0.6),Decay=color(0.2,0.3,0.4)}
local atmoFail=true
local atmo=setmetatable({Parent=Lighting,ClassName="Atmosphere"}, {
    __index=function(_,key) return atmoData[key] end,
    __newindex=function(_,key,value)
        atmoData[key]=value
        if key=="Density" and atmoFail then
            atmoFail=false
            error("Density write failed after mutation")
        end
    end,
})
function Lighting:FindFirstChildOfClass(kind)
    if kind=="Atmosphere" then return atmo end
end
state.playerWeatherEnabled=true
assert(not pcall(playerFX.syncWeather),"injected Atmosphere setter failure expected")
assert(atmo.Density==0.56 and boosterPro.playerFxOwned[atmo]==true)
state.playerWeatherEnabled=false
assert(pcall(playerFX.syncWeather),"Atmosphere restore must not throw")
assert(atmo.Density==0.12 and not playerFX.pending())
assert(boosterPro.playerFxOwned[atmo]==nil)
assert(playerFX.shutdown())
print("PASS: Player FX real Luau callbacks — avatar, respawn, rain, tint, fog external baseline, shutdown")
'''
output = Path(tempfile.gettempdir()) / "Army124-Player140.luau"
output.write_text(preamble + "\n" + source + "\n" + checks, encoding="utf-8")
print(f"Created isolated Lua Player runtime harness: {output}")
