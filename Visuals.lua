-- 124 Community Visuals v1.1.26 | booster recovery, safe frame pacing and full source audit
-- PlaceId: 18537079992
-- Локальный Luau-скрипт: ESP, Aim (голова/тело/ноги), Misc, FPS/Ping/часы.
-- Все изменяющие параметры функции выключены по умолчанию.
-- При повторном запуске старая копия очищается и настройки сцены восстанавливаются.

local CONFIG = {
    Version = "1.1.26",
    PlaceId = 18537079992,
    EspRefreshSeconds = 0.75, -- Лёгкое обновление списка игроков; FPS на первом месте.
    EspMaxPlayers = 12, -- Меньше Highlight и GUI-обновлений по умолчанию.
    StudMeters = 0.28, -- Стандартный масштаб Roblox: 1 stud ≈ 0.28 м.
    ConfigFile = "124_community_settings_v09.json",
    MenuKey = Enum.KeyCode.RightShift,
    EspFillTransparency = 0.88, -- Менее заметная подсветка.
    EspOutlineTransparency = 0.38, -- Встроенный Highlight не имеет толщины в px.
    EspNameSizeNear = 10,
    EspNameSizeMid = 9,
    EspNameSizeFar = 8,
    EspMetaSizeNear = 9, -- HP и дистанция, независимые TextLabel.
    EspMetaSizeFar = 8,
    EspMidDistanceMeters = 80,
    EspFarDistanceMeters = 150,
    EspLabelWidth = 148,
    EspLabelHeight = 27,
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
    AimScanInterval = 0.12, -- Таймер действует и при отсутствии целей.
    AimLostRescanSeconds = 0.06,
    AimLosBalancedSeconds = 0.045,
    AimLosEcoSeconds = 0.075,
    AimLosQualitySeconds = 0.02,
    RecoilShotGraceSeconds = 0.20, -- Поздний откат камеры после отпускания спуска.
    RecoilFireWindowSeconds = 0.40, -- Короткий выстрел (в т.ч. на телефоне).
    RecoilMaxHoldSeconds = 3.50, -- Предохранитель, если Tool.Deactivated не пришло.
    RecoilMaxFrameSeconds = 0.16, -- Не компенсируем скачок камеры после лагов.
    RecoilMinPitchDegrees = 0.045, -- Не реагируем на микродрожание камеры.
    RecoilMaxPitchDegrees = 5.0, -- Не воспринимаем резкий разворот как отдачу.
    RecoilMaxCorrectionDegrees = 1.60, -- Ограничение коррекции за кадр.
    BoosterBatch = 96, -- Средний пакет вместо слишком медленных 48 и старых 320.
    BoosterSliceMs = 0.90, -- Мягкий CPU budget для первого обхода.
    BoosterLowFpsSliceMs = 0.45, -- Делаем один небольшой пакет за низкий FPS.
    BoosterInitialDelay = 0.015, BoosterLowFpsDelay = 0.035,
    BoosterQueueBatch = 48, -- StreamingEnabled: до 48 новых объектов за проход.
    BoosterQueueSliceMs = 0.65,
    BoosterQueueDelay = 0.040, BoosterQueueLowFpsDelay = 0.075,
    BoosterRepairCooldown = 45, -- Нет повторного обхода каждые 12 секунд.
    BoosterRepairIdleSeconds = 3, -- Сначала даём стримингу завершиться.
    EspVisualBalancedHz = 24, -- ESP снижает нагрузку; AIM сохраняет свою частоту.
    EspVisualEcoHz = 12,
    EspLowFps = 42, EspLowHz = 12,
    EspCriticalFps = 30, EspCriticalHz = 8,
    EspShapeEcoLimit = 6,
    EspShapeBalancedLimit = 10,
    EspShapeQualityLimit = 20,
    PerfEcoEnterFps = 44,
    PerfEcoExitFps = 54, -- Гистерезис без прыгания ECO/BALANCED каждый замер.
    PerfTierEcoEnterDwell = 2, -- Быстрый переход в ECO при просадках FPS.
    PerfTierBalancedDwell = 15, -- Возврат осторожный, без постоянных качелей.
    PerfEcoLowSamples = 2,
    PerfBalancedRecoverySamples = 5,
    GuardLowFps = 39, GuardCriticalFps = 29,
    GuardRecoveryFps = 55, GuardLowSamples = 3,
    GuardRecoverSamples = 8, GuardMinStepSeconds = 12,
    GuardEspMaxL1 = 6, GuardEspMaxL2 = 4,
    GuardShapeMaxL1 = 4, GuardShapeMaxL2 = 2,
    GuardVisualHzL1 = 12, GuardVisualHzL2 = 8,
    FrameTimeWindow = 240, -- Скользящее окно; 1% low — по худшим кадрам.
    FrameTimeSpikeMs = 50,
    EspCacheIdleSeconds = 3.5, -- Коротко переиспользуем GUI за пределами TOP N.
    EspCacheMaxExtra = 4, -- Всего не более 4 скрытых Highlight сверх лимита.
    BhopMinInterval = 0.08, -- Частота проверок прыжка; физика ограничивает реальный BHOP.
    BhopMaxInterval = 0.60,
    BhopSpeedMultiplierCap = 2.0,
    BhopWalkSpeedCap = 32, -- Не разгоняем локальный WalkSpeed без ограничений.
    ChatMinInterval = 5, -- Уважаем штатные ограничения Roblox.
    ChatMaxInterval = 120,
    ChatMaxCodepoints = 160,
    FullBrightBrightness = 2.1,
    FullBrightAmbient = Color3.fromRGB(170, 170, 170),
    FullBrightOutdoorAmbient = Color3.fromRGB(175, 175, 175),
    FullBrightExposure = 0.12,
    Accent = Color3.fromRGB(205, 79, 76), -- Graphite operator interface.
    EspGold = Color3.fromRGB(232, 188, 78), -- Отдельный цвет GOLD, не связан с красной темой.
    Neutral = Color3.fromRGB(195, 202, 209),
    Window = Color3.fromRGB(16, 19, 22),
    Surface = Color3.fromRGB(32, 37, 42),
    Muted = Color3.fromRGB(154, 162, 170),
}

if game.PlaceId ~= CONFIG.PlaceId then
    warn("[124 Community Visuals] Неподдерживаемый PlaceId: " .. tostring(game.PlaceId))
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
    warn("[124 Community Visuals] Локальный игрок недоступен")
    return
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
if not PlayerGui then
    warn("[124 Community Visuals] PlayerGui недоступен")
    return
end

-- Общая среда позволяет безопасно перезапустить скрипт в том же executor.
local env = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then env = result end
end
-- Startup reporting is independent of the main GUI, which might not initialize.
local function bootFailure(stage, err)
    local reason = tostring(err or "unknown")
    env.ARMY124_BOOT_PHASE = "failed"
    env.ARMY124_BOOT_ERROR = tostring(stage) .. ": " .. reason
    warn("[124 START] " .. env.ARMY124_BOOT_ERROR)
    pcall(function()
        local previous = PlayerGui:FindFirstChild("Army124StartupError")
        if previous then previous:Destroy() end
        local screen = Instance.new("ScreenGui")
        screen.Name, screen.ResetOnSpawn = "Army124StartupError", false
        screen.IgnoreGuiInset, screen.DisplayOrder = true, 10000
        local card = Instance.new("Frame")
        card.AnchorPoint = Vector2.new(0.5, 0)
        card.Position = UDim2.new(0.5, 0, 0, 12)
        card.Size = UDim2.new(0.90, 0, 0, 110)
        card.BackgroundColor3 = Color3.fromRGB(22, 26, 30)
        card.BorderSizePixel = 0
        card.Parent = screen
        local max = Instance.new("UISizeConstraint")
        max.MaxSize, max.Parent = Vector2.new(520, 110), card
        local title = Instance.new("TextLabel")
        title.Position = UDim2.fromOffset(12, 5)
        title.Size = UDim2.new(1, -24, 0, 26)
        title.BackgroundTransparency = 1
        title.Text = "124 / ОШИБКА ЗАПУСКА: " .. tostring(stage)
        title.TextColor3 = Color3.fromRGB(234, 116, 112)
        title.Font, title.TextSize = Enum.Font.GothamBold, 13
        title.TextXAlignment, title.Parent = Enum.TextXAlignment.Left, card
        local detail = Instance.new("TextLabel")
        detail.Position = UDim2.fromOffset(12, 32)
        detail.Size = UDim2.new(1, -24, 1, -40)
        detail.BackgroundTransparency = 1
        detail.Text = reason:sub(1, 420)
        detail.Font, detail.TextSize = Enum.Font.Code, 11
        detail.TextWrapped = true
        detail.TextColor3 = Color3.fromRGB(225, 230, 236)
        detail.TextXAlignment = Enum.TextXAlignment.Left
        detail.TextYAlignment, detail.Parent = Enum.TextYAlignment.Top, card
        screen.Parent = PlayerGui
    end)
end
env.ARMY124_BOOT_PHASE = "preflight"
env.ARMY124_BOOT_ERROR = nil
-- Старый экземпляр ДОЛЖЕН освободить UI, BindToRenderStep и свойства.
-- Старые версии возвращают nil при успехе, поэтому проверяем освобождение
-- env.ARMY124_CLEANUP, а не только возвращаемое значение.
if type(env.ARMY124_CLEANUP) == "function" then
    local previous = env.ARMY124_CLEANUP
    local ok, result = pcall(previous)
    if not ok or result == false or env.ARMY124_CLEANUP == previous then
        bootFailure("PREVIOUS CLEANUP",
            "Старая копия не выгружена. Перезапусти игру. " .. tostring(result))
        return
    end
