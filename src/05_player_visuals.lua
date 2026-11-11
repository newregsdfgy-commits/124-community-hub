-- PLAYER VISUAL FX: client-owned avatar aura, glow, rain and environmental grading.
-- One controller, no changes to game/server player stats or other characters.
local playerFX = (function()
    local controller = {
        character = nil, childConnection = nil,
        auraAttachment = nil, auraEmitter = nil,
        glowHighlight = nil, glowLight = nil,
        weatherTone = nil, environmentTone = nil,
        rainGui = nil, rainLines = {}, rainConnection = nil,
        fog = {}, atmosphere = {}, atmosphereObject = nil,
        rainElapsed = 0, lastError = nil,
    }
    local white = Color3.new(1, 1, 1)
    local avatarColors = {
        PURPLE = Color3.fromRGB(170, 102, 255),
        CYAN = Color3.fromRGB(86, 224, 241),
        GOLD = Color3.fromRGB(255, 202, 100),
        GREEN = Color3.fromRGB(101, 243, 155),
    }
    local environmentColors = {
        VIOLET = Color3.fromRGB(215, 183, 255),
        CYAN = Color3.fromRGB(180, 231, 245),
        WARM = Color3.fromRGB(255, 212, 169),
        GREEN = Color3.fromRGB(188, 239, 189),
    }
    local weather = {
        FOG = {
            start = 8, distance = 150, fogColor = Color3.fromRGB(152, 167, 184),
            tint = Color3.fromRGB(210, 220, 228), brightness = -0.06,
            contrast = 0.03, saturation = -0.18,
            density = 0.56, haze = 2.8,
            skyColor = Color3.fromRGB(170, 183, 193),
            skyDecay = Color3.fromRGB(132, 145, 160),
        },
        RAIN = {
            start = 20, distance = 250, fogColor = Color3.fromRGB(104, 124, 155),
            tint = Color3.fromRGB(180, 198, 224), brightness = -0.11,
            contrast = 0.08, saturation = -0.27,
            density = 0.40, haze = 2.1,
            skyColor = Color3.fromRGB(126, 147, 176),
            skyDecay = Color3.fromRGB(87, 106, 143),
        },
        NIGHT = {
            start = 30, distance = 380, fogColor = Color3.fromRGB(41, 61, 99),
            tint = Color3.fromRGB(126, 158, 210), brightness = -0.24,
            contrast = 0.13, saturation = -0.24,
            density = 0.34, haze = 1.3,
            skyColor = Color3.fromRGB(74, 94, 139),
            skyDecay = Color3.fromRGB(46, 64, 107),
        },
    }
    local function active()
        return alive and env.ARMY124_BOOT_TOKEN == CONFIG.BootToken
    end
    local function safeDestroy(instance)
        if instance then pcall(function() instance:Destroy() end) end
    end
    local function newOwned(className, props, parent)
        if not active() then error("Player FX: устаревший запуск", 2) end
        local object = Instance.new(className)
        local ok, err = pcall(function()
            for property, value in pairs(props) do object[property] = value end
            object.Parent = parent
        end)
        if not ok then
            safeDestroy(object)
            error("Player FX " .. className .. ": " .. tostring(err), 2)
        end
        return object
    end
    local function removeAvatar()
        safeDestroy(controller.auraEmitter)
        safeDestroy(controller.auraAttachment)
        safeDestroy(controller.glowHighlight)
        safeDestroy(controller.glowLight)
        controller.auraEmitter, controller.auraAttachment = nil, nil
        controller.glowHighlight, controller.glowLight = nil, nil
    end
    local function bindCharacter(character)
        if controller.childConnection then
            controller.childConnection:Disconnect()
            controller.childConnection = nil
        end
        removeAvatar() -- Old R6/R15 body and its attachments must never persist.
        controller.character = character
        if character then
            controller.childConnection = character.ChildAdded:Connect(function(child)
                if active() and child.Name == "HumanoidRootPart"
                    and child:IsA("BasePart") then
                    local ok, err = pcall(controller.syncAvatar)
                    if not ok then
                        controller.lastError = tostring(err)
                        warn("[124 Player] late Root: " .. tostring(err))
                    end
                end
            end)
        end
    end
    function controller.syncAvatar()
        if not active() then return end
        local character = LocalPlayer.Character
        if controller.character ~= character then bindCharacter(character) end
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and not root:IsA("BasePart") then root = nil end
        if not root then
            removeAvatar()
            return
        end
        local color = avatarColors[state.playerAuraColor] or avatarColors.PURPLE
        local strength = math.clamp(tonumber(state.playerGlowPower) or 3, 1, 5)
        if state.playerAuraEnabled then
            if not controller.auraAttachment or controller.auraAttachment.Parent ~= root then
                safeDestroy(controller.auraAttachment)
                controller.auraAttachment = newOwned("Attachment", {
                    Name = "Army124PlayerAuraAttachment",
                    Position = Vector3.new(0, -0.5, 0),
                }, root)
                controller.auraEmitter = nil
            end
            if not controller.auraEmitter or controller.auraEmitter.Parent ~= controller.auraAttachment then
                controller.auraEmitter = newOwned("ParticleEmitter", {
                    Name = "Army124PlayerAura",
                    Texture = "rbxasset://textures/particles/sparkles_main.dds",
                    Rate = 10 + strength * 5,
                    Lifetime = NumberRange.new(0.75, 1.25),
                    Speed = NumberRange.new(0.45, 1.8),
                    SpreadAngle = Vector2.new(175, 175),
                    Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.14),
                        NumberSequenceKeypoint.new(0.5, 0.27),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.26),
                        NumberSequenceKeypoint.new(0.7, 0.48),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    LightEmission = 0.75,
                    LightInfluence = 0,
                    LockedToPart = false,
                    Enabled = true,
                }, controller.auraAttachment)
            end
            controller.auraEmitter.Color = ColorSequence.new(color)
            controller.auraEmitter.Rate = 10 + strength * 5
        else
            safeDestroy(controller.auraEmitter)
            safeDestroy(controller.auraAttachment)
            controller.auraEmitter, controller.auraAttachment = nil, nil
        end
        if state.playerGlowEnabled then
            if not controller.glowHighlight or controller.glowHighlight.Parent ~= PlayerGui then
                safeDestroy(controller.glowHighlight)
                controller.glowHighlight = newOwned("Highlight", {
                    Name = "Army124PlayerGlow",
                    Adornee = character,
                    DepthMode = Enum.HighlightDepthMode.Occluded,
                    FillTransparency = 0.86,
                    OutlineTransparency = 0.24,
                    Enabled = true,
                }, PlayerGui)
            end
            controller.glowHighlight.Adornee = character
            controller.glowHighlight.FillColor = color
            controller.glowHighlight.OutlineColor = color
            if not controller.glowLight or controller.glowLight.Parent ~= root then
                safeDestroy(controller.glowLight)
                controller.glowLight = newOwned("PointLight", {
                    Name = "Army124PlayerLight",
                    Shadows = false,
                    Range = 12,
                    Enabled = true,
                }, root)
            end
            controller.glowLight.Color = color
            controller.glowLight.Brightness = 0.4 + strength * 0.35
            controller.glowLight.Range = 8 + strength * 1.5
        else
            safeDestroy(controller.glowHighlight)
            safeDestroy(controller.glowLight)
            controller.glowHighlight, controller.glowLight = nil, nil
        end
    end
    -- Save only Fog properties that this module changes. Dynamic game
    -- changes are retained as the new baseline, never blindly overwritten.
    local fogKeys = {"FogEnd", "FogStart", "FogColor"}
    local function writeFog(key, value)
        local old = Lighting[key]
        local slot = controller.fog[key]
        if not slot then
            slot = {original = old, last = nil}
            controller.fog[key] = slot
        elseif slot.last ~= nil and old ~= slot.last then
            slot.original = old
        end
        Lighting[key] = value
        if Lighting[key] ~= value then error("Player FX fog write failed: " .. key) end
        slot.last = value
    end
    local function restoreFog()
        local complete = true
        for _, key in ipairs(fogKeys) do
            local slot = controller.fog[key]
            if slot then
                local ok = pcall(function()
                    if Lighting[key] == slot.last then
                        Lighting[key] = slot.original
                        if Lighting[key] ~= slot.original then
                            error("Player FX fog restore mismatch: " .. key)
                        end
                    end
                    -- A newer value from the game belongs to the game.
                end)
                if ok then controller.fog[key] = nil
                else complete = false end
            end
        end
        return complete
    end
    local atmoKeys = {"Density", "Haze", "Color", "Decay"}
    function controller.restoreAtmosphere()
        local complete = true
        for _, key in ipairs(atmoKeys) do
            local slot = controller.atmosphere[key]
            if slot then
                local ok = pcall(function()
                    local target = slot.object
                    if target and target.Parent and target[key] == slot.last then
                        target[key] = slot.original
                        if target[key] ~= slot.original then
                            error("Player FX atmosphere restore mismatch: " .. key)
                        end
                    end
                    -- Do not overwrite newer game-owned Atmosphere updates.
                end)
                if ok then controller.atmosphere[key] = nil
                else complete = false end
            end
        end
        if complete then controller.atmosphereObject = nil end
        return complete
    end
    local function writeAtmosphere(target, key, value)
        local slot = controller.atmosphere[key]
        local current = target[key]
        if not slot or slot.object ~= target then
            slot = {object = target, original = current, last = nil}
            controller.atmosphere[key] = slot
        elseif slot.last ~= nil and current ~= slot.last then
            slot.original = current
        end
        target[key] = value
        if target[key] ~= value then
            error("Player FX atmosphere write failed: " .. key)
        end
        slot.last = value
        controller.atmosphereObject = target
    end
    function controller.restoreWeather()
        -- Always attempt both: a failure restoring Fog must not skip Atmosphere.
        local fogOK = restoreFog()
        local atmoOK = controller.restoreAtmosphere()
        return fogOK and atmoOK
    end
    function controller.pending()
        return next(controller.fog) ~= nil or next(controller.atmosphere) ~= nil
    end
    local function ensureTone(field, name)
        local tone = controller[field]
        if not tone or tone.Parent ~= Lighting then
            safeDestroy(tone)
            tone = newOwned("ColorCorrectionEffect", {
                Name = name, Enabled = true, Brightness = 0,
                Contrast = 0, Saturation = 0, TintColor = white,
            }, Lighting)
            controller[field] = tone
        end
        return tone
    end
    local function stopRain()
        if controller.rainConnection then
            pcall(function() controller.rainConnection:Disconnect() end)
            controller.rainConnection = nil
        end
        safeDestroy(controller.rainGui)
        controller.rainGui = nil
        table.clear(controller.rainLines)
        controller.rainElapsed = 0
    end
    local function startRain()
        if controller.rainGui and controller.rainGui.Parent and controller.rainConnection then return end
        stopRain()
        local gui = newOwned("ScreenGui", {
            Name = "Army124PlayerRain", IgnoreGuiInset = true,
            ResetOnSpawn = false, DisplayOrder = 8,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, PlayerGui)
        controller.rainGui = gui
        for index = 1, 24 do
            local streak = newOwned("Frame", {
                Name = "RainStreak_" .. tostring(index),
                BackgroundColor3 = Color3.fromRGB(182, 207, 235),
                BackgroundTransparency = 0.63 + (index % 4) * 0.06,
                BorderSizePixel = 0, Active = false, Visible = true,
                Size = UDim2.fromOffset(index % 3 == 0 and 2 or 1, 13 + index % 13),
                Rotation = 16,
            }, gui)
            controller.rainLines[index] = streak
        end
        controller.rainConnection = RunService.RenderStepped:Connect(function(dt)
            if not active() or not state.playerWeatherEnabled
                or state.playerWeatherMode ~= "RAIN" or gui ~= controller.rainGui then
                stopRain()
                return
            end
            controller.rainElapsed = controller.rainElapsed + math.min(dt, 0.12)
            if controller.rainElapsed < 0.055 then return end
            controller.rainElapsed = 0
            local camera = Workspace.CurrentCamera
            if not camera then return end
            local size = camera.ViewportSize
            local now = os.clock()
            for i, streak in ipairs(controller.rainLines) do
                local x = ((i * 173) % 997) / 997
                local y = (now * (0.26 + i % 4 * 0.04) + i * 0.113) % 1
                streak.Position = UDim2.fromOffset(x * size.X, y * size.Y)
            end
        end)
    end
    function controller.syncWeather()
        if not active() then return end
        local mode = state.playerWeatherEnabled and state.playerWeatherMode or "CLEAR"
        local profile = weather[mode]
        if profile then
            -- Lighting.Fog* is ignored when a game has Atmosphere.
            -- Only adjust the existing Atmosphere if it exists, with owned
            -- snapshots. Never insert a second Atmosphere or destroy the game's.
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmosphere then
                if not restoreFog() then error("Player FX: Fog restore pending") end
                if controller.atmosphereObject
                    and controller.atmosphereObject ~= atmosphere
                    and not controller.restoreAtmosphere() then
                    error("Player FX: previous Atmosphere restore pending")
                end
                writeAtmosphere(atmosphere, "Density", profile.density)
                writeAtmosphere(atmosphere, "Haze", profile.haze)
                writeAtmosphere(atmosphere, "Color", profile.skyColor)
                writeAtmosphere(atmosphere, "Decay", profile.skyDecay)
            else
                if not controller.restoreAtmosphere() then
                    error("Player FX: Atmosphere restore pending")
                end
                -- Fog settings work only without an active Atmosphere.
                writeFog("FogEnd", profile.distance)
                writeFog("FogStart", profile.start)
                writeFog("FogColor", profile.fogColor)
            end
            local tone = ensureTone("weatherTone", "Army124PlayerWeatherTone")
            tone.TintColor = profile.tint
            tone.Brightness = profile.brightness
            tone.Contrast = profile.contrast
            tone.Saturation = profile.saturation
        else
            if not controller.restoreWeather() then
                error("Player FX: не удалось вернуть погоду, повторим при выгрузке")
            end
            safeDestroy(controller.weatherTone)
            controller.weatherTone = nil
        end
        if mode == "RAIN" then startRain() else stopRain() end
    end
    function controller.syncEnvironment()
        if not active() then return end
        if not state.playerEnvironmentEnabled then
            safeDestroy(controller.environmentTone)
            controller.environmentTone = nil
            return
        end
        local tone = ensureTone("environmentTone", "Army124PlayerEnvironmentTone")
        local color = environmentColors[state.playerEnvironmentColor]
            or environmentColors.VIOLET
        local t = math.clamp((tonumber(state.playerEnvironmentStrength) or 40) / 100, 0, 1)
        tone.TintColor = white:Lerp(color, t)
        tone.Brightness = 0
        tone.Contrast = 0.05 * t
        tone.Saturation = 0.02 * t
    end
    function controller.sync()
        if not active() then return end
        controller.syncAvatar()
        controller.syncWeather()
        controller.syncEnvironment()
    end
    function controller.shutdown()
        if controller.childConnection then
            controller.childConnection:Disconnect()
            controller.childConnection = nil
        end
        removeAvatar()
        controller.character = nil
        stopRain()
        safeDestroy(controller.weatherTone)
        safeDestroy(controller.environmentTone)
        controller.weatherTone, controller.environmentTone = nil, nil
        return controller.restoreWeather()
    end
    function controller.diagnostics()
        return string.format("Aura=%s Glow=%s | Weather=%s/%s | Tint=%s/%s"
            .. " | Rain=%s | PendingWeather=%s | Root=%s | Error=%s",
            tostring(state.playerAuraEnabled), tostring(state.playerGlowEnabled),
            tostring(state.playerWeatherEnabled), tostring(state.playerWeatherMode),
            tostring(state.playerEnvironmentEnabled), tostring(state.playerEnvironmentColor),
            tostring(controller.rainGui ~= nil),
            tostring(controller.pending()),
            tostring(controller.character ~= nil
                and controller.character:FindFirstChild("HumanoidRootPart") ~= nil),
            tostring(controller.lastError or "none"))
    end
    -- Follow Atmosphere insertion/removal, never poll every frame.
    local function onAtmosphereChange(obj)
        if active() and state.playerWeatherEnabled and obj:IsA("Atmosphere") then
            local ok, err = pcall(controller.syncWeather)
            if not ok then
                controller.lastError = tostring(err)
                warn("[124 Player] Atmosphere change: " .. tostring(err))
            end
        end
    end
    connect(Lighting.ChildAdded, onAtmosphereChange)
    connect(Lighting.ChildRemoved, onAtmosphereChange)
    -- One character observer, no expensive Workspace.DescendantAdded scanning.
    connect(LocalPlayer.CharacterAdded, function(character)
        if not active() then return end
        bindCharacter(character)
        local ok, err = pcall(controller.syncAvatar)
        if not ok then controller.lastError = tostring(err) end
    end)
    connect(LocalPlayer.CharacterRemoving, function(character)
        if controller.character == character then bindCharacter(nil) end
    end)
    return controller
end)()

