-- PLAYER VISUAL FX: client-owned avatar aura, glow, rain and environmental grading.
-- One controller, no changes to game/server player stats or other characters.
local playerFX = (function()
    local controller = {
        character = nil, childConnection = nil, childRemovedConnection = nil,
        auraAttachment = nil, auraUpperAttachment = nil,
        auraEmitter = nil, auraMist = nil, auraSparks = nil,
        glowHighlight = nil, glowLight = nil,
        auraAnimationConnection = nil, auraAnimationElapsed = 0,
        auraEco = false, lastQuality = "OFF", auraStrength = nil,
        weatherTone = nil, environmentTone = nil,
        rainGui = nil, rainLines = {}, rainConnection = nil,
        fog = {}, atmosphere = {}, atmosphereObject = nil,
        rainElapsed = 0, lastError = nil,
        weatherFallback = false,
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
        if instance then
            pcall(function() instance:Destroy() end)
            boosterPro.playerFxOwned[instance] = nil
        end
    end
    local function newOwned(className, props, parent)
        if not active() then error("Player FX: устаревший запуск", 2) end
        local object = Instance.new(className)
        local ok, err = pcall(function()
            for property, value in pairs(props) do object[property] = value end
            -- Register exact instance before Parent fires Booster DescendantAdded.
            boosterPro.playerFxOwned[object] = true
            object.Parent = parent
        end)
        if not ok then
            safeDestroy(object)
            error("Player FX " .. className .. ": " .. tostring(err), 2)
        end
        return object
    end
    -- The original single emitter formed a bright spot at the waist rather
    -- than enveloping the avatar. Keep a bounded three-layer halo instead.
    local function auraUsesEcoBudget()
        if state.playerAuraQuality == "ECO" then return true end
        if state.playerAuraQuality == "ULTRA" then return false end
        -- AUTO: two FPS thresholds avoid visible quality flicker.
        local fps = tonumber(measuredFps) or 60
        if controller.auraEco then
            if fps >= 52 then controller.auraEco = false end
        elseif fps > 0 and fps < 38 then
            controller.auraEco = true
        end
        return controller.auraEco
    end
    local function updateAuraBudget(strength)
        if not state.playerAuraEnabled then
            controller.lastQuality = "OFF"
            return
        end
        local eco = auraUsesEcoBudget()
        local multiplier = eco and 0.42 or 1
        controller.lastQuality = eco and "ECO" or "ULTRA"
        local rates = {
            {controller.auraEmitter, 18 + strength * 8},
            {controller.auraMist, 8 + strength * 4},
            {controller.auraSparks, 6 + strength * 2},
        }
        for _, entry in ipairs(rates) do
            if entry[1] and entry[1].Parent then
                local desired = math.floor(entry[2] * multiplier + 0.5)
                if entry[1].Rate ~= desired then entry[1].Rate = desired end
            end
        end
    end
    local function applyAuraPulse()
        local pulse = state.playerGlowPulse
            and (0.5 + 0.5 * math.sin(os.clock() * 2.35)) or 0.5
        if controller.glowHighlight and controller.glowHighlight.Parent then
            local glow = state.playerGlowEnabled
            local fill = glow and 0.65 or 0.83
            local outline = glow and 0.04 or 0.25
            controller.glowHighlight.FillTransparency =
                math.clamp(fill + (0.5 - pulse) * 0.10, 0, 1)
            controller.glowHighlight.OutlineTransparency =
                math.clamp(outline + (0.5 - pulse) * 0.10, 0, 1)
        end
        if controller.glowLight and controller.glowLight.Parent then
            local strength = math.clamp(tonumber(state.playerGlowPower) or 3, 1, 5)
            local base = 0.85 + strength * 0.55
            controller.glowLight.Brightness = base * (0.94 + pulse * 0.15)
        end
    end
    local function stopAuraAnimation()
        if controller.auraAnimationConnection then
            pcall(function() controller.auraAnimationConnection:Disconnect() end)
            controller.auraAnimationConnection = nil
        end
        controller.auraAnimationElapsed = 0
    end
    local function startAuraAnimation()
        if controller.auraAnimationConnection then return end
        -- No permanent frame loop. At most ~7 changes/sec, and only when
        -- Aura or Glow is enabled. Quality budget is re-evaluated here.
        local animationConnection
        animationConnection = RunService.Heartbeat:Connect(function(dt)
            if controller.auraAnimationConnection ~= animationConnection then return end
            if not active()
                or not (state.playerAuraEnabled or state.playerGlowEnabled)
                or controller.character ~= LocalPlayer.Character then
                stopAuraAnimation()
                return
            end
            controller.auraAnimationElapsed =
                controller.auraAnimationElapsed + math.min(math.max(tonumber(dt) or 0, 0), 0.25)
            if controller.auraAnimationElapsed < 0.14 then return end
            controller.auraAnimationElapsed = 0
            if state.playerAuraEnabled then
                updateAuraBudget(math.clamp(tonumber(state.playerGlowPower) or 3, 1, 5))
            end
            applyAuraPulse()
        end)
        controller.auraAnimationConnection = animationConnection
    end
    local function removeAvatar()
        stopAuraAnimation()
        safeDestroy(controller.auraMist)
        safeDestroy(controller.auraSparks)
        safeDestroy(controller.auraEmitter)
        safeDestroy(controller.auraAttachment)
        safeDestroy(controller.auraUpperAttachment)
        safeDestroy(controller.glowHighlight)
        safeDestroy(controller.glowLight)
        controller.auraEmitter, controller.auraMist, controller.auraSparks = nil, nil, nil
        controller.auraAttachment, controller.auraUpperAttachment = nil, nil
        controller.glowHighlight, controller.glowLight = nil, nil
        controller.auraStrength = nil
        controller.lastQuality = "OFF"
    end
    local function bindCharacter(character)
        if controller.childConnection then
            controller.childConnection:Disconnect()
            controller.childConnection = nil
        end
        if controller.childRemovedConnection then
            controller.childRemovedConnection:Disconnect()
            controller.childRemovedConnection = nil
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
            controller.childRemovedConnection = character.ChildRemoved:Connect(function(child)
                if active() and child.Name == "HumanoidRootPart"
                    and child:IsA("BasePart") then
                    local ok, err = pcall(controller.syncAvatar)
                    if not ok then controller.lastError = tostring(err) end
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
            if not controller.auraAttachment or controller.auraAttachment.Parent ~= root
                or not controller.auraUpperAttachment or controller.auraUpperAttachment.Parent ~= root then
                safeDestroy(controller.auraMist)
                safeDestroy(controller.auraSparks)
                safeDestroy(controller.auraEmitter)
                safeDestroy(controller.auraAttachment)
                safeDestroy(controller.auraUpperAttachment)
                controller.auraAttachment = newOwned("Attachment", {
                    Name = "Army124PlayerAuraAttachment",
                    Position = Vector3.new(0, -0.35, 0),
                }, root)
                controller.auraUpperAttachment = newOwned("Attachment", {
                    Name = "Army124PlayerAuraUpper",
                    Position = Vector3.new(0, 1.25, 0),
                }, root)
                controller.auraEmitter, controller.auraMist, controller.auraSparks = nil, nil, nil
                controller.auraStrength = nil
            end
            -- Layer 1: saturated light particles disperse around the torso.
            if not controller.auraEmitter or controller.auraEmitter.Parent ~= controller.auraAttachment then
                safeDestroy(controller.auraEmitter)
                controller.auraStrength = nil
                controller.auraEmitter = newOwned("ParticleEmitter", {
                    Name = "Army124PlayerAura",
                    Texture = "rbxasset://textures/particles/sparkles_main.dds",
                    Rate = 18 + strength * 8,
                    Lifetime = NumberRange.new(0.9, 1.4),
                    Speed = NumberRange.new(0.55, 1.7),
                    SpreadAngle = Vector2.new(360, 360),
                    Rotation = NumberRange.new(0, 360),
                    RotSpeed = NumberRange.new(-35, 35),
                    Acceleration = Vector3.new(0, 0.8, 0),
                    Drag = 0.45,
                    VelocityInheritance = 0.06,
                    Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.15),
                        NumberSequenceKeypoint.new(0.40, 0.58),
                        NumberSequenceKeypoint.new(1, 0.03),
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.28),
                        NumberSequenceKeypoint.new(0.40, 0.10),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    LightEmission = 0.98, LightInfluence = 0,
                    LockedToPart = false, Enabled = true,
                }, controller.auraAttachment)
            end
            -- Layer 2: translucent haze for volume instead of opaque blobs.
            if not controller.auraMist or controller.auraMist.Parent ~= controller.auraAttachment then
                safeDestroy(controller.auraMist)
                controller.auraStrength = nil
                controller.auraMist = newOwned("ParticleEmitter", {
                    Name = "Army124PlayerAuraMist",
                    Texture = "rbxasset://textures/particles/smoke_main.dds",
                    Rate = 8 + strength * 4,
                    Lifetime = NumberRange.new(1.25, 1.85),
                    Speed = NumberRange.new(0.22, 0.85),
                    SpreadAngle = Vector2.new(360, 360),
                    Rotation = NumberRange.new(0, 360),
                    RotSpeed = NumberRange.new(-18, 18),
                    Acceleration = Vector3.new(0, 0.48, 0),
                    Drag = 0.7,
                    VelocityInheritance = 0.12,
                    Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.48),
                        NumberSequenceKeypoint.new(0.55, 1.35),
                        NumberSequenceKeypoint.new(1, 0.35),
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.91),
                        NumberSequenceKeypoint.new(0.45, 0.79),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    LightEmission = 0.78, LightInfluence = 0,
                    LockedToPart = false, Enabled = true,
                }, controller.auraAttachment)
            end
            -- Layer 3: small pale highlights spread above the shoulders.
            if not controller.auraSparks or controller.auraSparks.Parent ~= controller.auraUpperAttachment then
                safeDestroy(controller.auraSparks)
                controller.auraStrength = nil
                controller.auraSparks = newOwned("ParticleEmitter", {
                    Name = "Army124PlayerAuraSparks",
                    Texture = "rbxasset://textures/particles/sparkles_main.dds",
                    Rate = 6 + strength * 2,
                    Lifetime = NumberRange.new(0.55, 1.0),
                    Speed = NumberRange.new(0.5, 1.4),
                    SpreadAngle = Vector2.new(360, 360),
                    Rotation = NumberRange.new(0, 360),
                    RotSpeed = NumberRange.new(-55, 55),
                    Acceleration = Vector3.new(0, 0.95, 0),
                    Drag = 0.3,
                    VelocityInheritance = 0.08,
                    Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.09),
                        NumberSequenceKeypoint.new(0.45, 0.24),
                        NumberSequenceKeypoint.new(1, 0.01),
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.36),
                        NumberSequenceKeypoint.new(0.42, 0.06),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    LightEmission = 1, LightInfluence = 0,
                    LockedToPart = false, Enabled = true,
                }, controller.auraUpperAttachment)
            end
            controller.auraEmitter.Color = ColorSequence.new(color)
            controller.auraMist.Color = ColorSequence.new(color:Lerp(white, 0.26))
            controller.auraSparks.Color = ColorSequence.new(color:Lerp(white, 0.63))
            -- Rebuild static sequences ONLY when the user changes intensity.
            if controller.auraStrength ~= strength then
                local coreSize = 0.35 + strength * 0.08
                local hazeSize = 1.05 + strength * 0.11
                local sparkSize = 0.13 + strength * 0.038
                controller.auraEmitter.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, coreSize * 0.32),
                    NumberSequenceKeypoint.new(0.40, coreSize),
                    NumberSequenceKeypoint.new(1, 0.025),
                })
                controller.auraMist.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, hazeSize * 0.35),
                    NumberSequenceKeypoint.new(0.5, hazeSize),
                    NumberSequenceKeypoint.new(1, 0.18),
                })
                controller.auraSparks.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, sparkSize * 0.4),
                    NumberSequenceKeypoint.new(0.48, sparkSize),
                    NumberSequenceKeypoint.new(1, 0.01),
                })
                controller.auraStrength = strength
            end
            updateAuraBudget(strength)
        else
            safeDestroy(controller.auraMist)
            safeDestroy(controller.auraSparks)
            safeDestroy(controller.auraEmitter)
            safeDestroy(controller.auraAttachment)
            safeDestroy(controller.auraUpperAttachment)
            controller.auraEmitter, controller.auraMist, controller.auraSparks = nil, nil, nil
            controller.auraAttachment, controller.auraUpperAttachment = nil, nil
            controller.auraStrength = nil
            controller.lastQuality = "OFF"
        end
        -- Glow and Aura share ONE local silhouette Highlight; no x-ray.
        if state.playerGlowEnabled or state.playerAuraEnabled then
            if not controller.glowHighlight or controller.glowHighlight.Parent ~= character then
                safeDestroy(controller.glowHighlight)
                controller.glowHighlight = newOwned("Highlight", {
                    Name = "Army124PlayerGlow",
                    Adornee = character,
                    DepthMode = Enum.HighlightDepthMode.Occluded,
                    FillTransparency = 0.80,
                    OutlineTransparency = 0.22,
                    Enabled = true,
                }, character)
            end
            controller.glowHighlight.Adornee = character
            controller.glowHighlight.FillColor = color
            controller.glowHighlight.OutlineColor = color:Lerp(white, 0.35)
        else
            safeDestroy(controller.glowHighlight)
            controller.glowHighlight = nil
        end
        if state.playerGlowEnabled then
            if not controller.glowLight or controller.glowLight.Parent ~= root then
                safeDestroy(controller.glowLight)
                controller.glowLight = newOwned("PointLight", {
                    Name = "Army124PlayerLight",
                    Shadows = false, Range = 12,
                    Enabled = true,
                }, root)
            end
            controller.glowLight.Color = color
            controller.glowLight.Range = 11 + strength * 1.8
        else
            safeDestroy(controller.glowLight)
            controller.glowLight = nil
        end
        if state.playerAuraEnabled or state.playerGlowEnabled then
            applyAuraPulse()
            startAuraAnimation()
        else
            stopAuraAnimation()
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
        -- A denied setter may mutate before throwing, or clamp the target.
        -- Record the actual value before reporting failure so OFF can undo it.
        local writeOK, writeError = pcall(function() Lighting[key] = value end)
        local readOK, applied = pcall(function() return Lighting[key] end)
        if readOK and applied ~= old then
            slot.last = applied
        elseif not readOK then
            slot.last = value -- Unverified write: retain a recovery candidate.
        end
        if not writeOK then
            error("Player FX fog write failed: " .. key .. ": " .. tostring(writeError))
        end
        if not readOK or applied ~= value then
            error("Player FX fog write failed: " .. key)
        end
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
        if complete then
            local released = controller.atmosphereObject
            if released then boosterPro.playerFxOwned[released] = nil end
            controller.atmosphereObject = nil
            if released then boosterPro.reapplyAtmosphereAfterPlayer(released) end
        end
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
        -- Claim the exact Atmosphere before attempting a possibly partial
        -- write; Booster must not overwrite an un-restored Player snapshot.
        controller.atmosphereObject = target
        boosterPro.playerFxOwned[target] = true
        local writeOK, writeError = pcall(function() target[key] = value end)
        local readOK, applied = pcall(function() return target[key] end)
        if readOK and applied ~= current then
            slot.last = applied
        elseif not readOK then
            slot.last = value
        end
        if not writeOK then
            error("Player FX atmosphere write failed: " .. key .. ": " .. tostring(writeError))
        end
        if not readOK or applied ~= value then
            error("Player FX atmosphere write failed: " .. key)
        end
        slot.last = value
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
            -- An old queued callback must never stop a newer rain session.
            if gui ~= controller.rainGui then return end
            if not active() or not state.playerWeatherEnabled
                or state.playerWeatherMode ~= "RAIN" then
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
        controller.weatherFallback = false
        if profile then
            -- Rendering Atmosphere and Fog can be protected by game code,
            -- disabled by the executor, or rejected by a custom client.
            -- A denied property write must NOT make the Weather toggle dead:
            -- still apply our own local ColorCorrection and rain overlay.
            local ok, reason = pcall(function()
                local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
                if atmosphere then
                    if not restoreFog() then error("Player FX: Fog restore pending") end
                    if controller.atmosphereObject
                        and controller.atmosphereObject ~= atmosphere
                        and not controller.restoreAtmosphere() then
                        error("Player FX: previous Atmosphere restore pending")
                    end
                    if controller.atmosphereObject ~= atmosphere then
                        if not boosterPro.releaseAtmosphereToPlayer(atmosphere) then
                            error("Player FX: Booster Atmosphere restore pending")
                        end
                    end
                    writeAtmosphere(atmosphere, "Density", profile.density)
                    writeAtmosphere(atmosphere, "Haze", profile.haze)
                    writeAtmosphere(atmosphere, "Color", profile.skyColor)
                    writeAtmosphere(atmosphere, "Decay", profile.skyDecay)
                else
                    if not controller.restoreAtmosphere() then
                        error("Player FX: Atmosphere restore pending")
                    end
                    writeFog("FogEnd", profile.distance)
                    writeFog("FogStart", profile.start)
                    writeFog("FogColor", profile.fogColor)
                end
            end)
            if not ok then
                controller.weatherFallback = true
                controller.lastError = tostring(reason)
                -- Attempt rollback of partially applied properties, retaining
                -- snapshots when the engine refuses restoration. Never touch
                -- a newer external value.
                pcall(restoreFog)
                pcall(controller.restoreAtmosphere)
            else
                controller.lastError = nil
            end
            local tone = ensureTone("weatherTone", "Army124PlayerWeatherTone")
            tone.TintColor = profile.tint
            tone.Brightness = profile.brightness
            tone.Contrast = profile.contrast
            tone.Saturation = profile.saturation
        else
            -- OFF is always an actual button action. Restore failures retain
            -- snapshots for the existing maintenance worker rather than
            -- leaving a weather effect visibly enabled.
            if not controller.restoreWeather() then
                controller.lastError = "Player FX: weather restore pending"
                controller.weatherFallback = true
            else
                controller.lastError = nil
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
        if controller.childRemovedConnection then
            controller.childRemovedConnection:Disconnect()
            controller.childRemovedConnection = nil
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
        return string.format("Aura=%s Glow=%s | Quality=%s/%s Pulse=%s | Weather=%s/%s | Tint=%s/%s"
            .. " | Rain=%s | PendingWeather=%s | Root=%s | Error=%s",
            tostring(state.playerAuraEnabled), tostring(state.playerGlowEnabled),
            tostring(state.playerAuraQuality), tostring(controller.lastQuality),
            tostring(state.playerGlowPulse),
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

