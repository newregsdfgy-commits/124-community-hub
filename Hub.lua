-- 124 Community Hub v1.0.0 | Армия Роблокса РП
-- PlaceId: 18537079992
-- Локальный Luau-скрипт: ESP, Aim (голова/тело/ноги), Misc, FPS/Ping/часы.
-- Все изменяющие параметры функции выключены по умолчанию.
-- При повторном запуске старая копия очищается и настройки сцены восстанавливаются.

local CONFIG = {
    Version = "1.0.0",
    PlaceId = 18537079992,
    EspRefreshSeconds = 0.55,
    EspMaxPlayers = 16, -- Ограничение количества Highlight для слабых телефонов.
    StudMeters = 0.28, -- Стандартный масштаб Roblox: 1 stud ≈ 0.28 м.
    ConfigFile = "124_community_settings_v09.json",
    MenuKey = Enum.KeyCode.RightShift,
    EspFillTransparency = 0.78,
    AimFovDefaultPixels = 175,
    AimFovMinPixels = 40,
    AimFovMaxPixels = 400,
    AimLockTolerance = 1.18, -- При сопровождении допускаем небольшой выход из первоначального FOV.
    AimVisibleRaycastChecks = 6, -- Пропускаем невидимый мелкий мусор при проверке видимости.
    AimRangeMaxMeters = 180,
    AimRangeMinMeters = 5,
    AimSmoothnessBaseline = 33, -- Smoothness=3 эквивалентен скорости v0.3 (11).
    AimKeyDefault = "F6", -- По умолчанию назначена F6, можно выбрать другую клавишу.
    AimKeyFile = "124_community_aim_key.txt", -- Необязательное локальное сохранение.
    AimScanInterval = 0.12, -- Захват обновляется с ограничением частоты.
    BoosterBatch = 80,
    FullBrightBrightness = 2.1,
    FullBrightAmbient = Color3.fromRGB(170, 170, 170),
    FullBrightOutdoorAmbient = Color3.fromRGB(175, 175, 175),
    FullBrightExposure = 0.12,
    Accent = Color3.fromRGB(232, 75, 91), -- Красный акцент в стиле Red Panel.
    Neutral = Color3.fromRGB(245, 137, 141),
    Window = Color3.fromRGB(15, 16, 21),
    Surface = Color3.fromRGB(25, 26, 32),
    Muted = Color3.fromRGB(139, 141, 151),
}

if game.PlaceId ~= CONFIG.PlaceId then
    warn("[124 Community Hub] Неподдерживаемый PlaceId: " .. tostring(game.PlaceId))
    return
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[124 Community Hub] Локальный игрок недоступен")
    return
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
if not PlayerGui then
    warn("[124 Community Hub] PlayerGui недоступен")
    return
end

-- Общая среда позволяет безопасно перезапустить скрипт в том же executor.
local env = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then env = result end
end
if type(env.ARMY124_CLEANUP) == "function" then
    pcall(env.ARMY124_CLEANUP)
end

local state = {
    esp = false,
    names = true,
    health = true,
    distance = true,
    teamColors = true,
    tracers = false,
    espBox = false,
    espSkeleton = false,
    espEnemyOnly = false,
    espRangeMeters = 200,
    espColorPreset = "TEAM", -- TEAM / GOLD / GREEN / WHITE
    espLineThickness = 2,
    performanceMode = "AUTO", -- AUTO / ECO / QUALITY
    activeHud = true,
    aimRangeMeters = 180,
    aimSmoothness = 3, -- 0 = мгновенно, 1 = быстро, 10 = максимально плавно.
    aimSmoothX = 5,
    aimSmoothY = 5,
    prediction = false,
    predictionSeconds = 0.08,
    targetLock = true,
    aimFovPixels = CONFIG.AimFovDefaultPixels,
    fovVisible = true,
    fovThickness = 2,
    visibleCheck = true, -- ON: только видимые, OFF: допускаются цели за стенами.
    fullbright = false,
    aimbot = false,
    aimKeyName = CONFIG.AimKeyDefault,
    aimMode = "body", -- head / body / legs; сохраняем прежний режим по умолчанию.
    teamCheck = true,
    antiAfk = false,
    booster = false,
    hud = true,
}

local alive = true
local connections = {}
local renderData = {}
local savedLighting = nil
local savedGraphics = setmetatable({}, { __mode = "k" })
local boosterRevision = 0
-- Только для исполнителей, умеющих читать/писать Terrain.Decoration.
-- Если это недоступно, не трогаем Terrain: полноценного SmoothPlastic для него нет.
local savedTerrainDecoration = nil
local aimHeldMouse = false
local aimHeldTouch = false
local aimHeldKey = false
local captureAimKey = false
local lastAimKeyToggle = -10
local keybindButton = nil
local keybindHint = nil
local repaintAimKeybind = function() end
local aimBound = false
local aimBindingName = "Army124CommunityAim_" .. tostring(LocalPlayer.UserId)
local statusMessage = nil
local refreshToggles = {}
local measuredFps = 60
local perfCounters = {espCount = 0, shapeCount = 0, aimScanMs = 0}
local shapeGui, activeInfo
local defaultSettings = nil
local profileName = "CUSTOM"
local clearTracers = function() end
local syncEspVisuals = function() end -- Переопределяется после создания ESP GUI.
local flushConfig = function() end
local releaseAntiAfk = function() end
local refreshSliders = {}
local repaintAimMode = function() end
local repaintColors = function() end
local repaintPerf = function() end
local repaintConfig = function() end
local requestSave = function() end
local lightingApplying = false
local aimTarget = nil
local aimNextScan = 0
local tracerGui = nil
local fovGui = nil

local function validAimKeyName(name)
    if type(name) ~= "string" then return false end
    if name == "NONE" then return true end
    if name == CONFIG.MenuKey.Name then return false end -- Клавиша управления меню зарезервирована.
    local ok, keycode = pcall(function() return Enum.KeyCode[name] end)
    return ok and keycode ~= nil and keycode ~= Enum.KeyCode.Unknown
end

local function saveAimKey(name)
    if not validAimKeyName(name) then return end
    env.ARMY124_AIM_KEY = name
    if type(writefile) == "function" then
        pcall(writefile, CONFIG.AimKeyFile, name)
    end
end

local function restoreAimKey()
    local stored = env.ARMY124_AIM_KEY
    if type(readfile) == "function" then
        local ok, fileValue = pcall(readfile, CONFIG.AimKeyFile)
        if ok and validAimKeyName(fileValue) then stored = fileValue end
    end
    if validAimKeyName(stored) then state.aimKeyName = stored end
end
restoreAimKey()

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local function mk(class, properties, parent)
    local instance = Instance.new(class)
    for key, value in pairs(properties or {}) do instance[key] = value end
    instance.Parent = parent
    return instance
end

local function round(instance, radius)
    mk("UICorner", {CornerRadius = UDim.new(0, radius)}, instance)
end

local function outline(instance, color)
    mk("UIStroke", {Color = color, Transparency = 0.30, Thickness = 1}, instance)
end

local function isLive(instance)
    return typeof(instance) == "Instance" and instance.Parent ~= nil
end

local function tell(message)
    if statusMessage and statusMessage.Parent then
        statusMessage.Text = message
    end
    print("[124 Community Hub] " .. message)
end

-- ESP: исходная Highlight/Billboard логика из v0.1, с удалением после респавна.
local function deleteRender(player)
    local item = renderData[player]
    if not item then return end
    for _, inst in ipairs({item.highlight, item.billboard, item.tracer}) do
        if inst then pcall(function() inst:Destroy() end) end
    end
    renderData[player] = nil
end

local function getPlayerColor(player)
    if state.espColorPreset == "GOLD" then return CONFIG.Accent end
    if state.espColorPreset == "GREEN" then return Color3.fromRGB(93, 210, 152) end
    if state.espColorPreset == "WHITE" then return Color3.fromRGB(229, 229, 223) end
    if state.teamColors and player.Team ~= nil then
        return player.TeamColor.Color
    end
    return CONFIG.Neutral
end

local function perfTier()
    if state.performanceMode == "ECO" then return "ECO" end
    if state.performanceMode == "QUALITY" then return "QUALITY" end
    if measuredFps < 26 then return "ECO" end
    return "BALANCED"
end

local function espLimit()
    local tier = perfTier()
    if tier == "ECO" then return 8 end
    if tier == "QUALITY" then return 20 end
    return CONFIG.EspMaxPlayers
end

local function createRender(player, character, head)
    local hl = mk("Highlight", {
        Name = "Army124ESPHighlight",
        Adornee = character,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        FillTransparency = CONFIG.EspFillTransparency,
        OutlineTransparency = 0,
    }, character)
    local bb = mk("BillboardGui", {
        Name = "Army124ESPLabel",
        Adornee = head,
        AlwaysOnTop = true,
        LightInfluence = 0,
        MaxDistance = state.espRangeMeters / CONFIG.StudMeters,
        Size = UDim2.fromOffset(192, 49),
        StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0),
        ResetOnSpawn = false,
    }, PlayerGui)
    local nameLabel = mk("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 25),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextStrokeTransparency = 0.3,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "",
    }, bb)
    local healthLabel = mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 25),
        Size = UDim2.new(1, 0, 0, 20),
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextStrokeTransparency = 0.3,
        TextColor3 = Color3.fromRGB(120, 255, 160),
        Text = "",
    }, bb)
    local item = {character = character, highlight = hl, billboard = bb,
        nameLabel = nameLabel, healthLabel = healthLabel}
    renderData[player] = item
    return item
end

local function setIfDifferent(instance, property, value)
    if instance[property] ~= value then instance[property] = value end
end

