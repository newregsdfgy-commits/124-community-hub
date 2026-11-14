local state = {
    esp = false,
    names = true,
    health = true,
    distance = true,
    teamColors = true,
    tracers = false,
    espBox = false,
    espEnemyOnly = false,
    crosshairLocal = false, -- Сохраняемый локальный прицел.
    espRangeMeters = 200,
    espMaxTargets = CONFIG.EspMaxPlayers, -- Настраиваемая вместимость ESP, отдельно от метров.
    espColorPreset = "TEAM", -- TEAM / GOLD / GREEN / WHITE
    espLineThickness = 1, -- Новая тонкая графика по умолчанию.
    performanceMode = "AUTO", -- AUTO / ECO / QUALITY
    performanceGuard = false, -- Opt-in; only reduces ESP visuals, never AIM.
    moduleCpuMonitor = false, -- Opt-in instrumentation: no os.clock per module if OFF.
    lazyLoading = true, -- Deferred ESP ScreenGui: create only on first use.
    sessionDiagnostics = false, -- Анализ LogService только по запросу.
    activeHud = true,
    aimRangeMeters = 180,
    aimSmoothness = 3, -- 0 = мгновенно, 1 = быстро, 10 = максимально плавно.
    aimSmoothX = 5,
    aimSmoothY = 5,
    aimStability = 3, -- 1..5: время подтверждения смены цели и FOV grace.
    aimDeadzonePixels = 2, -- 0..12: без микродвижения возле центра.
    prediction = false,
    predictionSeconds = 0.08,
    targetLock = true,
    aimFovPixels = CONFIG.AimFovDefaultPixels,
    fovVisible = true,
    fovThickness = 2,
    visibleCheck = true, -- ON: только видимые, OFF: допускаются цели за стенами.
    fullbright = false,
    booster = false, -- По умолчанию без изменения карты.
    boosterMode = "BALANCED", -- Сохраняемый выбор режима; раньше nil ломал Booster.
    airAlerts = false, -- Фоновый мониторинг только по запросу.
    aimbot = false,
    controlRecoil = false, -- По умолчанию выключено: не трогаем камеру без согласия.
    noRecoil = false, -- Только локальная компенсация наблюдаемого подброса камеры.
    noSpread = false, -- Только явные клиентские настройки Tool; серверный spread не меняет.
    recoilStrength = 75, -- Процент подавления измеренного вертикального скачка.
    aimKeyName = CONFIG.AimKeyDefault,
    aimMode = "body", -- head / body / legs; сохраняем прежний режим по умолчанию.
    teamCheck = true,
    aimOnlyRegisteredWeapons = true, -- Без подтверждения оружия AIM не наводится.
    aimWeaponNames = "", -- Храним список точных имён через "|", без угадывания.
    antiAfk = false,
    cameraFovEnabled = false, -- Отдельный FOV камеры; не совпадает с пиксельным AIM FOV.
    cameraFovDegrees = 85, -- Вертикальный угол обзора камеры, 55..110 градусов.
    antiAim = false, -- Визуальная локальная крутилка; стартует только по нажатию.
    antiAimSpeed = 1080, -- Градусов в секунду; ограничение задаётся ползунком.
    antiAimTilt = 12, -- Визуальный наклон туловища в градусах.
    speedEnabled = false,
    speedValue = 32, -- WalkSpeed, стандарт игры сохраняется при активации.
    noclip = false,
    fly = false,
    flySpeed = 60, -- Скорость полёта в studs/сек.
    musicId = "", -- Локальный звук НЕ запускается автоматически при загрузке.
    musicVolume = 35,
    musicLoop = true,
    -- PLAYER: local-only graphics; toggles start OFF even after loading a profile.
    playerAuraEnabled = false,
    playerGlowEnabled = false,
    playerAuraColor = "PURPLE",
    playerGlowPower = 3,
    playerAuraQuality = "AUTO", -- AUTO / ECO / ULTRA, adapt to actual local FPS.
    playerGlowPulse = true, -- Animation is inactive until Aura or Glow is enabled.
    playerWeatherEnabled = false,
    playerWeatherMode = "CLEAR",
    playerEnvironmentEnabled = false,
    playerEnvironmentColor = "VIOLET",
    playerEnvironmentStrength = 40,
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
    queueDropped = 0, scanned = 0, repairing = false,
    repairCoveredDrops = 0, repairRetryAt = 0, repairErrors = 0,
    queueLastAt = 0, slicePeakMs = 0, queuePeakMs = 0,
    changedProperties = 0, unverifiedWrites = 0, deniedWrites = 0,
    phase = "OFF", lastError = nil,
    -- Weak object keys track values actively written by Booster.
    graphicsWritten = setmetatable({}, {__mode = "k"}),
    -- Exact instances owned by Player FX; name-based protection is unsafe.
    playerFxOwned = setmetatable({}, {__mode = "k"}),
    recoveryFailures = 0, recoveryNextAt = 0,
    restoreRetryAt = 0, restoreRetryRunning = false,
    terrainRestoreRetryAt = 0, -- Backoff on inaccessible Terrain: no recurring 1s spikes.
    workers = {scan = 0, restore = 0, repair = 0, avatar = 0},
    lastRestoredAt = 0, lastRestoredComplete = nil,
    bootRoots = {}, -- Единственные ScreenGui, созданные данной копией Hub.
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
local refreshChoices = {}
local measuredFps = 60
local perfCounters = {espCount = 0, shapeCount = 0, aimScanMs = 0}
perfCounters.guard = {level = 0, low = 0, critical = 0, good = 0, changed = 0}
function perfCounters.guard.reset()
    local g = perfCounters.guard
    g.level, g.low, g.critical, g.good = 0, 0, 0, 0
    g.changed = os.clock()
end
function perfCounters.guard.update(fps, spikes)
    local g = perfCounters.guard
    if not state.performanceGuard then
        if g.level ~= 0 or g.low ~= 0 or g.critical ~= 0 or g.good ~= 0 then
            g.reset()
        end
        return
    end
    if type(fps) ~= "number" or fps <= 0 then return end
    -- Three sustained readings to step down; eight good readings to
    -- step UP. The guard is reversible and never modifies profile settings.
    -- Sustained 50ms+ frametime spikes matter even if average FPS looks fine.
    local stutters = type(spikes) == "number" and spikes or 0
    g.low = (fps < CONFIG.GuardLowFps or stutters >= 3) and g.low + 1 or 0
    g.critical = (fps < CONFIG.GuardCriticalFps or stutters >= 6)
        and g.critical + 1 or 0
    g.good = (fps >= CONFIG.GuardRecoveryFps and stutters == 0)
        and g.good + 1 or 0
    if os.clock() - g.changed < CONFIG.GuardMinStepSeconds then return end
    local nextLevel = g.level
    if g.level < 2 and g.critical >= CONFIG.GuardLowSamples then
        nextLevel = 2
    elseif g.level < 1 and g.low >= CONFIG.GuardLowSamples then
        nextLevel = 1
    elseif g.level > 0 and g.good >= CONFIG.GuardRecoverSamples then
        nextLevel = g.level - 1
    end
    if nextLevel ~= g.level then
        g.level, g.changed = nextLevel, os.clock()
        g.low, g.critical, g.good = 0, 0, 0
    end
end
function perfCounters.guard.description()
    local g = perfCounters.guard
    return state.performanceGuard and ("Guard ON | Visual limit L" .. g.level)
        or "Guard OFF | manual performance mode"
end
-- Optional per-call wall-time instrumentation. No timers, tracing or
-- collections when disabled. Samples are not a whole-process CPU percentage.
perfCounters.cpu = {entries = {}, keys = {
    "AIM", "Recoil", "ESP Draw", "ESP Scan", "Booster Q", "HUD"},
    wrapped = {}, lastSummary = ""}
function perfCounters.cpu.reset()
    table.clear(perfCounters.cpu.entries)
end
function perfCounters.cpu.record(name, elapsedMs)
    local entries = perfCounters.cpu.entries
    local item = entries[name]
    if not item then
        item = {count = 0, total = 0, peak = 0}
        entries[name] = item
    end
    item.count = item.count + 1
    item.total = item.total + elapsedMs
    if elapsedMs > item.peak then item.peak = elapsedMs end
end
function perfCounters.cpu.instrument(name, fn)
    return function(...)
        if not state.moduleCpuMonitor then return fn(...) end
        local start = os.clock()
        local a,b,c = fn(...)
        perfCounters.cpu.record(name, (os.clock() - start) * 1000)
        return a,b,c
    end
end
function perfCounters.cpu.summary()
    if not state.moduleCpuMonitor then return "Module CPU OFF (enable to measure)" end
    local out = {}
    for _,name in ipairs(perfCounters.cpu.keys) do
        local sample = perfCounters.cpu.entries[name]
        if sample and sample.count > 0 then
            out[#out + 1] = string.format("%s %.3f/%.3f ms (%d)",
                name, sample.total/sample.count, sample.peak, sample.count)
        else
            out[#out + 1] = name .. " --"
        end
    end
    return table.concat(out, " | ")
end
-- Покадровый рендер ESP (после Camera/AIM/Recoil); НЕ сканируем игроков каждый кадр.
perfCounters.espVisual = {bound = false, bindingName = "Army124CommunityESP_" .. tostring(LocalPlayer.UserId),
    errorAt = 0, scanErrorAt = 0, active = {}, projected = {}, ordered = {}, candidatePool = {},
    eligible = 0, missing = 0, omitted = 0, lastScanAt = 0,
    localReady = false, renderFailures = 0, watcherFailures = 0,
    urgentEvents = 0, urgentScans = 0, urgentSkipped = 0, motionCamera = nil,
    motionFrame = nil, motionUntil = 0}
-- Логи отключены без подписки. Игровые события могут приходить сотнями/сек.
-- Подписка создаётся только после явного включения пользователем.
perfCounters.session = {
    messages = 0, warnings = 0, errors = 0, keywordHits = 0,
    listening = false, label = nil, lastShown = "", connection = nil,
    keywords = {"anti-cheat", "anticheat", "exploit detected",
        "suspicious activity", "kick", "ban", "античит", "нарушение"},
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
    for _, keyword in ipairs(record.keywords) do
        if string.find(lower, keyword, 1, true) then
            record.keywordHits = record.keywordHits + 1
            break
        end
    end
end
function perfCounters.session.summary()
    local r = perfCounters.session
    return string.format("Logs %s | Warn %d | Err %d | Keywords %d",
        r.listening and "ON" or "OFF", r.warnings, r.errors, r.keywordHits)
end
function perfCounters.session.setEnabled(enabled)
    local record = perfCounters.session
    if not enabled or not alive then
        if record.connection then
            pcall(function() record.connection:Disconnect() end)
            record.connection = nil
        end
        record.listening = false
        record.lastShown = ""
        return
    end
    if record.connection then return end
    local ok, connection = pcall(function()
        return game:GetService("LogService").MessageOut:Connect(record.observe)
    end)
    if ok and connection then
        record.connection = connection
        record.listening = true
    else
        record.listening = false
        state.sessionDiagnostics = false
        warn("[124 Community Visuals] Log diagnostics unavailable: " .. tostring(connection))
    end
    record.lastShown = ""
end

-- Fixed-size ring buffer for frametime. O(1) work, no allocations per frame.
-- Percentile/sort only when diagnostics are requested or Memory is visible.
perfCounters.frametime = {data = {}, cursor = 1, count = 0, scratch = {},
    lastUpdated = 0, label = nil, lastShown = "", spikesThisSecond = 0}
function perfCounters.frametime.observe(dt)
    if type(dt) ~= "number" or dt <= 0 or dt ~= dt then return end
    local ft = perfCounters.frametime
    -- Показываем даже долгие зависания, не теряя >2 с. 10-секундный
    -- потолок защищает расчёты от Inf/экстремальных значений.
    ft.data[ft.cursor] = math.min(dt * 1000, 10000)
    if state.performanceGuard and dt * 1000 >= CONFIG.FrameTimeSpikeMs then
        ft.spikesThisSecond = ft.spikesThisSecond + 1
    end
    ft.cursor = ft.cursor % CONFIG.FrameTimeWindow + 1
    ft.count = math.min(ft.count + 1, CONFIG.FrameTimeWindow)
end
function perfCounters.frametime.summary()
    local ft = perfCounters.frametime
    if ft.count < 60 then return "Frame Time: собираем минимум 60 кадров" end
    local ordered = ft.scratch
    table.clear(ordered)
    local worst, spikes = 0, 0
    for i = 1, ft.count do
        local ms = ft.data[i]
        ordered[i] = ms
        if ms > worst then worst = ms end
        if ms >= CONFIG.FrameTimeSpikeMs then spikes = spikes + 1 end
    end
    table.sort(ordered)
    local p99ms = ordered[math.max(1, math.ceil(ft.count * 0.99))]
    -- 1% low: обратное среднему времени худших 1% кадров в окне,
    -- а не обратное одному p99-кадру.
    local worstCount = math.max(1, math.ceil(ft.count * 0.01))
    local worstSum = 0
    for i = ft.count - worstCount + 1, ft.count do
        worstSum = worstSum + ordered[i]
    end
    local low = math.floor(1000 / math.max(worstSum / worstCount, 0.01) + 0.5)
    return string.format("1%% Low %d FPS | p99 %.0f ms | Max %.0f ms | 50ms+ %d/%d",
        low, p99ms, worst, spikes, ft.count)
end
local shapeGui, activeInfo
local defaultSettings = nil
local profileName = "CUSTOM"
local clearTracers = function() end
local syncEspVisuals = function() end -- Переопределяется после создания ESP GUI.
local flushConfig = function() end
local releaseAntiAfk = function() end
local stopESPWatchers = function() end
local syncESPWatchers = function() end
local emergencyUIRollback = function() return true end
local refreshSliders = {}
local repaintAimMode = function() end
local repaintColors = function() end
local repaintPerf = function() end

local requestSave = function() end
local lightingApplying = false
local aimTarget = nil
local aimNextScan = 0
-- Общий кеш экипированного Tool; Recoil уже отслеживает ChildAdded/ChildRemoved.
local aimPro = {
    equipped = nil,
    nextLos = 0,
    blockedSince = 0,
    lostSince = 0, switchCandidate = nil, switchSince = 0,
    leadPart = nil, leadPoint = nil,
    lastCamera = nil, lastLocalCharacter = nil,
    rayParams = RaycastParams.new(),
    rayIgnore = {},
    candidates = {},
    allowedNames = {}, allowedNamesSource = nil,
    changed = function() end,
}
aimPro.rayParams.FilterType = Enum.RaycastFilterType.Exclude
aimPro.rayParams.IgnoreWater = true
function aimPro.reset()
    aimTarget = nil
    aimNextScan = 0
    aimPro.nextLos = 0
    aimPro.blockedSince = 0
    aimPro.lostSince = 0
    aimPro.switchCandidate = nil
    aimPro.switchSince = 0
    aimPro.leadPart = nil
    aimPro.leadPoint = nil
end
function aimPro.equippedTool()
    local tool = aimPro.equipped
    local character = LocalPlayer.Character
    if not character or not character.Parent or not tool or tool.Parent ~= character then
        return nil
    end
    if state.aimOnlyRegisteredWeapons then
        local names = state.aimWeaponNames or ""
        if aimPro.allowedNamesSource ~= names then
            local set = {}
            for name in string.gmatch(names, "[^|]+") do
                set[name] = true
            end
            aimPro.allowedNames = set
            aimPro.allowedNamesSource = names
        end
        if not aimPro.allowedNames[tool.Name] then return nil end
    end
    return tool
end
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
    CONFIG.PlaceCache.aimKey = name
    -- Совместимость со старым конфигом сохраняем только в исходной игре.
    if game.PlaceId == CONFIG.OriginalPlaceId then env.ARMY124_AIM_KEY = name end
    if type(writefile) == "function" then
        pcall(writefile, CONFIG.AimKeyFile, name)
    end
end

local function restoreAimKey()
    local stored = CONFIG.PlaceCache.aimKey
    if stored == nil and game.PlaceId == CONFIG.OriginalPlaceId then
        stored = env.ARMY124_AIM_KEY
    end
    if type(readfile) == "function" then
        local ok, fileValue = pcall(readfile, CONFIG.AimKeyFile)
        if ok and validAimKeyName(fileValue) then stored = fileValue end
    end
    if validAimKeyName(stored) then state.aimKeyName = stored end
end
restoreAimKey()

local function connect(signal, fn)
    -- Старый UI/модуль после hot reload не должен создавать новые подписки.
    if not alive or env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then
        error("124 Visuals: stale signal registration", 2)
    end
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

-- Единый roster без выделения массива на каждом AIM/ESP скане.
-- Удаление через swap-with-last сохраняет плотность массива.
perfCounters.roster = Players:GetPlayers()
perfCounters.rosterIndex = {}
for index, player in ipairs(perfCounters.roster) do
    perfCounters.rosterIndex[player] = index
end
connect(Players.PlayerAdded, function(player)
    if perfCounters.rosterIndex[player] then return end
    local index = #perfCounters.roster + 1
    perfCounters.roster[index] = player
    perfCounters.rosterIndex[player] = index
end)
connect(Players.PlayerRemoving, function(player)
    local roster, indices = perfCounters.roster, perfCounters.rosterIndex
    local index = indices[player]
    if not index then return end
    local last = roster[#roster]
    roster[index] = last
    roster[#roster] = nil
    indices[player] = nil
    if last and last ~= player then indices[last] = index end
end)

local function mk(class, properties, parent)
    -- Предотвращает создание UI старой корутиной после нового запуска.
    if not alive or env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then
        error("124 Visuals: stale GUI construction", 2)
    end
    local instance = Instance.new(class)
    -- Transactional construction: a failed property or Parent assignment
    -- must not leave an untracked, half-initialized Instance in memory.
    local ok, err = pcall(function()
        for key, value in pairs(properties or {}) do instance[key] = value end
        instance.Parent = parent
    end)
    if not ok then
        pcall(function() instance:Destroy() end)
        error(err, 2)
    end
    if class == "ScreenGui" and parent == PlayerGui then
        local roots = boosterPro.bootRoots
        roots[#roots + 1] = instance
    end
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
    print("[124 Community Visuals] " .. message)
end