end
if type(env.ARMY124_RECOVERY) == "function" then
    local ok, restored = pcall(env.ARMY124_RECOVERY)
    if not ok or restored ~= true then
        bootFailure("RECOVERY",
            "Восстановление старой графики не завершено. " .. tostring(restored))
        return
    end
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
    aimOnlyRegisteredWeapons = true, -- Без подтверждения оружия AIM не наводится.
    aimWeaponNames = "", -- Храним список точных имён через "|", без угадывания.
    antiAfk = false,
    bunnyHop = false, -- По умолчанию выключено, работает при движении по земле.
    bhopJumpInterval = 0.22, -- Пауза между попытками прыжка (сек).
    bhopSpeedMultiplier = 1.2, -- Множитель локального WalkSpeed.
    spamChat = false, -- Не запускается автоматически после загрузки.
    chatInterval = 8, -- Минимум CONFIG.ChatMinInterval.
    chatMessage = "", -- Пользовательский текст, без готовых фраз.
    airAlerts = false, -- Опционально: без фоновых Raycast/сканов игроков по умолчанию.
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
    queueDropped = 0, scanned = 0, repairing = false,
    repairCoveredDrops = 0, repairRetryAt = 0, repairErrors = 0,
    queueLastAt = 0, slicePeakMs = 0, queuePeakMs = 0,
    changedProperties = 0, phase = "OFF", lastError = nil,
    recoveryFailures = 0, recoveryNextAt = 0,
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
    errorAt = 0, active = {}, projected = {}, ordered = {}, candidatePool = {}}
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
-- Percentile/sort only when diagnostics are requested or MISC is visible.
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
local refreshSliders = {}
local repaintAimMode = function() end
local repaintColors = function() end
local repaintPerf = function() end
local repaintConfig = function() end
local requestSave = function() end
local lightingApplying = false
local aimTarget = nil
local aimNextScan = 0
-- Общий кеш экипированного Tool; Recoil уже отслеживает ChildAdded/ChildRemoved.
local aimPro = {
    equipped = nil,
    nextLos = 0,
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
    local instance = Instance.new(class)
    for key, value in pairs(properties or {}) do instance[key] = value end
    instance.Parent = parent
    -- Даже ошибка посередине построения UI не оставит несколько GUI.
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

-- AUTO определяем только один раз на измерение FPS. Гистерезис предотвращает
-- резкую смену количества ESP-объектов при 42–55 FPS.
local autoPerformanceTier = UserInputService.TouchEnabled and "ECO" or "BALANCED"
perfCounters.autoTierChangedAt = os.clock()
perfCounters.autoTierStableCount = 0
local function perfTier()
    if state.performanceMode == "ECO" then return "ECO" end
    if state.performanceMode == "QUALITY" then return "QUALITY" end
    return autoPerformanceTier
end
local function updateAutoPerformanceTier()
    -- Only AUTO may change its own tier. Require sustained readings AND
    -- minimum dwell to prevent repeated Highlight/Billboard destruction.
    if state.performanceMode ~= "AUTO" then
        perfCounters.autoTierStableCount = 0
        return
    end
    local candidate
    local needed
    if autoPerformanceTier == "BALANCED" then
        if measuredFps < CONFIG.PerfEcoEnterFps then
            candidate, needed = "ECO", CONFIG.PerfEcoLowSamples
        end
    elseif measuredFps >= CONFIG.PerfEcoExitFps then
        candidate, needed = "BALANCED", CONFIG.PerfBalancedRecoverySamples
    end
    if not candidate then
        perfCounters.autoTierStableCount = 0
        return
    end
    perfCounters.autoTierStableCount = perfCounters.autoTierStableCount + 1
    local dwell = candidate == "ECO" and CONFIG.PerfTierEcoEnterDwell
        or CONFIG.PerfTierBalancedDwell
    if perfCounters.autoTierStableCount >= needed
        and os.clock() - perfCounters.autoTierChangedAt >= dwell then
        autoPerformanceTier = candidate
        perfCounters.autoTierChangedAt = os.clock()
        perfCounters.autoTierStableCount = 0
    end
end
local function visualPerfTier()
    if state.performanceGuard and perfCounters.guard.level > 0 then return "ECO" end
    return perfTier()
end
local function espLimit()
    local tier = visualPerfTier()
    local normal = tier == "ECO" and 6
        or tier == "QUALITY" and 20 or CONFIG.EspMaxPlayers
    if state.performanceGuard and perfCounters.guard.level == 2 then
        return math.min(normal, CONFIG.GuardEspMaxL2)
    elseif state.performanceGuard and perfCounters.guard.level == 1 then
        return math.min(normal, CONFIG.GuardEspMaxL1)
    end
    return normal
end

-- Тонкий ESP. Ник над игроком; HP и дистанция в отдельной нижней строке.
-- Каждой подписи свой размер, без масштабирования GUI при отдалении.
local function createRender(player, character, head)
    local hl = mk("Highlight", {
        Name = "Army124ESPHighlight",
        Adornee = character,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        FillTransparency = CONFIG.EspFillTransparency,
        OutlineTransparency = CONFIG.EspOutlineTransparency,
    }, character)
    local bb = mk("BillboardGui", {
        Name = "Army124ESPLabel",
        Adornee = head,
        AlwaysOnTop = true,
        LightInfluence = 0,
        MaxDistance = state.espRangeMeters / CONFIG.StudMeters,
        Size = UDim2.fromOffset(CONFIG.EspLabelWidth, CONFIG.EspLabelHeight),
        StudsOffsetWorldSpace = Vector3.new(0, 2.1, 0),
        ResetOnSpawn = false,
    }, PlayerGui)
    local nameLabel = mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 13),
        TextSize = CONFIG.EspNameSizeNear,
        TextScaled = false,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamMedium,
        TextStrokeTransparency = 0.55,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "",
    }, bb)
    local healthLabel = mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 13),
        Size = UDim2.new(0.5, -3, 0, 12),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = CONFIG.EspMetaSizeNear,
        TextScaled = false,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.Gotham,
        TextStrokeTransparency = 0.55,
        TextColor3 = Color3.fromRGB(120, 255, 160),
        Text = "",
    }, bb)
    local distanceLabel = mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 3, 0, 13),
        Size = UDim2.new(0.5, -3, 0, 12),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = CONFIG.EspMetaSizeNear,
        TextScaled = false,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.Gotham,
        TextStrokeTransparency = 0.55,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        Text = "",
    }, bb)
    local item = {character = character, highlight = hl, billboard = bb,
        nameLabel = nameLabel, healthLabel = healthLabel, distanceLabel = distanceLabel,
        inactiveSince = nil}
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
    if item and (item.character ~= character or not isLive(item.highlight)
        or not isLive(item.billboard) or not isLive(item.distanceLabel)) then
        deleteRender(player)
        item = nil
    end
    if not item then item = createRender(player, character, head) end
    -- Кешируем части, которые рендерятся чаще, чем обновляется список игроков.
    item.head, item.root, item.humanoid = head, root, hum
    -- Повторно активируем готовые Highlights вместо Destroy/Instance.new.
    item.inactiveSince = nil
    setIfDifferent(item.highlight, "Enabled", true)
    local color = getPlayerColor(player)
    local meters = myRoot and math.floor(
        (root.Position - myRoot.Position).Magnitude * CONFIG.StudMeters + 0.5
    ) or 0
    local near = meters < CONFIG.EspMidDistanceMeters
    local far = meters >= CONFIG.EspFarDistanceMeters
    local nameSize = far and CONFIG.EspNameSizeFar
        or not near and CONFIG.EspNameSizeMid or CONFIG.EspNameSizeNear
    local metaSize = near and CONFIG.EspMetaSizeNear or CONFIG.EspMetaSizeFar
    setIfDifferent(item.billboard, "MaxDistance", state.espRangeMeters / CONFIG.StudMeters)
    setIfDifferent(item.highlight, "FillColor", color)
    setIfDifferent(item.highlight, "OutlineColor", color)
    setIfDifferent(item.nameLabel, "Text", state.names and player.DisplayName or "")
    setIfDifferent(item.nameLabel, "TextSize", nameSize)
    setIfDifferent(item.nameLabel, "TextColor3", color)
    setIfDifferent(item.nameLabel, "Visible", state.names)
    setIfDifferent(item.distanceLabel, "Text", state.distance and (tostring(meters) .. " м") or "")
    setIfDifferent(item.distanceLabel, "TextSize", metaSize)
    setIfDifferent(item.distanceLabel, "Visible", state.distance)
    local maxHp = math.max(hum.MaxHealth, 1)
    if state.health then
        local hp = math.clamp(hum.Health / maxHp, 0, 1)
        setIfDifferent(item.healthLabel, "Text",
            string.format("HP %d/%d", math.ceil(hum.Health), math.ceil(maxHp)))
        setIfDifferent(item.healthLabel, "TextColor3",
            Color3.fromRGB(math.floor(255 * (1 - hp)), math.floor(255 * hp), 90))
    end
    setIfDifferent(item.healthLabel, "TextSize", metaSize)
    setIfDifferent(item.healthLabel, "Visible", state.health)
    -- При отключении имени нижняя строка поднимается на его место.
    local lowerY = state.names and 13 or 0
    setIfDifferent(item.healthLabel, "Position", UDim2.fromOffset(0, lowerY))
    setIfDifferent(item.distanceLabel, "Position", UDim2.new(0.5, 3, 0, lowerY))
    local hasMeta = state.health or state.distance
    local height = state.names and (hasMeta and CONFIG.EspLabelHeight or 14) or 14
    setIfDifferent(item.billboard, "Size", UDim2.fromOffset(CONFIG.EspLabelWidth, height))
    setIfDifferent(item.billboard, "Enabled", state.names or hasMeta)
end

local function sameTeamESP(player)
    return player.Team ~= nil and LocalPlayer.Team ~= nil
        and player.Team == LocalPlayer.Team
end

