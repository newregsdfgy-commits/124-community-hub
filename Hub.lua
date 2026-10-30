-- 124 Community Hub v0.8 | Армия Роблокса РП
-- PlaceId: 18537079992
-- Локальный Luau-скрипт: ESP, Aim (голова/тело/ноги), Misc, FPS/Ping/часы.
-- Все изменяющие параметры функции выключены по умолчанию.
-- При повторном запуске старая копия очищается и настройки сцены восстанавливаются.

local CONFIG = {
    PlaceId = 18537079992,
    EspRefreshSeconds = 0.55,
    EspRefreshLowFps = 0.90,
    EspMaxPlayers = 16, -- Ограничение количества Highlight для слабых телефонов.
    StudMeters = 0.28, -- Стандартный масштаб Roblox: 1 stud ≈ 0.28 м.
    EspMaxMeters = 200,
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
    AimScanLowFpsInterval = 0.18, -- На слабых устройствах уменьшаем нагрузку.
    BoosterBatch = 80,
    FullBrightBrightness = 2.1,
    FullBrightAmbient = Color3.fromRGB(170, 170, 170),
    FullBrightOutdoorAmbient = Color3.fromRGB(175, 175, 175),
    FullBrightExposure = 0.12,
    Accent = Color3.fromRGB(194, 158, 105), -- Матовая латунь, без неоновой подсветки.
    Neutral = Color3.fromRGB(255, 196, 100),
    Window = Color3.fromRGB(21, 24, 27),
    Surface = Color3.fromRGB(31, 35, 39),
    Muted = Color3.fromRGB(150, 151, 148),
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
    aimRangeMeters = 180,
    aimSmoothness = 3, -- 0 = мгновенно, 1 = быстро, 10 = максимально плавно.
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
local lightingApplying = false
local aimTarget = nil
local aimNextScan = 0
local tracerGui = nil
local fovGui = nil

local function validAimKeyName(name)
    if type(name) ~= "string" then return false end
    if name == "NONE" then return true end
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
    if state.teamColors and player.Team ~= nil then
        return player.TeamColor.Color
    end
    return CONFIG.Neutral
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
        MaxDistance = CONFIG.EspMaxMeters / CONFIG.StudMeters,
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

local function refreshESP()
    if not state.esp then
        for player in pairs(renderData) do deleteRender(player) end
        return
    end
    local character = LocalPlayer.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        for player in pairs(renderData) do deleteRender(player) end
        return
    end
    -- Рисуем ближайших, чтобы не создавать десятки дорогих Highlight.
    local candidates = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local ch = player.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local distance = (root.Position - myRoot.Position).Magnitude
                if distance * CONFIG.StudMeters <= CONFIG.EspMaxMeters then
                    candidates[#candidates + 1] = {player = player, distance = distance}
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local keep = {}
    for i = 1, math.min(#candidates, CONFIG.EspMaxPlayers) do
        local player = candidates[i].player
        keep[player] = true
        updatePlayer(player, myRoot)
    end
    for player in pairs(renderData) do
        if not keep[player] then deleteRender(player) end
    end
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
    -- Пропускаем персонажей, не затрачивая время на остальные типы объектов.
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return end
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

local function setBooster(enabled)
    boosterRevision = boosterRevision + 1
    local revision = boosterRevision
    if enabled then
        applyLighting()
        local grassOff = hideTerrainGrass()
        task.spawn(function()
            local all = Workspace:GetDescendants()
            for _, obj in ipairs(all) do
                if not alive or not state.booster or revision ~= boosterRevision then return end
                optimizeObject(obj)
                if _ % CONFIG.BoosterBatch == 0 then task.wait() end
            end
            local effects = Lighting:GetDescendants()
            for _, obj in ipairs(effects) do
                if not alive or not state.booster or revision ~= boosterRevision then return end
                optimizeObject(obj)
                if _ % CONFIG.BoosterBatch == 0 then task.wait() end
            end
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
    local me = LocalPlayer.Character
    local myRoot = me and me:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local fov = state.aimFovPixels

    -- Если старый игрок жив и по-прежнему подходит — не переключаться каждые 0.12 с.
    if aimTarget and aimTarget.player.Parent == Players then
        local chosen = targetPart(aimTarget.character)
        if chosen then
            local kept = examineTarget(camera, aimTarget.player, chosen, myRoot,
                center, fov * CONFIG.AimLockTolerance, state.visibleCheck)
            if kept then return kept end
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
            return candidate
        end
    end
    return nil
end

local function aimFrame(dt)
    if UserInputService:GetFocusedTextBox() ~= nil then return end
    if not alive or not state.aimbot or not (aimHeldMouse or aimHeldTouch or aimHeldKey) then
        aimTarget = nil
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local now = os.clock()
    if now >= aimNextScan then
        local scanEvery = measuredFps < 25 and CONFIG.AimScanLowFpsInterval
            or CONFIG.AimScanInterval
        aimNextScan = now + scanEvery
        aimTarget = findAimTarget(camera)
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
    local goal = CFrame.lookAt(origin, point)
    if state.aimSmoothness == 0 then
        camera.CFrame = goal
    else
        local speed = CONFIG.AimSmoothnessBaseline / state.aimSmoothness
        local alpha = math.clamp(1 - math.exp(-speed * math.clamp(dt, 0, 0.1)), 0, 1)
        camera.CFrame = camera.CFrame:Lerp(goal, alpha)
    end
end

-- 124 / FIELD PANEL — простой собственный интерфейс без внешних UI-библиотек.
-- Плоские строки, осмысленные отступы и минимум визуальных эффектов.
local gui = mk("ScreenGui", {
    Name = "Army124CommunityHubV08",
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

-- Лёгкий FOV overlay: одно кольцо UIStroke, без цикла создания новых объектов.
fovGui = mk("ScreenGui", {
    Name = "Army124FovV08", ResetOnSpawn = false, IgnoreGuiInset = true,
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
end

local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(400, 720)
local winWidth = math.max(245, math.min(288, viewport.X - 24))
local winHeight = math.max(252, math.min(344, viewport.Y - 34))
local panel = mk("Frame", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(winWidth, winHeight),
    BackgroundColor3 = CONFIG.Window,
    BorderSizePixel = 0,
    Active = true,
}, gui)
round(panel, 6)
outline(panel, Color3.fromRGB(64, 66, 66))

-- Небольшая цветовая риска вместо яркой шапки на всю ширину.
mk("Frame", {
    Name = "AccentNotch", BorderSizePixel = 0,
    BackgroundColor3 = CONFIG.Accent,
    Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(35, 2),
}, panel)

local bar = mk("Frame", {
    Name = "DragBar", BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 61), Active = true,
}, panel)
local emblem = mk("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(45, 47, 45), BorderSizePixel = 0,
    Position = UDim2.fromOffset(11, 11), Size = UDim2.fromOffset(35, 34),
    Text = "124", TextColor3 = CONFIG.Accent,
    Font = Enum.Font.GothamBold, TextSize = 12,
}, bar)
round(emblem, 4)
mk("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(56, 8),
    Size = UDim2.new(1, -139, 0, 23),
    Text = "COMMUNITY", TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(229, 226, 217),
    TextXAlignment = Enum.TextXAlignment.Left,
}, bar)
mk("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(56, 30),
    Size = UDim2.new(1, -139, 0, 15),
    Text = "ARMY RP  /  0.8", TextSize = 10,
    Font = Enum.Font.Code, TextColor3 = CONFIG.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, bar)
local cleanup -- Обработчик выгрузки определяется ниже, как и раньше.
local hide = mk("TextButton", {
    Name = "Minimize", Position = UDim2.new(1, -67, 0, 14),
    Size = UDim2.fromOffset(25, 25), BackgroundColor3 = CONFIG.Surface,
    Text = "-", TextColor3 = Color3.fromRGB(199, 199, 191),
    TextSize = 17, Font = Enum.Font.GothamMedium,
    AutoButtonColor = true,
}, bar)
round(hide, 3)
local close = mk("TextButton", {
    Name = "CloseHub", Position = UDim2.new(1, -36, 0, 14),
    Size = UDim2.fromOffset(25, 25), BackgroundColor3 = CONFIG.Surface,
    Text = "x", TextColor3 = Color3.fromRGB(209, 162, 148),
    Font = Enum.Font.GothamBold, TextSize = 13,
    AutoButtonColor = true,
}, bar)
round(close, 3)
mk("Frame", {
    BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(61, 64, 65),
    BackgroundTransparency = 0.25,
    Position = UDim2.fromOffset(11, 60), Size = UDim2.new(1, -22, 0, 1),
}, panel)

-- Вкладки выглядят как обычная навигация, без трёх крупных плашек.
local tabs = mk("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(11, 65),
    Size = UDim2.new(1, -22, 0, 33),
}, panel)
mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, tabs)
local tabButtons = {}
local tabUnderline = {}
local pages = {}
local currentPage = "ESP"
for idx, key in ipairs({"ESP", "AIM", "MISC"}) do
    local button = mk("TextButton", {
        Name = key .. "Tab", LayoutOrder = idx,
        BackgroundTransparency = 1,
        Size = UDim2.new(1/3, -4, 1, -1),
        Text = key, Font = Enum.Font.GothamMedium,
        TextSize = 11, TextColor3 = CONFIG.Muted,
        AutoButtonColor = false,
    }, tabs)
    tabButtons[key] = button
    tabUnderline[key] = mk("Frame", {
        Name = "ActiveLine", BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 1, -2),
        Size = UDim2.new(1, -16, 0, 2),
        BackgroundColor3 = CONFIG.Accent,
        Visible = false,
    }, button)
    local scroll = mk("ScrollingFrame", {
        Name = key .. "Page",
        Position = UDim2.fromOffset(11, 100),
        Size = UDim2.new(1, -22, 1, -128),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(112, 110, 105),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = key == "ESP",
    }, panel)
    mk("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
    }, scroll)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 4),
    }, scroll)
    pages[key] = scroll
