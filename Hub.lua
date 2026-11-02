-- 124 Community Hub v1.1.9 | FPS Booster frame-budget / streaming queue / ESP visual limiter
-- PlaceId: 18537079992
-- Локальный Luau-скрипт: ESP, Aim (голова/тело/ноги), Misc, FPS/Ping/часы.
-- Все изменяющие параметры функции выключены по умолчанию.
-- При повторном запуске старая копия очищается и настройки сцены восстанавливаются.

local CONFIG = {
    Version = "1.1.9",
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
    BoosterBatch = 320, -- Максимум объектов за один проход, но ограничиваем и время.
    BoosterSliceMs = 2.2, -- Бюджет CPU на кадр для полной обработки карты.
    BoosterLowFpsSliceMs = 0.9, -- При низком FPS защищаем время отрисовки.
    BoosterQueueBatch = 144, -- Новые объекты StreamingEnabled.
    BoosterQueueSliceMs = 1.1,
    EspVisualBalancedHz = 40, -- ESP-рамки/скелеты, AIM остаётся покадровым.
    EspVisualEcoHz = 20,
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
    guardLowSince = nil, guardLastCheck = 0, guardWarned = false,
    queued = {}, queuedSeen = setmetatable({}, {__mode = "k"}),
    queueHead = 1, queueTail = 0, queueCount = 0, queueCap = 8192,
    queuedProcessed = setmetatable({}, {__mode = "k"}),
    queueDropped = 0, scanned = 0, repairing = false, repaired = false,
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

local cachedGreen = Color3.fromRGB(93, 210, 152)
local cachedWhite = Color3.fromRGB(229, 229, 223)
local function getPlayerColor(player)
    if state.espColorPreset == "GOLD" then return CONFIG.EspGold end
    if state.espColorPreset == "GREEN" then return cachedGreen end
    if state.espColorPreset == "WHITE" then return cachedWhite end
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
                        warn("[124 Community Hub] Lighting: откат " .. tostring(key) .. " не выполнен; повторим")
                    end
                end
            end
            lightingApplying = false
            if complete then savedLighting = nil end
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
    if savedTerrainDecoration then
        -- При переключении BALANCED -> WHITE исходная копия могла сохраниться
        -- после временного сбоя восстановления. Просто снова выключаем траву.
        local saved = savedTerrainDecoration
        local ok = pcall(saved.setter, saved.terrain, "Decoration", false)
        return ok
    end
    local getter, setter = terrainAccessor("read"), terrainAccessor("write")
    if not getter or not setter then return false end
    local okRead, original = pcall(getter, terrain, "Decoration")
    if not okRead or type(original) ~= "boolean" then return false end
    local okWrite = pcall(setter, terrain, "Decoration", false)
    if not okWrite then return false end
    savedTerrainDecoration = {terrain = terrain, original = original, setter = setter, getter = getter}
    return true
end

local function restoreTerrainGrass()
    local saved = savedTerrainDecoration
    if not saved then return true end
    local ok = pcall(function()
        saved.setter(saved.terrain, "Decoration", saved.original)
        -- При наличии функции чтения проверяем, что значение реально вернулось.
        if saved.getter then
            local value = saved.getter(saved.terrain, "Decoration")
            if value ~= saved.original then error("Terrain grass restore mismatch") end
        end
    end)
    if ok then
        savedTerrainDecoration = nil
    else
        boosterPro.restoreFailures = boosterPro.restoreFailures + 1
        if boosterPro.restoreFailures <= 3 then
            warn("[124 Community Hub] Booster: не удалось восстановить траву; снимок сохранён")
        end
    end
    return ok
end

-- Белая карта: Terrain окрашиваем только при доступном чтении исходного цвета.
-- Цвет каждого материала восстанавливается при отключении Booster и Unload.
local terrainMaterialNames = {
    "Grass", "LeafyGrass", "Ground", "Sand", "Sandstone", "Rock", "Slate",
    "Mud", "Snow", "Ice", "Glacier", "Concrete", "Brick", "Cobblestone",
    "Asphalt", "Basalt", "Pavement", "Limestone", "Salt", "CrackedLava",
}
local function whitenTerrain()
    if savedTerrainColors then
        -- Снимок сохранён после частичного отката; заново красим уже известные
        -- материалы в белый, не перезаписывая их оригинальные значения.
        for _, item in ipairs(savedTerrainColors.items) do
            pcall(function()
                savedTerrainColors.terrain:SetMaterialColor(item[1], Color3.fromRGB(255, 255, 255))
            end)
        end
        return
    end
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    local originals = {}
    for _, name in ipairs(terrainMaterialNames) do
        local material = Enum.Material[name]
        if material then
            local ok, value = pcall(function() return terrain:GetMaterialColor(material) end)
            if ok and value then
                local changed = pcall(function()
                    terrain:SetMaterialColor(material, Color3.fromRGB(255, 255, 255))
                end)
                if changed then originals[#originals + 1] = {material, value} end
            end
        end
    end
    if #originals > 0 then savedTerrainColors = {terrain = terrain, items = originals} end
end
local function restoreTerrainColors()
    local data = savedTerrainColors
    if not data then return true end
    -- Даже при частичном откате сохраняем ВСЕ оригиналы: иначе при следующем
    -- включении WHITE потеряем цвета уже восстановленных материалов.
    local complete = true
    for _, item in ipairs(data.items) do
        local ok = pcall(function()
            data.terrain:SetMaterialColor(item[1], item[2])
            local current = data.terrain:GetMaterialColor(item[1])
            if current ~= item[2] then error("Terrain material restore mismatch") end
        end)
        if not ok then
            complete = false
            boosterPro.restoreFailures = boosterPro.restoreFailures + 1
            if boosterPro.restoreFailures <= 3 then
                warn("[124 Community Hub] Booster: не удалось вернуть цвет Terrain; снимок сохранён")
            end
        end
    end
    if complete then savedTerrainColors = nil end
    return complete
end

-- FPS Booster Pro: три ступени, снимки ТОЛЬКО изменённых свойств.
-- Иерархии GUI (включая SurfaceGui/BillboardGui), камеры и персонажей исключены.
-- Профили можно менять в реальном времени, оригинальные значения не теряются.
-- Кэшируем модели игроков: на больших картах нельзя вызывать GetPlayers() на каждой детали.
boosterPro.protectedCharacters = setmetatable({}, {__mode = "k"})
boosterPro.protectedNames = {}
function boosterPro.watchPlayer(person)
    boosterPro.protectedNames[person.Name] = true
    if person.Character then boosterPro.protectedCharacters[person.Character] = true end
    if person.CharacterAdded then
        connect(person.CharacterAdded, function(character)
            boosterPro.protectedCharacters[character] = true
            -- Модель могла успеть получить белый материал ДО события CharacterAdded.
            -- Восстанавливаем снимки сразу, не дожидаясь отключения Booster.
            if boosterPro.restoreProtectedTree then
                boosterPro.restoreProtectedTree(character)
            end
        end)
    end
end
for _, person in ipairs(Players:GetPlayers()) do boosterPro.watchPlayer(person) end
if Players.PlayerAdded then connect(Players.PlayerAdded, boosterPro.watchPlayer) end

-- Проверять каждую родительскую модель для каждой детали дорого.
-- При обходе дерева достаточно проверить границу ветки ОДИН раз.
function boosterPro.isProtectedBranch(obj)
    local cam = Workspace.CurrentCamera
    if obj == cam then return true end
    if obj:IsA("LayerCollector") or obj:IsA("GuiBase2d") then return true end
    if obj:IsA("Model") then
        if boosterPro.protectedCharacters[obj] or boosterPro.protectedNames[obj.Name] then
            return true
        end
        if obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChild("HumanoidRootPart") then
            return true
        end
        if obj:FindFirstChild("Head") and
            (obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("Torso")
                or obj:FindFirstChild("LowerTorso")) then
            return true
        end
    end
    return false
end
function boosterPro.isProtected(obj)
    local parent = obj
    while parent and parent ~= Workspace and parent ~= Lighting do
        if boosterPro.isProtectedBranch(parent) then return true end
        parent = parent.Parent
    end
    return false
end

-- Таблицы целевых свойств общие для всех деталей, без десятков тысяч
-- временных таблиц и Color3.fromRGB на каждом объекте.
local graphicsWhite = Color3.new(1, 1, 1)
local graphicsPlain = {CastShadow = false}
local graphicsWhitePart = {CastShadow = false, Material = Enum.Material.SmoothPlastic,
    MaterialVariant = "", Color = graphicsWhite}
local graphicsUltraPart = {CastShadow = false, Material = Enum.Material.SmoothPlastic,
    MaterialVariant = "", Color = graphicsWhite, Reflectance = 0}
local graphicsWhiteMesh = {CastShadow = false, Material = Enum.Material.SmoothPlastic,
    MaterialVariant = "", TextureID = "", Color = graphicsWhite}
local graphicsUltraMesh = {CastShadow = false, Material = Enum.Material.SmoothPlastic,
    MaterialVariant = "", TextureID = "", Color = graphicsWhite, Reflectance = 0}
if Enum.RenderFidelity then graphicsUltraMesh.RenderFidelity = Enum.RenderFidelity.Performance end
local graphicsTransparent = {Transparency = 1}
local graphicsDisabled = {Enabled = false}
local graphicsSpecialMesh = {TextureId = ""}
local graphicsSurface = {ColorMap = "", NormalMap = "", RoughnessMap = "", MetalnessMap = ""}
local graphicsWater = {WaterWaveSize = 0, WaterWaveSpeed = 0, WaterReflectance = 0}
local graphicsAtmosphere = {Density = 0, Haze = 0, Glare = 0, Offset = 0}
local graphicsClouds = {Cover = 0, Density = 0}

local function graphicsProperty(obj)
    local level = state.boosterMode
    local white = level == "WHITE" or level == "ULTRA"
    local ultra = level == "ULTRA"
    if obj:IsA("Terrain") then
        return ultra and graphicsWater or nil
    elseif obj:IsA("MeshPart") then
        return ultra and graphicsUltraMesh or white and graphicsWhiteMesh or graphicsPlain
    elseif obj:IsA("BasePart") then
        return ultra and graphicsUltraPart or white and graphicsWhitePart or graphicsPlain
    elseif white and obj:IsA("SpecialMesh") then
        return graphicsSpecialMesh
    elseif white and obj:IsA("SurfaceAppearance") then
        return graphicsSurface
    elseif white and (obj:IsA("Decal") or obj:IsA("Texture")) then
        return graphicsTransparent
    elseif white and (obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight")) then
        return graphicsDisabled
    elseif obj:IsA("PostEffect") or obj:IsA("ParticleEmitter") or
        obj:IsA("Trail") or obj:IsA("Beam") then
        return graphicsDisabled
    elseif white and (obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles")) then
        return graphicsDisabled
    elseif ultra and obj:IsA("Atmosphere") then
        return graphicsAtmosphere
    elseif ultra and obj:IsA("Clouds") then
        return graphicsClouds
    end
    return nil
end

-- Не перезаписываем исходный снимок при переходе BALANCED -> WHITE -> ULTRA.
-- При возврате на менее жёсткий режим ненужные изменения сразу откатываются.
local function optimizeObject(obj, alreadyScreened)
    if not alive or not state.booster then return end
    local desired = graphicsProperty(obj)
    local snap = savedGraphics[obj]
    -- Не проверяем цепочку родителей и не создаём таблицу для нерелевантных объектов.
    if not desired and not snap then return end
    if not alreadyScreened and boosterPro.isProtected(obj) then return end
    desired = desired or {}
    if snap then
        for key, original in pairs(snap) do
            if desired[key] == nil then
                local ok = pcall(function() obj[key] = original end)
                if ok or not obj.Parent then
                    snap[key] = nil
                else
                    boosterPro.restoreFailures = boosterPro.restoreFailures + 1
                    if boosterPro.restoreFailures <= 3 then
                        warn("[124 Community Hub] Booster: ошибка смены режима, свойство " .. tostring(key))
                    end
                end
            end
        end
    end
    for key, target in pairs(desired) do
        local read, current = pcall(function() return obj[key] end)
        if read and current ~= target then
            local wrote = pcall(function() obj[key] = target end)
            if wrote then
                if not snap then snap = {}; savedGraphics[obj] = snap end
                if snap[key] == nil then snap[key] = current end
            end
        end
    end
    if snap and not next(snap) then savedGraphics[obj] = nil end
end

-- Проходим дерево без GetDescendants(): контролируем число объектов и CPU-миллисекунды.
-- Новые детали, добавленные во время обхода, дочитает FIFO после завершения.
local function optimizeHierarchy(root, revision)
    local stack = {{items = root:GetChildren(), index = 1}}
    local sliceStarted = os.clock()
    local count = 0
    while #stack > 0 do
        if not alive or not state.booster or revision ~= boosterRevision then return false end
        local level = stack[#stack]
        local obj = level.items[level.index]
        if not obj then
            stack[#stack] = nil
        else
            level.index = level.index + 1
            if not boosterPro.isProtectedBranch(obj) then
                if boosterPro.queuedSeen[obj] then boosterPro.queuedProcessed[obj] = true end
                optimizeObject(obj, true)
                local children = obj:GetChildren()
                if #children > 0 then
                    stack[#stack + 1] = {items = children, index = 1}
                end
            end
            boosterPro.scanned = boosterPro.scanned + 1
            count = count + 1
            if count >= CONFIG.BoosterBatch or (count % 16 == 0 and
                (os.clock() - sliceStarted) * 1000 >=
                    (measuredFps < 35 and CONFIG.BoosterLowFpsSliceMs or CONFIG.BoosterSliceMs)) then
                count = 0
                task.wait()
                sliceStarted = os.clock()
            end
        end
    end
    return true
end

function boosterPro.average(values)
    if #values < 2 then return nil end
    local total = 0
    for _, value in ipairs(values) do total = total + value end
    return math.floor(total / #values + 0.5)
end
function boosterPro.measure(value)
    if not alive or value <= 0 then return end
    local target = nil
    if state.booster then
        -- Измеряем и во время долгой перекраски: ранний FPS Guard иначе бесполезен.
        if boosterPro.startedAt and os.clock() >= boosterPro.startedAt + 4 then
            target = boosterPro.afterFPS
        end
    else
        target = boosterPro.originalFPS
    end
    if target then
        target[#target + 1] = value
        if #target > 6 then table.remove(target, 1) end
    end
    if state.booster then
        boosterPro.after = boosterPro.average(boosterPro.afterFPS)
        -- After the warmup, detect a sustained drop against pre-Booster FPS.
        -- The rollback function is installed after the UI and config handlers exist.
        if boosterPro.autoRollback then boosterPro.autoRollback() end
    end
end
function boosterPro.readout()
    local before = boosterPro.baseline and tostring(boosterPro.baseline) or "н/д"
    local after = boosterPro.after and tostring(boosterPro.after) or "замер..."
    local delta = ""
    if boosterPro.after and boosterPro.baseline and boosterPro.baseline > 0 then
        local change = boosterPro.after - boosterPro.baseline
        local rawPercent = change * 100 / boosterPro.baseline
        -- Симметричное округление: Lua math.floor(-40 - 0.5) давал -41.
        local percent = (rawPercent >= 0) and math.floor(rawPercent + 0.5)
            or -math.floor(-rawPercent + 0.5)
        delta = string.format(" | %+d FPS (%+d%%)", change, percent)
    elseif not state.booster and not boosterPro.after then
        after = "н/д"
    end
    local phase = state.booster and not boosterPro.complete
        and (" | Деталей: " .. tostring(boosterPro.scanned)) or ""
    return "До: " .. before .. " FPS  |  После: " .. after .. delta .. phase
end

function boosterPro.restoreObject(obj, snapshot)
    local left = false
    for key, original in pairs(snapshot) do
        local ok = pcall(function() obj[key] = original end)
        if ok or not obj.Parent then
            snapshot[key] = nil
        else
            left = true
            boosterPro.restoreFailures = boosterPro.restoreFailures + 1
            if boosterPro.restoreFailures <= 3 then
                warn("[124 Community Hub] Booster: не удалось восстановить " .. tostring(key)
                    .. " у " .. tostring(obj.Name))
            end
        end
    end
    if not left then savedGraphics[obj] = nil end
end

-- Снимки могли появиться раньше, чем Roblox объявил Model персонажем.
-- Инициируется CharacterAdded или поступлением Humanoid/частей тела.
function boosterPro.restoreProtectedTree(character)
    if not character then return end
    -- Раньше перебирались ВСЕ сохранённые детали карты на каждое появление
    -- персонажа. Теперь проверяем только его собственное дерево.
    local stack = {character}
    while #stack > 0 do
        local obj = stack[#stack]
        stack[#stack] = nil
        local snap = savedGraphics[obj]
        if snap then boosterPro.restoreObject(obj, snap) end
        for _, child in ipairs(obj:GetChildren()) do
            stack[#stack + 1] = child
        end
    end
end

local function setBooster(enabled, keepBaseline)
    boosterRevision = boosterRevision + 1
    local revision = boosterRevision
    boosterPro.revision = revision
    boosterPro.complete = false
    boosterPro.readyAt = nil
    boosterPro.restoreFailures = 0
    boosterPro.guardLowSince = nil
    boosterPro.guardLastCheck = 0
    -- Discard old queued descendants. New events belong to the new revision.
    boosterPro.queued = {}
    boosterPro.queuedSeen = setmetatable({}, {__mode = "k"})
    boosterPro.queuedProcessed = setmetatable({}, {__mode = "k"})
    boosterPro.queueHead, boosterPro.queueTail, boosterPro.queueCount = 1, 0, 0
    boosterPro.queueDropped, boosterPro.scanned = 0, 0
    boosterPro.repairing, boosterPro.repaired = false, false
    if enabled then
        boosterPro.after = nil
        boosterPro.afterFPS = {}
        boosterPro.guardWarned = false
        if not keepBaseline then boosterPro.baseline = boosterPro.average(boosterPro.originalFPS) end
        boosterPro.mode = state.boosterMode
        boosterPro.startedAt = os.clock()
        applyLighting()
        if state.boosterMode == "BALANCED" then
            restoreTerrainGrass()
            restoreTerrainColors()
        else
            hideTerrainGrass()
            whitenTerrain()
        end
        task.spawn(function()
            -- Сначала синхронизируем старые снимки: это важно при ULTRA -> BALANCED.
            local n, phaseStarted = 0, os.clock()
            for obj in pairs(savedGraphics) do
                if not alive or revision ~= boosterRevision or not state.booster then return end
                optimizeObject(obj)
                n = n + 1
                if n % 16 == 0 and ((os.clock() - phaseStarted) * 1000 >=
                    CONFIG.BoosterSliceMs or n % CONFIG.BoosterBatch == 0) then
                    task.wait()
                    phaseStarted = os.clock()
                end
            end
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then optimizeObject(terrain) end
            if not optimizeHierarchy(Workspace, revision) then return end
            if not optimizeHierarchy(Lighting, revision) then return end
            if revision ~= boosterRevision or not state.booster then return end
            boosterPro.complete = true
            boosterPro.readyAt = os.clock() + 1.5
            tell("FPS Booster Pro: " .. state.boosterMode .. " применён; просмотрено "
                .. tostring(boosterPro.scanned) .. " объектов; измеряем FPS")
        end)
    else
        restoreTerrainGrass()
        restoreTerrainColors()
        applyLighting()
        task.spawn(function()
            local count, sliceStarted = 0, os.clock()
            for obj, snapshot in pairs(savedGraphics) do
                if revision ~= boosterRevision or state.booster then return end
                boosterPro.restoreObject(obj, snapshot)
                count = count + 1
                if count % 16 == 0 and ((os.clock() - sliceStarted) * 1000 >=
                    CONFIG.BoosterSliceMs or count % CONFIG.BoosterBatch == 0) then
                    task.wait()
                    sliceStarted = os.clock()
                end
            end
            if alive and revision == boosterRevision then
                local remaining = 0
                for obj, snapshot in pairs(savedGraphics) do
                    if obj.Parent and next(snapshot) ~= nil then remaining = remaining + 1 end
                end
                if remaining > 0 or boosterPro.restoreFailures > 0 then
                    tell("FPS Booster Pro: частичный откат, ошибок "
                        .. tostring(boosterPro.restoreFailures) .. ", объектов с остатком "
                        .. tostring(remaining))
                else
                    tell("FPS Booster Pro: исходные свойства восстановлены")
                end
            end
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

local recoil = (function()
local controller = {bound = false, shots = 0, bindingName = "Army124CommunityRecoil_" .. tostring(LocalPlayer.UserId)}
-- RECOIL CONTROL v1.0.2 — локальная компенсация подброса камеры.
-- Не обращается к RemoteEvent, не меняет параметры оружия и не даёт гарантий
-- против серверного разброса или custom gun scripts без Tool.Activated.
-- Критический инвариант: без активного Tool + факта выстрела CFrame НЕ меняется.
local recoilTool = nil
local recoilToolConnections = {}
local recoilCharacterConnections = {}
local recoilLastCamera = nil
local recoilLastPitch = nil
local recoilFireUntil = 0
local recoilHolding = false
local recoilHoldStarted = 0

local function stopRecoilFire()
    recoilHolding = false
    recoilFireUntil = 0
end

local function resetRecoilTracking()
    stopRecoilFire()
    recoilLastCamera = nil
    recoilLastPitch = nil
end

local function disconnectRecoilConnections(collection)
    for _, conn in ipairs(collection) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(collection)
end

local function markRecoilShot()
    if not alive or not state.controlRecoil or not recoilTool then return end
    controller.shots = controller.shots + 1
    local now = os.clock()
    if not recoilHolding then recoilHoldStarted = now end
    recoilHolding = true
    recoilFireUntil = now + CONFIG.RecoilFireWindowSeconds
end

local function equipRecoilTool(tool)
    if recoilTool == tool then return end
    disconnectRecoilConnections(recoilToolConnections)
    recoilTool = nil
    resetRecoilTracking()
    if not tool or not tool:IsA("Tool") then return end
    recoilTool = tool
    recoilToolConnections[#recoilToolConnections + 1] = tool.Activated:Connect(markRecoilShot)
    recoilToolConnections[#recoilToolConnections + 1] = tool.Deactivated:Connect(function()
        recoilHolding = false
        recoilFireUntil = math.max(recoilFireUntil, os.clock() + CONFIG.RecoilShotGraceSeconds)
    end)
end

local function bindRecoilCharacter(character)
    disconnectRecoilConnections(recoilCharacterConnections)
    equipRecoilTool(nil)
    if not character then return end
    recoilCharacterConnections[#recoilCharacterConnections + 1] = character.ChildAdded:Connect(function(child)
        if alive and child:IsA("Tool") then equipRecoilTool(child) end
    end)
    recoilCharacterConnections[#recoilCharacterConnections + 1] = character.ChildRemoved:Connect(function(child)
        if child == recoilTool then equipRecoilTool(nil) end
    end)
    equipRecoilTool(character:FindFirstChildOfClass("Tool"))
end

local function shutdownRecoilControl()
    disconnectRecoilConnections(recoilCharacterConnections)
    equipRecoilTool(nil)
end

connect(LocalPlayer.CharacterAdded, bindRecoilCharacter)
bindRecoilCharacter(LocalPlayer.Character)

local function recoilFrame(dt)
    local camera = Workspace.CurrentCamera
    if not alive or not camera then
        recoilLastCamera = nil
        recoilLastPitch = nil
        return
    end
    local currentPitch = camera.CFrame:ToOrientation()
    local previousPitch = recoilLastPitch
    local sameCamera = recoilLastCamera == camera
    recoilLastCamera = camera
    recoilLastPitch = currentPitch -- Обновляем базу даже при выключенной функции.
    if not sameCamera or previousPitch == nil then return end
    if not state.controlRecoil or state.recoilStrength <= 0 or recoilTool == nil
        or recoilTool.Parent ~= LocalPlayer.Character then return end
    if isRobloxMenuOpen() or UserInputService:GetFocusedTextBox() ~= nil then return end
    -- AIM уже стабилизирует активную цель. Второе управление CFrame вызвало бы конфликт.
    if state.aimbot and (aimHeldMouse or aimHeldTouch or aimHeldKey) and aimTarget then return end
    local now = os.clock()
    local firing = now <= recoilFireUntil
        or (recoilHolding and now - recoilHoldStarted <= CONFIG.RecoilMaxHoldSeconds)
    if not firing or dt <= 0 or dt > CONFIG.RecoilMaxFrameSeconds then return end
    local pitchUp = signedAngle(previousPitch, currentPitch)
    if pitchUp < math.rad(CONFIG.RecoilMinPitchDegrees)
        or pitchUp > math.rad(CONFIG.RecoilMaxPitchDegrees) then return end
    local correction = math.min(
        pitchUp * (state.recoilStrength / 100),
        math.rad(CONFIG.RecoilMaxCorrectionDegrees)
    )
    if correction <= 0 then return end
    -- В Roblox положительный локальный X поднимает LookVector; отрицательный
    -- разворот компенсирует измеренный за кадр подброс, не меняя yaw и позицию.
    camera.CFrame = camera.CFrame * CFrame.Angles(-correction, 0, 0)
    recoilLastPitch = camera.CFrame:ToOrientation()
end

-- END RECOIL CONTROL v1.0.2
controller.reset = resetRecoilTracking
controller.shutdown = shutdownRecoilControl
controller.frame = recoilFrame
controller.inspect = function()
    return recoilTool and recoilTool.Name or "нет Tool", controller.shots
end
return controller
end)()

-- 124 / RED PANEL — собственный интерфейс без внешних UI-библиотек.
-- Две колонки на больших экранах, одна колонка на телефонах.
local gui = mk("ScreenGui", {
    Name = "Army124CommunityHubV100",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- Линии ESP на отдельном ScreenGui: позиции теперь обновляются после движения камеры.
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

-- v1.1.0 MEMORY: автономные контроллеры со снимками исходных свойств.
-- Один локальный контейнер во избежание лимита локальных переменных Luau.
local memoryFX = {
    camera = {saved = setmetatable({}, {__mode = "k"}), current = nil, bindingName =
        "Army124CameraFov_" .. tostring(LocalPlayer.UserId), bound = false},
    spin = {character = nil, humanoid = nil, originalAuto = nil,
        joint = nil, originalC0 = nil, nextJointSearch = 0, lastError = 0,
        pending = {}},
}

-- v1.1.1: снимок не теряется при временном отказе записи FOV.
-- В OFF повторяем восстановление на следующих кадрах и при выгрузке.
function memoryFX.camera.restore(camera)
    local controller = memoryFX.camera
    local old = camera and controller.saved[camera]
    if old == nil then return true end
    local ok = pcall(function() camera.FieldOfView = old end)
    if ok then controller.saved[camera] = nil end
    return ok
end

function memoryFX.camera.apply()
    local controller = memoryFX.camera
    local camera = Workspace.CurrentCamera
    if state.cameraFovEnabled and camera then
        -- Старую камеру восстанавливаем даже после ошибки первой попытки.
        for prior in pairs(controller.saved) do
            if prior ~= camera then controller.restore(prior) end
        end
        if controller.saved[camera] == nil then
            local ok, current = pcall(function() return camera.FieldOfView end)
            if ok then controller.saved[camera] = current end
        end
        if controller.saved[camera] ~= nil then
            controller.current = camera
            pcall(function()
                local degrees = math.clamp(state.cameraFovDegrees, 55, 110)
                if math.abs(camera.FieldOfView - degrees) > 0.01 then
                    camera.FieldOfView = degrees
                end
            end)
        end
    else
        controller.current = nil
        -- В отличие от v1.1.0 не забываем старую камеру после ошибки OFF.
        for prior in pairs(controller.saved) do controller.restore(prior) end
    end
end

function memoryFX.camera.reset()
    local controller = memoryFX.camera
    controller.current = nil
    for camera in pairs(controller.saved) do controller.restore(camera) end
    return next(controller.saved) == nil
end

-- Неудачные снимки C0/AutoRotate остаются привязаны к исходному объекту,
-- поэтому переключение персонажа не перезапишет оригинал нового рига.
function memoryFX.spin.restorePending()
    local spin = memoryFX.spin
    for object, properties in pairs(spin.pending) do
        for property, value in pairs(properties) do
            local ok = pcall(function() object[property] = value end)
            if ok then properties[property] = nil end
        end
        if not next(properties) then spin.pending[object] = nil end
    end
    return next(spin.pending) == nil
end

function memoryFX.spin.reset()
    local spin = memoryFX.spin
    spin.restorePending()
    if spin.joint and spin.originalC0 then
        local ok = pcall(function() spin.joint.C0 = spin.originalC0 end)
        if not ok then
            local pending = spin.pending[spin.joint] or {}
            -- Не заменяем ранее сохранённый оригинал новым повреждённым состоянием.
            if pending.C0 == nil then pending.C0 = spin.originalC0 end
            spin.pending[spin.joint] = pending
        end
    end
    if spin.humanoid and spin.originalAuto ~= nil then
        local ok = pcall(function() spin.humanoid.AutoRotate = spin.originalAuto end)
        if not ok then
            local pending = spin.pending[spin.humanoid] or {}
            if pending.AutoRotate == nil then pending.AutoRotate = spin.originalAuto end
            spin.pending[spin.humanoid] = pending
        end
    end
    spin.character, spin.humanoid, spin.joint = nil, nil, nil
    spin.originalAuto, spin.originalC0 = nil, nil
    spin.nextJointSearch = 0
    return next(spin.pending) == nil
end

function memoryFX.spin.frame(dt)
    memoryFX.spin.restorePending()
    -- При незавершённом откате не перезаписываем C0/AutoRotate новой позой.
    if not alive or not state.antiAim or next(memoryFX.spin.pending) ~= nil then
        if memoryFX.spin.character then memoryFX.spin.reset() end
        return
    end
    -- Не ломаем работающий AIM/Recoil, ввод текста и встроенное меню Roblox.
    if (state.aimbot and (aimHeldKey or aimHeldMouse or aimHeldTouch))
        or isRobloxMenuOpen() or UserInputService:GetFocusedTextBox() ~= nil then
        if memoryFX.spin.character then memoryFX.spin.reset() end
        return
    end
    local character = LocalPlayer.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not hum or not root or hum.Health <= 0 or hum.Sit then
        if memoryFX.spin.character then memoryFX.spin.reset() end
        return
    end
    local spin = memoryFX.spin
    if spin.character ~= character or spin.humanoid ~= hum then
        spin.reset()
        spin.character, spin.humanoid = character, hum
        spin.originalAuto = hum.AutoRotate
    end
    local now = os.clock()
    if not spin.joint and now >= spin.nextJointSearch then
        spin.nextJointSearch = now + 0.75
        -- Поддержка классических R6/R15 Motor6D; новые AnimationConstraint
        -- могут не поддерживать этот способ наклона.
        local candidate = character:FindFirstChild("Waist", true)
            or character:FindFirstChild("RootJoint", true)
            or character:FindFirstChild("Root", true)
        if candidate and candidate:IsA("Motor6D") then
            spin.joint = candidate
            spin.originalC0 = candidate.C0
        end
    end
    local ok, err = pcall(function()
        if hum.AutoRotate then hum.AutoRotate = false end
        local safeDt = math.clamp(type(dt) == "number" and dt or 0, 0, 0.05)
        local deltaYaw = math.rad(math.clamp(state.antiAimSpeed, 180, 1440)) * safeDt
        if deltaYaw > 0 then root.CFrame = root.CFrame * CFrame.Angles(0, deltaYaw, 0) end
        if spin.joint and spin.originalC0 then
            local target = spin.originalC0 * CFrame.Angles(math.rad(state.antiAimTilt), 0, 0)
            if spin.joint.C0 ~= target then spin.joint.C0 = target end
        end
    end)
    if not ok and now - spin.lastError > 3 then
        warn("[124 Community Hub] Anti-Aim: " .. tostring(err))
        spin.lastError = now
    end
end

-- Сохраняем только ограниченный набор настроек; код из JSON никогда не выполняется.
local HttpService = game:GetService("HttpService")
local storedKeys = {
    "esp", "tracers", "names", "health", "distance", "teamColors", "espBox", "espSkeleton",
    "espEnemyOnly", "espRangeMeters", "espColorPreset", "espLineThickness", "performanceMode",
    "aimbot", "aimRangeMeters", "aimSmoothness", "aimSmoothX", "aimSmoothY",
    "prediction", "predictionSeconds", "targetLock", "aimFovPixels", "aimMode",
    "fovVisible", "fovThickness", "visibleCheck", "teamCheck", "fullbright", "booster",
    "antiAfk", "airAlerts", "hud", "activeHud", "aimKeyName", "controlRecoil", "recoilStrength", "boosterMode",
    "cameraFovEnabled", "cameraFovDegrees", "antiAim", "antiAimSpeed", "antiAimTilt",
}
local numericRules = {
    espRangeMeters = {10, 200}, espLineThickness = {1, 4},
    aimRangeMeters = {5, 180}, aimSmoothness = {0, 10},
    aimSmoothX = {1, 10}, aimSmoothY = {1, 10},
    predictionSeconds = {0, 0.25}, aimFovPixels = {40, 400},
    fovThickness = {1, 4}, recoilStrength = {0, 100},
    cameraFovDegrees = {55, 110}, antiAimSpeed = {180, 1440}, antiAimTilt = {0, 25},
}
local textRules = {
    aimMode = {head = true, body = true, legs = true},
    espColorPreset = {TEAM = true, GOLD = true, GREEN = true, WHITE = true},
    performanceMode = {AUTO = true, ECO = true, QUALITY = true},
    boosterMode = {BALANCED = true, WHITE = true, ULTRA = true},
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
        return ok
    end
    return type(readfile) ~= "function" -- no competing disk source; env cache is authoritative
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
                -- Старый конфиг имел только один Booster (WHITE); сохраняем его смысл.
                if loaded.profiles.CUSTOM.boosterMode == nil and loaded.profiles.CUSTOM.booster then
                    profiles.CUSTOM.boosterMode = "WHITE"
                end
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
    local oldBoosterMode = state.boosterMode
    for key, value in pairs(sanitized) do state[key] = value end
    -- Автозагрузка не активирует боевые действия и вращение тела.
    -- Даже если в сохранённом CUSTOM antiAim=true, старт остаётся безопасным.
    if autoLoad then
        state.aimbot = false
        state.antiAfk = false
        state.antiAim = false
        -- Prevent an old saved profile from activating Booster before a baseline.
        -- The user may still enable it manually after loading the game.
        state.booster = false
        -- Аварийная загрузка после Safety Stop: старая файловая копия
        -- (при ошибке writefile) не должна снова включать опасные функции.
        if env.ARMY124_SAFE_BOOT == true then
            state.esp = false
            state.tracers = false
            state.espBox = false
            state.espSkeleton = false
            state.controlRecoil = false
            state.fullbright = false
            state.booster = false
            state.cameraFovEnabled = false
            -- Не стираем чужой пресет; обновляем только активный CUSTOM.
            if profileName == "CUSTOM" then
                profiles.CUSTOM = snapshotState()
            end
            -- Переходим к обычному сохранению. Если файловые API недоступны,
            -- синхронный env cache всё равно содержит безопасный снимок.
            if writeProfileFile() then
                env.ARMY124_SAFE_BOOT = nil
            end -- При отказе записи флаг остаётся, чтобы старый файл не включил функции.
        end
    end
    if state.aimKeyName then saveAimKey(state.aimKeyName) end
    if wasBooster ~= state.booster or (state.booster and oldBoosterMode ~= state.boosterMode) then
        setBooster(state.booster, wasBooster and state.booster)
    end
    pcall(applyLighting)
    setAimEnabled(state.aimbot, false)
    recoil.reset()
    memoryFX.spin.reset()
    memoryFX.camera.apply()
    aimTarget = nil
    aimNextScan = 0
    restoring = false
    for _, update in pairs(refreshToggles) do pcall(update) end
    for _, update in pairs(refreshSliders) do pcall(update) end
    pcall(repaintAimMode)
    pcall(repaintAimKeybind)
    pcall(repaintColors)
    pcall(repaintPerf)
    if boosterPro.repaint then pcall(boosterPro.repaint) end
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
-- На телефоне даже альбомный экран остаётся одноколоночным: элементы
-- управления не должны уменьшаться до нечитабельного размера.
local wideLayout = (not UserInputService.TouchEnabled) and viewport.X >= 770
local function windowMetrics(view)
    local mobile = UserInputService.TouchEnabled
    local wide = (not mobile) and view.X >= 770
    local landscape = view.X > view.Y
    local availableWidth = math.max(160, view.X - (mobile and 22 or 32))
    local preferredWidth = wide and 752 or (mobile and landscape and 520 or 410)
    local width = math.min(availableWidth, preferredWidth)
    local availableHeight = math.max(120, view.Y - (mobile and 22 or 38))
    local height = math.min(wide and 532 or 610, availableHeight)
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
-- AnchorPoint-aware экранный clamp: возвращает панель / плавающую кнопку в кадр.
-- GUI работает с IgnoreGuiInset=true, поэтому размеры берём из ViewportSize.
function boosterPro.clampWindowPosition(position, size, anchor)
    local camera = Workspace.CurrentCamera
    local view = camera and camera.ViewportSize or viewport
    anchor = anchor or Vector2.new(0, 0)
    local width = view.X * size.X.Scale + size.X.Offset
    local height = view.Y * size.Y.Scale + size.Y.Offset
    local margin = 5
    local x = view.X * position.X.Scale + position.X.Offset
    local y = view.Y * position.Y.Scale + position.Y.Offset
    local minX, maxX = margin + width * anchor.X, view.X - margin - width * (1 - anchor.X)
    local minY, maxY = margin + height * anchor.Y, view.Y - margin - height * (1 - anchor.Y)
    x = maxX >= minX and math.clamp(x, minX, maxX) or view.X * anchor.X
    y = maxY >= minY and math.clamp(y, minY, maxY) or view.Y * anchor.Y
    return UDim2.fromOffset(x, y)
end
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
    Position = UDim2.new(0, 0, 1, -57), Size = UDim2.new(1, 0, 0, 57),
}, panel)
round(tabs, 10)
-- Отделяем декоративную линию от горизонтального UIListLayout.
-- В v1.0.0 линия занимала полный слот и выталкивала вкладки ЗА окно.
mk("Frame", {
    Name = "NavLine", BackgroundColor3 = P.border, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 1),
}, tabs)
local navSlots = mk("Frame", {
    Name = "NavigationSlots", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 1, -1),
}, tabs)
mk("UIPadding", {
    PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
    PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
}, navSlots)
mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
}, navSlots)
local tabButtons, tabUnderline, tabOutlines, pages, pageColumns = {}, {}, {}, {}, {}
local currentPage = "AIM"
-- Защита от ложных нажатий: палец сдвигает страницу, а не переключатель.
local scrollFrames = {}
local touchGestures = setmetatable({}, {__mode = "k"})
local suppressTapUntil = 0
local function pointerOverScroll(position)
    if not position then return false end
    for _, scroll in ipairs(scrollFrames) do
        if scroll.Parent and scroll.Parent.Visible and scroll.Visible then
            local at, sz = scroll.AbsolutePosition, scroll.AbsoluteSize
            if at and sz and position.X >= at.X and position.X <= at.X + sz.X
                and position.Y >= at.Y and position.Y <= at.Y + sz.Y then
                return true
            end
        end
    end
    return false
end
connect(UserInputService.InputBegan, function(input)
    if not alive or input.UserInputType ~= Enum.UserInputType.Touch then return end
    if pointerOverScroll(input.Position) then
        touchGestures[input] = {start = input.Position, dragged = false}
    end
end)
connect(UserInputService.InputChanged, function(input)
    local touch = touchGestures[input]
    if not touch then return end
    local dx = input.Position.X - touch.start.X
    local dy = input.Position.Y - touch.start.Y
    if math.abs(dy) >= 11 and math.abs(dy) >= math.abs(dx) * 1.12 then
        touch.dragged = true
        suppressTapUntil = os.clock() + 0.22
    elseif math.abs(dx) >= 12 then
        touch.dragged = true
    end
end)
connect(UserInputService.InputEnded, function(input)
    local touch = touchGestures[input]
    if touch and touch.dragged then
        suppressTapUntil = math.max(suppressTapUntil, os.clock() + 0.22)
    end
end)
local function allowTap(input)
    if not alive then return false end
    if input and input.UserInputType == Enum.UserInputType.Keyboard then return true end
    if input and input.UserInputType == Enum.UserInputType.MouseButton1 then return true end
    if not UserInputService.TouchEnabled then return true end
    if input and input.UserInputType == Enum.UserInputType.Touch then
        local info = touchGestures[input]
        if info and info.dragged then return false end
    end
    return os.clock() >= suppressTapUntil
end
local function safeActivate(control, callback)
    return connect(control.Activated, function(input, ...)
        if allowTap(input) then callback(input, ...) end
    end)
end
local navigation = {
    {key = "AIM", label = "COMBAT", symbol = "◎"},
    {key = "ESP", label = "VISUALS", symbol = "▣"},
    {key = "MISC", label = "MEMORY", symbol = "≡"},
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
    round(scroll, 9)
    mk("UIStroke", {Color = P.border, Thickness = 1, Transparency = 0.54}, scroll)
    scroll.ScrollingEnabled = true
    scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    table.insert(scrollFrames, scroll)
    connect(scroll:GetPropertyChangedSignal("CanvasPosition"), function()
        if UserInputService.TouchEnabled then
            suppressTapUntil = os.clock() + 0.24
        end
    end)
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
        Size = UDim2.new(0.25, -8, 1, 0),
        Text = tab.symbol .. "  " .. tab.label,
        Font = Enum.Font.GothamMedium, TextSize = 11,
        TextColor3 = P.dim, AutoButtonColor = false,
    }, navSlots)
    round(button, 6)
    tabOutlines[key] = mk("UIStroke", {Color = P.accent, Transparency = 1, Thickness = 1}, button)
    tabButtons[key] = button
    tabUnderline[key] = mk("Frame", {
        Name = "ActiveLine", BackgroundColor3 = P.accent,
        BorderSizePixel = 0, Position = UDim2.new(0.5, -11, 0, -7),
        Size = UDim2.fromOffset(22, 2), Visible = false,
    }, button)
    local page = mk("Frame", {
        Name = key .. "Page", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 82),
        Size = UDim2.new(1, -24, 1, -155),
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
    ["FOV EDITOR"] = "right", ["CONTROL"] = "right", ["RECOIL CONTROL"] = "right",
    ["UTILITY"] = "left", ["PERFORMANCE"] = "right",
    ["CAMERA FOV"] = "left", ["ANTI-AIM"] = "right",
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
    panel.Position = boosterPro.clampWindowPosition(panel.Position, panel.Size, panel.AnchorPoint)
    if boosterPro.floatingButton then
        boosterPro.floatingButton.Position = boosterPro.clampWindowPosition(boosterPro.floatingButton.Position,
            boosterPro.floatingButton.Size, boosterPro.floatingButton.AnchorPoint)
    end
    wideLayout = wide
    -- На узких экранах короткие подписи не перекрывают соседние вкладки.
    for _, nav in ipairs(navigation) do
        tabButtons[nav.key].Text = width < 355 and (nav.key == "MISC" and "MEM" or nav.key)
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
        tabOutlines[name].Transparency = selected and 0.44 or 1
    end
end
for name, button in pairs(tabButtons) do
    safeActivate(button, function() showPage(name) end)
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

-- Линии сверху экрана к игрокам. Движение на КАЖДОМ кадре, поиск игроков реже.
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
    if not camera or not tracerGui or not tracerGui.Parent then
        -- Не оставляем старые линии на экране при смене/потере CurrentCamera.
        for _, item in pairs(renderData) do
            if item.tracer then item.tracer.Visible = false end
        end
        return
    end
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
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if player.Parent == Players and ch == player.Character
            and hum and hum.Health > 0 and head and root
            and (not state.espEnemyOnly or not sameTeamESP(player))
            and (root.Position - myRoot.Position).Magnitude * CONFIG.StudMeters <= state.espRangeMeters then
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
local function shapeItem(player, character)
    local item = shapeData[player]
    if item and item.container.Parent and item.character == character then return item end
    -- Респавн: старые кости относятся к другой модели, их нельзя переиспользовать.
    if item then pcall(function() item.container:Destroy() end) end
    local container = mk("Frame", {Name = "S" .. player.UserId, Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, Active = false}, shapeGui)
    item = {container = container, character = character, parts = {}, box = {}, bones = {}}
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
        if next(shapeData) ~= nil then clearShapes() end
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera or not shapeGui or not shapeGui.Parent then
        -- Не оставляем рамки и кости в последней позиции при отсутствии камеры.
        for _, item in pairs(shapeData) do hideShape(item) end
        perfCounters.shapeCount = 0
        return
    end
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        for _, item in pairs(shapeData) do hideShape(item) end
        perfCounters.shapeCount = 0
        return
    end
    local activeCount, active = 0, perfCounters.espVisual.active
    table.clear(active)
    -- Повторное использование таблиц уменьшает выделение памяти на каждом кадре.
    local projected = perfCounters.espVisual.projected
    for player, info in pairs(renderData) do
        local char = info.character
        local head = char and char:FindFirstChild("Head")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if player.Parent == Players and head and root and hum and hum.Health > 0
            and player.Character == char and (not state.espEnemyOnly or not sameTeamESP(player))
            and (root.Position - myRoot.Position).Magnitude * CONFIG.StudMeters <= state.espRangeMeters then
            active[player] = true
            local item = shapeItem(player, char)
            local color = getPlayerColor(player)
            local top, on1 = camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.25, 0))
            local bottom, on2 = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            if on1 and on2 and top.Z > 0 and bottom.Z > 0 then
                activeCount = activeCount + 1
                if state.espBox then
                    ensureShapeLines(item, "box", 4)
                    local half = math.clamp(math.abs(bottom.Y - top.Y) * 0.23, 4, 160)
                    local left, right = top.X - half, top.X + half
                    setLine(item.box[1], Vector2.new(left, top.Y), Vector2.new(right, top.Y), state.espLineThickness, color)
                    setLine(item.box[2], Vector2.new(left, bottom.Y), Vector2.new(right, bottom.Y), state.espLineThickness, color)
                    setLine(item.box[3], Vector2.new(left, top.Y), Vector2.new(left, bottom.Y), state.espLineThickness, color)
                    setLine(item.box[4], Vector2.new(right, top.Y), Vector2.new(right, bottom.Y), state.espLineThickness, color)
                else
                    for _, line in ipairs(item.box) do setIfDifferent(line, "Visible", false) end
                end
                if state.espSkeleton then
                    local pairsToDraw = char:FindFirstChild("UpperTorso") and shapePairsR15 or shapePairsR6
                    ensureShapeLines(item, "bones", #pairsToDraw)
                    table.clear(projected)
                    local function projectedPart(name)
                        -- false = проверяли, но точка за камерой/вне экрана.
                        local hit = projected[name]
                        if hit ~= nil then return hit ~= false and hit or nil end
                        local body = item.parts[name]
                        if not body or body.Parent ~= char then
                            body = char:FindFirstChild(name)
                            item.parts[name] = body
                        end
                        if body and body:IsA("BasePart") then
                            local vec, visible = camera:WorldToViewportPoint(body.Position)
                            if visible and vec.Z > 0 then
                                local result = Vector2.new(vec.X, vec.Y)
                                projected[name] = result
                                return result
                            end
                        end
                        projected[name] = false
                        return nil
                    end
                    for idx, names in ipairs(pairsToDraw) do
                        local a, b = projectedPart(names[1]), projectedPart(names[2])
                        if a and b then
                            setLine(item.bones[idx], a, b, state.espLineThickness, color)
                        else
                            setIfDifferent(item.bones[idx], "Visible", false)
                        end
                    end
                    -- R15 -> R6 / неполная модель: старые линии скрываем.
                    for idx = #pairsToDraw + 1, #item.bones do
                        setIfDifferent(item.bones[idx], "Visible", false)
                    end
                else
                    for _, line in ipairs(item.bones) do setIfDifferent(line, "Visible", false) end
                end
            else
                -- Не оставляем «замороженную» рамку в старой позиции.
                hideShape(item)
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
    mk("Frame", {Name = "SectionAccent", BackgroundColor3 = P.accent,
        BorderSizePixel = 0, Position = UDim2.fromOffset(4, 7),
        Size = UDim2.fromOffset(2, 12)}, container)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -16, 0, 18),
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
        Name = key, Size = UDim2.new(1, 0, 0, 55),
        BackgroundColor3 = P.tile, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "",
    }, columnFor(page))
    registerWidget(page, row)
    round(row, 6)
    mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 5), Size = UDim2.new(1, -72, 0, 21),
        Text = title, TextSize = 12, Font = Enum.Font.GothamMedium,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 31), Size = UDim2.new(1, -72, 0, 15),
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
    safeActivate(row, function()
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
        Size = UDim2.new(1, 0, 0, 55),
        Text = "", AutoButtonColor = true, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, button)
    round(button, 6)
    mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 5), Size = UDim2.new(1, -39, 0, 21),
        Text = text, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 32), Size = UDim2.new(1, -39, 0, 15),
        Text = description, Font = Enum.Font.Gotham, TextSize = 9,
        TextColor3 = P.dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -31, 0.5, -10),
        Size = UDim2.fromOffset(20, 20), Text = "›", Font = Enum.Font.GothamBold,
        TextSize = 19, TextColor3 = P.accent,
    }, button)
    safeActivate(button, function()
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
        Name = key .. "Slider", Size = UDim2.new(1, 0, 0, 74),
        BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, container)
    round(container, 7)
    mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, container)
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
        Position = UDim2.fromOffset(10, 44), Size = UDim2.new(1, -20, 0, 25),
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
        if (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch)
            and not sliderDrag then
            local touch = kind == Enum.UserInputType.Touch
            sliderDrag = {touch = touch, input = input, update = setFromX,
                origin = input.Position, active = not touch, cancelled = false}
            if not touch then setFromX(input.Position.X) end
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
    round(container, 7)
    mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, container)
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
        safeActivate(button, function()
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
    round(container, 7)
    mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, container)
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
    safeActivate(keybindButton, function()
        if not alive then return end
        captureAimKey = not captureAimKey
        repaint()
    end)
    safeActivate(clear, function()
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
    round(row, 7)
    mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, row)
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
        safeActivate(button, function()
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
addSection(pages.AIM, "RECOIL CONTROL", "Компенсация вертикальной отдачи при стрельбе")
addToggle(pages.AIM, "Control Recoil", "Работает при выстрелах из экипированного Tool", "controlRecoil", function()
    recoil.reset()
end)
addSlider(pages.AIM, "Сила Control Recoil", "0–100%; увеличивай постепенно", "recoilStrength",
    0, 100, 5, function(value) return tostring(value) .. "%" end)
addButton(pages.AIM, "Проверить Control Recoil", "Показать обнаруженное оружие и количество активаций", function()
    local weapon, shots = recoil.inspect()
    tell("Recoil | Tool: " .. tostring(weapon) .. " | Shots: " .. tostring(shots))
end)
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

addSection(pages.MISC, "AIR MOTION WATCH", "Подозрительное перемещение — не определение модераторов")
addToggle(pages.MISC, "Оповещения о полёте", "6+ секунд стабильного движения в воздухе", "airAlerts", function(on)
    if not on and boosterPro.airMonitor then boosterPro.airMonitor.clear() end
end)
addButton(pages.MISC, "Нагрузка Air Watch", "Игроки / замеры / лучи / время прохода", function()
    local mon = boosterPro.airMonitor
    if mon and mon.diagnostics then tell(mon.diagnostics()) end
end)
addSection(pages.MISC, "SESSION DIAGNOSTICS", "Клиентские события, без обхода античита")
perfCounters.session.label = mk("TextLabel", {
    Name = "ClientSessionDiagnostics", BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38),
    Text = "Logs N/A | Warn 0 | Err 0 | Keywords 0",
    TextColor3 = CONFIG.Muted, Font = Enum.Font.Code,
    TextSize = 10, TextWrapped = true,
}, columnFor(pages.MISC))
registerWidget(pages.MISC, perfCounters.session.label)
round(perfCounters.session.label, 6)
addButton(pages.MISC, "Проверка клиентских предупреждений",
    "Не видит серверный античит и не определяет риск бана", function()
    tell(perfCounters.session.summary() .. " | Совпадения не доказывают наличие античита")
end)
addButton(pages.MISC, "Safety Stop — завершить Hub",
    "Выключить модули и сохранить рискованные функции в состоянии OFF", function()
    tell("Safety Stop: выключаем Hub и сохраняем рискованные функции OFF")
    if cleanup then cleanup(true) end
end)
addSection(pages.MISC, "UTILITY", "Настройки клиента и графика")
addToggle(pages.MISC, "AntiAFK", "VirtualUser при событии Idled", "antiAfk", function(on)
    if not on then releaseAntiAfk() end
end)
addToggle(pages.MISC, "FPS Booster Pro", "Графика в 3 режимах, с откатом", "booster", setBooster)
-- FPS Guard does not claim a performance gain: when the measured FPS stays
-- noticeably worse than the pre-Booster baseline, it disables and rolls back.
-- This is only available after at least three actual pre-Booster samples.
boosterPro.autoRollback = function()
    if not alive or not state.booster then return end
    local baseline = boosterPro.baseline
    local avg = boosterPro.after
    if type(baseline) ~= "number" or baseline < 35 or
        type(avg) ~= "number" or #boosterPro.afterFPS < 4 then return end
    local now = os.clock()
    -- В том числе ДО окончания перекраски, если карта очень большая.
    local guardReady = boosterPro.complete and boosterPro.readyAt
        or (boosterPro.startedAt and boosterPro.startedAt + 8)
    if not guardReady or now < guardReady + (boosterPro.complete and 4 or 0) then return end
    -- Prevent several checks within the same measurement second.
    if now - boosterPro.guardLastCheck < 0.8 then return end
    boosterPro.guardLastCheck = now
    local bad = avg <= baseline * 0.70 and baseline - avg >= 12
    if not bad then
        boosterPro.guardLowSince = nil
        return
    end
    if not boosterPro.guardLowSince then boosterPro.guardLowSince = now; return end
    if now - boosterPro.guardLowSince < 12 then return end
    state.booster = false
    setBooster(false)
    if refreshToggles.booster then pcall(refreshToggles.booster) end
    requestSave()
    tell("FPS Guard: Booster выключен — FPS упал с " .. tostring(baseline)
        .. " до " .. tostring(avg) .. ". Возвращаем графику.")