local function updatePlayer(player, myRoot)
    if not state.esp or player.Parent ~= Players then
        deleteRender(player)
        return
    end
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not (character and head and root and hum) or hum.Health <= 0 then
        deleteRender(player)
        return
    end
    local item = renderData[player]
    if item and (item.character ~= character or not isLive(item.highlight) or not isLive(item.billboard)) then
        deleteRender(player)
        item = nil
    end
    if not item then item = createRender(player, character, head) end
    local color = getPlayerColor(player)
    setIfDifferent(item.billboard, "MaxDistance", state.espRangeMeters / CONFIG.StudMeters)
    setIfDifferent(item.highlight, "FillColor", color)
    setIfDifferent(item.highlight, "OutlineColor", color)
    local labelParts = {}
    if state.names then table.insert(labelParts, player.DisplayName) end
    if state.distance and myRoot then
        local meters = math.floor((root.Position - myRoot.Position).Magnitude * CONFIG.StudMeters + 0.5)
        table.insert(labelParts, tostring(meters) .. " м")
    end
    local nameText = table.concat(labelParts, "  |  ")
    setIfDifferent(item.nameLabel, "Text", nameText)
    setIfDifferent(item.nameLabel, "TextColor3", color)
    setIfDifferent(item.nameLabel, "Visible", #labelParts > 0)
    local maxHp = math.max(hum.MaxHealth, 1)
    local hp = math.clamp(hum.Health / maxHp, 0, 1)
    if state.health then
        setIfDifferent(item.healthLabel, "Text", string.format("HP %d/%d", math.ceil(hum.Health), math.ceil(maxHp)))
        setIfDifferent(item.healthLabel, "TextColor3", Color3.fromRGB(math.floor(255 * (1 - hp)), math.floor(255 * hp), 90))
    end
    setIfDifferent(item.healthLabel, "Visible", state.health)
    setIfDifferent(item.billboard, "Enabled", item.nameLabel.Visible or item.healthLabel.Visible)
end

local function sameTeamESP(player)
    return player.Team ~= nil and LocalPlayer.Team ~= nil
        and player.Team == LocalPlayer.Team
end

local function refreshESP()
    if not state.esp then
        for player in pairs(renderData) do deleteRender(player) end
        perfCounters.espCount = 0
        return
    end
    local character = LocalPlayer.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        for player in pairs(renderData) do deleteRender(player) end
        perfCounters.espCount = 0
        return
    end
    -- Рисуем ближайших, чтобы не создавать десятки дорогих Highlight.
    local candidates = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and (not state.espEnemyOnly or not sameTeamESP(player)) then
            local ch = player.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local distance = (root.Position - myRoot.Position).Magnitude
                if distance * CONFIG.StudMeters <= state.espRangeMeters then
                    candidates[#candidates + 1] = {player = player, distance = distance}
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local keep = {}
    for i = 1, math.min(#candidates, espLimit()) do
        local player = candidates[i].player
        keep[player] = true
        updatePlayer(player, myRoot)
    end
    for player in pairs(renderData) do
        if not keep[player] then deleteRender(player) end
    end
    perfCounters.espCount = math.min(#candidates, espLimit())
end

-- FullBright и FPS Booster имеют общую исходную копию освещения.
local lightingProperties = {
    "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation", "GlobalShadows"
}

local function captureLighting()
    if savedLighting then return end
    savedLighting = {}
    for _, key in ipairs(lightingProperties) do
        local ok, value = pcall(function() return Lighting[key] end)
        if ok then savedLighting[key] = value end
    end
end

local function wantedLightingValue(key)
    if not savedLighting then return nil end
    if state.fullbright then
        if key == "Brightness" then return CONFIG.FullBrightBrightness end
        if key == "Ambient" then return CONFIG.FullBrightAmbient end
        if key == "OutdoorAmbient" then return CONFIG.FullBrightOutdoorAmbient end
        if key == "ExposureCompensation" then return CONFIG.FullBrightExposure end
    end
    if key == "GlobalShadows" and (state.fullbright or state.booster) then
        return false
    end
    return nil
end

-- При смене игрового времени ClockTime НЕ трогаем: это устраняет дневные вспышки.
-- Настройки удерживаются по событию, а не только раз в 2 секунды.
local function enforceLightingProperty(key)
    if not alive or lightingApplying or not savedLighting then return end
    local wanted = wantedLightingValue(key)
    if wanted == nil then return end
    lightingApplying = true
    pcall(function()
        if Lighting[key] ~= wanted then Lighting[key] = wanted end
    end)
    lightingApplying = false
end

local function applyLighting()
    if lightingApplying then return end
    if not state.fullbright and not state.booster then
        if savedLighting then
            lightingApplying = true
            for key, original in pairs(savedLighting) do
                pcall(function() if Lighting[key] ~= original then Lighting[key] = original end end)
            end
            lightingApplying = false
            savedLighting = nil
        end
        return
    end
    captureLighting()
    lightingApplying = true
    for _, key in ipairs(lightingProperties) do
        local wanted = wantedLightingValue(key)
        if wanted ~= nil then
            pcall(function()
                if Lighting[key] ~= wanted then Lighting[key] = wanted end
            end)
        elseif savedLighting[key] ~= nil then
            -- Когда FullBright отключён, но Booster работает, возвращаем
            -- остальные параметры освещения, оставляя тени выключенными.
            pcall(function()
                if Lighting[key] ~= savedLighting[key] then Lighting[key] = savedLighting[key] end
            end)
        end
    end
    lightingApplying = false
end

-- Отключение декоративной травы Terrain — только при поддержке исполнителя.
-- Terrain.Decoration официально NotScriptable, поэтому используем API
-- исполнителя исключительно если можем прочитать и вернуть исходное значение.
local function terrainAccessor(kind)
    local direct = kind == "read" and gethiddenproperty or sethiddenproperty
    local alternate = kind == "read" and gethiddenprop or sethiddenprop
    if type(direct) == "function" then return direct end
    if type(alternate) == "function" then return alternate end
    return nil
end

local function hideTerrainGrass()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return false end
    if savedTerrainDecoration then return true end
    local getter, setter = terrainAccessor("read"), terrainAccessor("write")
    if not getter or not setter then return false end
    local okRead, original = pcall(getter, terrain, "Decoration")
    if not okRead or type(original) ~= "boolean" then return false end
    local okWrite = pcall(setter, terrain, "Decoration", false)
    if not okWrite then return false end
    savedTerrainDecoration = {terrain = terrain, original = original, setter = setter}
    return true
end

local function restoreTerrainGrass()
    local saved = savedTerrainDecoration
    savedTerrainDecoration = nil
    if saved then
        pcall(saved.setter, saved.terrain, "Decoration", saved.original)
    end
end

-- SmoothPlastic покрывает BasePart и MeshPart, включая землю из деталей.
-- Воксельный Terrain — другой тип поверхности: его НЕ заменяем и не портим.
local function graphicsProperty(obj)
    if obj:IsA("Terrain") then
        return nil
    elseif obj:IsA("MeshPart") then
        return {
            Material = Enum.Material.SmoothPlastic,
            MaterialVariant = "",
            TextureID = "",
            CastShadow = false,
        }
    elseif obj:IsA("BasePart") then
        return {
            Material = Enum.Material.SmoothPlastic,
            MaterialVariant = "",
            CastShadow = false,
        }
    elseif obj:IsA("SpecialMesh") then
        return {TextureId = ""}
    elseif obj:IsA("SurfaceAppearance") then
        return {ColorMap = "", NormalMap = "", RoughnessMap = "", MetalnessMap = ""}
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        return {Transparency = 1}
    elseif obj:IsA("PostEffect") or obj:IsA("ParticleEmitter") or
        obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or
        obj:IsA("Fire") or obj:IsA("Sparkles") then
        return {Enabled = false}
    end
    return nil
end

local function optimizeObject(obj)
    if not alive or not state.booster or savedGraphics[obj] then return end
    local props = graphicsProperty(obj)
    if not props then return end
    -- Нельзя портить внешний вид персонажей, включая вложенные модели аксессуаров.
    local ancestor = obj.Parent
    while ancestor and ancestor ~= Workspace and ancestor ~= Lighting do
        if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
            return
        end
        ancestor = ancestor.Parent
    end
    local camera = Workspace.CurrentCamera
    if camera and obj:IsDescendantOf(camera) then return end
    local snapshot = {}
    for key, value in pairs(props) do
        local okRead, old = pcall(function() return obj[key] end)
        if okRead and old ~= value then
            local okWrite = pcall(function() obj[key] = value end)
            -- Сохраняем только реально изменённые свойства.
            if okWrite then snapshot[key] = old end
        end
    end
    if next(snapshot) then savedGraphics[obj] = snapshot end
end

-- Обходим мир порциями без полной копии Workspace:GetDescendants().
-- В памяти хранятся только списки детей текущей ветки.
local function optimizeHierarchy(root, revision)
    local stack = {{items = root:GetChildren(), index = 1}}
    local processed = 0
    while #stack > 0 do
        if not alive or not state.booster or revision ~= boosterRevision then return false end
        local level = stack[#stack]
        local obj = level.items[level.index]
        if not obj then
            stack[#stack] = nil
        else
            level.index = level.index + 1
            optimizeObject(obj)
            -- Не обходим всё дерево персонажа: оно не должно меняться.
            local characterModel = obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid")
            if not characterModel then
                local children = obj:GetChildren()
                if #children > 0 then
                    stack[#stack + 1] = {items = children, index = 1}
                end
            end
            processed = processed + 1
            if processed % CONFIG.BoosterBatch == 0 then task.wait() end
        end
    end
    return true
end

local function setBooster(enabled)
    boosterRevision = boosterRevision + 1
    local revision = boosterRevision
    if enabled then
        applyLighting()
        local grassOff = hideTerrainGrass()
        task.spawn(function()
            if not optimizeHierarchy(Workspace, revision) then return end
            if not optimizeHierarchy(Lighting, revision) then return end
            if grassOff then
                tell("FPS Booster: пластик + трава Terrain скрыта")
            else
                tell("FPS Booster: пластик; Terrain.Decoration недоступен")
            end
        end)
    else
        restoreTerrainGrass()
        applyLighting()
        task.spawn(function()
            local counter = 0
            for obj, snapshot in pairs(savedGraphics) do
                if revision ~= boosterRevision or state.booster then return end
                for key, original in pairs(snapshot) do
                    pcall(function() obj[key] = original end)
                end
                savedGraphics[obj] = nil
                counter = counter + 1
                if counter % CONFIG.BoosterBatch == 0 then task.wait() end
            end
            if alive then tell("FPS Booster: материалы восстановлены") end
        end)
    end
end

-- AIM: поиск объекта в FOV, сохранение цели, необязательная проверка видимости.
-- ВАЖНО: отключение Visible Check пропускает Raycast, но объект должен быть перед камерой.
-- ПК: удерживание ПКМ. Android: кнопка AIM.
local function targetPart(character)
    if state.aimMode == "head" then
        return character:FindFirstChild("Head")
    elseif state.aimMode == "body" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("LeftLowerLeg")
        or character:FindFirstChild("RightLowerLeg")
        or character:FindFirstChild("Left Leg")
        or character:FindFirstChild("Right Leg")
        or character:FindFirstChild("LeftUpperLeg")
        or character:FindFirstChild("RightUpperLeg")
end

local function sameTeam(player)
    return state.teamCheck and player.Team ~= nil
        and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
end

-- Raycast не должен ошибочно считать полностью прозрачные служебные детали стеной.
local function canSee(camera, point, targetCharacter)
    local origin = camera.CFrame.Position
    local direction = point - origin
    if direction.Magnitude < 0.05 then return false end
    local exclusions = {}
    if LocalPlayer.Character then exclusions[1] = LocalPlayer.Character end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    for _ = 1, CONFIG.AimVisibleRaycastChecks do
        params.FilterDescendantsInstances = exclusions
        local result = Workspace:Raycast(origin, direction, params)
        if not result then return true end
        if result.Instance:IsDescendantOf(targetCharacter) then return true end
        if result.Instance.Transparency >= 0.98 then
            exclusions[#exclusions + 1] = result.Instance
        else
            return false
        end
    end
    return false
end

-- Согласованная проверка: используется и при поиске, и при сопровождении цели.
local function predictedPoint(part)
    local point = part.Position
    if not state.prediction then return point end
    local ok, velocity = pcall(function() return part.AssemblyLinearVelocity end)
    if ok and typeof(velocity) == "Vector3" then
        point = point + velocity * state.predictionSeconds
    end
    return point
end

local function signedAngle(a, b)
    return (b - a + math.pi) % (math.pi * 2) - math.pi
end

local function examineTarget(camera, player, part, myRoot, center, fovLimit, withLos)
    local character = player and player.Character
    if not character or not part or not part:IsA("BasePart")
        or not part:IsDescendantOf(character) or sameTeam(player) then return nil end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local point = part.Position
    if (point - myRoot.Position).Magnitude * CONFIG.StudMeters > state.aimRangeMeters then
        return nil
    end
    local projected, onScreen = camera:WorldToViewportPoint(point)
    if not onScreen or projected.Z <= 0 then return nil end
    local pixels = (Vector2.new(projected.X, projected.Y) - center).Magnitude
    if pixels > fovLimit then return nil end
    if withLos and not canSee(camera, point, character) then return nil end
    return {player = player, part = part, character = character, pixels = pixels}
end

local function findAimTarget(camera)
    local scanStarted = os.clock()
    local function done(result)
        perfCounters.aimScanMs = math.floor((os.clock() - scanStarted) * 10000 + 0.5) / 10
        return result
    end
    local me = LocalPlayer.Character
    local myRoot = me and me:FindFirstChild("HumanoidRootPart")
    if not myRoot then return done(nil) end
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local fov = state.aimFovPixels

    -- Если старый игрок жив и по-прежнему подходит — не переключаться каждые 0.12 с.
    if state.targetLock and aimTarget and aimTarget.player.Parent == Players then
        local chosen = targetPart(aimTarget.character)
        if chosen then
            local kept = examineTarget(camera, aimTarget.player, chosen, myRoot,
                center, fov * CONFIG.AimLockTolerance, state.visibleCheck)
            if kept then return done(kept) end
        end
    end

    local candidates = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not sameTeam(player) then
            local part = targetPart(player.Character)
            if part then
                -- На этом этапе нет Raycast: сначала дешёвые проверки дальности и FOV.
                local found = examineTarget(camera, player, part, myRoot,
                    center, fov, false)
                if found then candidates[#candidates + 1] = found end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.pixels < b.pixels end)
    for _, candidate in ipairs(candidates) do
        if not state.visibleCheck
            or canSee(camera, candidate.part.Position, candidate.character) then
            return done(candidate)
        end
    end
    return done(nil)
end

-- Один и тот же безопасный источник статуса системного меню для AIM и горячих клавиш.
-- pcall необходим: некоторые исполнители могут ограничивать чтение GuiService.
local function isRobloxMenuOpen()
    local ok, open = pcall(function() return GuiService.MenuIsOpen end)
    return ok and open == true
end

local function aimFrame(dt)
    -- Не опрашиваем GuiService каждый кадр, если AIM не включён/не удерживается.
    if not alive or not state.aimbot or not (aimHeldMouse or aimHeldTouch or aimHeldKey) then
        aimTarget = nil
        return
    end
    -- Останавливаем наведение при открытом меню, сбрасываем кэш и пересканируем
    -- цель после закрытия. Состояние тумблера AIM сохраняется намеренно.
    if isRobloxMenuOpen() then
        aimTarget = nil
        aimNextScan = 0
        return
    end
    if UserInputService:GetFocusedTextBox() ~= nil then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local now = os.clock()
    local scannedThisFrame = false
    if now >= aimNextScan then
        local tier = perfTier()
        local scanEvery = tier == "ECO" and 0.24
            or tier == "QUALITY" and 0.08 or CONFIG.AimScanInterval
        aimNextScan = now + scanEvery
        aimTarget = findAimTarget(camera)
        scannedThisFrame = true
    end
    local current = aimTarget
    local part = current and current.part
    if not part or not part.Parent or not current.player
        or current.player.Character ~= current.character or sameTeam(current.player) then
        aimTarget = nil
        aimNextScan = 0
        return
    end
    local origin = camera.CFrame.Position
    local point = part.Position
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot or (point - origin).Magnitude <= 0.05
        or (point - myRoot.Position).Magnitude * CONFIG.StudMeters > state.aimRangeMeters then
        aimTarget = nil
        aimNextScan = 0
        return
    end
    -- AIM-LOS-01: между плановыми сканами повторно проверяем живую цель.
    -- В кадре нового скана Raycast уже был, повторять его не нужно.
    -- При потере видимости камера НЕ меняется и следующий кадр ищет новую цель.
    -- Максимум CONFIG.AimVisibleRaycastChecks raycast за кадр сопровождения.
    if state.visibleCheck and not scannedThisFrame
        and not canSee(camera, point, current.character) then
        aimTarget = nil
        aimNextScan = 0
        return
    end
    local goal = CFrame.lookAt(origin, predictedPoint(part))
    if state.aimSmoothness == 0 then
        camera.CFrame = goal
    else
        -- Независимое сглаживание углов по X/Y, сохраняем roll исходной камеры.
        local cx, cy, cz = camera.CFrame:ToOrientation()
        local gx, gy = goal:ToOrientation()
        local speed = CONFIG.AimSmoothnessBaseline / state.aimSmoothness
        local dtSafe = math.clamp(dt, 0, 0.1)
        local alphaX = math.clamp(1 - math.exp(-speed * state.aimSmoothX / 5 * dtSafe), 0, 1)
        local alphaY = math.clamp(1 - math.exp(-speed * state.aimSmoothY / 5 * dtSafe), 0, 1)
        local nextPitch = cx + signedAngle(cx, gx) * alphaY
        local nextYaw = cy + signedAngle(cy, gy) * alphaX
        camera.CFrame = CFrame.new(origin) * CFrame.fromOrientation(nextPitch, nextYaw, cz)
    end
end

-- 124 / RED PANEL — собственный интерфейс без внешних UI-библиотек.
-- Две колонки на больших экранах, одна колонка на телефонах.
local gui = mk("ScreenGui", {
    Name = "Army124CommunityHubV100",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- Линии ESP оставляем в отдельном ScreenGui; сам рендер не меняется.
tracerGui = mk("ScreenGui", {
    Name = "Army124TracersV05", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)
shapeGui = mk("ScreenGui", {
    Name = "Army124ShapeOverlayV100", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 92, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- Лёгкий FOV overlay: одно кольцо UIStroke, без цикла создания новых объектов.
fovGui = mk("ScreenGui", {
    Name = "Army124FovV100", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 94, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)
local fovCircle = mk("Frame", {
    Name = "AimFovRing", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.fromOffset(state.aimFovPixels * 2, state.aimFovPixels * 2),
    Active = false, Visible = false,
}, fovGui)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, fovCircle)
local fovStroke = mk("UIStroke", {
    Color = CONFIG.Accent, Thickness = state.fovThickness,
    Transparency = 0.12, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, fovCircle)
local function refreshFovRing()
    if not alive or not fovCircle.Parent then return end
    fovCircle.Visible = state.aimbot and state.fovVisible
    fovCircle.Size = UDim2.fromOffset(state.aimFovPixels * 2, state.aimFovPixels * 2)
    fovStroke.Thickness = state.fovThickness
end

-- Одна точка синхронизации состояния AIM для GUI, клавиатуры и Android.
local repaintAimTouch = function() end -- Назначается после создания экранной кнопки.
local function setAimEnabled(enabled, activateKeyAim)
    if not alive then return end
    state.aimbot = enabled == true
    if not state.aimbot then
        aimHeldKey = false
        aimHeldTouch = false
        aimHeldMouse = false
    elseif activateKeyAim then
        -- Быстрый режим: горячая клавиша сразу начинает наведение без ПКМ.
        aimHeldKey = true
    end
    aimTarget = nil
    aimNextScan = 0
    if refreshToggles.aimbot then refreshToggles.aimbot() end
    refreshFovRing()
    repaintAimTouch()
    requestSave()
end

-- Сохраняем только ограниченный набор настроек; код из JSON никогда не выполняется.
local HttpService = game:GetService("HttpService")
local storedKeys = {
    "esp", "tracers", "names", "health", "distance", "teamColors", "espBox", "espSkeleton",
    "espEnemyOnly", "espRangeMeters", "espColorPreset", "espLineThickness", "performanceMode",
    "aimbot", "aimRangeMeters", "aimSmoothness", "aimSmoothX", "aimSmoothY",
    "prediction", "predictionSeconds", "targetLock", "aimFovPixels", "aimMode",
    "fovVisible", "fovThickness", "visibleCheck", "teamCheck", "fullbright", "booster",
    "antiAfk", "hud", "activeHud", "aimKeyName",
}
local numericRules = {
    espRangeMeters = {10, 200}, espLineThickness = {1, 4},
    aimRangeMeters = {5, 180}, aimSmoothness = {0, 10},
    aimSmoothX = {1, 10}, aimSmoothY = {1, 10},
    predictionSeconds = {0, 0.25}, aimFovPixels = {40, 400},
    fovThickness = {1, 4},
}
local textRules = {
    aimMode = {head = true, body = true, legs = true},
    espColorPreset = {TEAM = true, GOLD = true, GREEN = true, WHITE = true},
    performanceMode = {AUTO = true, ECO = true, QUALITY = true},
}
defaultSettings = {}
for _, key in ipairs(storedKeys) do defaultSettings[key] = state[key] end
local profiles = {CUSTOM = {}} -- Только CUSTOM записывается на диск.
local presetData = {
    LEGIT = {aimFovPixels = 95, aimSmoothness = 8, visibleCheck = true,
        targetLock = true, prediction = false, aimRangeMeters = 85},
    RAGE = {aimFovPixels = 350, aimSmoothness = 0, visibleCheck = false,
        targetLock = true, prediction = true, predictionSeconds = 0.10,
        aimRangeMeters = 180},
}
local dirtyToken = 0
local restoring = false

local function snapshotState()
    local snapshot = {}
    for _, key in ipairs(storedKeys) do snapshot[key] = state[key] end
    return snapshot
end

local function validatedSettings(values)
    local result = {}
    if type(values) ~= "table" then return result end
    for _, key in ipairs(storedKeys) do
        local incoming = values[key]
        if incoming ~= nil then
            local baseline = defaultSettings[key]
            if type(baseline) == "boolean" and type(incoming) == "boolean" then
                result[key] = incoming
            elseif type(baseline) == "number" and type(incoming) == "number" and incoming == incoming then
                local rule = numericRules[key]
                result[key] = rule and math.clamp(incoming, rule[1], rule[2]) or baseline
            elseif type(baseline) == "string" and type(incoming) == "string" then
                if key == "aimKeyName" then
                    if validAimKeyName(incoming) then result[key] = incoming end
                elseif textRules[key] and textRules[key][incoming] then
                    result[key] = incoming
                end
            end
        end
    end
    return result
end

local function writeProfileFile()
    local data = {version = 1, current = profileName,
        profiles = {CUSTOM = profiles.CUSTOM or {}}}
    env.ARMY124_CONFIG_V09 = data
    if type(writefile) == "function" then
        local ok, err = pcall(function()
            writefile(CONFIG.ConfigFile, HttpService:JSONEncode(data))
        end)
        if not ok then tell("Config: файл не сохранён: " .. tostring(err)) end
    end
end

local function storeCustomSnapshot()
    if profileName == "CUSTOM" then
        profiles.CUSTOM = snapshotState()
    end
end

flushConfig = function()
    -- Сброс ожидающих таймеров и синхронная запись до выгрузки.
    dirtyToken = dirtyToken + 1
    storeCustomSnapshot()
    writeProfileFile()
end

requestSave = function()
    if restoring or not alive then return end
    dirtyToken = dirtyToken + 1
    local token = dirtyToken
    task.delay(1.4, function()
        if alive and token == dirtyToken then
            storeCustomSnapshot()
            writeProfileFile()
        end
    end)
end

local function readProfileFile()
    local loaded = env.ARMY124_CONFIG_V09
    if type(readfile) == "function" then
        local ok, contents = pcall(readfile, CONFIG.ConfigFile)
        if ok and type(contents) == "string" then
            local parsedOk, decoded = pcall(function() return HttpService:JSONDecode(contents) end)
            if parsedOk and type(decoded) == "table" then loaded = decoded end
        end
    end
    if type(loaded) == "table" and loaded.version == 1 then
        if type(loaded.profiles) == "table" then
            if loaded.profiles.CUSTOM then
                profiles.CUSTOM = validatedSettings(loaded.profiles.CUSTOM)
            end
            -- Старые изменённые LEGIT/RAGE специально игнорируем:
            -- именованные пресеты остаются неизменяемыми.
        end
        if type(loaded.current) == "string" and (loaded.current == "CUSTOM"
            or presetData[loaded.current]) then profileName = loaded.current end
    end
end
readProfileFile()

local function applySettings(incoming, autoLoad)
    restoring = true
    local sanitized = validatedSettings(incoming)
    local wasBooster = state.booster
    for key, value in pairs(sanitized) do state[key] = value end
    -- Автозагрузка не активирует наведение/AFK без нажатия пользователя.
    if autoLoad then
        state.aimbot = false
        state.antiAfk = false
    end
    if state.aimKeyName then saveAimKey(state.aimKeyName) end
    if wasBooster ~= state.booster then setBooster(state.booster) end
    pcall(applyLighting)
    setAimEnabled(state.aimbot, false)
    aimTarget = nil
    aimNextScan = 0
    restoring = false
    for _, update in pairs(refreshToggles) do pcall(update) end
    for _, update in pairs(refreshSliders) do pcall(update) end
    pcall(repaintAimMode)
    pcall(repaintAimKeybind)
    pcall(repaintColors)
    pcall(repaintPerf)
    pcall(repaintConfig)
    syncEspVisuals() -- Полная синхронизация всех типов ESP после загрузки конфига.
end

local function useProfile(name, autoLoad)
    if name ~= "CUSTOM" and not presetData[name] then return end
    if not autoLoad then
        -- Сохраняем предыдущий CUSTOM до изменения активного имени.
        flushConfig()
    end
    profileName = name
    local values = table.clone(defaultSettings)
    if name == "CUSTOM" then
        for k, v in pairs(profiles.CUSTOM or {}) do values[k] = v end
    else
        for k, v in pairs(presetData[name]) do values[k] = v end
    end
    applySettings(values, autoLoad)
    if not autoLoad then
        -- Записываем имя активного профиля. LEGIT/RAGE при этом не изменяются.
        flushConfig()
        tell("Профиль " .. name .. " загружен")
    end
end


local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(390, 720)
local TweenService = game:GetService("TweenService")
local P = {
    background = CONFIG.Window,
    panel = Color3.fromRGB(21, 22, 28),
    tile = CONFIG.Surface,
    border = Color3.fromRGB(51, 53, 63),
    text = Color3.fromRGB(237, 235, 240),
    dim = CONFIG.Muted,
    accent = CONFIG.Accent,
    off = Color3.fromRGB(57, 59, 69),
}
local wideLayout = viewport.X >= 650
local function windowMetrics(view)
    local wide = view.X >= 650
    local width = math.max(260, math.min(wide and 752 or 400, view.X - (wide and 32 or 16)))
    local height = math.max(260, math.min(wide and 532 or 620, view.Y - (wide and 38 or 24)))
    return width, height, wide
end
local winWidth, winHeight = windowMetrics(viewport)
local panel = mk("Frame", {
    Name = "RedPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(winWidth, winHeight),
    BackgroundColor3 = P.background,
    BorderSizePixel = 0,
    Active = true,
}, gui)
round(panel, 11)
mk("UIStroke", {Color = P.border, Transparency = 0.08, Thickness = 1}, panel)
local panelScale = mk("UIScale", {Scale = 1}, panel)
local function tweenPanel(toScale)
    pcall(function()
        TweenService:Create(panelScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out), {Scale = toScale}):Play()
    end)
end
-- Верхняя тонкая линия и ручная композиция шапки: без тяжёлых градиентов и свечения.
mk("Frame", {
    Name = "TopAccent", BorderSizePixel = 0,
    BackgroundColor3 = P.accent,
    Position = UDim2.fromOffset(15, 0), Size = UDim2.fromOffset(75, 2),
}, panel)
local bar = mk("Frame", {
    Name = "DragBar", BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 74), Active = true,
}, panel)
local emblem = mk("Frame", {
    Name = "BrandMark", BackgroundColor3 = Color3.fromRGB(42, 23, 32),
    BorderSizePixel = 0, Position = UDim2.fromOffset(16, 17),
    Size = UDim2.fromOffset(37, 37),
}, bar)
round(emblem, 8)
mk("UIStroke", {Color = P.accent, Thickness = 1, Transparency = 0.53}, emblem)
mk("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
    Text = "124", Font = Enum.Font.GothamBold,
    TextColor3 = P.accent, TextSize = 13,
}, emblem)
mk("TextLabel", {
    Name = "BrandTitle", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(66, 16), Size = UDim2.new(1, -183, 0, 21),
    Text = "124 COMMUNITY", TextColor3 = P.text, TextSize = 15,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, bar)
mk("TextLabel", {
    Name = "BrandCaption", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(66, 38), Size = UDim2.new(1, -183, 0, 16),
    Text = "ARMY RP   /   RED PANEL   /   v" .. CONFIG.Version,
    TextColor3 = P.dim, Font = Enum.Font.Code,
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, bar)
local cleanup -- Обработчик выгрузки определяется ниже.
local hide = mk("TextButton", {
    Name = "Minimize", Position = UDim2.new(1, -82, 0, 21),
    Size = UDim2.fromOffset(28, 28), BackgroundColor3 = P.tile,
    Text = "—", TextColor3 = P.dim, TextSize = 16,
    Font = Enum.Font.GothamMedium, AutoButtonColor = true,
}, bar)
round(hide, 6)
local close = mk("TextButton", {
    Name = "CloseHub", Position = UDim2.new(1, -47, 0, 21),
    Size = UDim2.fromOffset(28, 28), BackgroundColor3 = P.tile,
    Text = "×", TextColor3 = Color3.fromRGB(242, 146, 154),
    Font = Enum.Font.GothamMedium, TextSize = 16, AutoButtonColor = true,
}, bar)
round(close, 6)
mk("Frame", {
    Name = "HeaderDivider", BorderSizePixel = 0, BackgroundColor3 = P.border,
    Position = UDim2.fromOffset(15, 73), Size = UDim2.new(1, -30, 0, 1),
}, panel)

-- Навигация внизу, как в референсе. Слоты управления не участвуют в ESP/AIM логике.
local tabs = mk("Frame", {
    Name = "BottomNavigation", BackgroundColor3 = P.panel, BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -53), Size = UDim2.new(1, 0, 0, 53),
}, panel)
round(tabs, 10)
mk("Frame", {
    Name = "NavLine", BackgroundColor3 = P.border, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 1),
}, tabs)
mk("UIPadding", {
    PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
    PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 6),
}, tabs)
mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
}, tabs)
local tabButtons, tabUnderline, pages, pageColumns = {}, {}, {}, {}
local currentPage = "AIM"
local navigation = {
    {key = "AIM", label = "COMBAT", symbol = "◎"},
    {key = "ESP", label = "VISUALS", symbol = "▣"},
    {key = "MISC", label = "MISC", symbol = "≡"},
    {key = "CFG", label = "CONFIG", symbol = "◇"},
}
local function makeColumn(parent, name)
    local scroll = mk("ScrollingFrame", {
        Name = name, BackgroundColor3 = P.panel, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = P.accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Active = true,
    }, parent)
    round(scroll, 8)
    mk("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, scroll)
    mk("UIPadding", {
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 9),
    }, scroll)
    return scroll
end
for idx, tab in ipairs(navigation) do
    local key = tab.key
    local button = mk("TextButton", {
        Name = key .. "Tab", LayoutOrder = idx,
        BackgroundColor3 = P.panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0.25, -5, 1, 0),
        Text = tab.symbol .. "  " .. tab.label,
        Font = Enum.Font.GothamMedium, TextSize = 11,
        TextColor3 = P.dim, AutoButtonColor = false,
    }, tabs)
    round(button, 6)
    tabButtons[key] = button
    tabUnderline[key] = mk("Frame", {
        Name = "ActiveLine", BackgroundColor3 = P.accent,
        BorderSizePixel = 0, Position = UDim2.new(0.5, -11, 0, -7),
        Size = UDim2.fromOffset(22, 2), Visible = false,
    }, button)
    local page = mk("Frame", {
        Name = key .. "Page", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 82),
        Size = UDim2.new(1, -24, 1, -153),
        Visible = key == "AIM",
    }, panel)
    pages[key] = page
    pageColumns[page] = {
        left = makeColumn(page, key .. "Left"),
        right = makeColumn(page, key .. "Right"),
        side = "left", widgets = {}, order = 0,
    }
end
-- Каждый элемент сохраняет свой логический столбец. После поворота телефона
-- элементы безопасно переподключаются, сохраняя LayoutOrder и обработчики.
local sectionSides = {
    ["VISUALS"] = "left", ["ESP OPTIONS"] = "right",
    ["TARGETING"] = "left", ["ADVANCED"] = "right",
    ["FOV EDITOR"] = "right", ["CONTROL"] = "right",
    ["UTILITY"] = "left", ["PERFORMANCE"] = "right",
    ["PROFILES"] = "left", ["CONFIG TOOLS"] = "right", ["WINDOW"] = "right",
}
local function columnFor(page)
    local info = pageColumns[page]
    if not info then return page end
    return wideLayout and info[info.side] or info.left
end
local function registerWidget(page, widget)
    local info = pageColumns[page]
    if not info then return widget end
    info.order = info.order + 1
    widget.LayoutOrder = info.order
    table.insert(info.widgets, {object = widget, side = info.side})
    return widget
end
local function applyResponsiveLayout()
    local view = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or viewport
    local width, height, wide = windowMetrics(view)
    panel.Size = UDim2.fromOffset(width, height)
    wideLayout = wide
    -- На узких экранах короткие подписи не перекрывают соседние вкладки.
    for _, nav in ipairs(navigation) do
        tabButtons[nav.key].Text = width < 355 and nav.key
            or (nav.symbol .. "  " .. nav.label)
        tabButtons[nav.key].TextSize = width < 355 and 10 or 11
    end
    for _, page in pairs(pages) do
        local info = pageColumns[page]
        if wide then
            info.left.Position = UDim2.new(0, 0, 0, 0)
            info.left.Size = UDim2.new(0.5, -5, 1, 0)
            info.right.Position = UDim2.new(0.5, 5, 0, 0)
            info.right.Size = UDim2.new(0.5, -5, 1, 0)
            info.right.Visible = true
        else
            info.left.Position = UDim2.fromScale(0, 0)
            info.left.Size = UDim2.fromScale(1, 1)
            info.right.Visible = false
        end
        for _, item in ipairs(info.widgets) do
            local desired = wide and info[item.side] or info.left
            if item.object.Parent ~= desired then item.object.Parent = desired end
        end
    end
end
local function showPage(key)
    if not pages[key] then return end
    if key ~= "AIM" and captureAimKey then
        captureAimKey = false
        repaintAimKeybind()
    end
    currentPage = key
    for name, page in pairs(pages) do
        local selected = name == key
        page.Visible = selected
        tabButtons[name].BackgroundColor3 = selected and Color3.fromRGB(50, 28, 37) or P.panel
        tabButtons[name].TextColor3 = selected and P.text or P.dim
        tabButtons[name].Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium
        tabUnderline[name].Visible = selected
    end
end
for name, button in pairs(tabButtons) do
    connect(button.Activated, function() showPage(name) end)
end
applyResponsiveLayout()
showPage("AIM")
local currentLayoutCamera = nil
local cameraLayoutConnection = nil
local function trackLayoutCamera()
    if cameraLayoutConnection then
        pcall(function() cameraLayoutConnection:Disconnect() end)
        cameraLayoutConnection = nil
    end
    local camera = Workspace.CurrentCamera
    if camera then
        cameraLayoutConnection = connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
            if alive then applyResponsiveLayout() end
        end)
    end
end
trackLayoutCamera()
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    if alive then trackLayoutCamera(); applyResponsiveLayout() end
end)

-- Линии сверху экрана к позиции над головой игрока, до 200 метров.
-- Рендер выполняется с ограниченной частотой, а не на каждом кадре.
clearTracers = function()
    for _, data in pairs(renderData) do
        if data.tracer then
            pcall(function() data.tracer:Destroy() end)
            data.tracer = nil
        end
    end
end

local function refreshTracers()
    if not alive or not state.esp or not state.tracers then
        clearTracers()
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera or not tracerGui or not tracerGui.Parent then return end
    local viewportSize = camera.ViewportSize
    local source = Vector2.new(viewportSize.X * 0.5, 12)
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then clearTracers(); return end
    for player, data in pairs(renderData) do
        local ch = data.character
        local head = ch and ch:FindFirstChild("Head")
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local visible = false
        local screenPosition
        if head and root and (root.Position - myRoot.Position).Magnitude * CONFIG.StudMeters <= state.espRangeMeters then
            local point, onScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.8, 0))
            visible = onScreen and point.Z > 0
            screenPosition = point
        end
        if visible then
            if not data.tracer or not data.tracer.Parent then
                data.tracer = mk("Frame", {
                    Name = "Army124TopTracer", AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = CONFIG.Neutral, BackgroundTransparency = 0.12,
                    BorderSizePixel = 0, ZIndex = 1,
                }, tracerGui)
            end
            local goal2d = Vector2.new(screenPosition.X, screenPosition.Y)
            local vector = goal2d - source
            local length = vector.Magnitude
            data.tracer.Visible = length > 2
            if length > 2 then
                data.tracer.Size = UDim2.fromOffset(length, 2)
                data.tracer.Position = UDim2.fromOffset((goal2d.X + source.X) / 2, (goal2d.Y + source.Y) / 2)
                data.tracer.Rotation = math.deg(math.atan2(vector.Y, vector.X))
                setIfDifferent(data.tracer, "BackgroundColor3", getPlayerColor(player))
            end
        elseif data.tracer then
            data.tracer.Visible = false
        end
    end
end

-- 2D Box + Skeleton: UI-примитивы создаём один раз на игрока, переиспользуем.
local shapeData = {}
local shapePairsR15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local shapePairsR6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local function shapeLine(parent)
    return mk("Frame", {BackgroundColor3 = CONFIG.Accent,
        BackgroundTransparency = 0.07, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Visible = false,
        Size = UDim2.fromOffset(2, 2)}, parent)
end
local function clearShapes()
    for player, item in pairs(shapeData) do
        pcall(function() item.container:Destroy() end)
        shapeData[player] = nil
    end
    perfCounters.shapeCount = 0
end
local function setLine(line, a, b, thick, color)
    local delta = b - a
    if delta.Magnitude < 0.5 then line.Visible = false; return end
    setIfDifferent(line, "Visible", true)
    setIfDifferent(line, "Size", UDim2.fromOffset(delta.Magnitude, thick))
    setIfDifferent(line, "Position", UDim2.fromOffset((a.X + b.X) * 0.5, (a.Y + b.Y) * 0.5))
    setIfDifferent(line, "Rotation", math.deg(math.atan2(delta.Y, delta.X)))
    setIfDifferent(line, "BackgroundColor3", color)
end
local function shapeItem(player)
    local item = shapeData[player]
    if item and item.container.Parent then return item end
    local container = mk("Frame", {Name = "S" .. player.UserId, Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, Active = false}, shapeGui)
    item = {container = container, box = {}, bones = {}}
    -- Ленивое создание: линии Skeleton не нужны, пока выключена эта функция.
    shapeData[player] = item
    return item
end
local function hideShape(item)
    for _, line in ipairs(item.box) do setIfDifferent(line, "Visible", false) end
    for _, line in ipairs(item.bones) do setIfDifferent(line, "Visible", false) end
end
local function ensureShapeLines(item, kind, count)
    local lines = item[kind]
    while #lines < count do lines[#lines + 1] = shapeLine(item.container) end
    return lines
end
local function refreshShapes()
    if not alive or not state.esp or not (state.espBox or state.espSkeleton) then
        clearShapes()
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local activeCount, active = 0, {}
    for player, info in pairs(renderData) do
        local char = info.character
        local head = char and char:FindFirstChild("Head")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if head and root and hum and hum.Health > 0 then
            active[player] = true
            local item = shapeItem(player)
            hideShape(item)
            if state.espBox then ensureShapeLines(item, "box", 4) end
            if state.espSkeleton then
                local count = char:FindFirstChild("UpperTorso") and #shapePairsR15 or #shapePairsR6
                ensureShapeLines(item, "bones", count)
            end
            local color = getPlayerColor(player)
            local top, on1 = camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.25, 0))
            local bottom, on2 = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            if on1 and on2 and top.Z > 0 and bottom.Z > 0 then
                activeCount = activeCount + 1
                if state.espBox then
                    local half = math.clamp(math.abs(bottom.Y - top.Y) * 0.23, 4, 160)
                    local left, right = top.X - half, top.X + half
                    setLine(item.box[1], Vector2.new(left, top.Y), Vector2.new(right, top.Y), state.espLineThickness, color)
                    setLine(item.box[2], Vector2.new(left, bottom.Y), Vector2.new(right, bottom.Y), state.espLineThickness, color)
                    setLine(item.box[3], Vector2.new(left, top.Y), Vector2.new(left, bottom.Y), state.espLineThickness, color)
                    setLine(item.box[4], Vector2.new(right, top.Y), Vector2.new(right, bottom.Y), state.espLineThickness, color)
                end
                if state.espSkeleton then
                    local pairsToDraw = char:FindFirstChild("UpperTorso") and shapePairsR15 or shapePairsR6
                    local cached = {}
                    for idx, names in ipairs(pairsToDraw) do
                        local function p(name)
                            if cached[name] ~= nil then return cached[name] end
                            local body = char:FindFirstChild(name)
                            if not body or not body:IsA("BasePart") then return nil end
                            local vec, visible = camera:WorldToViewportPoint(body.Position)
                            local result = visible and vec.Z > 0 and Vector2.new(vec.X, vec.Y) or nil
                            cached[name] = result
                            return result
                        end
                        local a, b = p(names[1]), p(names[2])
                        if a and b then setLine(item.bones[idx], a, b, state.espLineThickness, color) end
                    end
                end
            end
        end
    end
    for player, item in pairs(shapeData) do
        if not active[player] then
            pcall(function() item.container:Destroy() end)
            shapeData[player] = nil
        end
    end
    perfCounters.shapeCount = activeCount
end

syncEspVisuals = function()
    refreshESP()
    if state.esp and state.tracers then
        refreshTracers()
    else
        clearTracers()
    end
    if state.esp and (state.espBox or state.espSkeleton) then
        refreshShapes()
    else
        clearShapes()
    end
end

-- Единая сетка компонентов. Стилизация не меняет обработчики состояний.
local function addSection(page, title, subtitle)
    local info = pageColumns[page]
    if info then info.side = sectionSides[title] or info.side end
    local container = mk("Frame", {
        Name = title .. "Heading", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 39),
    }, columnFor(page))
    registerWidget(page, container)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 0, 18),
        Text = title, Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(4, 23), Size = UDim2.new(1, -8, 0, 13),
        Text = subtitle, Font = Enum.Font.Gotham,
        TextSize = 9, TextColor3 = P.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, container)
