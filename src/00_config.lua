-- 124 Visuals v1.4.6 | UI Input, Weather, Aura and Lifecycle Repair
-- Первый плейс: 18537079992. Запуск поддерживает все игровые PlaceId.
-- Локальный Luau-скрипт: ESP, Aim (голова/тело/ноги), Misc, FPS/Ping/часы.
-- Все изменяющие параметры функции выключены по умолчанию.
-- При повторном запуске старая копия очищается и настройки сцены восстанавливаются.

local CONFIG = {
    Version = "1.4.6",
    OriginalPlaceId = 18537079992,
    EspRefreshSeconds = 0.35, -- Быстрый поиск персонажей, без обновления UI каждый кадр.
    EspEventMinSeconds = 0.18, -- Коалесцированные события не запускают 16 полных сканов/сек.
    EspMaxPlayers = 64, -- Видимый, настраиваемый лимит вместо скрытого TOP 6/12.
    EspRangeMinMeters = 10,
    EspRangeMaxMeters = 1000,
    EspRangeStepMeters = 5,
    EspLongRangeMeters = 350,
    EspExtremeRangeMeters = 700,
    EspLongScanSeconds = 0.45,
    EspExtremeScanSeconds = 0.65,
    MiscSpeedRefreshHz = 4, -- Speed only: раз в 250 мс.
    MiscNoclipRefreshHz = 30, -- Speed + Noclip: максимум 30 проверок в секунду.
    EspLongVisualHz = 18,
    EspExtremeVisualHz = 10,
    EspFarTextRefreshSeconds = 0.50, -- Обновление дальних меток.
    EspRespawnCoalesceSeconds = 0.045,
    EspRespawnMinIntervalSeconds = 0.10,
    EspCameraMotionDot = 0.9998,
    EspCameraMotionStuds = 0.12,
    EspCameraMotionHoldSeconds = 0.20,
    EspCameraMotionMinFps = 48,
    EspCameraMotionVisualHz = 36,
    StudMeters = 0.28, -- Стандартный масштаб Roblox: 1 stud ≈ 0.28 м.
    ConfigFile = game.PlaceId == 18537079992
        and "124_community_settings_v09.json"
        or ("124_visuals_settings_" .. tostring(game.PlaceId) .. ".json"),
    MenuKey = Enum.KeyCode.RightShift,
    EspFillTransparency = 0.88, -- Менее заметная подсветка.
    EspOutlineTransparency = 0.38, -- Встроенный Highlight не имеет толщины в px.
    EspNameSizeNear = 12,
    EspNameSizeMid = 11,
    EspNameSizeFar = 10, -- Ранее 8px: дальние подписи были почти нечитаемыми.
    EspMetaSizeNear = 10, -- HP и дистанция, независимые TextLabel.
    EspMetaSizeFar = 9,
    EspMidDistanceMeters = 80,
    EspFarDistanceMeters = 150,
    EspLabelWidth = 148,
    EspLabelHeight = 27,
    AimFovDefaultPixels = 175,
    AimFovMinPixels = 40,
    AimFovMaxPixels = 400,
    AimLockTolerance = 1.18, -- При сопровождении допускаем небольшой выход из первоначального FOV.
    AimVisibleRaycastChecks = 6, -- Пропускаем прозрачные служебные детали.
    AimLosCandidatesPerScan = 8, -- Ограничиваем число LOS-проверок при плотных серверах.
    AimOcclusionGraceSeconds = 0.12, -- Один короткий сбой LOS не переключает цель.
    AimPredictionMaxStuds = 10, -- Исключаем рывки от аномальной скорости сборки.
    AimMaxTurnDegreesPerSecond = 360, -- Предел поворота в режиме Smooth.
    AimRangeMaxMeters = 180,
    AimRangeMinMeters = 5,
    AimSmoothnessBaseline = 33, -- Smoothness=3 эквивалентен скорости v0.3 (11).
    AimKeyDefault = "F6", -- По умолчанию назначена F6, можно выбрать другую клавишу.
    AimKeyFile = game.PlaceId == 18537079992
        and "124_community_aim_key.txt"
        or ("124_visuals_aim_key_" .. tostring(game.PlaceId) .. ".txt"), -- Отдельно для каждой игры.
    AimScanInterval = 0.12, -- Таймер действует и при отсутствии целей.
    AimLostRescanSeconds = 0.06,
    AimLosBalancedSeconds = 0.045,
    AimLosEcoSeconds = 0.075,
    AimLosQualitySeconds = 0.02,
    RecoilShotGraceSeconds = 0.20, -- Поздний откат камеры после отпускания спуска.
    RecoilFireWindowSeconds = 0.40, -- Короткий выстрел (в т.ч. на телефоне).
    RecoilMaxHoldSeconds = 8.0, -- Только при реальном удержании кнопки стрельбы.
    RecoilOrphanHoldSeconds = 0.55, -- Если Tool не прислал Deactivated, без ввода не держим 8 сек.
    RecoilInputDedupSeconds = 0.04,
    SpreadVerificationSeconds = 0.50, -- Резервная периодическая проверка.
    SpreadEventMinSeconds = 0.05, -- Не чаще 20 реактивных проверок в секунду.
    SpreadDiscoverySeconds = 3.0, -- Обнаружить новые атрибуты и переименованные параметры.
    SpreadDiscoveryBatch = 48, -- Ограничение работы одного обновления.
    SpreadShotRecheckSeconds = 0.18,
    SpreadPostShotSeconds = 0.06,
    SpreadMaxWritableValue = 1000000,
    SpreadErrorLogSeconds = 4,
    RecoilMaxCorrectionPerSecond = 120, -- Единая плавность при 60/120+ FPS.
    RecoilMaxFrameSeconds = 0.16, -- Не компенсируем скачок камеры после лагов.
    RecoilMinPitchDegrees = 0.045, -- Не реагируем на микродрожание камеры.
    RecoilMaxPitchDegrees = 5.0, -- Не воспринимаем резкий разворот как отдачу.
    RecoilMaxCorrectionDegrees = 1.60, -- Ограничение коррекции за кадр.
    KeyMaxWrongAttempts = 5,
    KeyLocalCooldownSeconds = 25,
    KeySubmitDedupSeconds = 0.18,
    KeyCloseConfirmSeconds = 4,
    BoosterBatch = 64, -- Меньше объектов за проход: плавнее, но дольше первичный скан.
    BoosterSliceMs = 0.75, -- Мягкий бюджет основной обработки (не гарантия hard real-time).
    BoosterLowFpsSliceMs = 0.35, -- При низком FPS чаще отдаём кадр.
    BoosterInitialDelay = 0, BoosterLowFpsDelay = 0, -- Yield без искусственного ожидания.
    BoosterQueueBatch = 24, -- StreamingEnabled: короче проходы при массовой подгрузке.
    BoosterQueueSliceMs = 0.35,
    BoosterQueueDelay = 0.040, BoosterQueueLowFpsDelay = 0.075,
    BoosterRepairCooldown = 45, -- Нет повторного обхода каждые 12 секунд.
    BoosterRepairIdleSeconds = 3, -- Сначала даём стримингу завершиться.
    EspVisualBalancedHz = 24, -- ESP снижает нагрузку; AIM сохраняет свою частоту.
    EspVisualEcoHz = 12,
    EspLowFps = 42, EspLowHz = 12,
    EspCriticalFps = 30, EspCriticalHz = 8,
    EspShapeEcoLimit = 10,
    EspShapeBalancedLimit = 18,
    EspShapeQualityLimit = 32,
    ShapeNewContainersPerDraw = 2, -- Создаём 2D ESP постепенно, без пакетного всплеска.
    ShapeNewLinesPerDraw = 8, -- Ограничиваем Instance.new в рендер-проходе.
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
    EspCacheIdleSeconds = 2.0, -- Переиспользование без долгих невидимых устаревших объектов.
    EspCacheMaxExtra = 4, -- Всего не более 4 скрытых Highlight сверх лимита.
    -- LITE: chat/BHOP constants removed.
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

-- В разных играх используем общие сервисы Roblox, без ограничения на один PlaceId.
if type(game.PlaceId) ~= "number" or game.PlaceId <= 0 then
    warn("[124 Visuals] Не определён корректный PlaceId")
    return
end
print("[124 Visuals] v" .. CONFIG.Version .. " | PlaceId=" .. tostring(game.PlaceId))

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
-- Уникальный токен запуска: завершение старой корутины не меняет новый BOOT_PHASE.
CONFIG.BootToken = {}
env.ARMY124_BOOT_TOKEN = CONFIG.BootToken
-- Не расходуем дополнительные top-level locals: большие Luau-скрипты
-- чувствительны к ограничению числа локальных регистров.
if type(env.ARMY124_PLACE_CACHE) ~= "table" then
    env.ARMY124_PLACE_CACHE = {}
end
CONFIG.PlaceCache = env.ARMY124_PLACE_CACHE[tostring(game.PlaceId)]
if type(CONFIG.PlaceCache) ~= "table" then
    CONFIG.PlaceCache = {}
    env.ARMY124_PLACE_CACHE[tostring(game.PlaceId)] = CONFIG.PlaceCache
end
-- Startup reporting is independent of the main GUI, which might not initialize.
local function bootFailure(stage, err)
    if env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then return end
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
-- Старый ScreenGui ошибки имеет DisplayOrder выше ключа: убираем его сразу.
pcall(function()
    local oldError = PlayerGui:FindFirstChild("Army124StartupError")
    if oldError then oldError:Destroy() end
end)
-- Старый экземпляр ДОЛЖЕН освободить UI, BindToRenderStep и свойства.
-- Старые версии возвращают nil при успехе, поэтому проверяем освобождение
-- env.ARMY124_CLEANUP, а не только возвращаемое значение.
if type(env.ARMY124_CLEANUP) == "function" then
    local previous = env.ARMY124_CLEANUP
    local ok, result = pcall(previous)
    if env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then return CONFIG.BootToken end
    if not ok or result == false or env.ARMY124_CLEANUP == previous then
        bootFailure("PREVIOUS CLEANUP",
            "Старая копия не выгружена. Перезапусти игру. " .. tostring(result))
        return CONFIG.BootToken
    end
end
if type(env.ARMY124_RECOVERY) == "function" then
    local ok, restored = pcall(env.ARMY124_RECOVERY)
    if env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then return CONFIG.BootToken end
    if not ok or restored ~= true then
        bootFailure("RECOVERY",
            "Восстановление старой графики не завершено. " .. tostring(restored))
        return CONFIG.BootToken
    end
end

if env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then return CONFIG.BootToken end