end
addSection(pages.MISC, "GRAPHICS QUALITY", "Выбери степень оптимизации")
boosterPro.repaint = addChoice(pages.MISC, "Режим графики", {
    {value = "BALANCED", label = "BALANCED"},
    {value = "WHITE", label = "WHITE MAP"},
    {value = "ULTRA", label = "ULTRA LOW"},
}, "boosterMode", function(mode)
    if state.booster then setBooster(true, true) end
end)
boosterPro.label = mk("TextLabel", {
    Name = "BoosterProFPSComparison", BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 44),
    TextWrapped = true, Text = "До: н/д FPS | После: н/д",
    TextSize = 10, TextColor3 = Color3.fromRGB(221, 225, 227),
    Font = Enum.Font.Code,
}, columnFor(pages.MISC))
registerWidget(pages.MISC, boosterPro.label)
round(boosterPro.label, 6)
addButton(pages.MISC, "Сравнение FPS", "Нужны реальные замеры до и после включения", function()
    tell("Booster Pro [" .. state.boosterMode .. "]: " .. boosterPro.readout()
        .. " | Проверено: " .. tostring(boosterPro.scanned)
        .. " | Очередь: " .. tostring(boosterPro.queueCount)
        .. " | Пропущено: " .. tostring(boosterPro.queueDropped))
end)
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
addSection(pages.MISC, "CAMERA FOV", "Угол обзора, не радиус AIM")
addToggle(pages.MISC, "Camera FOV", "Переопределить вертикальный угол обзора", "cameraFovEnabled", function()
    memoryFX.camera.apply()
end)
addSlider(pages.MISC, "Угол камеры", "55–110°, стандартное значение игры вернётся при OFF",
    "cameraFovDegrees", 55, 110, 1,
    function(value) return tostring(value) .. "°" end,
    function() memoryFX.camera.apply() end)