end

local function addToggle(page, title, description, key, onChanged)
    local row = mk("TextButton", {
        Name = key, Size = UDim2.new(1, 0, 0, 49),
        BackgroundColor3 = P.tile, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "",
    }, columnFor(page))
    registerWidget(page, row)
    round(row, 6)
    mk("UIStroke", {Color = P.border, Transparency = 0.78, Thickness = 1}, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 5), Size = UDim2.new(1, -72, 0, 21),
        Text = title, TextSize = 12, Font = Enum.Font.GothamMedium,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 28), Size = UDim2.new(1, -72, 0, 14),
        Text = description, TextSize = 9, Font = Enum.Font.Gotham,
        TextColor3 = P.dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local pill = mk("Frame", {
        Name = "Switch", Position = UDim2.new(1, -51, 0.5, -11),
        Size = UDim2.fromOffset(40, 22), BackgroundColor3 = P.off,
        BorderSizePixel = 0,
    }, row)
    round(pill, 11)
    local knob = mk("Frame", {
        Name = "Knob", Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.fromRGB(222, 223, 227), BorderSizePixel = 0,
    }, pill)
    round(knob, 8)
    local function update()
        if not row.Parent then return end
        local enabled = state[key] == true
        pill.BackgroundColor3 = enabled and P.accent or P.off
        knob.Position = UDim2.fromOffset(enabled and 21 or 3, 3)
        knob.BackgroundColor3 = enabled and Color3.fromRGB(255, 250, 251)
            or Color3.fromRGB(203, 204, 212)
    end
    refreshToggles[key] = update
    connect(row.Activated, function()
        if not alive then return end
        state[key] = not state[key]
        if onChanged then
            local ok, err = pcall(onChanged, state[key])
            if not ok then tell("Ошибка: " .. tostring(err)) end
        end
        update()
        requestSave()
    end)
    update()
    return row