end

local function showPage(key)
    if key ~= "AIM" and captureAimKey then
        captureAimKey = false
        repaintAimKeybind()
    end
    currentPage = key
    for name, page in pairs(pages) do
        local selected = name == key
        page.Visible = selected
        tabButtons[name].TextColor3 = selected and Color3.fromRGB(236, 228, 211) or CONFIG.Muted
        tabButtons[name].Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium
        tabUnderline[name].Visible = selected
    end
end
for name, button in pairs(tabButtons) do
    connect(button.Activated, function() showPage(name) end)
end
showPage("ESP")

-- Линии сверху экрана к позиции над головой игрока, до 200 метров.
-- Рендер выполняется с ограниченной частотой, а не на каждом кадре.
local function clearTracers()
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
        if head and root and (root.Position - myRoot.Position).Magnitude * CONFIG.StudMeters <= CONFIG.EspMaxMeters then
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

-- Строки интерфейса: включённость показывает маленький индикатор справа,
-- всё остальное остаётся спокойным, без перекраски карточки целиком.
local function addSection(page, title, subtitle)
    local container = mk("Frame", {
        Name = title .. "Heading", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 33),
    }, page)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 0, 17),
        Text = title, Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 16), Size = UDim2.new(1, -4, 0, 15),
        Text = subtitle, Font = Enum.Font.Gotham,
        TextSize = 9, TextColor3 = CONFIG.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