addButton(pages.MISC, "Вернуть FOV камеры", "Отключить настройку и вернуть исходный угол", function()
    state.cameraFovEnabled = false
    memoryFX.camera.reset()
    if refreshToggles.cameraFovEnabled then refreshToggles.cameraFovEnabled() end
    requestSave()
    tell("Camera FOV: исходный угол восстановлен")
end)
addSection(pages.MISC, "ANTI-AIM", "Локальное вращение тела; реальная репликация не гарантируется")
addToggle(pages.MISC, "Anti-Aim Spin", "Быстрая крутилка + наклон корпуса", "antiAim", function(enabled)
    if not enabled then memoryFX.spin.reset() end
end)
addSlider(pages.MISC, "Скорость вращения", "180–1440°/сек. При активном AIM вращение останавливается",
    "antiAimSpeed", 180, 1440, 60,
    function(value) return tostring(value) .. " °/s" end)
addSlider(pages.MISC, "Наклон тела", "0–25°, поддержка классических ригов R6/R15",
    "antiAimTilt", 0, 25, 1,
    function(value) return tostring(value) .. "°" end)
addButton(pages.MISC, "Сбросить Anti-Aim", "Выключить вращение и восстановить AutoRotate/C0", function()
    state.antiAim = false
    memoryFX.spin.reset()
    if refreshToggles.antiAim then refreshToggles.antiAim() end
    requestSave()
    tell("Anti-Aim: отключён, исходная анимация восстановлена")
end)
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
boosterPro.floatingButton = mini
-- v1.1.3: предупреждение о рискованных функциях после сворачивания.
-- Это информирование пользователя, НЕ обход античита и НЕ защита от бана.
-- Локальный scope не увеличивает количество локальных переменных главного chunk.
do
    local warning = {visible = false, serial = 0, unlockAt = 0}
    boosterPro.riskWarning = warning
    local function clockNow()
        if type(time) == "function" then return time() end
        return os.clock()
    end
    local function risksEnabled()
        local risks = {}
        if state.aimbot then
            if state.aimMode == "head" then
                table.insert(risks, "AIM: наведение на голову")
            elseif state.aimSmoothness <= 2 then
                table.insert(risks, "AIM: высокая скорость")
            elseif not state.visibleCheck then
                table.insert(risks, "AIM: без проверки видимости")
            elseif state.aimFovPixels >= 300 then
                table.insert(risks, "AIM: большой FOV")
            else
                table.insert(risks, "Aimbot")
            end
        end
        if state.antiAim then table.insert(risks, "Anti-Aim Spin") end
        if state.controlRecoil then table.insert(risks, "Control Recoil") end
        if state.esp then table.insert(risks, "ESP / Visuals") end
        if state.fullbright then table.insert(risks, "FullBright") end
        if state.antiAfk then table.insert(risks, "AntiAFK") end
        return risks
    end
    -- v1.1.4: выдержанный интерфейс вместо типовой яркой карточки.
    -- Один прокручиваемый текстовый блок и две крупные кнопки: на узких экранах
    -- всё содержимое остаётся доступным без уменьшения шрифта до нечитаемого.
    local veil = mk("Frame", {
        Name = "RiskWarningOverlay", Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = Color3.fromRGB(7, 8, 11),
        BackgroundTransparency = 0.23, BorderSizePixel = 0,
        Active = true, Visible = false, ZIndex = 200,
    }, gui)
    local shadow = mk("Frame", {
        Name = "RiskWarningShadow", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 5),
        Size = UDim2.fromScale(0.91, 0.87),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.52, BorderSizePixel = 0,
        ZIndex = 201,
    }, veil)
    mk("UISizeConstraint", {MaxSize = Vector2.new(426, 338)}, shadow)
    round(shadow, 8)
    local card = mk("Frame", {
        Name = "RiskWarningCard", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.91, 0.87),
        BackgroundColor3 = Color3.fromRGB(22, 23, 27), BorderSizePixel = 0,
        Active = true, ZIndex = 202,
    }, veil)
    mk("UISizeConstraint", {MaxSize = Vector2.new(426, 338)}, card)
    round(card, 8)
    mk("UIStroke", {Color = Color3.fromRGB(77, 75, 79), Thickness = 1,
        Transparency = 0.06}, card)

    -- Короткая служебная шапка: минимум декора, чёткая иерархия текста.
    mk("Frame", {
        Name = "RiskAccent", Position = UDim2.fromOffset(0, 12),
        Size = UDim2.fromOffset(3, 47), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(214, 160, 86), ZIndex = 203,
    }, card)
    mk("TextLabel", {
        Name = "RiskWarningOverline", Position = UDim2.fromOffset(20, 10),
        Size = UDim2.new(1, -40, 0, 16), BackgroundTransparency = 1,
        Text = "124 COMMUNITY  /  SESSION", Font = Enum.Font.Code,
        TextSize = 10, TextColor3 = Color3.fromRGB(148, 146, 149),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203,
    }, card)
    mk("TextLabel", {
        Name = "RiskWarningTitle", Position = UDim2.fromOffset(20, 29),
        Size = UDim2.new(1, -40, 0, 28), BackgroundTransparency = 1,
        Text = "⚠  ВНИМАНИЕ", Font = Enum.Font.GothamBold,
        TextSize = 17, TextColor3 = Color3.fromRGB(239, 197, 126),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203,
    }, card)
    mk("Frame", {
        Name = "RiskWarningRuleTop", Position = UDim2.fromOffset(20, 66),
        Size = UDim2.new(1, -40, 0, 1), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(61, 60, 65), ZIndex = 203,
    }, card)

    -- Прокрутка только текста. Действия всегда видны, даже при многих рисках.
    local scroll = mk("ScrollingFrame", {
        Name = "RiskWarningScroll", Position = UDim2.fromOffset(20, 77),
        Size = UDim2.new(1, -40, 1, -199), BorderSizePixel = 0,
        BackgroundTransparency = 1, ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(119, 100, 91),
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 203,
    }, card)
    mk("UIListLayout", {Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
    mk("UIPadding", {PaddingRight = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 5)}, scroll)
    mk("TextLabel", {
        Name = "RiskWarningMessage", LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = "Внимание, вы включили функции, которые могут вызвать " ..
            "подозрения у модерации или античита и привести " ..
            "к блокировке аккаунта в этом режиме.",
        TextColor3 = Color3.fromRGB(221, 219, 222),
        Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 204,
    }, scroll)
    mk("TextLabel", {
        Name = "RiskWarningFeaturesHeader", LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = "АКТИВНЫЕ ФУНКЦИИ", Font = Enum.Font.Code,
        TextSize = 10, TextColor3 = Color3.fromRGB(159, 154, 154),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 204,
    }, scroll)
    local risksText = mk("TextLabel", {
        Name = "RiskWarningFeatures", LayoutOrder = 3,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamMedium,
        TextSize = 12, TextWrapped = true,
        TextColor3 = Color3.fromRGB(233, 191, 135),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 204,
    }, scroll)
    mk("Frame", {
        Name = "RiskWarningRuleBottom", Position = UDim2.new(0, 20, 1, -112),
        Size = UDim2.new(1, -40, 0, 1), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(61, 60, 65), ZIndex = 203,
    }, card)
    local stopButton = mk("TextButton", {
        Name = "RiskWarningDisable", Position = UDim2.new(0, 20, 1, -101),
        Size = UDim2.new(1, -40, 0, 42), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(145, 58, 66),
        Text = "ОТКЛЮЧИТЬ ЭТИ ФУНКЦИИ",
        TextColor3 = Color3.fromRGB(255, 247, 246),
        Font = Enum.Font.GothamBold, TextSize = 12,
        AutoButtonColor = true, ZIndex = 204,
    }, card)
    round(stopButton, 5)
    mk("UIStroke", {Color = Color3.fromRGB(175, 74, 81), Thickness = 1,
        Transparency = 0.18}, stopButton)
    local dismissButton = mk("TextButton", {
        Name = "RiskWarningDismiss", Position = UDim2.new(0, 20, 1, -49),
        Size = UDim2.new(1, -40, 0, 32), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(35, 36, 41),
        Text = "ЗАКРЫТЬ ЧЕРЕЗ 5 С",
        TextColor3 = Color3.fromRGB(166, 165, 171),
        Font = Enum.Font.GothamMedium, TextSize = 11,
        AutoButtonColor = false, ZIndex = 204,
    }, card)
    round(dismissButton, 5)
    mk("UIStroke", {Color = Color3.fromRGB(69, 68, 74), Thickness = 1}, dismissButton)
    local function repaintClose()
        local remaining = math.max(0, math.ceil(warning.unlockAt - clockNow()))
        dismissButton.Text = remaining > 0
            and ("ЗАКРЫТЬ ЧЕРЕЗ " .. tostring(remaining) .. " С") or "ЗАКРЫТЬ"
        dismissButton.TextColor3 = remaining > 0 and Color3.fromRGB(166, 165, 171)
            or Color3.fromRGB(234, 225, 218)
        dismissButton.BackgroundColor3 = remaining > 0
            and Color3.fromRGB(35, 36, 41) or Color3.fromRGB(48, 46, 50)
        return remaining
    end
    function warning.show()
        -- Only once per script execution; later menu collapses stay uninterrupted.
        if not alive or warning.visible or warning.shownOnce then return end
        local risks = risksEnabled()
        if #risks == 0 then return end
        warning.shownOnce = true
        warning.serial = warning.serial + 1
        local serial = warning.serial
        warning.unlockAt = clockNow() + 5
        warning.visible = true
        risksText.Text = "•  " .. table.concat(risks, "\n•  ")
        scroll.CanvasPosition = Vector2.new(0, 0)
        stopButton.Text = "ОТКЛЮЧИТЬ ЭТИ ФУНКЦИИ"
        veil.Visible = true
        local function countdown()
            if not alive or not warning.visible or warning.serial ~= serial then return end
            if repaintClose() > 0 then task.delay(0.2, countdown) end
        end
        countdown()
    end
    connect(stopButton.Activated, function()
        if not alive or not warning.visible then return end
        -- Полное отключение именно активных боевых/визуальных модулей.
        setAimEnabled(false, false)
        state.controlRecoil = false
        state.antiAim = false
        state.esp = false
        state.tracers = false
        state.espBox = false
        state.espSkeleton = false
        state.fullbright = false
        state.antiAfk = false
        recoil.reset()
        memoryFX.spin.reset()
        releaseAntiAfk()
        pcall(applyLighting)
        pcall(refreshESP)
        pcall(clearTracers)
        pcall(syncEspVisuals)
        for _, update in pairs(refreshToggles) do pcall(update) end
        pcall(flushConfig)
        risksText.Text = "Рискованные функции отключены."
        stopButton.Text = "ФУНКЦИИ ОТКЛЮЧЕНЫ"
        repaintClose() -- Предупреждение остаётся ещё до истечения 5 секунд.
    end)
    connect(dismissButton.Activated, function()
        if not alive or not warning.visible then return end
        if clockNow() < warning.unlockAt then
            repaintClose()
            return
        end
        warning.visible = false
        warning.serial = warning.serial + 1
        veil.Visible = false
    end)
end
-- v1.1.6 Air Motion Reliability Fix. Пассивная эвристика: не утверждает, что пользователь
-- читер или модератор, не просматривает роли и не вмешивается в сетевые вызовы.
-- Короткие прыжки, падения, телепорты, транспорт и касание платформ отбрасываются.
do
    -- Cheap eligibility filtering across the WHOLE roster; bounded raycasts per scan.
    -- Retain observation priority while rotating fresh candidates; no fixed first-24 cut-off.
    local mon = {tracks = {}, lastAlert = {}, visible = false, serial = 0,
        activePlayer = nil, activeCharacter = nil, scanCursor = 1,
        triggered = 0, lastGlobal = -1e8, sampleInterval = 0.45, holdSeconds = 6.3,
        cooldownSeconds = 90, candidateLimit = 16, trackedPriority = 8,
        scanMs = 0, scanned = 0, eligible = 0, probes = 0, skipped = 0}
    boosterPro.airMonitor = mon
    local function now()
        if type(time) == "function" then return time() end
        return os.clock()
    end
    local alert = mk("Frame", {
        Name = "AirMotionAlert", AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -9, 0, 72),
        Size = UDim2.new(0.94, 0, 0, 175),
        BackgroundColor3 = Color3.fromRGB(22, 23, 28),
        BorderSizePixel = 0, Visible = false, ZIndex = 80,
    }, gui)
    mk("UISizeConstraint", {MaxSize = Vector2.new(356, 175)}, alert)
    round(alert, 7)
    mk("UIStroke", {Color = Color3.fromRGB(155, 114, 67), Thickness = 1,
        Transparency = 0.12}, alert)
    mk("Frame", {
        Name = "AirMotionAccent", Position = UDim2.fromOffset(0, 12),
        Size = UDim2.fromOffset(3, 37), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(216, 162, 85), ZIndex = 81,
    }, alert)
    mk("TextLabel", {
        Name = "AirMotionHeader", Position = UDim2.fromOffset(13, 8),
        Size = UDim2.new(1, -47, 0, 18), BackgroundTransparency = 1,
        Text = "⚠  НЕОБЫЧНОЕ ПЕРЕМЕЩЕНИЕ", Font = Enum.Font.GothamBold,
        TextSize = 11, TextColor3 = Color3.fromRGB(245, 196, 128),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 81,
    }, alert)
    local title = mk("TextLabel", {
        Name = "AirMotionPlayer", Position = UDim2.fromOffset(13, 28),
        Size = UDim2.new(1, -26, 0, 20), BackgroundTransparency = 1,
        Text = "", Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Color3.fromRGB(240, 237, 237),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 81,
    }, alert)
    mk("TextLabel", {
        Name = "AirMotionInfo", Position = UDim2.fromOffset(13, 53),
        Size = UDim2.new(1, -26, 0, 65), BackgroundTransparency = 1,
        Text = "Длительное движение высоко над землёй. Это НЕ доказывает статус модератора. Рекомендуем отключить AIM / RAGE.",
        Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true,
        TextColor3 = Color3.fromRGB(196, 193, 198),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 81,
    }, alert)
    local disable = mk("TextButton", {
        Name = "AirMotionDisable", Position = UDim2.new(0, 13, 1, -41),
        Size = UDim2.new(1, -62, 0, 30),
        BackgroundColor3 = Color3.fromRGB(105, 46, 52), BorderSizePixel = 0,
        Text = "ВЫКЛЮЧИТЬ AIM / SPIN / RECOIL", Font = Enum.Font.GothamBold,
        TextSize = 10, TextColor3 = Color3.fromRGB(246, 240, 240),
        AutoButtonColor = true, ZIndex = 81,
    }, alert)
    round(disable, 4)
    local dismiss = mk("TextButton", {
        Name = "AirMotionDismiss", Position = UDim2.new(1, -43, 1, -41),
        Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.fromRGB(45, 44, 48),
        BorderSizePixel = 0, Text = "×", Font = Enum.Font.GothamMedium,
        TextSize = 16, TextColor3 = Color3.fromRGB(235, 229, 225), ZIndex = 81,
    }, alert)
    round(dismiss, 4)
    function mon.hide()
        mon.visible = false
        mon.activePlayer, mon.activeCharacter = nil, nil
        mon.serial = mon.serial + 1 -- invalidate the pending 12-second callback
        alert.Visible = false
    end
    function mon.clear()
        table.clear(mon.tracks)
        mon.scanCursor = 1
        mon.hide()
    end
    function mon.diagnostics()
        return string.format("Air Watch | eligible %d | sampled %d | probes %d | deferred %d | scan %.2f ms",
            mon.eligible, mon.scanned, mon.probes, mon.skipped, mon.scanMs)
    end
    function mon.show(player)
        if not alive or not state.airAlerts or not player or player.Parent ~= Players
            or not player.Character or mon.visible then return end
        local t = now()
        if t - (mon.lastAlert[player] or -1e8) < mon.cooldownSeconds or t - mon.lastGlobal < 12 then return end
        mon.lastAlert[player] = t
        mon.lastGlobal = t
        mon.triggered = mon.triggered + 1
        mon.visible = true
        mon.activePlayer, mon.activeCharacter = player, player.Character
        mon.serial = mon.serial + 1
        local serial = mon.serial
        local name = tostring(player.DisplayName or player.Name or "Игрок")
        local account = tostring(player.Name or "?")
        title.Text = "Игрок " .. name .. " (@" .. account .. ")"
        disable.Text = "ВЫКЛЮЧИТЬ AIM / SPIN / RECOIL"
        alert.Visible = true
        task.delay(12, function()
            if alive and mon.visible and mon.serial == serial then
                mon.hide()
            end
        end)
    end
    local groundParams = RaycastParams.new()
    groundParams.FilterType = Enum.RaycastFilterType.Exclude
    local function rayDown(pos, ch, offset)
        local from = pos + offset
        groundParams.FilterDescendantsInstances = {ch}
        mon.probes = mon.probes + 1
        local ok, hit = pcall(function()
            return Workspace:Raycast(from, Vector3.new(0, -48, 0), groundParams)
        end)
        return ok and hit == nil -- inaccessible Raycast fails closed
    end
    local function canSample(player, myRoot)
        if player == LocalPlayer or player.Parent ~= Players then return nil end
        local ch = player.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local humanoid = ch and ch:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or (humanoid.Health or 0) <= 0
            or humanoid.Sit or humanoid.SeatPart or root.Anchored then return nil end
        local pos = root.Position
        if not pos or (pos - myRoot.Position).Magnitude > 380 then return nil end
        -- Отбрасываем заведомо обычные движения/транспорт.
        local okState, humState = pcall(function() return humanoid:GetState() end)
        if not okState then return nil end
        do
            local st = tostring(humState)
            if st:find("Seated", 1, true) or st:find("Climbing", 1, true)
                or st:find("Swimming", 1, true) or st:find("Dead", 1, true)
                or st:find("Jumping", 1, true) then return nil end
        end
        local floorOk, floor = pcall(function() return humanoid.FloorMaterial end)
        if not floorOk or floor ~= Enum.Material.Air then return nil end
        -- Не используем абсолютную Y-высоту. Неизвестная геометрия => нет тревоги.
        if not rayDown(pos, ch, Vector3.new(0, 0, 0)) then return nil end
        return ch, pos
    end
    function mon.observe(player, t, myRoot)
        if not alive or not state.airAlerts then return end
        local ch, pos = canSample(player, myRoot)
        if not ch then mon.tracks[player] = nil; return end
        local track = mon.tracks[player]
        if not track or track.character ~= ch or t - track.lastTime > 1.3 or t <= track.lastTime then
            mon.tracks[player] = {
                character = ch, lastPos = pos, lastTime = t,
                beginTime = t, origin = pos, distance = 0, samples = 1,
            }
            return
        end
        local dt = t - track.lastTime
        local dx, dy, dz = pos.X-track.lastPos.X, pos.Y-track.lastPos.Y, pos.Z-track.lastPos.Z
        local stepHorizontal = math.sqrt(dx*dx + dz*dz)
        local speed = stepHorizontal / dt
        local verticalSpeed = math.abs(dy) / dt
        -- Нельзя считать полётом одиночный телепорт, падение или рывок репликации.
        if speed < 10 or speed > 85 or verticalSpeed > 4.5
            or math.abs(pos.Y-track.origin.Y) > 7 then
            mon.tracks[player] = {
                character = ch, lastPos = pos, lastTime = t,
                beginTime = t, origin = pos, distance = 0, samples = 1,
            }
            return
        end
        track.distance = track.distance + stepHorizontal
        track.samples = track.samples + 1
        track.lastPos, track.lastTime = pos, t
        local elapsed = t - track.beginTime
        local ox, oz = pos.X-track.origin.X, pos.Z-track.origin.Z
        local displacement = math.sqrt(ox*ox + oz*oz)
        if elapsed >= mon.holdSeconds and track.samples >= 12
            and track.distance >= 75 and displacement >= 55 then
            -- Проверка опоры по трём точкам; отказ/попадание отменяет тревогу.
            -- Дополнительные лучи делаются только при готовом кандидате.
            if rayDown(pos, ch, Vector3.new(3, 0, 0))
                and rayDown(pos, ch, Vector3.new(0, 0, 3)) then
                mon.show(player)
            end
            mon.tracks[player] = nil
        end
    end
    function mon.scan()
        if not alive or not state.airAlerts then return end
        local started = os.clock()
        local myCh = LocalPlayer.Character
        local myRoot = myCh and myCh:FindFirstChild("HumanoidRootPart")
        if not myRoot then
            table.clear(mon.tracks)
            mon.eligible, mon.scanned, mon.probes, mon.skipped = 0, 0, 0, 0
            return
        end
        local t = now()
        mon.probes = 0
        local candidates = {}
        -- Фильтровать дешёво всех: дальние и незагруженные НЕ тратят бюджет.
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= LocalPlayer and other.Parent == Players then
                local ch = other.Character
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                if root and root.Position and (root.Position - myRoot.Position).Magnitude <= 380 then
                    candidates[#candidates+1] = other
                end
            end
        end
        mon.eligible = #candidates
        local selected, picked = {}, {}
        local budget = math.min(mon.candidateLimit, #candidates)
        -- Незавершённые подтверждения получают ограниченный приоритет, но
        -- не могут занять все слоты и навсегда вытеснить новых игроков.
        local active = {}
        for _, other in ipairs(candidates) do
            local tr = mon.tracks[other]
            if tr and t - tr.lastTime <= 1.3 then active[#active+1] = other end
        end
        table.sort(active, function(a,b)
            return mon.tracks[a].lastTime < mon.tracks[b].lastTime
        end)
        for i=1,math.min(#active, mon.trackedPriority, budget) do
            local other = active[i]
            selected[#selected+1], picked[other] = other, true
        end
        if #candidates > 0 then
            local cursor = ((mon.scanCursor-1) % #candidates)+1
            local considered = 0
            while #selected < budget and considered < #candidates do
                local other = candidates[cursor]
                if not picked[other] then
                    selected[#selected+1], picked[other] = other, true
                end
                cursor = cursor % #candidates + 1
                considered = considered + 1
            end
            mon.scanCursor = cursor
        else
            mon.scanCursor = 1
        end
        mon.scanned = #selected
        mon.skipped = #candidates - #selected
        for _, other in ipairs(selected) do mon.observe(other, t, myRoot) end
        for player,tr in pairs(mon.tracks) do
            if player.Parent ~= Players or player.Character ~= tr.character
                or t - tr.lastTime > 1.3 then mon.tracks[player] = nil end
        end
        -- Если наблюдаемый игрок сменил персонажа, не показывать устаревшую карточку.
        if mon.activePlayer and (mon.activePlayer.Parent ~= Players
            or mon.activePlayer.Character ~= mon.activeCharacter) then
            mon.hide()
        end
        mon.scanMs = (os.clock()-started)*1000
    end
    connect(Players.PlayerRemoving, function(player)
        mon.tracks[player] = nil
        mon.lastAlert[player] = nil
        if mon.activePlayer == player then mon.hide() end
    end)
    connect(disable.Activated, function()
        if not alive or not mon.visible then return end
        setAimEnabled(false, false)
        state.antiAim = false
        state.controlRecoil = false
        recoil.reset()
        memoryFX.spin.reset()
        for _, repaint in pairs(refreshToggles) do pcall(repaint) end
        requestSave()
        disable.Text = "ФУНКЦИИ ОТКЛЮЧЕНЫ"
    end)
    connect(dismiss.Activated, function()
        mon.hide()
    end)
    task.spawn(function()
        while alive do
            task.wait(mon.sampleInterval)
            if not alive then break end
            if state.airAlerts then
                local ok, err = pcall(mon.scan)
                if not ok then
                    -- Неполная информация: сбрасываем историю, не показываем ложную тревогу.
                    table.clear(mon.tracks)
                end
            elseif next(mon.tracks) ~= nil or mon.visible then
                mon.clear()
            end
        end
    end)
end

local miniMoving = false
connect(hide.Activated, function()
    captureAimKey = false
    repaintAimKeybind()
    tweenPanel(0.94)
    panel.Visible = false
    mini.Visible = true
    boosterPro.riskWarning.show()
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
        mini.Position = boosterPro.clampWindowPosition(UDim2.new(
            miniStartOrigin.X.Scale, miniStartOrigin.X.Offset + offset.X,
            miniStartOrigin.Y.Scale, miniStartOrigin.Y.Offset + offset.Y),
            mini.Size, mini.AnchorPoint)
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
            if panel.Visible then
                panelScale.Scale = 0.94; tweenPanel(1)
            else
                boosterPro.riskWarning.show()
            end
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
    panel.Position = boosterPro.clampWindowPosition(UDim2.new(
        panelOrigin.X.Scale, panelOrigin.X.Offset + delta.X,
        panelOrigin.Y.Scale, panelOrigin.Y.Offset + delta.Y
    ), panel.Size, panel.AnchorPoint)
end)

connect(UserInputService.InputChanged, function(input)
    if not sliderDrag then return end
    if sliderDrag.touch then
        if input ~= sliderDrag.input then return end
        local dx = input.Position.X - sliderDrag.origin.X
        local dy = input.Position.Y - sliderDrag.origin.Y
        if not sliderDrag.active then
            if math.abs(dy) >= 10 and math.abs(dy) > math.abs(dx) * 1.1 then
                sliderDrag.cancelled = true
                return
            end
            if math.abs(dx) >= 10 and math.abs(dx) >= math.abs(dy) * 1.2 then
                sliderDrag.active = true
            end
        end
        if sliderDrag.active and not sliderDrag.cancelled then
            sliderDrag.update(input.Position.X)
        end
    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
        sliderDrag.update(input.Position.X)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if not sliderDrag then return end
    if (sliderDrag.touch and input == sliderDrag.input)
        or (not sliderDrag.touch and input.UserInputType == Enum.UserInputType.MouseButton1) then
        if sliderDrag.touch and not sliderDrag.active and not sliderDrag.cancelled
            and allowTap(input) then
            sliderDrag.update(input.Position.X)
        end
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

-- StreamingEnabled can add hundreds of descendants in one frame. Do NOT spawn
-- a coroutine for every instance: a bounded FIFO lets the client keep rendering.
function boosterPro.queueObject(obj)
    if not alive or not state.booster or boosterPro.queuedSeen[obj] then return end
    -- Нерелевантные узлы не занимают память в очереди.
    if not graphicsProperty(obj) then return end
    if boosterPro.queueCount >= boosterPro.queueCap then
        boosterPro.queueDropped = boosterPro.queueDropped + 1
        return -- Не блокируем рендер при бурной подгрузке.
    end
    boosterPro.queueTail = boosterPro.queueTail % boosterPro.queueCap + 1
    boosterPro.queued[boosterPro.queueTail] = obj
    boosterPro.queuedSeen[obj] = true
    boosterPro.queueCount = boosterPro.queueCount + 1
end
connect(Workspace.DescendantAdded, function(obj)
    if not alive or not state.booster then return end
    -- A late avatar must not be recolored; restore already captured originals.
    local parent = obj.Parent
    if parent and parent:IsA("Model") and
        (obj:IsA("Humanoid") or obj.Name == "HumanoidRootPart"
            or obj.Name == "UpperTorso" or obj.Name == "Torso") and
        boosterPro.isProtected(obj) then
        boosterPro.restoreProtectedTree(parent)
        return
    end
    boosterPro.queueObject(obj)
end)
connect(Lighting.DescendantAdded, boosterPro.queueObject)
task.spawn(function()
    while alive do
        -- Во время первичного обхода не обрабатываем одни и те же детали дважды.
        if state.booster and boosterPro.complete and not boosterPro.repairing and boosterPro.queueCount > 0 then
            local revision = boosterRevision
            local sliceStarted = os.clock()
            local count = math.min(CONFIG.BoosterQueueBatch, boosterPro.queueCount)
            for i = 1, count do
                if not alive or not state.booster or revision ~= boosterRevision then break end
                local index = boosterPro.queueHead
                local obj = boosterPro.queued[index]
                boosterPro.queued[index] = nil
                boosterPro.queueHead = index % boosterPro.queueCap + 1
                boosterPro.queueCount = boosterPro.queueCount - 1
                if obj then
                    boosterPro.queuedSeen[obj] = nil
                    if not boosterPro.queuedProcessed[obj] and obj.Parent then
                        optimizeObject(obj)
                    end
                    boosterPro.queuedProcessed[obj] = nil
                end
                if i % 16 == 0 and
                    (os.clock() - sliceStarted) * 1000 >= CONFIG.BoosterQueueSliceMs then
                    break
                end
            end
        end
        -- Если StreamingEnabled переполнил кольцевую очередь,
        -- один фоновый повторный проход восстановит пропущенные детали.
        -- Проход ограничен тем же миллисекундным бюджетом; не бесконечный цикл.
        if state.booster and boosterPro.complete and boosterPro.queueCount == 0
            and boosterPro.queueDropped > 0 and not boosterPro.repaired
            and not boosterPro.repairing then
            boosterPro.repairing, boosterPro.repaired = true, true
            local repairRevision = boosterRevision
            task.spawn(function()
                local ok, result = pcall(function()
                    return optimizeHierarchy(Workspace, repairRevision)
                        and optimizeHierarchy(Lighting, repairRevision)
                end)
                boosterPro.repairing = false
                if alive and state.booster and repairRevision == boosterRevision then
                    if ok and result then
                        tell("Booster: восстановлена обработка пропущенных при подгрузке объектов")
                    else
                        warn("[124 Community Hub] Booster: повторная проверка подгрузки не завершена")
                    end
                end
            end)
        end
        task.wait(state.booster and boosterPro.complete and boosterPro.queueCount > 0 and 0 or 0.12)
    end
end)

for _, property in ipairs(lightingProperties) do
    connect(Lighting:GetPropertyChangedSignal(property), function()
        if state.fullbright or (property == "GlobalShadows" and state.booster) then
            enforceLightingProperty(property)
        end
    end)
end

cleanup = function(safeStop)
    if not alive then return end
    -- Только явный Safety Stop сохраняет безопасное состояние. Обычный Unload
    -- и hot-reload не изменяют выбранные пользователем настройки CUSTOM.
    if safeStop == true then
        state.aimbot = false
        state.antiAim = false
        state.controlRecoil = false
        state.esp = false
        state.tracers = false
        state.espBox = false
        state.espSkeleton = false
        state.fullbright = false
        state.antiAfk = false
        state.booster = false
        state.cameraFovEnabled = false
        -- Если запись файла запрещена, защита на следующем запуске
        -- в рамках той же сессии executor всё равно сработает.
        env.ARMY124_SAFE_BOOT = true
    end
    pcall(flushConfig) -- Safety Stop сохраняет уже выключенные переключатели.
    releaseAntiAfk()
    recoil.shutdown()
    memoryFX.spin.reset()
    state.cameraFovEnabled = false
    memoryFX.camera.reset()
    alive = false
    state.esp = false
    state.aimbot = false
    state.controlRecoil = false
    state.antiAim = false
    aimHeldKey = false
    captureAimKey = false
    state.antiAfk = false
    state.booster = false
    state.fullbright = false
    boosterRevision = boosterRevision + 1
    restoreTerrainGrass()
    restoreTerrainColors()
    if aimBound then
        pcall(function() RunService:UnbindFromRenderStep(aimBindingName) end)
    end
    if recoil.bound then
        pcall(function() RunService:UnbindFromRenderStep(recoil.bindingName) end)
    end
    if memoryFX.camera.bound then
        pcall(function() RunService:UnbindFromRenderStep(memoryFX.camera.bindingName) end)
        memoryFX.camera.bound = false
    end
    if perfCounters.espVisual.bound then
        pcall(function() RunService:UnbindFromRenderStep(perfCounters.espVisual.bindingName) end)
        perfCounters.espVisual.bound = false
    end
    pcall(applyLighting)
    -- Сначала пробуем восстановить и объекты. После этого собираем ВСЕ
    -- неудавшиеся снимки в один callback, переживающий hot-reexecute.
    for obj, saved in pairs(savedGraphics) do
        boosterPro.restoreObject(obj, saved)
    end
    if savedLighting or savedTerrainDecoration or savedTerrainColors
        or next(savedGraphics) ~= nil or next(memoryFX.camera.saved) ~= nil
        or next(memoryFX.spin.pending) ~= nil then
        local previousRecovery = env.ARMY124_RECOVERY
        local pendingRecovery
        pendingRecovery = function()
            local oldDone = true
            if type(previousRecovery) == "function" then
                local ok, result = pcall(previousRecovery)
                oldDone = ok and result == true
            end
            pcall(applyLighting)
            if savedTerrainDecoration then restoreTerrainGrass() end
            if savedTerrainColors then restoreTerrainColors() end
            for obj, snapshot in pairs(savedGraphics) do
                boosterPro.restoreObject(obj, snapshot)
            end
            memoryFX.camera.reset()
            memoryFX.spin.restorePending()
            local done = not (savedLighting or savedTerrainDecoration or savedTerrainColors)
                and next(savedGraphics) == nil
                and next(memoryFX.camera.saved) == nil
                and next(memoryFX.spin.pending) == nil
            if done and oldDone and env.ARMY124_RECOVERY == pendingRecovery then
                env.ARMY124_RECOVERY = nil
            end
            return done and oldDone
        end
        env.ARMY124_RECOVERY = pendingRecovery
        warn("[124 Community Hub] Откат графики/камеры/позы не завершён; данные сохранены для повтора")
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
-- LogService предоставляет только локально видимые сообщения.
-- Никаких перехватов Kick, RemoteEvent или попыток скрыть скрипт.
do
    local ok, result = pcall(function()
        local logs = game:GetService("LogService")
        return connect(logs.MessageOut, perfCounters.session.observe)
    end)
    perfCounters.session.listening = ok and result ~= nil
end
connect(close.Activated, function() if cleanup then cleanup() end end)
connect(Players.PlayerRemoving, deleteRender)

-- Camera FOV сразу после штатной камеры и ДО AIM/Recoil/ESP,
-- чтобы все проекции одного кадра использовали одинаковый угол.
memoryFX.camera.bound = pcall(function()
    RunService:BindToRenderStep(memoryFX.camera.bindingName,
        Enum.RenderPriority.Camera.Value + 1, memoryFX.camera.apply)
end)
if not memoryFX.camera.bound then
    connect(RunService.RenderStepped, memoryFX.camera.apply)
end
-- Simulation clock rather than render loop: separates body rotation from camera ESP.
if RunService.PreSimulation then
    connect(RunService.PreSimulation, memoryFX.spin.frame)
else
    connect(RunService.Heartbeat, memoryFX.spin.frame)
end

local okBind, errBind = pcall(function()
    RunService:BindToRenderStep(aimBindingName, Enum.RenderPriority.Camera.Value + 2, aimFrame)
end)
if okBind then
    aimBound = true
else
    tell("BindToRenderStep недоступен; используем RenderStepped")
    connect(RunService.RenderStepped, aimFrame)
end

local okRecoilBind, errRecoilBind = pcall(function()
    RunService:BindToRenderStep(recoil.bindingName, Enum.RenderPriority.Camera.Value + 3, recoil.frame)
end)
if okRecoilBind then
    recoil.bound = true
else
    tell("Recoil: BindToRenderStep недоступен — " .. tostring(errRecoilBind))
    connect(RunService.RenderStepped, recoil.frame)
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

-- Smooth ESP v1.0.5: экранные рамки/кости/линии обновляются синхронно с
-- камерой (без интервала 0.08–0.25 с). Частота равна реальным кадрам игры;
-- новых игроков по-прежнему отбирает медленный refreshESP(), не рендер-цикл.
local espVisualElapsed = 0
perfCounters.espVisual.frame = function(dt)
    if not alive or not state.esp then espVisualElapsed = 0; return end
    if not state.tracers and not state.espBox and not state.espSkeleton then
        espVisualElapsed = 0
        return
    end
    -- AIM/Recoil идут каждый кадр. Только тяжёлые ESP GUI-примитивы
    -- обновляем с отдельным пределом кадров при AUTO/ECO.
    if type(dt) == "number" and dt > 0 then
        local hz = perfTier() == "ECO" and CONFIG.EspVisualEcoHz
            or perfTier() == "QUALITY" and 120 or CONFIG.EspVisualBalancedHz
        espVisualElapsed = espVisualElapsed + math.min(dt, 0.12)
        if espVisualElapsed < 1 / hz then return end
        espVisualElapsed = 0
    end
    if state.tracers then
        local ok, err = pcall(refreshTracers)
        if not ok then
            local now = os.clock()
            if now - perfCounters.espVisual.errorAt >= 2 then
                warn("[124 Community Hub] ESP tracers draw: " .. tostring(err))
                perfCounters.espVisual.errorAt = now
            end
        end
    end
    if state.espBox or state.espSkeleton then
        local ok, err = pcall(refreshShapes)
        if not ok then
            local now = os.clock()
            if now - perfCounters.espVisual.errorAt >= 2 then
                warn("[124 Community Hub] ESP shapes draw: " .. tostring(err))
                perfCounters.espVisual.errorAt = now
            end
        end
    end
end
perfCounters.espVisual.bound = pcall(function()
    RunService:BindToRenderStep(perfCounters.espVisual.bindingName, Enum.RenderPriority.Camera.Value + 4, perfCounters.espVisual.frame)
end)
if not perfCounters.espVisual.bound then
    -- Fallback: exec без BindToRenderStep. Используем тот же RenderStepped,
    -- без task.wait(), чтобы не возвращать старые 4–12 FPS.
    connect(RunService.RenderStepped, perfCounters.espVisual.frame)
    tell("ESP: Camera bind unavailable; using RenderStepped")
end

local frames, accumulated = 0, 0
connect(RunService.RenderStepped, function(dt)
    if not alive then return end
    frames = frames + 1
    accumulated = accumulated + math.max(dt, 0)
    if accumulated >= 1 then
        measuredFps = math.floor(frames / math.max(accumulated, 0.01) + 0.5)
        boosterPro.measure(measuredFps)
        frames, accumulated = 0, 0
    end
end)

task.spawn(function()
    while alive do
        -- Отложенный откат после временного отказа записи API: до полной успешности
        -- не забываем исходные свойства. Не восстанавливаем Terrain при WHITE/ULTRA.
        if not state.fullbright and not state.booster
            and type(env.ARMY124_RECOVERY) == "function" then
            pcall(env.ARMY124_RECOVERY)
        end
        if state.fullbright or state.booster then
            for _, key in ipairs(lightingProperties) do enforceLightingProperty(key) end
        elseif savedLighting then
            applyLighting()
        end
        if not state.booster or state.boosterMode == "BALANCED" then
            if savedTerrainDecoration then restoreTerrainGrass() end
            if savedTerrainColors then restoreTerrainColors() end
        end
        stats.Visible = state.hud
        if boosterPro.label and boosterPro.label.Parent then
            boosterPro.label.Text = boosterPro.readout()
        end
        if perfCounters.session.label and perfCounters.session.label.Parent then
            local summary = perfCounters.session.summary()
            if summary ~= perfCounters.session.lastShown then
                perfCounters.session.label.Text = summary
                perfCounters.session.lastShown = summary
            end
        end
        perfLabel.Text = string.format("FPS %d | ESP %d | Shape %d | Scan %.1f ms | %s",
            measuredFps, perfCounters.espCount, perfCounters.shapeCount,
            perfCounters.aimScanMs, perfTier())
        activeInfo.Visible = state.activeHud
        if state.activeHud then
            local features = {}
            if state.esp then table.insert(features, "ESP") end
            if state.aimbot then table.insert(features, "AIM") end
            if state.controlRecoil then table.insert(features, "RECOIL") end
            if state.antiAim then table.insert(features, "SPIN") end
            if state.cameraFovEnabled then table.insert(features, "FOV") end
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
print("[124 Community Hub] " .. CONFIG.Version .. " загружен | MEMORY / SESSION DIAGNOSTICS")