end

local function addButton(page, text, description, handler)
    local button = mk("TextButton", {
        BackgroundColor3 = P.tile,
        Size = UDim2.new(1, 0, 0, 49),
        Text = "", AutoButtonColor = true, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, button)
    round(button, 6)
    mk("UIStroke", {Color = P.border, Transparency = 0.77, Thickness = 1}, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 5), Size = UDim2.new(1, -39, 0, 21),
        Text = text, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 28), Size = UDim2.new(1, -39, 0, 14),
        Text = description, Font = Enum.Font.Gotham, TextSize = 9,
        TextColor3 = P.dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -31, 0.5, -10),
        Size = UDim2.fromOffset(20, 20), Text = "›", Font = Enum.Font.GothamBold,
        TextSize = 19, TextColor3 = P.accent,
    }, button)
    connect(button.Activated, function()
        if not alive then return end
        local ok, err = pcall(handler)
        if not ok then tell("Ошибка кнопки: " .. tostring(err)) end
    end)
    return button
end

-- Общий drag-handler работает и с мышью, и с touch; нет RenderStepped у слайдеров.
local sliderDrag = nil
local function addSlider(page, title, description, key, minValue, maxValue, step, formatter, onChanged)
    local container = mk("Frame", {
        Name = key .. "Slider", Size = UDim2.new(1, 0, 0, 67),
        BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, container)
    round(container, 6)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -103, 0, 18), Text = title,
        TextColor3 = P.text,
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    local valueLabel = mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -105, 0, 5),
        Size = UDim2.fromOffset(95, 18),
        TextColor3 = CONFIG.Accent, Font = Enum.Font.Code,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
    }, container)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 24),
        Size = UDim2.new(1, -20, 0, 13), Text = description,
        TextColor3 = CONFIG.Muted, Font = Enum.Font.Gotham,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    local touchArea = mk("TextButton", {
        Name = "DragArea", BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(10, 40), Size = UDim2.new(1, -20, 0, 24),
    }, container)
    local track = mk("Frame", {
        Name = "Track", BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(84, 86, 83),
        Position = UDim2.new(0, 6, 0.5, -2),
        Size = UDim2.new(1, -12, 0, 4),
    }, touchArea)
    round(track, 2)
    local fill = mk("Frame", {
        Name = "Fill", BorderSizePixel = 0,
        BackgroundColor3 = CONFIG.Accent, Size = UDim2.fromScale(0, 1),
    }, track)
    round(fill, 2)
    local thumb = mk("Frame", {
        Name = "Thumb", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(251, 239, 241), BorderSizePixel = 0,
    }, track)
    round(thumb, 6)

    local function repaint()
        if not container.Parent then return end
        local fraction = math.clamp((state[key] - minValue) / (maxValue - minValue), 0, 1)
        fill.Size = UDim2.fromScale(fraction, 1)
        thumb.Position = UDim2.fromScale(fraction, 0.5)
        valueLabel.Text = formatter(state[key])
    end
    local function setFromX(x)
        if not alive or not track.Parent then return end
        local fraction = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minValue + fraction * (maxValue - minValue)
        local snapped = math.clamp(minValue + math.floor((raw - minValue) / step + 0.5) * step, minValue, maxValue)
        if state[key] ~= snapped then
            state[key] = snapped
            if onChanged then onChanged(snapped) end
        end
        repaint()
        requestSave()
    end
    refreshSliders[key] = repaint
    connect(touchArea.InputBegan, function(input)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
            sliderDrag = {touch = kind == Enum.UserInputType.Touch, input = input, update = setFromX}
            setFromX(input.Position.X)
        end
    end)
    repaint()
    return container
