-- 124 Community Hub v1.1.7 | Memory / Camera FOV / Anti-Aim (draw with camera; gameplay scanning stays throttled)
-- PlaceId: 18537079992
-- Локальный Luau-скрипт: ESP, Aim (голова/тело/ноги), Misc, FPS/Ping/часы.
-- Все изменяющие параметры функции выключены по умолчанию.
-- При повторном запуске старая копия очищается и настройки сцены восстанавливаются.

local CONFIG = {
    Version = "1.1.7",
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
    RecoilShotGraceSeconds = 0.20, -- Поздний откат камеры после отпускания спуска.
    RecoilFireWindowSeconds = 0.40, -- Короткий выстрел (в т.ч. на телефоне).
    RecoilMaxHoldSeconds = 3.50, -- Предохранитель, если Tool.Deactivated не пришло.
    RecoilMaxFrameSeconds = 0.16, -- Не компенсируем скачок камеры после лагов.
    RecoilMinPitchDegrees = 0.045, -- Не реагируем на микродрожание камеры.
    RecoilMaxPitchDegrees = 5.0, -- Не воспринимаем резкий разворот как отдачу.
    RecoilMaxCorrectionDegrees = 1.60, -- Ограничение коррекции за кадр.
    BoosterBatch = 80,
    FullBrightBrightness = 2.1,
    FullBrightAmbient = Color3.fromRGB(170, 170, 170),
    FullBrightOutdoorAmbient = Color3.fromRGB(175, 175, 175),
    FullBrightExposure = 0.12,
    Accent = Color3.fromRGB(232, 75, 91), -- Красный акцент в стиле Red Panel.
    EspGold = Color3.fromRGB(232, 188, 78), -- Отдельный цвет GOLD, не связан с красной темой.
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
-- Если прошлый Hub не смог восстановить защищённое свойство, повторяем
-- откат ДО новой инициализации (и не теряем старый оригинал).
if type(env.ARMY124_RECOVERY) == "function" then
    pcall(env.ARMY124_RECOVERY)
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
    controlRecoil = false, -- По умолчанию выключено: не трогаем камеру без согласия.
    recoilStrength = 75, -- Процент подавления измеренного вертикального скачка.
    aimKeyName = CONFIG.AimKeyDefault,
    aimMode = "body", -- head / body / legs; сохраняем прежний режим по умолчанию.
    teamCheck = true,
    antiAfk = false,
    airAlerts = true, -- Консервативное предупреждение о необычном перемещении.
    booster = false,
    boosterMode = "BALANCED", -- BALANCED / WHITE / ULTRA
    cameraFovEnabled = false, -- Отдельный FOV камеры; не совпадает с пиксельным AIM FOV.
    cameraFovDegrees = 85, -- Вертикальный угол обзора камеры, 55..110 градусов.
    antiAim = false, -- Визуальная локальная крутилка; стартует только по нажатию.
    antiAimSpeed = 1080, -- Градусов в секунду; ограничение задаётся ползунком.
    antiAimTilt = 12, -- Визуальный наклон туловища в градусах.
    hud = true,
}

local alive = true
local connections = {}
local renderData = {}
local savedLighting = nil
local savedGraphics = setmetatable({}, { __mode = "k" })
local boosterRevision = 0
-- Один объект состояния, чтобы избежать избытка локальных переменных в Luau.
local boosterPro = {
    originalFPS = {}, afterFPS = {}, baseline = nil, after = nil,
    complete = false, readyAt = nil, running = false,
    label = nil, revision = 0, mode = nil, restoreFailures = 0,
}
-- Только для исполнителей, умеющих читать/писать Terrain.Decoration.
-- Если это недоступно, не трогаем Terrain: полноценного SmoothPlastic для него нет.
local savedTerrainDecoration = nil
local savedTerrainColors = nil -- Цвета всех поддерживаемых материалов Terrain; полный откат.
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
-- Покадровый рендер ESP (после Camera/AIM/Recoil); НЕ сканируем игроков каждый кадр.
perfCounters.espVisual = {bound = false, bindingName = "Army124CommunityESP_" .. tostring(LocalPlayer.UserId),
    errorAt = 0, active = {}, projected = {}}
-- Только пассивная диагностика клиентских событий: это НЕ обход античита и НЕ антибан.
perfCounters.session = {
    messages = 0, warnings = 0, errors = 0, keywordHits = 0,
    listening = false, label = nil, lastShown = "",
}
function perfCounters.session.observe(message, level)
    if type(message) ~= "string" then return end
    local record = perfCounters.session
    record.messages = record.messages + 1
    local kind = tostring(level)
    local okName, enumName = pcall(function() return level.Name end)
    if okName and type(enumName) == "string" then kind = enumName end
    if kind:find("MessageError", 1, true) then
        record.errors = record.errors + 1
    elseif kind:find("MessageWarning", 1, true) then
        record.warnings = record.warnings + 1
    end
    -- Совпадение ключевого слова НЕ доказывает наличие античита.
    local lower = string.lower(message)
    for _, keyword in ipairs({"anti-cheat", "anticheat", "exploit detected",
        "suspicious activity", "kick", "ban", "античит", "нарушение"}) do
        if string.find(lower, keyword, 1, true) then
            record.keywordHits = record.keywordHits + 1
            break
        end
    end
end
function perfCounters.session.summary()
    local r = perfCounters.session
    return string.format("Logs %s | Warn %d | Err %d | Keywords %d",
        r.listening and "ON" or "N/A", r.warnings, r.errors, r.keywordHits)
end
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
    if state.espColorPreset == "GOLD" then return CONFIG.EspGold end
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
            -- Сохраняем ПОЛНЫЙ снимок до полного отката: если пользователь снова
            -- включит FullBright после частичного отказа, оригиналы не потеряются.
            local complete = true
            for key, original in pairs(savedLighting) do
                local ok = pcall(function()
                    if Lighting[key] ~= original then Lighting[key] = original end
                    if Lighting[key] ~= original then error("Lighting restore mismatch") end
                end)
                if not ok then
                    complete = false
                    boosterPro.restoreFailures = boosterPro.restoreFailures + 1
                    if boosterPro.restoreFailures <= 3 then
                        warn("[124 Community Hub] Lighting: отк