local espCandidateScratch = {}
local espKeepScratch = {}
local function refreshESP()
    if not state.esp then
        for player in pairs(renderData) do deleteRender(player) end
        table.clear(perfCounters.espVisual.ordered)
        perfCounters.espCount = 0
        return
    end
    local character = LocalPlayer.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        for player in pairs(renderData) do deleteRender(player) end
        table.clear(perfCounters.espVisual.ordered)
        perfCounters.espCount = 0
        return
    end
    -- Рисуем ближайших, чтобы не создавать десятки дорогих Highlight.
    local candidates = espCandidateScratch
    local pool = perfCounters.espVisual.candidatePool
    local maxStuds = state.espRangeMeters / CONFIG.StudMeters
    local maxDistanceSquared = maxStuds * maxStuds
    table.clear(candidates)
    for _, player in ipairs(perfCounters.roster) do
        if player ~= LocalPlayer and (not state.espEnemyOnly or not sameTeamESP(player)) then
            local ch = player.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local offset = root.Position - myRoot.Position
                local dist2 = offset:Dot(offset)
                if dist2 <= maxDistanceSquared then
                    local index = #candidates + 1
                    local entry = pool[index]
                    if not entry then
                        entry = {}
                        pool[index] = entry
                    end
                    entry.player, entry.distanceSquared = player, dist2
                    candidates[index] = entry
                end
            end
        end
    end
    -- Discard stale Player references after population shrinks; reuse records.
    for i = #candidates + 1, #pool do
        pool[i].player = nil
    end
    table.sort(candidates, function(a, b)
        if a.distanceSquared ~= b.distanceSquared then
            return a.distanceSquared < b.distanceSquared
        end
        return a.player.UserId < b.player.UserId -- Stable tie breaker.
    end)
    local keep = espKeepScratch
    local ordered = perfCounters.espVisual.ordered
    table.clear(keep)
    table.clear(ordered)
    local limit = math.min(#candidates, espLimit())
    for i = 1, limit do
        local player = candidates[i].player
        keep[player] = true
        updatePlayer(player, myRoot)
        if renderData[player] then ordered[#ordered + 1] = player end
    end
    local now, cached = os.clock(), 0
    for player, item in pairs(renderData) do
        if not keep[player] then
            local invalid = player.Parent ~= Players or item.character ~= player.Character
                or not isLive(item.highlight) or not isLive(item.billboard)
            local expired = item.inactiveSince
                and (now - item.inactiveSince >= CONFIG.EspCacheIdleSeconds)
            if invalid or expired or cached >= CONFIG.EspCacheMaxExtra then
                deleteRender(player)
            else
                -- Скрытые объекты сохраняют только невидимый кэш на 3.5 сек.
                -- Не должны оставаться линии/подсветка вне выбранного TOP N.
                if not item.inactiveSince then item.inactiveSince = now end
                cached = cached + 1
                setIfDifferent(item.highlight, "Enabled", false)
                setIfDifferent(item.billboard, "Enabled", false)
                if item.tracer then setIfDifferent(item.tracer, "Visible", false) end
            end
        end
    end
    perfCounters.espCount = #ordered
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
                        warn("[124 Community Visuals] Lighting: откат " .. tostring(key) .. " не выполнен; повторим")
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
            warn("[124 Community Visuals] Booster: не удалось восстановить траву; снимок сохранён")
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
                warn("[124 Community Visuals] Booster: не удалось вернуть цвет Terrain; снимок сохранён")
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
for _, person in ipairs(perfCounters.roster) do boosterPro.watchPlayer(person) end
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
                        warn("[124 Community Visuals] Booster: ошибка смены режима, свойство " .. tostring(key))
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
                boosterPro.changedProperties = boosterPro.changedProperties + 1
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
            if count >= CONFIG.BoosterBatch or (count % 4 == 0 and
                (os.clock() - sliceStarted) * 1000 >=
                    (measuredFps < 35 and CONFIG.BoosterLowFpsSliceMs or CONFIG.BoosterSliceMs)) then
                boosterPro.slicePeakMs = math.max(boosterPro.slicePeakMs,
                    (os.clock() - sliceStarted) * 1000)
                count = 0
                task.wait(measuredFps < 42 and CONFIG.BoosterLowFpsDelay
                    or CONFIG.BoosterInitialDelay)
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
        .. " | Записано свойств: " .. tostring(boosterPro.changedProperties)
        .. " | " .. tostring(boosterPro.phase)
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
                warn("[124 Community Visuals] Booster: не удалось восстановить " .. tostring(key)
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
    boosterPro.failed = nil
    boosterPro.guardLowSince = nil
    boosterPro.guardLastCheck = 0
    -- Discard old queued descendants. New events belong to the new revision.
    boosterPro.queued = {}
    boosterPro.queuedSeen = setmetatable({}, {__mode = "k"})
    boosterPro.queuedProcessed = setmetatable({}, {__mode = "k"})
    boosterPro.queueHead, boosterPro.queueTail, boosterPro.queueCount = 1, 0, 0
    boosterPro.queueDropped, boosterPro.scanned = 0, 0
    boosterPro.queueLastAt = 0
    boosterPro.slicePeakMs, boosterPro.queuePeakMs = 0, 0
    boosterPro.changedProperties = 0
    boosterPro.phase = enabled and "SCANNING" or "RESTORING"
    boosterPro.repairing = false
    boosterPro.repairCoveredDrops, boosterPro.repairRetryAt, boosterPro.repairErrors = 0, 0, 0
    if enabled then
        boosterPro.lastError = nil
        boosterPro.after = nil
        boosterPro.afterFPS = {}
        boosterPro.guardWarned = false
        if not keepBaseline then boosterPro.baseline = boosterPro.average(boosterPro.originalFPS) end
        boosterPro.mode = state.boosterMode
        boosterPro.startedAt = os.clock()
        local setupOk, setupErr = pcall(function()
            applyLighting()
            if state.boosterMode == "BALANCED" then
                restoreTerrainGrass()
                restoreTerrainColors()
            else
                hideTerrainGrass()
                whitenTerrain()
            end
        end)
        if not setupOk then
            boosterPro.lastError = tostring(setupErr)
            warn("[124 Community Visuals] Booster: ошибка подготовки графики: 
                .. tostring(setupErr))
            state.booster = false
            local rollbackOk, rollbackErr = pcall(setBooster, false)
            if not rollbackOk then
                warn("[124 Community Visuals] Booster: ошибка запуска отката: "
                    .. tostring(rollbackErr))
            end
            if refreshToggles.booster then pcall(refreshToggles.booster) end
            requestSave()
            return
        end
        task.spawn(function()
            local ok, err = pcall(function()
            -- Сначала синхронизируем старые снимки: это важно при ULTRA -> BALANCED.
            local n, phaseStarted = 0, os.clock()
            for obj in pairs(savedGraphics) do
                if not alive or revision ~= boosterRevision or not state.booster then return end
                optimizeObject(obj)
                n = n + 1
                if n % 4 == 0 and ((os.clock() - phaseStarted) * 1000 >=
                    (measuredFps < 42 and CONFIG.BoosterLowFpsSliceMs
                        or CONFIG.BoosterSliceMs)
                    or n % CONFIG.BoosterBatch == 0) then
                    task.wait(measuredFps < 42 and CONFIG.BoosterLowFpsDelay
                        or CONFIG.BoosterInitialDelay)
                    phaseStarted = os.clock()
                end
            end
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then optimizeObject(terrain) end
            if not optimizeHierarchy(Workspace, revision) then return end
            if not optimizeHierarchy(Lighting, revision) then return end
            if revision ~= boosterRevision or not state.booster then return end
            boosterPro.complete = true
            boosterPro.phase = "READY"
            boosterPro.readyAt = os.clock() + 1.5
            -- Compare FPS only after optimization actually finishes; earlier
            -- samples include initial workload and would trigger a false auto-rollback.
            boosterPro.afterFPS = {}
            boosterPro.after = nil
            boosterPro.guardLowSince = nil
            tell("FPS Booster Pro:  .. state.boosterMode .. " применён; просмотрено "
                .. tostring(boosterPro.scanned) .. " объектов; измеряем FPS")
            end)
            if not ok and alive and revision == boosterRevision and state.booster then
                boosterPro.complete = false
                boosterPro.phase = "FAILED"
                boosterPro.failed = tostring(err)
                boosterPro.lastError = boosterPro.failed
                warn("[124 Community Visuals] Booster: ошибка полного обхода:  .. boosterPro.failed)
                tell("FPS Booster остановлен: ошибка обработки карты; восстановление графики")
                state.booster = false
                local restored, restoreErr = pcall(setBooster, false)
                if not restored then
                    warn("[124 Community Visuals] Ошибка запуска отката Booster: " .. tostring(restoreErr))
                end
                if refreshToggles.booster then pcall(refreshToggles.booster) end
                requestSave()
            end
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
                if count % 4 == 0 and ((os.clock() - sliceStarted) * 1000 >=
                    (measuredFps < 42 and CONFIG.BoosterLowFpsSliceMs
                        or CONFIG.BoosterSliceMs)
                    or count % CONFIG.BoosterBatch == 0) then
                    task.wait(measuredFps < 42 and CONFIG.BoosterLowFpsDelay
                        or CONFIG.BoosterInitialDelay)
                    sliceStarted = os.clock()
                end
            end
            if alive and revision == boosterRevision then
                local remaining = 0
                for obj, snapshot in pairs(savedGraphics) do
                    if obj.Parent and next(snapshot) ~= nil then remaining = remaining + 1 end
                end
                boosterPro.phase = remaining > 0 and "RESTORE PENDING" or "OFF"
                if remaining > 0 or boosterPro.restoreFailures > 0 then
                    tell("FPS Booster Pro: частичный откат, ошибок 
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
    -- Один RaycastParams и один массив вместо создания на каждый кадр.
    local exclusions = aimPro.rayIgnore
    table.clear(exclusions)
    local myCharacter = LocalPlayer.Character
    if myCharacter then exclusions[1] = myCharacter end
    local params = aimPro.rayParams
    for _ = 1, CONFIG.AimVisibleRaycastChecks do
        params.FilterDescendantsInstances = exclusions
        local result = Workspace:Raycast(origin, direction, params)
        if not result then return true end
        if result.Instance:IsDescendantOf(targetCharacter) then return true end
        if result.Instance:IsA("BasePart") and result.Instance.Transparency >= 0.98 then
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

-- Квадрат дистанции вместо квадратного корня на всех проверяемых целях.
local function examineTarget(camera, player, part, myRoot, center, fovLimit, withLos)
    local character = player and player.Character
    if not character or not part or not part:IsA("BasePart")
        or not part:IsDescendantOf(character) or sameTeam(player) then return nil end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local point = part.Position
    local offset = point - myRoot.Position
    local maxStuds = state.aimRangeMeters / CONFIG.StudMeters
    if offset:Dot(offset) > maxStuds * maxStuds then return nil end
    local projected, onScreen = camera:WorldToViewportPoint(point)
    if not onScreen or projected.Z <= 0 then return nil end
    local dx, dy = projected.X - center.X, projected.Y - center.Y
    local pixelSquared = dx * dx + dy * dy
    if pixelSquared > fovLimit * fovLimit then return nil end
    if withLos and not canSee(camera, point, character) then return nil end
    return {player = player, part = part, character = character,
        humanoid = hum, pixelsSquared = pixelSquared}
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

    if state.targetLock and aimTarget and aimTarget.player.Parent == Players then
        local chosen = targetPart(aimTarget.character)
        if chosen then
            local kept = examineTarget(camera, aimTarget.player, chosen, myRoot,
                center, fov * CONFIG.AimLockTolerance, state.visibleCheck)
            if kept then return done(kept) end
        end
    end

    -- Без Visible Check не создаём сортированный список: ищем один минимум.
    local candidates = aimPro.candidates
    table.clear(candidates)
    local best = nil
    for _, player in ipairs(perfCounters.roster) do
        if player ~= LocalPlayer and player.Character and not sameTeam(player) then
            local part = targetPart(player.Character)
            if part then
                local found = examineTarget(camera, player, part, myRoot,
                    center, fov, false)
                if found then
                    if state.visibleCheck then
                        candidates[#candidates + 1] = found
                    elseif not best or found.pixelsSquared < best.pixelsSquared then
                        best = found
                    end
                end
            end
        end
    end
    if not state.visibleCheck then return done(best) end
    table.sort(candidates, function(a, b) return a.pixelsSquared < b.pixelsSquared end)
    for _, candidate in ipairs(candidates) do
        if canSee(camera, candidate.part.Position, candidate.character) then
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
    -- Отсутствие Tool — абсолютный запрет движения камеры, даже при F6/ПКМ/touch.
    if not alive or not state.aimbot or not (aimHeldMouse or aimHeldTouch or aimHeldKey)
        or not aimPro.equippedTool() then
        aimTarget = nil
        return
    end
    if isRobloxMenuOpen() then
        aimPro.reset()
        return
    end
    if UserInputService:GetFocusedTextBox() ~= nil then return end
    local camera = Workspace.CurrentCamera
    if not camera then aimTarget = nil; return end
    local now = os.clock()
    local tier = perfTier()
    local scanEvery = tier == "ECO" and 0.24
        or tier == "QUALITY" and 0.08 or CONFIG.AimScanInterval
    local losInterval = tier == "ECO" and CONFIG.AimLosEcoSeconds
        or tier == "QUALITY" and CONFIG.AimLosQualitySeconds
        or CONFIG.AimLosBalancedSeconds
    local scannedThisFrame = false
    if now >= aimNextScan then
        aimNextScan = now + scanEvery
        aimTarget = findAimTarget(camera)
        scannedThisFrame = true
        if aimTarget then
            -- Новый поиск уже сделал LOS при включённом Visible Check.
            aimPro.nextLos = now + losInterval
        end
    end
    local current = aimTarget
    -- Отсутствие цели НЕ обнуляет таймер поиска (было до 60 сканов/с).
    if not current then return end
    local part = current.part
    if not part or not part.Parent or not current.player
        or current.player.Character ~= current.character or sameTeam(current.player)
        or not current.humanoid or current.humanoid.Health <= 0 then
        aimTarget = nil
        aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
        return
    end
    local origin = camera.CFrame.Position
    local point = part.Position
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot or (point - origin).Magnitude <= 0.05
        or (point - myRoot.Position).Magnitude * CONFIG.StudMeters > state.aimRangeMeters then
        aimTarget = nil
        aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
        return
    end
    -- Проверка видимости прицеливания остаётся активной, но Raycast реже.
    if state.visibleCheck and not scannedThisFrame and now >= aimPro.nextLos then
        if not canSee(camera, point, current.character) then
            aimTarget = nil
            aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
            return
        end
        aimPro.nextLos = now + losInterval
    end
    local goal = CFrame.lookAt(origin, predictedPoint(part))
    if state.aimSmoothness == 0 then
        camera.CFrame = goal
    else
        -- Не меняем уже проверенную формулу поворота и плавности.
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
    if tool and tool:IsA("Tool") and tool.Parent == LocalPlayer.Character then
        recoilTool = tool
        recoilToolConnections[#recoilToolConnections + 1] = tool.Activated:Connect(markRecoilShot)
        recoilToolConnections[#recoilToolConnections + 1] = tool.Deactivated:Connect(function()
            recoilHolding = false
            recoilFireUntil = math.max(recoilFireUntil, os.clock() + CONFIG.RecoilShotGraceSeconds)
        end)
    end
    -- Без Tool в руках AIM перестаёт управлять камерой и сбрасывает захват.
    aimPro.equipped = recoilTool
    aimPro.reset()
    aimPro.changed()
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
connect(LocalPlayer.CharacterRemoving, function(character)
    if aimPro.equipped and aimPro.equipped.Parent == character then
        equipRecoilTool(nil)
    end
end)
bindRecoilCharacter(LocalPlayer.Character)

local function recoilFrame(dt)
    -- OFF: нулевые вычисления углов камеры.
    -- После включения первый кадр записывает базу, не компенсируя
    -- несуществующий скачок на границе состояний.
    if not alive or not state.controlRecoil or state.recoilStrength <= 0
        or recoilTool == nil or recoilTool.Parent ~= LocalPlayer.Character then
        recoilLastCamera, recoilLastPitch = nil, nil
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        recoilLastCamera, recoilLastPitch = nil, nil
        return
    end
    local currentPitch = camera.CFrame:ToOrientation()
    local previousPitch = recoilLastPitch
    local sameCamera = recoilLastCamera == camera
    recoilLastCamera = camera
    recoilLastPitch = currentPitch
    if not sameCamera or previousPitch == nil then return end
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

-- Bootstrap registered BEFORE creating any new ScreenGui or UI input handlers.
-- The UI section runs inside its own function: Luau permits 200 locals per
-- function, and the preceding 1600-line controller already uses many.
local function abortPartialHub()
    alive = false
    boosterRevision = boosterRevision + 1
    state.esp, state.aimbot, state.booster = false, false, false
    state.controlRecoil, state.antiAim, state.fullbright = false, false, false
    pcall(function() recoil.shutdown() end)
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    for _, name in ipairs({
        aimBindingName,
        "Army124CommunityRecoil_" .. tostring(LocalPlayer.UserId),
        "Army124CommunityESP_" .. tostring(LocalPlayer.UserId),
        "Army124CameraFov_" .. tostring(LocalPlayer.UserId),
    }) do
        pcall(function() RunService:UnbindFromRenderStep(name) end)
    end
    for _, root in ipairs(boosterPro.bootRoots) do
        pcall(function() root:Destroy() end)
    end
    table.clear(boosterPro.bootRoots)
    pcall(function() restoreTerrainGrass() end)
    pcall(function() restoreTerrainColors() end)
    pcall(function() applyLighting() end)
    if env.ARMY124_CLEANUP == abortPartialHub then
        env.ARMY124_CLEANUP = nil
    end
    return true
end
env.ARMY124_CLEANUP = abortPartialHub

local function initializeHubUI()
-- 124 Community Visuals / Purple Dashboard — pure Roblox GUI, no external UI dependency.
-- Две колонки на больших экранах, одна колонка на телефонах.
local gui = mk("ScreenGui", {
    Name = "Army124CommunityVisualsGUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- Lazy Loading: expensive per-player Tracer/Box/Skeleton GUI containers
-- are created only on first use. No memory allocations for them at startup.
-- Existing FOV ring is tiny and intentionally kept eager to avoid aim regressions.
perfCounters.lazy = {tracersCreated = 0, shapesCreated = 0}
function perfCounters.lazy.ensureTracer()
    if not alive or not state.esp or not state.tracers then return false end
    if not tracerGui or not tracerGui.Parent then
        tracerGui = mk("ScreenGui", {
            Name = "Army124TracersV05", ResetOnSpawn = false,
            IgnoreGuiInset = true, DisplayOrder = 90,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, PlayerGui)
        perfCounters.lazy.tracersCreated = perfCounters.lazy.tracersCreated + 1
    end
    return true
end
function perfCounters.lazy.ensureShapes()
    if not alive or not state.esp or not (state.espBox or state.espSkeleton) then
        return false
    end
    if not shapeGui or not shapeGui.Parent then
        shapeGui = mk("ScreenGui", {
            Name = "Army124ShapeOverlayV100", ResetOnSpawn = false,
            IgnoreGuiInset = true, DisplayOrder = 92,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, PlayerGui)
        perfCounters.lazy.shapesCreated = perfCounters.lazy.shapesCreated + 1
    end
    return true
end
function perfCounters.lazy.prepare()
    if not state.lazyLoading then
        -- Eager option for debugging / compatibility, without changing
        -- the user's esp/tracer/shape enabled state.
        if not tracerGui or not tracerGui.Parent then
            tracerGui = mk("ScreenGui", {Name = "Army124TracersV05",
                ResetOnSpawn = false, IgnoreGuiInset = true,
                DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, PlayerGui)
            perfCounters.lazy.tracersCreated = perfCounters.lazy.tracersCreated + 1
        end
        if not shapeGui or not shapeGui.Parent then
            shapeGui = mk("ScreenGui", {Name = "Army124ShapeOverlayV100",
                ResetOnSpawn = false, IgnoreGuiInset = true,
                DisplayOrder = 92, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, PlayerGui)
            perfCounters.lazy.shapesCreated = perfCounters.lazy.shapesCreated + 1
        end
    end
end

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
    if not alive or (not state.cameraFovEnabled and next(controller.saved) == nil) then
        return -- OFF: не обращаемся к камере без ожидающего отката.
    end
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
    spin.nextPendingRetry = 0
    return next(spin.pending) == nil
end

function memoryFX.spin.frame(dt)
    local spin = memoryFX.spin
    if not alive then return end
    if not state.antiAim and not spin.character and next(spin.pending) == nil then
        return -- OFF: никакой инспекции позы или C0.
    end
    -- При отказе C0/AutoRotate повторяем раз в секунду, не 60 раз.
    if next(spin.pending) ~= nil then
        local now = os.clock()
        if now >= (spin.nextPendingRetry or 0) then
            spin.nextPendingRetry = now + 1.0
            spin.restorePending()
        end
    end
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
        warn("[124 Community Visuals] Anti-Aim: " .. tostring(err))
        spin.lastError = now
    end
end

-- MOVEMENT / CHAT: отдельный контроллер, без RenderStepped и автоматической рассылки.
-- Chat Timer даёт уведомление о готовности; отправка ТОЛЬКО по нажатию пользователем.
local utilityFX = {bunny = {token = 0}, chat = {
    token = 0, sent = 0, errors = 0, readyCount = 0,
    inFlight = false, lastSentAt = -1e8,
    timerStatus = "OFF", sendStatus = "NOT SENT",
    repaintText = function() end, repaintStatus = function() end,
    commitText = function() return false end
}}
do
    local bunny = utilityFX.bunny
    local chat = utilityFX.chat
    local TextChatService = game:GetService("TextChatService")

    -- Восстанавливаем только собственный WalkSpeed, не перетираем изменения игры.
    function bunny.restore()
        local hum = bunny.humanoid
        if hum and hum.Parent and bunny.originalSpeed and bunny.appliedSpeed then
            pcall(function()
                if math.abs(hum.WalkSpeed - bunny.appliedSpeed) < 0.05 then
                    hum.WalkSpeed = bunny.originalSpeed
                end
            end)
        end
        bunny.humanoid, bunny.originalSpeed, bunny.appliedSpeed = nil, nil, nil
        bunny.suspended = false
    end

    function bunny.applySpeed()
        local hum = bunny.humanoid
        if not alive or not state.bunnyHop or not hum or not hum.Parent then return end
        if not bunny.originalSpeed or bunny.originalSpeed <= 0 then return end
        -- Внешнее управление скоростью (спринт, стан, форма) приоритетнее Hub.
        -- При конфликте не пытаемся каждую итерацию перезаписывать WalkSpeed.
        if bunny.suspended then
            -- Возобновляем ТОЛЬКО когда игра вернула исходный WalkSpeed
            -- после спринта/стана, без вмешательства в новую игровую скорость.
            if math.abs(hum.WalkSpeed - bunny.originalSpeed) < 0.05 then
                bunny.suspended = false
                bunny.appliedSpeed = nil
            else
                return
            end
        end
        if bunny.appliedSpeed and math.abs(hum.WalkSpeed - bunny.appliedSpeed) >= 0.05 then
            bunny.suspended = true
            return
        end
        -- Если у игры исходная скорость выше лимита, не замедляем её.
        local speed = math.max(bunny.originalSpeed,
            math.min(bunny.originalSpeed * state.bhopSpeedMultiplier,
                CONFIG.BhopWalkSpeedCap))
        if math.abs(hum.WalkSpeed - speed) < 0.05 then
            bunny.appliedSpeed = speed
            return
        end
        local ok = pcall(function() hum.WalkSpeed = speed end)
        if ok then bunny.appliedSpeed = speed end
    end

    function bunny.stop()
        bunny.token = bunny.token + 1
        bunny.restore()
    end

    function bunny.sync()
        bunny.stop()
        if not alive or not state.bunnyHop then return end
        local token = bunny.token
        task.spawn(function()
            while alive and state.bunnyHop and token == bunny.token do
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Parent and hum.Health > 0 then
                    if bunny.humanoid ~= hum then
                        bunny.restore()
                        bunny.humanoid = hum
                        bunny.originalSpeed = hum.WalkSpeed
                        bunny.appliedSpeed = nil
                        bunny.suspended = false
                        bunny.applySpeed()
                    end
                    bunny.applySpeed()
                    if hum.MoveDirection.Magnitude > 0.08
                        and hum.FloorMaterial ~= Enum.Material.Air
                        and not hum.Sit and not hum.PlatformStand then
                        hum.Jump = true
                    end
                elseif bunny.humanoid then
                    bunny.restore()
                end
                task.wait(math.clamp(state.bhopJumpInterval,
                    CONFIG.BhopMinInterval, CONFIG.BhopMaxInterval))
            end
        end)
    end

    function chat.stop()
        chat.token = chat.token + 1
        chat.timerStatus = "OFF"
        chat.repaintStatus()
    end

    -- Пользовательский таймер напоминания (НЕ отправка по таймеру).
    function chat.sync()
        chat.stop()
        if not alive or not state.spamChat then return end
        chat.timerStatus = "WAITING"
        chat.repaintStatus()
        local token = chat.token
        task.spawn(function()
            local deadline = os.clock() + state.chatInterval
            while alive and state.spamChat and token == chat.token do
                local remaining = deadline - os.clock()
                if remaining <= 0 then
                    chat.readyCount = chat.readyCount + 1
                    chat.timerStatus = "READY: нажмите отправить"
                    chat.repaintStatus()
                    -- Каждая следующая готовность не вызывает SendAsync.
                    deadline = os.clock() + state.chatInterval
                else
                    task.wait(math.min(0.5, remaining))
                end
            end
        end)
    end

    -- Без угадывания публичности custom TextChannel: выбираем только RBXGeneral.
    -- Наличие TextSource означает членство; CanSend — право отправки.
    -- PlatformIntegratedChat не читается из LocalScript (RobloxScriptSecurity).
    local function currentChatChannel()
        local channels = TextChatService:FindFirstChild("TextChannels")
        if not channels then return nil, "TextChannels не загружены" end
        local channel = channels:FindFirstChild("RBXGeneral")
        if not channel or not channel:IsA("TextChannel") then
            return nil, "RBXGeneral недоступен; выбери стандартный чат Roblox"
        end
        local permitted = false
        for _, source in ipairs(channel:GetChildren()) do
            if source:IsA("TextSource") and source.UserId == LocalPlayer.UserId then
                permitted = source.CanSend == true
                break
            end
        end
        if not permitted then
            return nil, "нет права Send в RBXGeneral (проверь доступ к чату)"
        end
        return channel
    end

    -- Вызывать исключительно из кнопки, после ввода сообщения пользователем.
    function chat.sendOnce()
        if not alive then return end
        if chat.inFlight then
            tell("Chat: предыдущая отправка ещё выполняется")
            return
        end
        local okText = chat.commitText()
        if not okText then
            tell("Chat: введи сообщение (до 160 символов)")
            return
        end
        -- TextSource.CanSend is channel-local, NOT the account-wide permission.
        -- Never use a custom GUI remote as a workaround for denied chat access.
        chat.inFlight = true
        chat.sendStatus = "CHECKING ACCESS"
        chat.repaintStatus()
        local permissionToken = chat.token
        local okAccess, permitted = pcall(function()
            return TextChatService:CanUserChatAsync(LocalPlayer.UserId)
        end)
        if not alive or permissionToken ~= chat.token then
            chat.inFlight = false
            return
        end
        if not okAccess or permitted ~= true then
            chat.inFlight = false
            chat.sendStatus = okAccess and "BLOCKED BY ROBLOX" or "PERMISSION UNKNOWN"
            chat.repaintStatus()
            tell(okAccess and
                "Chat: Roblox запрещает отправку сообщений этому аккаунту. "
                .. "Кастомный чат игры не отменяет настройки общения."
                or "Chat: не удалось проверить разрешение Roblox. Отправка отменена.")
            return
        end

        local now = os.clock()
        local waitTime = state.chatInterval - (now - chat.lastSentAt)
        if waitTime > 0 then
            chat.inFlight = false
            tell("Chat: повторная отправка доступна через "
                .. tostring(math.ceil(waitTime)) .. " с")
            return
        end
        local channel, channelError = currentChatChannel()
        if not channel then
            chat.inFlight = false
            chat.sendStatus = channelError
            chat.errors = chat.errors + 1
            chat.repaintStatus()
            tell("Chat: " .. channelError)
            return
        end
        local message = state.chatMessage
        chat.lastSentAt = now
        chat.sendStatus = "SENDING"
        chat.repaintStatus()
        -- SendAsync yields: нельзя отменить уже начатую отправку, но токен
        -- не позволяет обновлять состояние после Unload/нового включения.
        local token = chat.token
        local ok, reply = pcall(function() return channel:SendAsync(message) end)
        chat.inFlight = false
        if not alive or token ~= chat.token then return end
        if not ok then
            chat.sendStatus, chat.errors = "API ERROR", chat.errors + 1
            tell("Chat: ошибка отправки: " .. tostring(reply))
        else
            -- В режиме Platform-Integrated Chat Roblox может вернуть "".
            -- Проверять PlatformIntegratedChat из LocalScript нельзя: защищённое свойство.
            if type(reply) ~= "userdata" and typeof(reply) ~= "Instance" then
                chat.sendStatus = "UNSUPPORTED / EMPTY RESULT"
                chat.errors = chat.errors + 1
                tell("Chat: SendAsync не поддерживается в режиме этой игры; "
                    .. "отправляй сообщения через встроенный чат Roblox")
            else
                local okStatus, status = pcall(function() return reply.Status end)
                chat.sendStatus = okStatus and status and status.Name or "UNKNOWN"
                if okStatus and status == Enum.TextChatMessageStatus.Success then
                    chat.sent = chat.sent + 1
                    chat.errors = 0
                else
                    chat.errors = chat.errors + 1
                end
                tell("Chat: локальный статус " .. chat.sendStatus ..
                    " (доставку получателям проверяй на втором клиенте)")
            end
        end
        chat.repaintStatus()
    end
end

-- Сохраняем только ограниченный набор настроек; код из JSON никогда не выполняется.
local HttpService = game:GetService("HttpService")
local storedKeys = {
    "esp", "tracers", "names", "health", "distance", "teamColors", "espBox", "espSkeleton",
    "espEnemyOnly", "espRangeMeters", "espColorPreset", "espLineThickness", "performanceMode",
    "performanceGuard", "moduleCpuMonitor", "lazyLoading",
    "sessionDiagnostics",
    "aimbot", "aimRangeMeters", "aimSmoothness", "aimSmoothX", "aimSmoothY",
    "prediction", "predictionSeconds", "targetLock", "aimFovPixels", "aimMode",
    "aimOnlyRegisteredWeapons", "aimWeaponNames",
    "fovVisible", "fovThickness", "visibleCheck", "teamCheck", "fullbright", "booster",
    "antiAfk", "airAlerts", "hud", "activeHud", "aimKeyName", "controlRecoil", "recoilStrength", "boosterMode",
    "bunnyHop", "bhopJumpInterval", "bhopSpeedMultiplier", "spamChat", "chatInterval", "chatMessage",
    "cameraFovEnabled", "cameraFovDegrees", "antiAim", "antiAimSpeed", "antiAimTilt",
}
local numericRules = {
    espRangeMeters = {10, 200}, espLineThickness = {1, 2},
    aimRangeMeters = {5, 180}, aimSmoothness = {0, 10},
    aimSmoothX = {1, 10}, aimSmoothY = {1, 10},
    predictionSeconds = {0, 0.25}, aimFovPixels = {40, 400},
    fovThickness = {1, 4}, recoilStrength = {0, 100},
    bhopJumpInterval = {CONFIG.BhopMinInterval, CONFIG.BhopMaxInterval},
    bhopSpeedMultiplier = {1, CONFIG.BhopSpeedMultiplierCap},
    chatInterval = {CONFIG.ChatMinInterval, CONFIG.ChatMaxInterval},
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
-- Текст и интервал чата — глобальные настройки, независимо от LEGIT/RAGE/CUSTOM.
local chatPreferences = {}
local weaponPreferences = {}
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
                if key == "aimWeaponNames" then
                    result[key] = incoming:sub(1, 400)
                elseif key == "chatMessage" then
                    local value = incoming:gsub("[%c]", " "):gsub("^%s+", ""):gsub("%s+$", "")
                    local count = utf8.len(value)
                    if count then
                        if count > CONFIG.ChatMaxCodepoints then
                            local stopAt = utf8.offset(value, CONFIG.ChatMaxCodepoints + 1)
                            if stopAt then value = value:sub(1, stopAt - 1) end
                        end
                        result[key] = value
                    end
                elseif key == "aimKeyName" then
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
    chatPreferences.chatMessage = state.chatMessage
    chatPreferences.chatInterval = state.chatInterval
    weaponPreferences.aimOnlyRegisteredWeapons = state.aimOnlyRegisteredWeapons
    weaponPreferences.aimWeaponNames = state.aimWeaponNames
    local data = {version = 1, current = profileName,
        profiles = {CUSTOM = profiles.CUSTOM or {}},
        chatPreferences = chatPreferences,
        weaponPreferences = weaponPreferences}
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
        if type(loaded.weaponPreferences) == "table" then
            local prefs = validatedSettings({
                aimOnlyRegisteredWeapons = loaded.weaponPreferences.aimOnlyRegisteredWeapons,
                aimWeaponNames = loaded.weaponPreferences.aimWeaponNames,
            })
            weaponPreferences.aimOnlyRegisteredWeapons = prefs.aimOnlyRegisteredWeapons
            weaponPreferences.aimWeaponNames = prefs.aimWeaponNames
        end
        if type(loaded.chatPreferences) == "table" then
            local prefs = validatedSettings({
                chatMessage = loaded.chatPreferences.chatMessage,
                chatInterval = loaded.chatPreferences.chatInterval,
            })
            chatPreferences.chatMessage = prefs.chatMessage
            chatPreferences.chatInterval = prefs.chatInterval
        end
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
    -- Миграция: старые профили могли сохранить толстые линии (2-4 px).
    -- При первом запуске новой версии используем тонкий стиль 1 px.
    if autoLoad then state.espLineThickness = 1 end
    -- Автозагрузка не активирует боевые действия и вращение тела.
    -- Даже если в сохранённом CUSTOM antiAim=true, старт остаётся безопасным.
    if autoLoad then
        state.aimbot = false
        -- Старая сохраненная версия не включает AIM с любым Tool.
        -- Первую регистрацию оружия пользователь делает вручную в AIM.
        state.aimOnlyRegisteredWeapons = true
        state.airAlerts = false -- Высокая нагрузка фонового мониторинга, ON только вручную.
        state.sessionDiagnostics = false -- Анализ логов только по ручному запросу.
        state.moduleCpuMonitor = false -- Тяжёлая телеметрия включается вручную.
        state.antiAfk = false
        state.antiAim = false
        state.bunnyHop = false
        state.spamChat = false
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
            state.bunnyHop = false
            state.spamChat = false
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
    perfCounters.session.setEnabled(state.sessionDiagnostics)
    perfCounters.lazy.prepare()
    if not state.performanceGuard then perfCounters.guard.reset() end
    if not state.moduleCpuMonitor then perfCounters.cpu.reset() end
    utilityFX.bunny.sync()
    utilityFX.chat.sync()
    utilityFX.chat.repaintText()
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
    if type(weaponPreferences.aimOnlyRegisteredWeapons) == "boolean" then
        values.aimOnlyRegisteredWeapons = weaponPreferences.aimOnlyRegisteredWeapons
    end
    if type(weaponPreferences.aimWeaponNames) == "string" then
        values.aimWeaponNames = weaponPreferences.aimWeaponNames
    end
    if type(chatPreferences.chatMessage) == "string" then
        values.chatMessage = chatPreferences.chatMessage
    end
    if type(chatPreferences.chatInterval) == "number" then
        values.chatInterval = chatPreferences.chatInterval
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
    panel = Color3.fromRGB(23, 28, 32),
    tile = CONFIG.Surface,
    border = Color3.fromRGB(64, 73, 81),
    text = Color3.fromRGB(235, 238, 240),
    dim = CONFIG.Muted,
    accent = CONFIG.Accent,
    off = Color3.fromRGB(55, 62, 69),
}
-- На телефоне даже альбомный экран остаётся одноколоночным: элементы
-- управления не должны уменьшаться до нечитабельного размера.
local wideLayout = (not UserInputService.TouchEnabled) and viewport.X >= 770
local function windowMetrics(view)
    local mobile = UserInputService.TouchEnabled
    local wide = (not mobile) and view.X >= 770
    local landscape = view.X > view.Y
    local availableWidth = math.max(160, view.X - (mobile and 22 or 32))
    local preferredWidth = wide and 960 or (mobile and landscape and 520 or 410)
    local width = math.min(availableWidth, preferredWidth)
    local availableHeight = math.max(120, view.Y - (mobile and 22 or 38))
    local height = math.min(wide and 624 or 610, availableHeight)
    return width, height, wide
end
local winWidth, winHeight = windowMetrics(viewport)
local panel = mk("Frame", {
    Name = "CommunityVisualsPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(winWidth, winHeight),
    BackgroundColor3 = P.background,
    BorderSizePixel = 0,
    Active = true, ClipsDescendants = true,
}, gui)
round(panel, 4)
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
local panelTween = nil
local function tweenPanel(toScale)
    if panelTween then panelTween:Cancel(); panelTween = nil end
    local ok, tween = pcall(function()
        return TweenService:Create(panelScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out), {Scale = toScale})
    end)
    if ok and tween then panelTween = tween; tween:Play()
    else panelScale.Scale = toScale end
end
local function hidePanelAnimation()
    if panelTween then panelTween:Cancel(); panelTween = nil end
    panelScale.Scale = 1
end
-- The accent mark is inexpensive; no animated gradients, glow or overlays.
mk("Frame", {
    Name = "TopAccent", BorderSizePixel = 0,
    BackgroundColor3 = P.accent,
    Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(83, 2),
}, panel)
local bar = mk("Frame", {
    Name = "DragBar", BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 74), Active = true,
}, panel)
local emblem = mk("Frame", {
    Name = "BrandMark", BackgroundColor3 = P.tile,
    BorderSizePixel = 0, Position = UDim2.fromOffset(16, 17),
    Size = UDim2.fromOffset(37, 37),
}, bar)
round(emblem, 3)
mk("UIStroke", {Color = P.accent, Thickness = 1, Transparency = 0.53}, emblem)
mk("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
    Text = "124", Font = Enum.Font.GothamBold,
    TextColor3 = P.accent, TextSize = 13,
}, emblem)
mk("TextLabel", {
    Name = "BrandTitle", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(66, 16), Size = UDim2.new(1, -183, 0, 21),
    Text = "124 / COMMUNITY", TextColor3 = P.text, TextSize = 14,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, bar)
mk("TextLabel", {
    Name = "BrandCaption", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(66, 38), Size = UDim2.new(1, -183, 0, 16),
    Text = "OPERATOR  /  v" .. CONFIG.Version,
    TextColor3 = P.dim, Font = Enum.Font.Code,
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, bar)
local pageHeader = mk("TextLabel", {
    Name = "CurrentPageTitle", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(206, 15), Size = UDim2.new(1, -335, 0, 29),
    Text = "ОБЗОР", TextColor3 = P.text, TextSize = 19,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    Visible = false, TextTruncate = Enum.TextTruncate.AtEnd,
}, bar)
local pageSubHeader = mk("TextLabel", {
    Name = "CurrentPageSubtitle", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(207, 46), Size = UDim2.new(1, -336, 0, 16),
    Text = "Мониторинг локальной сессии",
    TextColor3 = P.dim, TextSize = 11, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, Visible = false,
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

-- Sidebar on desktop; bottom navigation stays accessible on small screens.
local tabs = mk("Frame", {
    Name = "VisualsNavigation", BackgroundColor3 = P.panel, BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -57), Size = UDim2.new(1, 0, 0, 57),
}, panel)
round(tabs, 3)
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
local navigationLayout = mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
}, navSlots)
local tabButtons, tabUnderline, tabOutlines, pages, pageColumns = {}, {}, {}, {}, {}
local currentPage = "HOME"
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
    {key = "HOME", label = "Обзор", symbol = "01"},
    {key = "ESP", label = "ESP", symbol = "02"},
    {key = "AIM", label = "AIM", symbol = "03"},
    {key = "MISC", label = "Производительность", symbol = "04"},
    {key = "CFG", label = "Настройки", symbol = "05"},
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
    round(scroll, 3)
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
        Size = UDim2.new(0.2, -9, 0, 40),
        Text = tab.symbol .. "  " .. tab.label,
        Font = Enum.Font.GothamMedium, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = P.dim, AutoButtonColor = false,
    }, navSlots)
    round(button, 6)
    tabOutlines[key] = mk("UIStroke", {Color = P.border, Transparency = 1, Thickness = 1}, button)
    tabButtons[key] = button
    tabUnderline[key] = mk("Frame", {
        Name = "ActiveLine", BackgroundColor3 = P.accent,
        BorderSizePixel = 0, Position = UDim2.new(0.5, -11, 1, -3),
        Size = UDim2.fromOffset(22, 2), Visible = false,
    }, button)
    local page = mk("Frame", {
        Name = key .. "Page", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 82),
        Size = UDim2.new(1, -24, 1, -155),
        Visible = key == "HOME",
    }, panel)
    pages[key] = page
    if key ~= "HOME" then
        pageColumns[page] = {
            left = makeColumn(page, key .. "Left"),
            right = makeColumn(page, key .. "Right"),
            side = "left", widgets = {}, order = 0,
        }
    end
end
-- Dashboard visual reference: graphite operator layout with live metrics.
-- It does not create new RenderStepped handlers, only updates from existing workers.
do
    local home = pages.HOME
    local dash = {history = {}, bars = {}, cards = {}, lastSlowAt = -1e8}
    boosterPro.dashboard = dash
    local scroller = mk("ScrollingFrame", {
        Name = "DashboardScroll", BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), ScrollBarThickness = 3,
        ScrollBarImageColor3 = P.accent, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromScale(0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
        Active = true,
    }, home)
    table.insert(scrollFrames, scroller)
    local content = mk("Frame", {
        Name = "DashboardContent", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -18, 0, 490),
    }, scroller)
    local dashboardTitle = mk("TextLabel", {
        Name = "DashboardTitle", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(5, 2), Size = UDim2.new(1, -10, 0, 33),
        Text = "ОБЗОР СЕССИИ", TextColor3 = P.text, TextSize = 17,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    }, content)
    local dashboardSubtitle = mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 37),
        Size = UDim2.new(1, -10, 0, 19),
        Text = "Измерения локальной сессии",
        TextColor3 = P.dim, TextSize = 11, Font = Enum.Font.Gotham,
        TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left,
    }, content)
    dash.titleLabel, dash.subtitleLabel = dashboardTitle, dashboardSubtitle
    local cardsFrame = mk("Frame", {
        Name = "Metrics", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 73), Size = UDim2.new(1, 0, 0, 105),
    }, content)
    local cardSpec = {
        {"fps", "FPS", "LIVE", "КАДРЫ / СЕК"},
        {"low", "1% LOW", "FRAME", "СТАБИЛЬНОСТЬ"},
        {"ping", "PING", "NET", "ЗАДЕРЖКА"},
        {"esp", "ESP", "PLAYERS", "АКТИВНЫЕ МЕТКИ"}
    }
    for index, spec in ipairs(cardSpec) do
        local card = mk("Frame", {
            Name = "Metric_" .. spec[1], BackgroundColor3 = P.tile,
            BorderSizePixel = 0, Size = UDim2.fromOffset(120, 105),
        }, cardsFrame)
        round(card, 3)
        mk("UIStroke", {Color = P.border, Transparency = 0.28, Thickness = 1}, card)
        mk("Frame", {Name = "MetricRule", BorderSizePixel = 0,
            Position = UDim2.fromOffset(13, 9), Size = UDim2.fromOffset(18, 2),
            BackgroundColor3 = P.accent}, card)
        mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(13, 14),
            Size = UDim2.new(1, -26, 0, 17), Text = spec[2],
            TextColor3 = P.dim, Font = Enum.Font.Code,
            TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        local value = mk("TextLabel", {
            Name = "Value", BackgroundTransparency = 1,
            Position = UDim2.fromOffset(13, 35), Size = UDim2.new(1, -26, 0, 30),
            Text = "--", TextColor3 = P.text, Font = Enum.Font.GothamBold,
            TextSize = 21, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)
        mk("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(13, 73), Size = UDim2.new(1, -26, 0, 18),
            Text = spec[4], TextColor3 = P.dim, Font = Enum.Font.Code,
            TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)
        dash.cards[spec[1]] = {root = card, value = value, index = index}
    end
    local chart = mk("Frame", {
        Name = "PerformanceHistory", BackgroundColor3 = P.panel,
        BorderSizePixel = 0, Position = UDim2.fromOffset(0, 202),
        Size = UDim2.new(0.66, -7, 0, 242),
    }, content)
    round(chart, 3)
    mk("UIStroke", {Color = P.border, Transparency = 0.25}, chart)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(17, 12),
        Size = UDim2.new(1, -34, 0, 26),
        Text = "ИСТОРИЯ FPS", Font = Enum.Font.GothamBold,
        TextColor3 = P.text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    }, chart)
    local chartArea = mk("Frame", {
        Name = "FPSBars", BackgroundColor3 = P.background, BorderSizePixel = 0,
        Position = UDim2.fromOffset(16, 51), Size = UDim2.new(1, -32, 1, -67),
        ClipsDescendants = true,
    }, chart)
    round(chartArea, 6)
    for i = 1, 16 do
        local bar = mk("Frame", {
            Name = "Sample" .. i, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new((i - 1)/16, 3, 1, -7),
            Size = UDim2.new(1/16, -6, 0.06, 0),
            BackgroundColor3 = P.accent,
            BackgroundTransparency = 0.15,
        }, chartArea)
        dash.bars[i] = bar
    end
    local actions = mk("Frame", {
        Name = "QuickActions", BackgroundColor3 = P.panel,
        BorderSizePixel = 0, Position = UDim2.new(0.66, 7, 0, 202),
        Size = UDim2.new(0.34, -7, 0, 242),
    }, content)
    round(actions, 3)
    mk("UIStroke", {Color = P.border, Transparency = 0.25}, actions)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(13, 12),
        Size = UDim2.new(1, -26, 0, 25),
        Text = "БЫСТРЫЕ ДЕЙСТВИЯ", TextColor3 = P.text,
        TextSize = 14, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, actions)
    local actionList = mk("Frame", {
        Name = "ActionList", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 1, -58),
    }, actions)
    mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 7)}, actionList)
    local function action(caption, hint, callback)
        local button = mk("TextButton", {
            Name = "Action_" .. caption:gsub("[^%w]", ""),
            LayoutOrder = #actionList:GetChildren(),
            Size = UDim2.new(1, 0, 0, 39),
            Text = "  " .. caption .. "     ›",
            BackgroundColor3 = P.tile, BorderSizePixel = 0,
            AutoButtonColor = true, TextColor3 = P.text,
            Font = Enum.Font.GothamMedium, TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, actionList)
        round(button, 6)
        mk("UIStroke", {Color = P.border, Transparency = 0.38}, button)
        safeActivate(button, function()
            if not alive then return end
            local ok, err = pcall(callback)
            if not ok then tell("Dashboard: " .. tostring(err)) end
        end)
        return button
    end
    action("Open Performance", "", function()
        if dash.openSettings then dash.openSettings() end
    end)
    action("Enable ECO", "", function()
        state.performanceMode = "ECO"
        pcall(repaintPerf)
        requestSave()
        tell("Visuals: ECO включён")
    end)
    action("Toggle Guard", "", function()
        state.performanceGuard = not state.performanceGuard
        perfCounters.guard.reset()
        if refreshToggles.performanceGuard then
            pcall(refreshToggles.performanceGuard)
        end
        requestSave()
        tell("Performance Guard: " .. (state.performanceGuard and "ON" or "OFF"))
    end)
    action("Safety Stop", "", function()
        -- Two deliberate presses prevent accidental unload on touch devices.
        local now = os.clock()
        if (dash.safeStopArmedUntil or 0) < now then
            dash.safeStopArmedUntil = now + 4
            tell("Safety Stop: нажми кнопку ещё раз в течение 4 секунд")
            return
        end
        dash.safeStopArmedUntil = 0
        if cleanup then cleanup(true) end
    end)
    local info = mk("Frame", {
        Name = "FooterBanner", BackgroundColor3 = P.tile,
        Position = UDim2.fromOffset(0, 462), Size = UDim2.new(1, 0, 0, 64),
        BorderSizePixel = 0,
    }, content)
    round(info, 3)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(17, 9),
        Size = UDim2.new(1, -30, 0, 20),
        Text = "124 Community Visuals", Font = Enum.Font.GothamBold,
        TextSize = 13, TextColor3 = P.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, info)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(17, 33),
        Size = UDim2.new(1, -30, 0, 19),
        Text = "Local Roblox stats • No system changes or simulated FPS gains",
        TextColor3 = P.dim, Font = Enum.Font.Gotham,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, info)
    local sideStatus = mk("TextLabel", {
        Name = "SidebarStatus", Visible = false, BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 1, -42), Size = UDim2.fromOffset(160, 23),
        Text = "●  CLIENT ACTIVE", TextColor3 = Color3.fromRGB(96, 209, 148),
        Font = Enum.Font.GothamMedium, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, tabs)
    dash.sidebarStatus = sideStatus
    dash.layout = function(wide)
        local cellH = wide and 105 or 91
        dash.titleLabel.Visible = not wide
        dash.subtitleLabel.Visible = not wide
        cardsFrame.Position = UDim2.fromOffset(0, wide and 12 or 73)
        cardsFrame.Size = UDim2.new(1, 0, 0, wide and 105 or 193)
        for _, card in pairs(dash.cards) do
            local i = card.index - 1
            if wide then
                card.root.Position = UDim2.new(i / 4, 0, 0, 0)
                card.root.Size = UDim2.new(0.25, -8, 0, cellH)
            else
                card.root.Position = UDim2.new(i % 2 / 2, 0, 0, math.floor(i / 2) * 100)
                card.root.Size = UDim2.new(0.5, -7, 0, cellH)
            end
        end
        if wide then
            chart.Position = UDim2.fromOffset(0, 143)
            chart.Size = UDim2.new(0.66, -7, 0, 242)
            actions.Position = UDim2.new(0.66, 7, 0, 143)
            actions.Size = UDim2.new(0.34, -7, 0, 242)
            info.Position = UDim2.fromOffset(0, 403)
            content.Size = UDim2.new(1, -18, 0, 480)
        else
            chart.Position = UDim2.fromOffset(0, 295)
            chart.Size = UDim2.new(1, 0, 0, 190)
            actions.Position = UDim2.fromOffset(0, 495)
            actions.Size = UDim2.new(1, 0, 0, 237)
            info.Position = UDim2.fromOffset(0, 746)
            content.Size = UDim2.new(1, -18, 0, 823)
        end
        sideStatus.Visible = wide
    end
    dash.push = function(fps)
        local history = dash.history
        if #history >= 16 then table.remove(history, 1) end
        history[#history + 1] = math.clamp(fps, 0, 240)
        dash.historyVersion = (dash.historyVersion or 0) + 1
    end
    dash.update = function()
        if not alive or not panel.Visible or not home.Visible then return end
        dash.cards.fps.value.Text = tostring(measuredFps) .. " FPS"
        dash.cards.esp.value.Text = tostring(perfCounters.espCount) .. " active"
        local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
        dash.cards.ping.value.Text = ok and type(ping) == "number"
            and (tostring(math.floor(ping * 1000 + 0.5)) .. " ms") or "-- ms"
        if os.clock() - dash.lastSlowAt >= 3 then
            dash.lastSlowAt = os.clock()
            local summary = perfCounters.frametime.summary()
            local low = summary:match("1%% Low (%d+) FPS")
            dash.cards.low.value.Text = low and (low .. " FPS") or "-- FPS"
        end
        if dash.drawnVersion ~= dash.historyVersion then
            for i = 1, 16 do
                local value = dash.history[i] or 0
                dash.bars[i].Size = UDim2.new(1/16, -6,
                    math.clamp(value / 120, 0.06, 0.96), 0)
            end
            dash.drawnVersion = dash.historyVersion
        end
    end
end

-- Каждый элемент сохраняет свой логический столбец. После поворота телефона
-- элементы безопасно переподключаются, сохраняя LayoutOrder и обработчики.
local sectionSides = {
    ["VISUALS"] = "left", ["ESP OPTIONS"] = "right",
    ["TARGETING"] = "left", ["ADVANCED"] = "right",
    ["FOV EDITOR"] = "right", ["CONTROL"] = "right", ["RECOIL CONTROL"] = "right",
    ["UTILITY"] = "left", ["PERFORMANCE"] = "right",
    ["CAMERA FOV"] = "left", ["ANTI-AIM"] = "right",
    ["BUNNY HOP"] = "left", ["CHAT TOOLS"] = "right",
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
    pageHeader.Visible, pageSubHeader.Visible = wide, wide
    if wide then
        -- Desktop: screenshot-inspired left sidebar; real contents on the right.
        tabs.Position = UDim2.fromOffset(0, 0)
        tabs.Size = UDim2.new(0, 188, 1, 0)
        navSlots.Position = UDim2.fromOffset(0, 87)
        navSlots.Size = UDim2.new(1, 0, 1, -150)
        navigationLayout.FillDirection = Enum.FillDirection.Vertical
        navigationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        navigationLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        navigationLayout.Padding = UDim.new(0, 8)
    else
        -- Mobile: five evenly sized buttons in a bottom row.
        tabs.Position = UDim2.new(0, 0, 1, -57)
        tabs.Size = UDim2.new(1, 0, 0, 57)
        navSlots.Position = UDim2.fromOffset(0, 1)
        navSlots.Size = UDim2.new(1, 0, 1, -1)
        navigationLayout.FillDirection = Enum.FillDirection.Horizontal
        navigationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        navigationLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        navigationLayout.Padding = UDim.new(0, 4)
    end
    for _, nav in ipairs(navigation) do
        local button = tabButtons[nav.key]
        if wide then
            button.Size = UDim2.new(1, -18, 0, 44)
            button.Text = "   " .. nav.symbol .. "    " .. nav.label
            button.TextSize = 12
            button.TextXAlignment = Enum.TextXAlignment.Left
            tabUnderline[nav.key].Position = UDim2.fromOffset(0, 4)
            tabUnderline[nav.key].Size = UDim2.new(0, 3, 1, -8)
        else
            button.Size = UDim2.new(0.2, -9, 0, 40)
            local short = nav.key == "MISC" and "PERF" or nav.key
            button.Text = short
            button.TextSize = width < 355 and 9 or 10
            button.TextXAlignment = Enum.TextXAlignment.Center
            tabUnderline[nav.key].Position = UDim2.new(0.5, -11, 1, -3)
            tabUnderline[nav.key].Size = UDim2.fromOffset(22, 2)
        end
    end
    for _, page in pairs(pages) do
        if wide then
            page.Position = UDim2.fromOffset(198, 82)
            page.Size = UDim2.new(1, -211, 1, -99)
        else
            page.Position = UDim2.fromOffset(12, 82)
            page.Size = UDim2.new(1, -24, 1, -155)
        end
        local info = pageColumns[page]
        if info then
            if wide then
                info.left.Position = UDim2.fromOffset(0, 0)
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
    if boosterPro.dashboard then boosterPro.dashboard.layout(wide) end
    local brandTitle = bar:FindFirstChild("BrandTitle")
    local brandCaption = bar:FindFirstChild("BrandCaption")
    if brandTitle then
        brandTitle.Size = wide and UDim2.fromOffset(122, 21) or UDim2.new(1, -183, 0, 21)
        brandTitle.TextSize = wide and 12 or 15
    end
    if brandCaption then
        brandCaption.Size = wide and UDim2.fromOffset(122, 16) or UDim2.new(1, -183, 0, 16)
    end
end

local function showPage(key)
    if not pages[key] then return end
    if key ~= "AIM" and captureAimKey then
        captureAimKey = false
        repaintAimKeybind()
    end
    currentPage = key
    local titles = {HOME = "Dashboard", ESP = "Visuals", AIM = "Aim",
        MISC = "Performance", CFG = "Settings"}
    local descriptions = {HOME = "Live game performance and optimization overview",
        ESP = "Player overlays and visibility controls",
        AIM = "Targeting, weapon filters and FOV",
        MISC = "Client graphics, monitoring and performance",
        CFG = "Profiles, preferences and recovery"}
    pageHeader.Text = titles[key] or key
    pageSubHeader.Text = descriptions[key] or ""
    for name, page in pairs(pages) do
        local selected = name == key
        page.Visible = selected
        tabButtons[name].BackgroundColor3 = selected and P.tile or P.panel
        tabButtons[name].TextColor3 = selected and P.text or P.dim
        tabButtons[name].Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium
        tabUnderline[name].Visible = selected
        tabOutlines[name].Transparency = selected and 0.44 or 1
    end
end
for name, button in pairs(tabButtons) do
    safeActivate(button, function() showPage(name) end)
end
boosterPro.dashboard.openSettings = function() showPage("MISC") end
applyResponsiveLayout()
showPage("HOME")
local currentLayoutCamera = nil
local cameraLayoutConnection = nil
local layoutPending = false
local function queueResponsiveLayout()
    if not alive or layoutPending then return end
    layoutPending = true
    task.defer(function()
        layoutPending = false
        if alive and panel.Parent then
            local ok, err = pcall(applyResponsiveLayout)
            if not ok then warn("[124 Community Visuals] Layout: " .. tostring(err)) end
        end
    end)
end
local function trackLayoutCamera()
    local camera = Workspace.CurrentCamera
    if camera == currentLayoutCamera then return end
    if cameraLayoutConnection then
        pcall(function() cameraLayoutConnection:Disconnect() end)
        cameraLayoutConnection = nil
    end
    currentLayoutCamera = camera
    if camera then
        cameraLayoutConnection = connect(camera:GetPropertyChangedSignal("ViewportSize"),queueResponsiveLayout)
    end
end
trackLayoutCamera()
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    if alive then trackLayoutCamera(); queueResponsiveLayout() end
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
    if camera and (not tracerGui or not tracerGui.Parent) then
        perfCounters.lazy.ensureTracer()
    end
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
        local head, root, hum = data.head, data.root, data.humanoid
        local visible = false
        local screenPosition
        if data.inactiveSince == nil and player.Parent == Players and ch == player.Character
            and hum and hum.Parent == ch and hum.Health > 0
            and head and head.Parent == ch and root and root.Parent == ch
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
                    BackgroundColor3 = CONFIG.Neutral, BackgroundTransparency = 0.38,
                    BorderSizePixel = 0, ZIndex = 1,
                }, tracerGui)
            end
            local goal2d = Vector2.new(screenPosition.X, screenPosition.Y)
            local vector = goal2d - source
            local length = vector.Magnitude
            setIfDifferent(data.tracer, "Visible", length > 2)
            if length > 2 then
                setIfDifferent(data.tracer, "Size", UDim2.fromOffset(length, 1))
                setIfDifferent(data.tracer, "Position",
                    UDim2.fromOffset((goal2d.X + source.X) / 2, (goal2d.Y + source.Y) / 2))
                setIfDifferent(data.tracer, "Rotation", math.deg(math.atan2(vector.Y, vector.X)))
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
        BackgroundTransparency = 0.22, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Visible = false,
        Size = UDim2.fromOffset(1, 1)}, parent)
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
    if camera and (not shapeGui or not shapeGui.Parent) then
        perfCounters.lazy.ensureShapes()
    end
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
    local tier = visualPerfTier()
    local shapeBudget = tier == "ECO" and CONFIG.EspShapeEcoLimit
        or tier == "QUALITY" and CONFIG.EspShapeQualityLimit
        or CONFIG.EspShapeBalancedLimit
    if state.performanceGuard and perfCounters.guard.level == 2 then
        shapeBudget = math.min(shapeBudget, CONFIG.GuardShapeMaxL2)
    elseif state.performanceGuard and perfCounters.guard.level == 1 then
        shapeBudget = math.min(shapeBudget, CONFIG.GuardShapeMaxL1)
    end
    table.clear(active)
    -- Отрисовываем в том же порядке, что и ближайших игроков в ESP.
    -- Никогда не проверяем части персонажей после заполнения лимита.
    local projected = perfCounters.espVisual.projected
    for _, player in ipairs(perfCounters.espVisual.ordered) do
        if activeCount >= shapeBudget then break end
        local info = renderData[player]
        local char = info and info.character
        local head, root, hum = info and info.head, info and info.root, info and info.humanoid
        if info and player.Parent == Players and head and head.Parent == char
            and root and root.Parent == char and hum and hum.Parent == char
            and hum.Health > 0 and player.Character == char
            and (not state.espEnemyOnly or not sameTeamESP(player))
            and (root.Position - myRoot.Position).Magnitude * CONFIG.StudMeters <= state.espRangeMeters then
            active[player] = true
            local item = shapeItem(player, char)
            item.inactiveSince = nil
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
    local now, cached = os.clock(), 0
    for player, item in pairs(shapeData) do
        if not active[player] then
            hideShape(item)
            local invalid = player.Parent ~= Players or item.character ~= player.Character
                or not renderData[player] or not item.container.Parent
            local expired = item.inactiveSince
                and (now - item.inactiveSince >= CONFIG.EspCacheIdleSeconds)
            if invalid or expired or cached >= CONFIG.EspCacheMaxExtra then
                pcall(function() item.container:Destroy() end)
                shapeData[player] = nil
            else
                if not item.inactiveSince then item.inactiveSince = now end
                cached = cached + 1
            end
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
        BorderSizePixel = 0, Position = UDim2.fromOffset(4, 9),
        Size = UDim2.fromOffset(14, 2)}, container)
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
    round(row, 3)
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
    round(pill, 4)
    local knob = mk("Frame", {
        Name = "Knob", Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.fromRGB(222, 223, 227), BorderSizePixel = 0,
    }, pill)
    round(knob, 3)
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
    round(container, 3)
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
    round(container, 3)
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
    round(container, 3)
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