end

local function addToggle(page, title, description, key, onChanged)
    local row = mk("TextButton", {
        Name = key,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = CONFIG.Surface,
        BorderSizePixel = 0, AutoButtonColor = false, Text = "",
    }, page)
    round(row, 4)
    local accentLine = mk("Frame", {
        Name = "EnabledMark", BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 8), Size = UDim2.fromOffset(2, 29),
        BackgroundColor3 = CONFIG.Accent, Visible = false,
    }, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -62, 0, 19),
        Text = title, TextSize = 12, Font = Enum.Font.GothamMedium,
        TextColor3 = Color3.fromRGB(226, 225, 216),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 25), Size = UDim2.new(1, -62, 0, 14),
        Text = description, TextSize = 9, Font = Enum.Font.Gotham,
        TextColor3 = CONFIG.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local pill = mk("TextLabel", {
        Position = UDim2.new(1, -47, 0, 12),
        Size = UDim2.fromOffset(37, 21),
        BackgroundColor3 = Color3.fromRGB(53, 55, 56),
        Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = Color3.fromRGB(177, 180, 175), Text = "OFF",
    }, row)
    round(pill, 3)
    local function update()
        if not row.Parent then return end
        local enabled = state[key]
        pill.Text = enabled and "ON" or "OFF"
        pill.BackgroundColor3 = enabled and CONFIG.Accent or Color3.fromRGB(53, 55, 56)
        pill.TextColor3 = enabled and CONFIG.Window or Color3.fromRGB(177, 180, 175)
        accentLine.Visible = enabled
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
    end)
    update()
    return row