end

-- Небольшой сегментированный переключатель вместо двух взаимоисключающих Toggle.
local function addAimModeSelector(page)
    local container = mk("Frame", {
        Name = "AimModeSelector", Size = UDim2.new(1, 0, 0, 63),
        BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, container)
    round(container, 6)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 0, 16),
        Text = "Точка наведения", Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = P.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    local bar = mk("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 27),
        Size = UDim2.new(1, -16, 0, 29),
    }, container)
    local modes = {
        {value = "head", text = "ГОЛОВА"},
        {value = "body", text = "ТЕЛО"},
        {value = "legs", text = "НОГИ"},
    }
    local buttons = {}
    local function repaint()
        for _, mode in ipairs(modes) do
            local button = buttons[mode.value]
            if button and button.Parent then
                local selected = state.aimMode == mode.value
                button.BackgroundColor3 = selected and CONFIG.Accent or Color3.fromRGB(42, 43, 51)
                button.TextColor3 = selected and CONFIG.Window or Color3.fromRGB(187, 190, 185)
            end
        end
    end
    for index, mode in ipairs(modes) do
        local button = mk("TextButton", {
            Name = "Aim_" .. mode.value,
            Size = UDim2.new(1/3, -4, 1, 0),
            Position = UDim2.new((index - 1)/3, 2, 0, 0),
            BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(42, 43, 51),
            Text = mode.text, Font = Enum.Font.GothamBold, TextSize = 10,
            TextColor3 = CONFIG.Muted, AutoButtonColor = false,
        }, bar)
        round(button, 3)
        buttons[mode.value] = button
        connect(button.Activated, function()
            if not alive then return end
            state.aimMode = mode.value
            aimTarget = nil
            aimNextScan = 0
            repaint()
            requestSave()
        end)
    end
    repaintAimMode = repaint
    repaint()
    return container