addSection(pages.ESP, "VISUALS", "Компактные подписи и тонкие ESP-линии")

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
addSlider(pages.ESP, "Толщина линий", "Box / Skeleton (1–2 px), Tracer всегда 1 px", "espLineThickness", 1, 2, 1,
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
addToggle(pages.AIM, "Aimbot", "Наведение только с экипированным Tool", "aimbot", function(enabled)
    setAimEnabled(enabled, false)
end)
addAimModeSelector(pages.AIM)
-- Без знаний об оружии игры не гадаем по названиям. Игрок может один раз
-- зарегистрировать экипированное огнестрельное Tool; только оно пройдёт фильтр.
addToggle(pages.AIM, "Только отмеченное оружие",
    "ON по умолчанию; сначала запомни реальное оружие", "aimOnlyRegisteredWeapons", function()
        aimPro.reset()
        repaintAimTouch()
    end)
addButton(pages.AIM, "Запомнить оружие в руках",
    "Зарегистрировать текущий Tool для AIM", function()
        local tool = aimPro.equipped
        local character = LocalPlayer.Character
        if not character or not tool or tool.Parent ~= character
            or not tool:IsA("Tool") then
            tell("AIM: сначала возьми оружие в руки")
            return
        end
        local name = tool.Name
        if #name > 60 or name:find("|", 1, true) then
            tell("AIM: имя инструмента слишком длинное или содержит |")
            return
        end
        local current = state.aimWeaponNames or ""
        local padded = "|" .. current .. "|"
        if not padded:find("|" .. name .. "|", 1, true) then
            if #current + #name + 1 > 400 then
                tell("AIM: список оружия заполнен")
                return
            end
            state.aimWeaponNames = current == "" and name or (current .. "|" .. name)
        end
        state.aimOnlyRegisteredWeapons = true
        aimPro.reset()
        if refreshToggles.aimOnlyRegisteredWeapons then
            refreshToggles.aimOnlyRegisteredWeapons()
        end
        repaintAimTouch()
        requestSave()
        tell("AIM: оружие " .. name .. " зарегистрировано")
    end)
addButton(pages.AIM, "Очистить список оружия",
    "Убрать разрешённые Tool и выключить строгий режим", function()
        state.aimWeaponNames = ""
        state.aimOnlyRegisteredWeapons = false
        aimPro.reset()
        if refreshToggles.aimOnlyRegisteredWeapons then
            refreshToggles.aimOnlyRegisteredWeapons()
        end
        repaintAimTouch()
        requestSave()
        tell("AIM: список оружия очищен")
    end)
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
addButton(pages.AIM, "Управление", "ПКМ: удерживать | клавиша: ON/OFF | телефон: AIM | нужен Tool", function()
    local tool = aimPro.equipped
    local eligible = aimPro.equippedTool() ~= nil
    tell("AIM: клавиша " .. state.aimKeyName .. " | FOV " .. state.aimFovPixels
        .. "px | Visible Check " .. (state.visibleCheck and "ON" or "OFF")
        .. " | Tool: " .. (tool and tool.Name or "НЕТ")
        .. " | Режим оружия: " .. (eligible and "OK" or "НЕТ / запомни Tool")
        .. " | Scan: " .. tostring(perfCounters.aimScanMs) .. " мс")
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
addToggle(pages.MISC, "Анализ логов",
    "OFF по умолчанию: LogService не обрабатывается в фоне",
    "sessionDiagnostics", function(enabled)
        perfCounters.session.setEnabled(enabled)
    end)
perfCounters.session.label = mk("TextLabel", {
    Name = "ClientSessionDiagnostics", BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38),
    Text = "Logs OFF | Warn 0 | Err 0 | Keywords 0",
    TextColor3 = CONFIG.Muted, Font = Enum.Font.Code,
    TextSize = 10, TextWrapped = true,
}, columnFor(pages.MISC))
registerWidget(pages.MISC, perfCounters.session.label)
round(perfCounters.session.label, 6)
addButton(pages.MISC, "Проверка клиентских предупреждений",
    "Не видит серверный античит и не определяет риск бана", function()
    tell(perfCounters.session.summary() .. " | Совпадения не доказывают наличие античита")
end)
addButton(pages.MISC, "Safety Stop — закрыть Visuals",
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
    -- A slow scan must never turn Booster off before it applies to the map.
    if not boosterPro.complete then return end
    local guardReady = boosterPro.readyAt
    if not guardReady or now < guardReady + 6 then return end
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
addButton(pages.MISC, "Сравнение FPS", "Реальные замеры после окончания обработки", function()
    tell("Booster Pro [" .. state.boosterMode .. "]: " .. boosterPro.readout()
        .. " | Проверено: " .. tostring(boosterPro.scanned)
        .. " | Очередь: " .. tostring(boosterPro.queueCount)
        .. " | Пропущено: " .. tostring(boosterPro.queueDropped)
        .. " | CPU max init/queue: "
        .. string.format("%.2f/%.2f ms", boosterPro.slicePeakMs,
            boosterPro.queuePeakMs))
end)
addButton(pages.MISC, "Диагностика Booster", "Режим, прогресс, изменения и ошибки обработки", function()
    local errorText = boosterPro.lastError and tostring(boosterPro.lastError):sub(1, 110)
        or "нет"
    tell("BOOSTER " .. tostring(boosterPro.phase)
        .. " | Включён: " .. tostring(state.booster)
        .. " | Режим: " .. tostring(state.boosterMode)
        .. " | Просмотрено: " .. tostring(boosterPro.scanned)
        .. " | Записано свойств: " .. tostring(boosterPro.changedProperties)
        .. " | Очередь: " .. tostring(boosterPro.queueCount)
        .. " | Переполнение: " .. tostring(boosterPro.queueDropped)
        .. " | Ошибка: " .. errorText)
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
addToggle(pages.MISC, "Performance Guard",
    "OFF по умолчанию; при просадке снижает только ESP, не AIM",
    "performanceGuard", function(enabled)
        perfCounters.guard.reset()
        perfCounters.guard.changed = os.clock() - CONFIG.GuardMinStepSeconds
        if not enabled then
            -- State is untouched; only effective visual budgets are restored.
            perfCounters.guard.reset()
        end
    end)
addToggle(pages.MISC, "Module CPU Monitor",
    "Измеряет время обработчиков AIM/Recoil/ESP; OFF для минимального overhead",
    "moduleCpuMonitor", function()
        perfCounters.cpu.reset()
    end)
addButton(pages.MISC, "Нагрузка модулей (avg / peak)",
    "Примерное время вызовов в мс, не общий процент CPU", function()
        tell(perfCounters.cpu.summary())
    end)
addToggle(pages.MISC, "Lazy Loading",
    "Создаёт ESP-слои только при первом включении функций",
    "lazyLoading", function()
        perfCounters.lazy.prepare()
    end)
addButton(pages.MISC, "Диагностика Performance",
    "Текущий Guard, число ESP-слоёв, AIM не ограничивается", function()
        tell(perfCounters.guard.description() .. " | lazy tracer "
            .. tostring(perfCounters.lazy.tracersCreated)
            .. " / shapes " .. tostring(perfCounters.lazy.shapesCreated)
            .. " | " .. (state.lazyLoading and "Lazy ON" or "Lazy OFF"))
    end)
perfCounters.guard.label = mk("TextLabel", {
    Name = "PerformanceGuardDiagnostics", Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
    Text = "Performance Guard: OFF", TextColor3 = CONFIG.Muted,
    Font = Enum.Font.Code, TextSize = 10, TextWrapped = true,
}, columnFor(pages.MISC))
registerWidget(pages.MISC, perfCounters.guard.label)
round(perfCounters.guard.label, 6)
local perfLabel = mk("TextLabel", {Name = "PerfDiagnostics", BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35),
    Text = "ESP 0 · Box 0 · Scan 0ms", TextColor3 = CONFIG.Muted,
    TextSize = 10, Font = Enum.Font.Code}, columnFor(pages.MISC))
registerWidget(pages.MISC, perfLabel)
round(perfLabel, 6)
perfCounters.frametime.label = mk("TextLabel", {
    Name = "FrameTimeDiagnostics",
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
    Text = "1% Low: замер... | p99: замер...",
    TextColor3 = CONFIG.Muted, TextSize = 10,
    Font = Enum.Font.Code, TextWrapped = true,
}, columnFor(pages.MISC))
registerWidget(pages.MISC, perfCounters.frametime.label)
round(perfCounters.frametime.label, 6)
addButton(pages.MISC, "Проверка микрофризов",
    "Показать 1% Low, p99, худший кадр и число задержек от 50 мс", function()
        tell(perfCounters.frametime.summary())
    end)
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
-- MOVEMENT: BHOP только при движении, оба параметра меняются без RenderStepped.
addSection(pages.MISC, "BUNNY HOP", "Прыжки на земле и настройка скорости")
addToggle(pages.MISC, "Bunny Hop", "Автопрыжки при движении, без телепортов", "bunnyHop", function()
    utilityFX.bunny.sync()
end)
addSlider(pages.MISC, "Задержка прыжков", "Меньше секунд = чаще попытки", "bhopJumpInterval",
    CONFIG.BhopMinInterval, CONFIG.BhopMaxInterval, 0.02,
    function(v) return string.format("%.2f сек", v) end)
addSlider(pages.MISC, "Скорость движения", "Множитель WalkSpeed, не накопление импульса", "bhopSpeedMultiplier",
    1, CONFIG.BhopSpeedMultiplierCap, 0.1,
    function(v) return string.format("%.1fx", v) end, function()
        utilityFX.bunny.applySpeed()
    end)
addButton(pages.MISC, "Статус Bunny Hop", "Проверить текущую скорость и переключатель", function()
    local b = utilityFX.bunny
    local hum = b.humanoid
    tell("BHOP " .. (state.bunnyHop and "ON" or "OFF")
        .. " | " .. tostring(state.bhopJumpInterval) .. " сек"
        .. " | x" .. tostring(state.bhopSpeedMultiplier)
        .. " | WalkSpeed " .. (hum and tostring(hum.WalkSpeed) or "н/д")
        .. (b.suspended and " | PAUSED: ждем исходный WalkSpeed" or ""))
end)

-- CHAT: only native authorized TextChannels; custom remote names are not send APIs.
addSection(pages.MISC, "CHAT TOOLS", "Только ручная отправка при разрешении Roblox")
local chatTextFrame = mk("Frame", {
    Name = "ChatCustomTextFrame", Size = UDim2.new(1, 0, 0, 78),
    BackgroundColor3 = CONFIG.Surface, BorderSizePixel = 0,
}, columnFor(pages.MISC))
registerWidget(pages.MISC, chatTextFrame)
round(chatTextFrame, 7)
mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, chatTextFrame)
mk("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 5),
    Size = UDim2.new(1, -20, 0, 18), Text = "Текст сообщения",
    TextColor3 = P.text, TextSize = 12, Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
}, chatTextFrame)
local chatTextBox = mk("TextBox", {
    Name = "CustomChatMessage",
    Position = UDim2.fromOffset(10, 28),
    Size = UDim2.new(1, -20, 0, 39),
    BackgroundColor3 = P.background,
    TextColor3 = P.text,
    PlaceholderColor3 = CONFIG.Muted,
    PlaceholderText = "Введи сообщение (до 160 символов)",
    Text = state.chatMessage,
    Font = Enum.Font.Gotham, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    MultiLine = false,
    TextWrapped = false,
    BorderSizePixel = 0,
}, chatTextFrame)
round(chatTextBox, 5)
mk("UIPadding", {PaddingLeft = UDim.new(0, 9),
    PaddingRight = UDim.new(0, 9)}, chatTextBox)