end

local function addButton(page, text, description, handler)
    local button = mk("TextButton", {
        BackgroundColor3 = Color3.fromRGB(46, 46, 44),
        Size = UDim2.new(1, 0, 0, 45),
        Text = "", AutoButtonColor = true,
    }, page)
    round(button, 4)
    mk("Frame", {
        BorderSizePixel = 0, BackgroundColor3 = CONFIG.Accent,
        Position = UDim2.fromOffset(0, 8), Size = UDim2.fromOffset(2, 29),
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -20, 0, 19),
        Text = text, Font = Enum.Font.GothamMedium,
        TextSize = 12, TextColor3 = Color3.fromRGB(234, 225, 207),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 25),
        Size = UDim2.new(1, -20, 0, 14),
        Text = description, Font = Enum.Font.Gotham,
        TextSize = 9, TextColor3 = CONFIG.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, button)
    connect(button.Activated, handler)
    return button
end

-- Общий drag-handler работает и с мышью, и с touch; нет RenderStepped у слайдеров.
local sliderDrag = nil
local function addSlider(page, title, description, key, minValue, maxValue, step, formatter, onChanged)
    local container = mk("Frame", {
        Name = key .. "Slider", Size = UDim2.new(1, 0, 0, 67),
        BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
    }, page)
    round(container, 4)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -103, 0, 18), Text = title,
        TextColor3 = Color3.fromRGB(229, 226, 217),
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
        BackgroundColor3 = Color3.fromRGB(238, 230, 210), BorderSizePixel = 0,
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
    end
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
    }, page)
    round(container, 4)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 0, 16),
        Text = "Точка наведения", Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = Color3.fromRGB(229, 226, 217),
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
                button.BackgroundColor3 = selected and CONFIG.Accent or Color3.fromRGB(48, 51, 53)
                button.TextColor3 = selected and CONFIG.Window or Color3.fromRGB(187, 190, 185)
            end
        end
    end
    for index, mode in ipairs(modes) do
        local button = mk("TextButton", {
            Name = "Aim_" .. mode.value,
            Size = UDim2.new(1/3, -4, 1, 0),
            Position = UDim2.new((index - 1)/3, 2, 0, 0),
            BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(48, 51, 53),
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
        end)
    end
    repaint()
    return container
end

-- Назначение клавиши работает в любой версии с доступным UserInputService.
-- Подсказка и кнопка сброса находятся внутри прокручиваемой вкладки AIM.
local function addAimKeybind(page)
    local container = mk("Frame", {
        Name = "AimKeybind", Size = UDim2.new(1, 0, 0, 78),
        BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
    }, page)
    round(container, 4)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 4),
        Size = UDim2.new(1, -20, 0, 20), Text = "Клавиша включения AIM",
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = Color3.fromRGB(229, 226, 217),
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
        BackgroundColor3 = Color3.fromRGB(48, 51, 53),
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
        repaint()
    end)
    repaint()
    return repaint
end

addSection(pages.ESP, "VISUALS", "Индикаторы игроков и дистанция")