end

-- Назначение клавиши работает в любой версии с доступным UserInputService.
-- Подсказка и кнопка сброса находятся внутри прокручиваемой вкладки AIM.
local function addAimKeybind(page)
    local container = mk("Frame", {
        Name = "AimKeybind", Size = UDim2.new(1, 0, 0, 78),
        BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, container)
    round(container, 6)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 4),
        Size = UDim2.new(1, -20, 0, 20), Text = "Клавиша включения AIM",
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = P.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    keybindHint = mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 23),
        Size = UDim2.new(1, -20, 0, 15),
        Text = "Нажать клавишу: AIM ON/OFF; ПКМ тоже работает",
        Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = CONFIG.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, container)
    keybindButton = mk("TextButton", {
        Name = "AssignAimKey", Position = UDim2.fromOffset(10, 43),
        Size = UDim2.new(1, -83, 0, 27),
        BackgroundColor3 = Color3.fromRGB(42, 43, 51),
        TextColor3 = CONFIG.Accent, Font = Enum.Font.GothamBold,
        TextSize = 11, AutoButtonColor = true, Text = "",
    }, container)
    round(keybindButton, 3)
    local clear = mk("TextButton", {
        Name = "ClearAimKey", Position = UDim2.new(1, -65, 0, 43),
        Size = UDim2.fromOffset(55, 27),
        BackgroundColor3 = Color3.fromRGB(52, 48, 48),
        TextColor3 = Color3.fromRGB(218, 194, 188),
        Font = Enum.Font.GothamMedium, TextSize = 10,
        Text = "СБРОС", AutoButtonColor = true,
    }, container)
    round(clear, 3)
    local function repaint()
        if not keybindButton.Parent then return end
        if captureAimKey then
            keybindButton.Text = "НАЖМИ КЛАВИШУ..."
            keybindHint.Text = "Выбор клавиши: нажми любую клавишу на ПК"
        else
            keybindButton.Text = state.aimKeyName == "NONE"
                and "НЕ НАЗНАЧЕНА" or ("КЛАВИША: " .. state.aimKeyName)
            keybindHint.Text = "Клавиша переключает AIM; ПКМ работает отдельно"
        end
    end
    connect(keybindButton.Activated, function()
        if not alive then return end
        captureAimKey = not captureAimKey
        repaint()
    end)
    connect(clear.Activated, function()
        if not alive then return end
        captureAimKey = false
        state.aimKeyName = "NONE"
        saveAimKey("NONE")
        requestSave()
        repaint()
    end)
    repaint()
    return repaint
end