local chatEditing = false
utilityFX.chat.repaintText = function()
    if chatTextBox.Parent and not chatEditing and chatTextBox.Text ~= state.chatMessage then
        chatTextBox.Text = state.chatMessage
    end
end
connect(chatTextBox.Focused, function() chatEditing = true end)
-- Единая нормализация текста при потере фокуса и при ручной отправке.
utilityFX.chat.commitText = function()
    local value = chatTextBox.Text:gsub("[%c]", " ")
        :gsub("^%s+", ""):gsub("%s+$", "")
    local chars = utf8.len(value)
    if not chars then
        tell("Chat: некорректный UTF-8")
        utilityFX.chat.repaintText()
        return false
    end
    if chars > CONFIG.ChatMaxCodepoints then
        local cut = utf8.offset(value, CONFIG.ChatMaxCodepoints + 1)
        if cut then value = value:sub(1, cut - 1) end
    end
    if state.chatMessage ~= value then
        state.chatMessage = value
        requestSave()
    end
    if chatTextBox.Text ~= value then chatTextBox.Text = value end
    return value ~= ""
end
connect(chatTextBox.FocusLost, function()
    chatEditing = false
    utilityFX.chat.commitText()
    utilityFX.chat.repaintText()
end)
addSlider(pages.MISC, "Задержка сообщений", "Пауза между ручными отправками / напоминаниями", "chatInterval",
    CONFIG.ChatMinInterval, CONFIG.ChatMaxInterval, 1,
    function(v) return tostring(v) .. " сек" end,
    function() if state.spamChat then utilityFX.chat.sync() end end)
