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
    local value = {ClassName = class, ChildAdded = signal(), Parent = nil}
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
local RunService = {RenderStepped = signal()}
local CONFIG = {BootToken = {}}
local env = {ARMY124_BOOT_TOKEN = CONFIG.BootToken}
local alive = true
local state = {
    playerAuraEnabled = false, playerGlowEnabled = false,
    playerAuraColor = "PURPLE", playerGlowPower = 3,
    playerWeatherEnabled = false, playerWeatherMode = "CLEAR",
    playerEnvironmentEnabled = false, playerEnvironmentColor = "VIOLET",
    playerEnvironmentStrength = 40,
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
assert(playerFX.auraEmitter.Rate == 25)
assert(playerFX.glowLight.Parent == rootOne)
assert(playerFX.glowHighlight.Adornee == charOne)
local oldAura = playerFX.auraAttachment
local oldGlow = playerFX.glowHighlight

state.playerGlowPower = 5
state.playerAuraColor = "CYAN"
playerFX.syncAvatar()
assert(playerFX.auraEmitter.Rate == 35)
assert(playerFX.glowLight.Brightness > 1)

-- New character should own new particles and old ones must be destroyed.
local rootTwo = Instance.new("Part")
rootTwo.Name = "HumanoidRootPart"
local charTwo = Instance.new("Model")
charTwo.children = {HumanoidRootPart = rootTwo}
LocalPlayer.Character = charTwo
LocalPlayer.CharacterAdded:Fire(charTwo)
assert(oldAura.destroyed and oldGlow.destroyed)
assert(playerFX.auraAttachment.Parent == rootTwo)
assert(playerFX.glowHighlight.Adornee == charTwo)

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
assert(playerFX.environmentTone == nil)
assert(playerFX.childConnection == nil)
assert(not playerFX.pending())
assert(playerFX.shutdown())
assert(#instances == weatherCount)
print("PASS: Player FX real Luau callbacks — avatar, respawn, rain, tint, fog external baseline, shutdown")
'''
output = Path(tempfile.gettempdir()) / "Army124-Player140.luau"
output.write_text(preamble + "\n" + source + "\n" + checks, encoding="utf-8")
print(f"Created isolated Lua Player runtime harness: {output}")