local function addChoice(page, label, choices, key, callback)
    local row = mk("Frame", {Name = key .. "Choices", Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0}, columnFor(page))
    registerWidget(page, row)
    round(row, 6)
    mk("TextLabel", {Text = label, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
        TextSize = 11, TextColor3 = P.text,
        Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left}, row)
    local buttons = {}
    local function repaint()
        for _, option in ipairs(choices) do
            local button = buttons[option.value]
            if button and button.Parent then
                local enabled = state[key] == option.value
                button.BackgroundColor3 = enabled and CONFIG.Accent or Color3.fromRGB(42, 43, 51)
                button.TextColor3 = enabled and CONFIG.Window or CONFIG.Muted
            end
        end
    end
    for i, option in ipairs(choices) do
        local button = mk("TextButton", {Text = option.label, BackgroundColor3 = CONFIG.Surface,
            TextColor3 = CONFIG.Muted, BorderSizePixel = 0, AutoButtonColor = true,
            TextSize = 9, Font = Enum.Font.GothamBold,
            Position = UDim2.new((i - 1) / #choices, 7, 0, 30),
            Size = UDim2.new(1 / #choices, -14 / #choices, 0, 27)}, row)
        round(button, 3)
        buttons[option.value] = button
        connect(button.Activated, function()
            state[key] = option.value
            if callback then callback(option.value) end
            repaint()
            requestSave()
        end)
    end
    repaint()
    return repaint
end

addSection(pages.ESP, "VISUALS", "Индикаторы игроков и дистанция")

addToggle(pages.ESP, "ESP подсветка", "Игроки за объектами до 200 м", "esp", function()
    refreshESP()
    refreshTracers()
    refreshShapes()
end)
addToggle(pages.ESP, "Линия над игроками", "От верха экрана к игрокам до 200 м", "tracers", function(enabled)
    if not enabled then clearTracers() else refreshTracers() end
    if enabled and not state.esp then tell("Включи ESP, чтобы отображать линии") end
end)
addToggle(pages.ESP, "2D Box", "Контур (при включённом ESP)", "espBox", function(enabled)
    refreshShapes()
    if enabled and not state.esp then tell("Включи ESP для отображения 2D Box") end
end)
addToggle(pages.ESP, "Skeleton ESP", "Кости R6/R15 (при включённом ESP)", "espSkeleton", function(enabled)
    refreshShapes()
    if enabled and not state.esp then tell("Включи ESP для Skeleton") end
end)
addToggle(pages.ESP, "Только противники", "Не отображать свою команду", "espEnemyOnly", function()
    refreshESP(); refreshShapes()
end)
addSection(pages.ESP, "ESP OPTIONS", "Дальность, стиль и подписи")
addSlider(pages.ESP, "Дальность ESP", "До 200 метров", "espRangeMeters", 10, 200, 5,
    function(v) return tostring(v) .. " м" end,
    function() refreshESP(); refreshShapes() end)
addSlider(pages.ESP, "Толщина линий", "Box / Skeleton (1–4 px)", "espLineThickness", 1, 4, 1,
    function(v) return tostring(v) .. " px" end, refreshShapes)
repaintColors = addChoice(pages.ESP, "Цвет ESP", {
    {value="TEAM", label="TEAM"}, {value="GOLD", label="GOLD"},
    {value="GREEN", label="GREEN"}, {value="WHITE", label="WHITE"},
}, "espColorPreset", function() refreshESP(); refreshShapes() end)
addToggle(pages.ESP, "Имена", "DisplayName над персонажами", "names")
addToggle(pages.ESP, "Здоровье", "HP над персонажами", "health")
addToggle(pages.ESP, "Дистанция", "Расстояние в метрах (≈)", "distance")
addToggle(pages.ESP, "Цвет команд", "Расцветка согласно TeamColor", "teamColors")

addSection(pages.AIM, "TARGETING", "Точка наведения и управление")
addToggle(pages.AIM, "Aimbot", "Включить наведение камеры", "aimbot", function(enabled)
    setAimEnabled(enabled, false)
end)
addAimModeSelector(pages.AIM)
repaintAimKeybind = addAimKeybind(pages.AIM)
addToggle(pages.AIM, "Проверка команды", "Игнорировать союзников", "teamCheck", function()
    aimTarget = nil
    aimNextScan = 0
end)
addToggle(pages.AIM, "Visible Check", "ON: только видимые | OFF: через стены", "visibleCheck", function()
    aimTarget = nil
    aimNextScan = 0
end)
addToggle(pages.AIM, "Target Lock", "Удерживать выбранную цель", "targetLock", function()
    aimTarget = nil; aimNextScan = 0
end)
addSection(pages.AIM, "ADVANCED", "Точность и упреждение")
addToggle(pages.AIM, "Prediction", "Упреждение движения персонажа", "prediction")
addSlider(pages.AIM, "Упреждение", "Прогноз 0–0.25 секунды", "predictionSeconds", 0, 0.25, 0.01,
    function(v) return string.format("%.2f s", v) end)
addSlider(pages.AIM, "Скорость по горизонтали", "Множитель плавности X", "aimSmoothX", 1, 10, 1,
    function(v) return tostring(v) .. " / 10" end)
addSlider(pages.AIM, "Скорость по вертикали", "Множитель плавности Y", "aimSmoothY", 1, 10, 1,
    function(v) return tostring(v) .. " / 10" end)
addSection(pages.AIM, "FOV EDITOR", "Круг захвата отображается на экране")
addToggle(pages.AIM, "Показывать FOV", "Круг на экране при включённом AIM", "fovVisible", refreshFovRing)
addSlider(pages.AIM, "Радиус FOV", "40–400 пикселей, размер зоны захвата", "aimFovPixels",
    CONFIG.AimFovMinPixels, CONFIG.AimFovMaxPixels, 5,
    function(value) return tostring(value) .. " px" end,
    function() aimTarget = nil; aimNextScan = 0; refreshFovRing() end)
addSlider(pages.AIM, "Толщина FOV", "Тонкая или выраженная окружность", "fovThickness",
    1, 4, 1, function(value) return tostring(value) .. " px" end,
    refreshFovRing)
addSection(pages.AIM, "CONTROL", "Дистанция и плавность")
addSlider(pages.AIM, "Дистанция AIM", "5–180 метров, граница захвата", "aimRangeMeters",
    CONFIG.AimRangeMinMeters, CONFIG.AimRangeMaxMeters, 5,
    function(value) return tostring(value) .. " м" end,
    function() aimTarget = nil; aimNextScan = 0 end)
addSlider(pages.AIM, "Скорость AIM", "0 = максимум · 10 = плавно", "aimSmoothness",
    0, 10, 1,
    function(value) return value == 0 and "MAX" or "Smooth " .. tostring(value) end)
addButton(pages.AIM, "Управление", "ПКМ: удерживать | клавиша: ON/OFF | телефон: AIM", function()
    tell("AIM: клавиша " .. state.aimKeyName .. " | FOV " .. state.aimFovPixels
        .. "px | Visible Check " .. (state.visibleCheck and "ON" or "OFF"))
end)

addSection(pages.MISC, "UTILITY", "Настройки клиента и графика")
addToggle(pages.MISC, "AntiAFK", "VirtualUser при событии Idled", "antiAfk", function(on)
    if not on then releaseAntiAfk() end
end)
addToggle(pages.MISC, "FPS Booster", "Пластик на земле / деталях + скрытие травы*", "booster", setBooster)
addToggle(pages.MISC, "FullBright", "Осветлить сцену локально", "fullbright", function() applyLighting() end)
addToggle(pages.MISC, "Часы / FPS / Ping", "Информационный блок экрана", "hud")
addToggle(pages.MISC, "HUD активных функций", "Состояние AIM, ESP, Booster", "activeHud")
addSection(pages.MISC, "PERFORMANCE", "Режимы и диагностика")
repaintPerf = addChoice(pages.MISC, "Режим производительности", {
    {value = "AUTO", label = "AUTO"},
    {value = "ECO", label = "ECO"},
    {value = "QUALITY", label = "QUALITY"},
}, "performanceMode")
local perfLabel = mk("TextLabel", {Name = "PerfDiagnostics", BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35),
    Text = "ESP 0 · Box 0 · Scan 0ms", TextColor3 = CONFIG.Muted,
    TextSize = 10, Font = Enum.Font.Code}, columnFor(pages.MISC))
registerWidget(pages.MISC, perfLabel)
round(perfLabel, 6)
addButton(pages.MISC, "Reset Character", "Локальный сброс Humanoid", function()
    local character = LocalPlayer.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not hum then
        tell("Reset: персонаж пока не загружен")
        return
    end
    local ok, err = pcall(function() hum.Health = 0 end)
    if ok then
        tell("Reset: запрос на сброс персонажа выполнен")
    else
        tell("Reset: " .. tostring(err))
    end
end)

addSection(pages.CFG, "PROFILES", "Настройки сохраняются локально при поддержке executor")
local profileLabels = {LEGIT = "LEGIT", RAGE = "RAGE", CUSTOM = "CUSTOM"}
local activeProfileLabel = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 27),
    Text = "ACTIVE: CUSTOM", BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0, TextColor3 = CONFIG.Accent,
    Font = Enum.Font.Code, TextSize = 11}, columnFor(pages.CFG))
registerWidget(pages.CFG, activeProfileLabel)
round(activeProfileLabel, 6)
repaintConfig = function()
    if activeProfileLabel.Parent then activeProfileLabel.Text = "ACTIVE: " .. profileName end
end
for _, name in ipairs({"LEGIT", "RAGE", "CUSTOM"}) do
    addButton(pages.CFG, "Профиль " .. name, "Применить настройки " .. name, function()
        useProfile(name, false)
    end)
end
addSection(pages.CFG, "CONFIG TOOLS", "Сохранение и восстановление")
addButton(pages.CFG, "Сохранить CUSTOM", "Сохранить текущие параметры", function()
    dirtyToken = dirtyToken + 1
    profiles.CUSTOM = snapshotState()
    profileName = "CUSTOM"
    writeProfileFile()
    repaintConfig()
    tell("CUSTOM сохранён")
end)
addButton(pages.CFG, "Восстановить профиль", "Загрузить выбранные настройки", function()
    useProfile(profileName, false)
end)
addButton(pages.CFG, "Сброс настроек", "Вернуть стандартные значения", function()
    dirtyToken = dirtyToken + 1
    profileName = "CUSTOM"
    profiles.CUSTOM = table.clone(defaultSettings)
    applySettings(defaultSettings, false)
    flushConfig()
    tell("Сброс выполнен")
end)
addSection(pages.CFG, "WINDOW", "RightShift — скрыть / открыть панель")
applyResponsiveLayout()


local status = mk("TextLabel", {
    Name = "Footer", Position = UDim2.new(0, 18, 1, -70),
    Size = UDim2.new(1, -36, 0, 15), BackgroundTransparency = 1,
    Text = "v" .. CONFIG.Version .. "    ·    LOCAL SESSION    ·    ×  UNLOAD",
    TextSize = 10, Font = Enum.Font.Code,
    TextColor3 = CONFIG.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, panel)
statusMessage = status

local mini = mk("TextButton", {
    Name = "OpenHub", Position = UDim2.new(0, 12, 0.39, 0),
    Size = UDim2.fromOffset(67, 35),
    BackgroundColor3 = P.background,
    TextColor3 = P.accent,
    Text = "124  ◇", TextSize = 12,
    Font = Enum.Font.Code, Visible = false,
}, gui)
round(mini, 4)
outline(mini, P.border)
local miniMoving = false
connect(hide.Activated, function()
    captureAimKey = false
    repaintAimKeybind()
    tweenPanel(0.94)
    panel.Visible = false
    mini.Visible = true
end)
connect(mini.Activated, function()
    if miniMoving then return end
    panelScale.Scale = 0.94
    panel.Visible = true
    mini.Visible = false
    tweenPanel(1)
end)
local miniDragInput, miniStartPos, miniStartOrigin
connect(mini.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        miniMoving = false
        miniDragInput = input
        miniStartPos = input.Position
        miniStartOrigin = mini.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if not miniDragInput or not miniStartPos then return end
    if miniDragInput.UserInputType == Enum.UserInputType.Touch then
        if miniDragInput ~= input then return end
    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end
    local offset = input.Position - miniStartPos
    if offset.Magnitude >= 8 then miniMoving = true end
    if miniMoving then
        mini.Position = UDim2.new(miniStartOrigin.X.Scale, miniStartOrigin.X.Offset + offset.X,
            miniStartOrigin.Y.Scale, miniStartOrigin.Y.Offset + offset.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if miniDragInput and (input == miniDragInput or
        (miniDragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1)) then
        miniDragInput = nil
        task.delay(0.15, function() if alive then miniMoving = false end end)
    end
end)

local aimTouchButton = mk("TextButton", {
    Name = "AimHold", AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -115),
    Size = UDim2.fromOffset(90, 41),
    BackgroundColor3 = Color3.fromRGB(47, 48, 45),
    TextColor3 = Color3.fromRGB(230, 224, 207),
    Text = "AIM: OFF", TextSize = 12,
    Font = Enum.Font.GothamMedium, Visible = false,
}, gui)
round(aimTouchButton, 5)
repaintAimTouch = function()
    if not aimTouchButton.Parent then return end
    local active = state.aimbot and aimHeldTouch
    aimTouchButton.Text = active and "AIM: ON" or "AIM: OFF"
    aimTouchButton.BackgroundColor3 = active and CONFIG.Accent or Color3.fromRGB(47, 48, 45)
    aimTouchButton.TextColor3 = active and CONFIG.Window or Color3.fromRGB(230, 224, 207)
end
connect(aimTouchButton.Activated, function()
    if not state.aimbot then return end
    aimHeldTouch = not aimHeldTouch
    aimTarget = nil
    aimNextScan = 0
    repaintAimTouch()
end)
repaintAimTouch()

local stats = mk("TextLabel", {
    Name = "Stats", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 12),
    Size = UDim2.fromOffset(192, 24),
    BackgroundColor3 = Color3.fromRGB(28, 31, 32),
    BackgroundTransparency = 0.16, BorderSizePixel = 0,
    TextColor3 = P.text,
    Text = "--:--:-- | FPS -- | Ping --",
    Font = Enum.Font.Code, TextSize = 10,
    Visible = state.hud,
}, gui)
round(stats, 4)
activeInfo = mk("TextLabel", {
    Name = "ActiveFeatures", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 41), Size = UDim2.fromOffset(192, 19),
    BackgroundColor3 = Color3.fromRGB(28, 31, 32), BackgroundTransparency = 0.22,
    TextColor3 = CONFIG.Accent, TextSize = 10, Font = Enum.Font.Code,
    Text = "", Visible = false,
}, gui)
round(activeInfo, 3)