addToggle(pages.MISC, "Chat Timer", "Только напоминания, без автоотправки и обхода ограничений", "spamChat",
    function() utilityFX.chat.sync() end)
local chatStatus = mk("TextLabel", {
    Name = "ChatTimerStatus", BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 34),
    TextWrapped = true, TextSize = 10, Font = Enum.Font.Code,
    TextColor3 = P.dim, Text = "Chat Timer: OFF",
}, columnFor(pages.MISC))
registerWidget(pages.MISC, chatStatus)
round(chatStatus, 5)
utilityFX.chat.repaintStatus = function()
    if not chatStatus.Parent then return end
    local c = utilityFX.chat
    chatStatus.Text = "Timer: " .. tostring(c.timerStatus)
        .. " | Send: " .. tostring(c.sendStatus)
        .. " | " .. tostring(state.chatInterval) .. " с"
end
addButton(pages.MISC, "Отправить сообщение",
    "При разрешении Roblox; кастомный чат не обходит запрет",
    function() utilityFX.chat.sendOnce() end)
addButton(pages.MISC, "Проверить доступ к чату",
    "Проверяет CanUserChatAsync без отправки сообщения", function()
        local ok, allowed = pcall(function()
            return game:GetService("TextChatService"):CanUserChatAsync(LocalPlayer.UserId)
        end)
        local status = ok and (allowed == true and "ALLOWED" or "BLOCKED") or "UNKNOWN"
        utilityFX.chat.sendStatus = status
        utilityFX.chat.repaintStatus()
        tell(status == "ALLOWED" and "Chat: Roblox разрешает отправку при наличии TextChannel."
            or status == "BLOCKED" and
            "Chat: аккаунту недоступен текстовый чат по настройкам Roblox."
            or "Chat: не удалось прочитать разрешение Roblox.")
    end)