addToggle(pages.ESP, "ESP подсветка", "Игроки за объектами до 200 м", "esp", function()
    refreshESP()
    refreshTracers()
end)
addToggle(pages.ESP, "Линия над игроками", "От верха экрана к игрокам до 200 м", "tracers", function(enabled)
    if not enabled then clearTracers() else refreshTracers() end
end)
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
addToggle(pages.MISC, "AntiAFK", "VirtualUser при событии Idled", "antiAfk")
addToggle(pages.MISC, "FPS Booster", "Пластик на земле / деталях + скрытие травы*", "booster", setBooster)
addToggle(pages.MISC, "FullBright", "Осветлить сцену локально", "fullbright", function() applyLighting() end)
addToggle(pages.MISC, "Часы / FPS / Ping", "Информационный блок экрана", "hud")
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

local status = mk("TextLabel", {
    Name = "Footer", Position = UDim2.new(0, 11, 1, -23),
    Size = UDim2.new(1, -22, 0, 17), BackgroundTransparency = 1,
    Text = "0.8   /   local   /   x to unload",
    TextSize = 10, Font = Enum.Font.Code,
    TextColor3 = CONFIG.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, panel)
statusMessage = status

local mini = mk("TextButton", {
    Name = "OpenHub", Position = UDim2.new(0, 12, 0.39, 0),
    Size = UDim2.fromOffset(60, 34),
    BackgroundColor3 = CONFIG.Window,
    TextColor3 = CONFIG.Accent,
    Text = "[124]", TextSize = 12,
    Font = Enum.Font.Code, Visible = false,
}, gui)
round(mini, 4)
outline(mini, Color3.fromRGB(100, 97, 88))
connect(hide.Activated, function()
    captureAimKey = false
    repaintAimKeybind()
    panel.Visible = false
    mini.Visible = true
end)
connect(mini.Activated, function() panel.Visible = true; mini.Visible = false end)

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
    TextColor3 = Color3.fromRGB(229, 226, 217),
    Text = "--:--:-- | FPS -- | Ping --",
    Font = Enum.Font.Code, TextSize = 10,
    Visible = state.hud,
}, gui)
round(stats, 4)

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
            if name ~= "Unknown" and validAimKeyName(name) then
                state.aimKeyName = name
                captureAimKey = false
                saveAimKey(name)
                repaintAimKeybind()
                tell("AIM: назначена клавиша " .. name)
            end
            return
        end
        -- При назначении буквенных клавиш (E, F и т.д.) Roblox может помечать
        -- InputBegan как processed даже без чата. Проверяем именно поле ввода
        -- и открытое меню, а не один флаг processed.
        local menuOpen = false
        pcall(function() menuOpen = GuiService.MenuIsOpen == true end)
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

connect(LocalPlayer.Idled, function()
    if not alive or not state.antiAfk then return end
    local ok, err = pcall(function()
        local camera = Workspace.CurrentCamera
        VirtualUser:CaptureController()
        VirtualUser:Button2Down(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
        task.wait(0.1)
        if alive and state.antiAfk then
            VirtualUser:Button2Up(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
        end
    end)
    if not ok then tell("AntiAFK: VirtualUser недоступен — " .. tostring(err)) end
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
    for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
    table.clear(connections)
    pcall(function() gui:Destroy() end)
    pcall(function() if tracerGui then tracerGui:Destroy() end end)
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
        local delay = (measuredFps > 0 and measuredFps < 25)
            and CONFIG.EspRefreshLowFps or CONFIG.EspRefreshSeconds
        task.wait(delay)
    end
end)

-- Прозрачные линии обновляются 7–12 раз/с, отдельно от ESP-подписей.
task.spawn(function()
    while alive do
        if state.esp and state.tracers then
            local ok, err = pcall(refreshTracers)
            if not ok then warn("[124 Community Hub] Tracers: " .. tostring(err)) end
        end
        task.wait(measuredFps < 25 and 0.15 or 0.085)
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

refreshFovRing()
print("[124 Community Hub] v0.8 загружен | Hotkey | Visible Check | FOV Editor")