-- Перетаскивание окна на ПК и телефоне.
local dragging, dragTouch, dragOrigin, panelOrigin = false, nil, nil, nil
connect(bar.InputBegan, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = true
    dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
    dragOrigin = input.Position
    panelOrigin = panel.Position
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or (dragTouch ~= nil and input == dragTouch) then
        dragging = false
        dragTouch = nil
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimHeldMouse = false
    end
end)
connect(UserInputService.InputBegan, function(input, processed)
    if not alive then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- Если начал печатать в TextBox, не назначаем клавишу от чата.
        if captureAimKey and UserInputService:GetFocusedTextBox() ~= nil then
            captureAimKey = false
            repaintAimKeybind()
            return
        end
        -- Переназначение клавиши обрабатывается раньше горячей клавиши.
        if captureAimKey then
            local name = input.KeyCode.Name
            if name == CONFIG.MenuKey.Name then
                captureAimKey = false
                repaintAimKeybind()
                tell("Клавиша " .. name .. " занята открытием меню")
                return
            end
            if name ~= "Unknown" and validAimKeyName(name) then
                state.aimKeyName = name
                captureAimKey = false
                saveAimKey(name)
                requestSave()
                repaintAimKeybind()
                tell("AIM: назначена клавиша " .. name)
            end
            return
        end
        -- При назначении буквенных клавиш (E, F и т.д.) Roblox может помечать
        -- InputBegan как processed даже без чата. Проверяем именно поле ввода
        -- и открытое меню, а не один флаг processed.
        local menuOpen = isRobloxMenuOpen()
        if UserInputService:GetFocusedTextBox() == nil and not menuOpen
            and input.KeyCode == CONFIG.MenuKey then
            panel.Visible = not panel.Visible
            mini.Visible = not panel.Visible
            if panel.Visible then panelScale.Scale = 0.94; tweenPanel(1) end
            return
        end
        if UserInputService:GetFocusedTextBox() == nil and not menuOpen
            and state.aimKeyName ~= "NONE"
            and input.KeyCode.Name == state.aimKeyName then
            local now = os.clock()
            if now - lastAimKeyToggle >= 0.20 then
                lastAimKeyToggle = now
                local enabled = not state.aimbot
                setAimEnabled(enabled, enabled)
                tell("AIM " .. (enabled and "ON" or "OFF") .. " [" .. state.aimKeyName .. "]")
            end
        end
        return
    end
    -- В Roblox ПКМ при управлении камерой может иметь processed=true.
    if input.UserInputType == Enum.UserInputType.MouseButton2
        and UserInputService:GetFocusedTextBox() == nil then
        aimHeldMouse = true
        aimNextScan = 0
    end
end)
connect(UserInputService.InputChanged, function(input)
    if not dragging or not dragOrigin or not panelOrigin then return end
    if dragTouch then
        if input ~= dragTouch then return end
    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end
    local delta = input.Position - dragOrigin
    panel.Position = UDim2.new(
        panelOrigin.X.Scale, panelOrigin.X.Offset + delta.X,
        panelOrigin.Y.Scale, panelOrigin.Y.Offset + delta.Y
    )
end)

connect(UserInputService.InputChanged, function(input)
    if not sliderDrag then return end
    if sliderDrag.touch then
        if input == sliderDrag.input then sliderDrag.update(input.Position.X) end
    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
        sliderDrag.update(input.Position.X)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if not sliderDrag then return end
    if (sliderDrag.touch and input == sliderDrag.input)
        or (not sliderDrag.touch and input.UserInputType == Enum.UserInputType.MouseButton1) then
        sliderDrag = nil
    end
end)

local antiAfkPressed = false
local antiAfkBusy = false
releaseAntiAfk = function()
    if antiAfkPressed then
        antiAfkPressed = false
        local camera = Workspace.CurrentCamera
        pcall(function()
            VirtualUser:Button2Up(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
        end)
    end
end
connect(LocalPlayer.Idled, function()
    if not alive or not state.antiAfk or antiAfkBusy then return end
    antiAfkBusy = true
    local camera = Workspace.CurrentCamera
    local cframe = camera and camera.CFrame or CFrame.new()
    local ok, err = pcall(function()
        VirtualUser:CaptureController()
        antiAfkPressed = true -- Защита от ошибки внутри виртуального нажатия.
        VirtualUser:Button2Down(Vector2.new(0, 0), cframe)
    end)
    if ok then task.wait(0.1) end
    -- Обязательно отпускаем даже после выключения функции или Unload.
    releaseAntiAfk()
    antiAfkBusy = false
    if not ok and alive then tell("AntiAFK: VirtualUser недоступен — " .. tostring(err)) end
end)

connect(Workspace.DescendantAdded, function(obj)
    if alive and state.booster then
        task.defer(function() optimizeObject(obj) end)
    end
end)
connect(Lighting.DescendantAdded, function(obj)
    if alive and state.booster then
        task.defer(function() optimizeObject(obj) end)
    end
end)

for _, property in ipairs(lightingProperties) do
    connect(Lighting:GetPropertyChangedSignal(property), function()
        if state.fullbright or (property == "GlobalShadows" and state.booster) then
            enforceLightingProperty(property)
        end
    end)
end

cleanup = function()
    if not alive then return end
    pcall(flushConfig) -- Последние изменения сохраняются до alive=false.
    releaseAntiAfk()
    alive = false
    state.esp = false
    state.aimbot = false
    aimHeldKey = false
    captureAimKey = false
    state.antiAfk = false
    state.booster = false
    state.fullbright = false
    boosterRevision = boosterRevision + 1
    restoreTerrainGrass()
    if aimBound then
        pcall(function() RunService:UnbindFromRenderStep(aimBindingName) end)
    end
    pcall(applyLighting)
    for obj, saved in pairs(savedGraphics) do
        for key, value in pairs(saved) do
            pcall(function() obj[key] = value end)
        end
        savedGraphics[obj] = nil
    end
    for player in pairs(renderData) do deleteRender(player) end
    clearShapes()
    for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
    table.clear(connections)
    pcall(function() gui:Destroy() end)
    pcall(function() if tracerGui then tracerGui:Destroy() end end)
    pcall(function() if shapeGui then shapeGui:Destroy() end end)
    pcall(function() if fovGui then fovGui:Destroy() end end)
    if env.ARMY124_CLEANUP == cleanup then env.ARMY124_CLEANUP = nil end
end

env.ARMY124_CLEANUP = cleanup
connect(close.Activated, function() if cleanup then cleanup() end end)
connect(Players.PlayerRemoving, deleteRender)

local okBind, errBind = pcall(function()
    RunService:BindToRenderStep(aimBindingName, Enum.RenderPriority.Camera.Value + 1, aimFrame)
end)
if okBind then
    aimBound = true
else
    tell("BindToRenderStep недоступен; используем RenderStepped")
    connect(RunService.RenderStepped, aimFrame)
end

task.spawn(function()
    while alive do
        if state.esp or next(renderData) ~= nil then
            local ok, err = pcall(refreshESP)
            if not ok then warn("[124 Community Hub] ESP: " .. tostring(err)) end
        end
        local tier = perfTier()
        local interval = tier == "ECO" and 1.0 or tier == "QUALITY" and 0.35
            or CONFIG.EspRefreshSeconds
        task.wait(interval)
    end
end)

-- Прозрачные линии обновляются 7–12 раз/с, отдельно от ESP-подписей.
task.spawn(function()
    while alive do
        if state.esp and state.tracers then
            local ok, err = pcall(refreshTracers)
            if not ok then warn("[124 Community Hub] Tracers: " .. tostring(err)) end
        elseif state.esp == false or state.tracers == false then
            clearTracers()
        end
        if state.esp and (state.espBox or state.espSkeleton) then
            local ok, err = pcall(refreshShapes)
            if not ok then warn("[124 Community Hub] Shapes: " .. tostring(err)) end
        elseif next(shapeData) ~= nil then
            clearShapes()
        end
        local tier = perfTier()
        task.wait(tier == "ECO" and 0.25 or tier == "QUALITY" and 0.08 or 0.12)
    end
end)

local frames, accumulated = 0, 0
connect(RunService.RenderStepped, function(dt)
    if not alive then return end
    frames = frames + 1
    accumulated = accumulated + math.max(dt, 0)
    if accumulated >= 1 then
        measuredFps = math.floor(frames / math.max(accumulated, 0.01) + 0.5)
        frames, accumulated = 0, 0
    end
end)

task.spawn(function()
    while alive do
        -- Страховочная проверка освещения. Основная защита от мигания — Changed-события.
        if state.fullbright or state.booster then
            for _, key in ipairs(lightingProperties) do enforceLightingProperty(key) end
        end
        stats.Visible = state.hud
        perfLabel.Text = string.format("FPS %d | ESP %d | Shape %d | Scan %.1f ms | %s",
            measuredFps, perfCounters.espCount, perfCounters.shapeCount,
            perfCounters.aimScanMs, perfTier())
        activeInfo.Visible = state.activeHud
        if state.activeHud then
            local features = {}
            if state.esp then table.insert(features, "ESP") end
            if state.aimbot then table.insert(features, "AIM") end
            if state.booster then table.insert(features, "BOOST") end
            if state.fullbright then table.insert(features, "LIGHT") end
            activeInfo.Text = #features > 0 and table.concat(features, " | ") or "124 / IDLE"
        end
        aimTouchButton.Visible = state.aimbot and UserInputService.TouchEnabled
        if not state.aimbot and (aimHeldTouch or aimHeldKey) then
            aimHeldTouch = false
            aimHeldKey = false
            repaintAimTouch()
        end
        if state.hud then
            local ping = "--"
            local ok, value = pcall(function() return LocalPlayer:GetNetworkPing() end)
            if ok and type(value) == "number" then
                ping = tostring(math.floor(value * 1000 + 0.5))
            end
            stats.Text = string.format("%s | FPS %d | %sms", os.date("%H:%M:%S"), measuredFps, ping)
        end
        task.wait(0.8)
    end
end)

-- Применяем профиль после создания всей GUI и привязок.
useProfile(profileName, true)
refreshFovRing()
print("[124 Community Hub] " .. CONFIG.Version .. " загружен | RED PANEL UI")