addButton(pages.MISC, "Статус чата", "Попытки отправки и готовность таймера", function()
    local c = utilityFX.chat
    tell("Chat " .. (state.spamChat and "TIMER ON" or "TIMER OFF")
        .. " | интервал " .. tostring(state.chatInterval) .. " с"
        .. " | локальных Success " .. tostring(c.sent)
        .. " | напоминаний " .. tostring(c.readyCount)
        .. " | ошибок " .. tostring(c.errors)
        .. " | таймер " .. tostring(c.timerStatus)
        .. " | отправка " .. tostring(c.sendStatus))
end)
utilityFX.chat.repaintStatus()

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
    Text = "124 COMMUNITY VISUALS   ·   v" .. CONFIG.Version .. "    ·    LOCAL SESSION",
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
    Text = "124  V", TextSize = 12,
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
        if state.bunnyHop then table.insert(risks, "Bunny Hop") end
        if state.spamChat then table.insert(risks, "Chat Timer") end
        if state.booster then table.insert(risks, "FPS Booster") end
        if state.cameraFovEnabled then table.insert(risks, "Camera FOV") end
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
        state.bunnyHop = false
        state.spamChat = false
        utilityFX.bunny.stop()
        utilityFX.chat.stop()
        if state.booster then
            state.booster = false
            setBooster(false)
        end
        state.cameraFovEnabled = false
        memoryFX.camera.reset()
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
        for _, other in ipairs(perfCounters.roster) do
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
            -- Без фонового мониторинга скрипт не просыпается каждые 0.45 сек.
            task.wait(state.airAlerts and mon.sampleInterval or 1.5)
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
    hidePanelAnimation()
    panel.Visible = false
    mini.Visible = true
    boosterPro.riskWarning.show()
end)
connect(mini.Activated, function()
    if miniMoving then return end
    hidePanelAnimation()
    panelScale.Scale = 0.98
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
    aimTouchButton.Text = active and (aimPro.equippedTool() and "AIM: ON" or "AIM: NO GUN")
        or "AIM: OFF"
    aimTouchButton.BackgroundColor3 = active and CONFIG.Accent or Color3.fromRGB(47, 48, 45)
    aimTouchButton.TextColor3 = active and CONFIG.Window or Color3.fromRGB(230, 224, 207)
end
aimPro.changed = function() if alive then repaintAimTouch() end end
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
    if not panel.Visible or input.Position.X >= bar.AbsolutePosition.X + bar.AbsoluteSize.X - 100 then
        return
    end
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
            if panel.Visible then
                hidePanelAnimation()
                panel.Visible = false
                mini.Visible = true
                boosterPro.riskWarning.show()
            else
                hidePanelAnimation()
                panelScale.Scale = 0.98
                panel.Visible = true
                mini.Visible = false
                tweenPanel(1)
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
    if not sliderDrag or sliderDrag.cancelled then return end
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
    -- Quiet-window repair: don't rescan the entire map while streaming is active.
    boosterPro.queueLastAt = os.clock()
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
                if i % 4 == 0 and
                    (os.clock() - sliceStarted) * 1000 >=
                        (measuredFps < 42 and CONFIG.BoosterLowFpsSliceMs
                            or CONFIG.BoosterQueueSliceMs) then
                    break
                end
            end
            local queueMs = (os.clock() - sliceStarted) * 1000
            boosterPro.queuePeakMs = math.max(boosterPro.queuePeakMs, queueMs)
            if state.moduleCpuMonitor then
                perfCounters.cpu.record("Booster Q", queueMs)
            end
        end
        -- Если StreamingEnabled переполнил кольцевую очередь,
        -- один фоновый повторный проход восстановит пропущенные детали.
        -- Проход ограничен тем же миллисекундным бюджетом; не бесконечный цикл.
        -- После нескольких переполнений допускаем новые проверки.
        -- Защита от вечного сканирования: максимум один запуск в 12 сек,
        -- не более трёх повторов при постоянной ошибке API.
        if state.booster and boosterPro.complete and boosterPro.queueCount == 0
            and boosterPro.queueDropped > boosterPro.repairCoveredDrops
            and not boosterPro.repairing and os.clock() >= boosterPro.repairRetryAt
            and os.clock() - boosterPro.queueLastAt >= CONFIG.BoosterRepairIdleSeconds
            and boosterPro.repairErrors < 3 then
            boosterPro.repairing = true
            boosterPro.repairRetryAt = os.clock() + CONFIG.BoosterRepairCooldown
            local repairRevision = boosterRevision
            local coveredDrops = boosterPro.queueDropped
            task.spawn(function()
                local ok, result = pcall(function()
                    return optimizeHierarchy(Workspace, repairRevision)
                        and optimizeHierarchy(Lighting, repairRevision)
                end)
                if not alive or not state.booster or repairRevision ~= boosterRevision then
                    return -- Новая ревизия владеет собственным состоянием.
                end
                boosterPro.repairing = false
                if ok and result then
                    boosterPro.repairCoveredDrops = coveredDrops
                    boosterPro.repairErrors = 0
                else
                    boosterPro.repairErrors = boosterPro.repairErrors + 1
                    if boosterPro.repairErrors <= 3 then
                        warn("[124 Community Visuals] Booster: повторный обход не завершён ("
                            .. tostring(boosterPro.repairErrors) .. "/3)")
                    end
                end
            end)
        end
        -- Не создаём пустой цикл на каждом Heartbeat во время repair:
        -- обработка очереди невозможна, пока идёт полный повторный обход.
        task.wait((not state.booster and 0.75)
            or (boosterPro.complete and not boosterPro.repairing
                and boosterPro.queueCount > 0
                and (measuredFps < 42 and CONFIG.BoosterQueueLowFpsDelay
                    or CONFIG.BoosterQueueDelay))
            or 0.20)
    end
end)

for _, property in ipairs(lightingProperties) do
    connect(Lighting:GetPropertyChangedSignal(property), function()
        if state.fullbright or (property == "GlobalShadows" and state.booster) then
            enforceLightingProperty(property)
        end
    end)
end

-- Чанковый откат вместо синхронной массовой записи свойств: каждый проход
-- отдаёт кадр после 16 объектов/2 мс. Работает и при hot reload.
function boosterPro.restoreGraphicsSliced()
    local started, count = os.clock(), 0
    for obj, snapshot in pairs(savedGraphics) do
        boosterPro.restoreObject(obj, snapshot)
        count = count + 1
        if count % 4 == 0 and ((os.clock() - started) * 1000 >=
            CONFIG.BoosterSliceMs or count % CONFIG.BoosterBatch == 0) then
            task.wait()
            started = os.clock()
        end
    end
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
        state.bunnyHop = false
        state.spamChat = false
        state.sessionDiagnostics = false
        state.booster = false
        state.cameraFovEnabled = false
        -- Если запись файла запрещена, защита на следующем запуске
        -- в рамках той же сессии executor всё равно сработает.
        env.ARMY124_SAFE_BOOT = true
    end
    pcall(flushConfig) -- Safety Stop сохраняет уже выключенные переключатели.
    releaseAntiAfk()
    utilityFX.bunny.stop() -- Сразу возвращаем исходную скорость при Unload.
    utilityFX.chat.stop() -- Прерываем ожидающую отправку и не посылаем сообщений.
    recoil.shutdown()
    perfCounters.session.setEnabled(false)
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
    state.bunnyHop = false
    state.spamChat = false
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
    -- Нагрузку распределяем по кадрам, сохраняя snapshots при частичном откате.
    boosterPro.restoreGraphicsSliced()
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
            boosterPro.restoreGraphicsSliced()
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
        warn("[124 Community Visuals] Откат графики/камеры/позы не завершён; данные сохранены для повтора")
    end
    for player in pairs(renderData) do deleteRender(player) end
    clearShapes()
    for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
    table.clear(connections)
    hidePanelAnimation()
    pcall(function() gui:Destroy() end)
    pcall(function() if tracerGui then tracerGui:Destroy() end end)
    pcall(function() if shapeGui then shapeGui:Destroy() end end)
    pcall(function() if fovGui then fovGui:Destroy() end end)
    if env.ARMY124_CLEANUP == cleanup then env.ARMY124_CLEANUP = nil end
    return true
end

env.ARMY124_CLEANUP = cleanup
-- LogService не подписывается при загрузке: включается только из MISC.
perfCounters.session.setEnabled(state.sessionDiagnostics)
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

perfCounters.cpu.wrapped.AIM = perfCounters.cpu.instrument("AIM", aimFrame)
perfCounters.cpu.wrapped.Recoil = perfCounters.cpu.instrument("Recoil", recoil.frame)
perfCounters.cpu.wrapped.ESPScan = perfCounters.cpu.instrument("ESP Scan", refreshESP)
local okBind, errBind = pcall(function()
    RunService:BindToRenderStep(aimBindingName, Enum.RenderPriority.Camera.Value + 2, perfCounters.cpu.wrapped.AIM)
end)
if okBind then
    aimBound = true
else
    tell("BindToRenderStep недоступен; используем RenderStepped")
    connect(RunService.RenderStepped, perfCounters.cpu.wrapped.AIM)
end

local okRecoilBind, errRecoilBind = pcall(function()
    RunService:BindToRenderStep(recoil.bindingName, Enum.RenderPriority.Camera.Value + 3, perfCounters.cpu.wrapped.Recoil)
end)
if okRecoilBind then
    recoil.bound = true
else
    tell("Recoil: BindToRenderStep недоступен — " .. tostring(errRecoilBind))
    connect(RunService.RenderStepped, perfCounters.cpu.wrapped.Recoil)
end

task.spawn(function()
    while alive do
        if state.esp or next(renderData) ~= nil then
            local ok, err = pcall(perfCounters.cpu.wrapped.ESPScan)
            if not ok then warn("[124 Community Visuals] ESP: " .. tostring(err)) end
        end
        -- Visual guard may slow roster refresh independently of AIM scans.
        local tier = visualPerfTier()
        local interval = tier == "ECO" and 1.25 or tier == "QUALITY" and 0.45
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
        local tier = visualPerfTier()
        local hz = tier == "ECO" and CONFIG.EspVisualEcoHz
            or tier == "QUALITY" and 120 or CONFIG.EspVisualBalancedHz
        -- При просадках сразу ограничиваем ТОЛЬКО ESP GUI, AIM не затрагиваем.
        if state.performanceMode == "AUTO" then
            if measuredFps < CONFIG.EspCriticalFps then
                hz = math.min(hz, CONFIG.EspCriticalHz)
            elseif measuredFps < CONFIG.EspLowFps then
                hz = math.min(hz, CONFIG.EspLowHz)
            end
        end
        if state.performanceGuard and perfCounters.guard.level == 2 then
            hz = math.min(hz, CONFIG.GuardVisualHzL2)
        elseif state.performanceGuard and perfCounters.guard.level == 1 then
            hz = math.min(hz, CONFIG.GuardVisualHzL1)
        end
        espVisualElapsed = espVisualElapsed + math.min(dt, 0.12)
        local period = 1 / hz
        if espVisualElapsed < period then return end
        -- Не теряем дробную часть времени; не догоняем пропущенные кадры.
        espVisualElapsed = math.min(espVisualElapsed - period, period)
    end
    if state.tracers then
        local ok, err = pcall(refreshTracers)
        if not ok then
            local now = os.clock()
            if now - perfCounters.espVisual.errorAt >= 2 then
                warn("[124 Community Visuals] ESP tracers draw: " .. tostring(err))
                perfCounters.espVisual.errorAt = now
            end
        end
    end
    if state.espBox or state.espSkeleton then
        local ok, err = pcall(refreshShapes)
        if not ok then
            local now = os.clock()
            if now - perfCounters.espVisual.errorAt >= 2 then
                warn("[124 Community Visuals] ESP shapes draw: " .. tostring(err))
                perfCounters.espVisual.errorAt = now
            end
        end
    end
end
perfCounters.cpu.wrapped.ESPDraw =
    perfCounters.cpu.instrument("ESP Draw", perfCounters.espVisual.frame)
perfCounters.espVisual.bound = pcall(function()
    RunService:BindToRenderStep(perfCounters.espVisual.bindingName, Enum.RenderPriority.Camera.Value + 4, perfCounters.cpu.wrapped.ESPDraw)
end)
if not perfCounters.espVisual.bound then
    -- Fallback: exec без BindToRenderStep. Используем тот же RenderStepped,
    -- без task.wait(), чтобы не возвращать старые 4–12 FPS.
    connect(RunService.RenderStepped, perfCounters.cpu.wrapped.ESPDraw)
    tell("ESP: Camera bind unavailable; using RenderStepped")
end

local frames, accumulated = 0, 0
connect(RunService.RenderStepped, function(dt)
    if not alive then return end
    perfCounters.frametime.observe(dt) -- O(1); статистика вычисляется только в MISC.
    frames = frames + 1
    accumulated = accumulated + math.max(dt, 0)
    if accumulated >= 1 then
        measuredFps = math.floor(frames / math.max(accumulated, 0.01) + 0.5)
        if boosterPro.dashboard then boosterPro.dashboard.push(measuredFps) end
        updateAutoPerformanceTier()
        perfCounters.guard.update(measuredFps, perfCounters.frametime.spikesThisSecond)
        perfCounters.frametime.spikesThisSecond = 0
        boosterPro.measure(measuredFps)
        frames, accumulated = 0, 0
    end
end)

task.spawn(function()
    while alive do
        local hudStart = state.moduleCpuMonitor and os.clock() or nil
        -- Отложенный откат после временного отказа записи API: до полной успешности
        -- не забываем исходные свойства. Не восстанавливаем Terrain при WHITE/ULTRA.
        if not state.fullbright and not state.booster
            and type(env.ARMY124_RECOVERY) == "function"
            and os.clock() >= boosterPro.recoveryNextAt then
            local ok, done = pcall(env.ARMY124_RECOVERY)
            if ok and done == true then
                boosterPro.recoveryFailures = 0
                boosterPro.recoveryNextAt = 0
            else
                boosterPro.recoveryFailures = boosterPro.recoveryFailures + 1
                local seconds = math.min(120, 2 ^ math.min(boosterPro.recoveryFailures, 7))
                boosterPro.recoveryNextAt = os.clock() + seconds
                if boosterPro.recoveryFailures == 1 or boosterPro.recoveryFailures == 5 then
                    warn("[124 Community Visuals] Recovery не завершён (попытка "
                        .. tostring(boosterPro.recoveryFailures)
                        .. "); повтор через " .. tostring(seconds) .. " сек")
                end
            end
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
        if boosterPro.dashboard then boosterPro.dashboard.update() end
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
        if panel.Visible and pages.MISC.Visible and perfCounters.guard.label then
            local label = perfCounters.guard.description()
            if perfCounters.guard.label.Text ~= label then
                perfCounters.guard.label.Text = label
            end
        end
        if state.hud or state.activeHud or pages.MISC.Visible then
            local display = string.format("FPS %d | ESP %d | Shape %d | Scan %.1f ms | %s",
                measuredFps, perfCounters.espCount, perfCounters.shapeCount,
                perfCounters.aimScanMs, perfTier())
            if perfLabel.Text ~= display then perfLabel.Text = display end
        end
        -- O(N log N) percentile work only when the PERFORMANCE page is visible,
        -- and no more than once every three seconds. Never in RenderStepped.
        if panel.Visible and pages.MISC.Visible
            and os.clock() - perfCounters.frametime.lastUpdated >= 3 then
            perfCounters.frametime.lastUpdated = os.clock()
            local summary = perfCounters.frametime.summary()
            if summary ~= perfCounters.frametime.lastShown then
                perfCounters.frametime.lastShown = summary
                if perfCounters.frametime.label and perfCounters.frametime.label.Parent then
                    perfCounters.frametime.label.Text = summary
                end
            end
        end
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
            if state.bunnyHop then table.insert(features, "BHOP") end
            if state.spamChat then table.insert(features, "CHAT") end
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
        if hudStart then
            perfCounters.cpu.record("HUD", (os.clock() - hudStart) * 1000)
        end
        task.wait((state.hud or state.activeHud) and 1.0 or 1.5)
    end
end)

-- Применяем профиль после создания всей GUI и привязок.
useProfile(profileName, true)
refreshFovRing()
print("[124 Community Visuals] " .. CONFIG.Version .. " загружен | MEMORY / SESSION DIAGNOSTICS")
end -- initializeHubUI; isolates UI locals from root Luau limit.

env.ARMY124_BOOT_PHASE = "initializing-ui"
local initOk, initErr = xpcall(initializeHubUI, function(err)
    local msg = tostring(err)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        local ok, trace = pcall(debug.traceback, msg, 2)
        if ok and type(trace) == "string" then return trace end
    end
    return msg
end)
if not initOk then
    local registered = env.ARMY124_CLEANUP
    if type(registered) == "function" and registered ~= abortPartialHub then
        local cleaned, result = pcall(registered)
        if not cleaned or result == false then pcall(abortPartialHub) end
    else
        pcall(abortPartialHub)
    end
    bootFailure("UI INITIALIZATION", initErr)
elseif not PlayerGui:FindFirstChild("Army124CommunityVisualsGUI") then
    bootFailure("GUI MISSING", "UI завершилась, но ScreenGui отсутствует.")
else
    env.ARMY124_BOOT_PHASE = "ready"
    env.ARMY124_BOOT_ERROR = nil
    pcall(function()
        local old = PlayerGui:FindFirstChild("Army124StartupError")
        if old then old:Destroy() end
    end)
end
