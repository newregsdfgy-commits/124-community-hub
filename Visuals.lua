-- 124 Visuals v1.1.63 | key event correctness, spread event pacing, recoil hold
-- Первый плейс: 18537079992. Запуск поддерживает все игровые PlaceId.
-- Локальный Luau-скрипт: ESP, Aim (голова/тело/ноги), Misc, FPS/Ping/часы.
-- Все изменяющие параметры функции выключены по умолчанию.
-- При повторном запуске старая копия очищается и настройки сцены восстанавливаются.

local CONFIG = {
    Version = "1.1.63",
    OriginalPlaceId = 18537079992,
    EspRefreshSeconds = 0.35, -- Быстрый поиск персонажей, без обновления UI каждый кадр.
    EspEventMinSeconds = 0.18, -- Коалесцированные события не запускают 16 полных сканов/сек.
    EspMaxPlayers = 64, -- Видимый, настраиваемый лимит вместо скрытого TOP 6/12.
    EspRangeMinMeters = 10,
    EspRangeMaxMeters = 1000,
    EspRangeStepMeters = 5,
    EspLongRangeMeters = 350,
    EspExtremeRangeMeters = 700,
    EspLongScanSeconds = 0.55,
    EspExtremeScanSeconds = 0.80,
    MiscSpeedRefreshHz = 4, -- Speed only: раз в 250 мс.
    MiscNoclipRefreshHz = 30, -- Speed + Noclip: максимум 30 проверок в секунду.
    EspLongVisualHz = 18,
    EspExtremeVisualHz = 10,
    EspFarTextRefreshSeconds = 0.85, -- Дальние текстовые метки не обновляются при каждом скане.
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
    SpreadShotRecheckSeconds = 0.18,
    SpreadPostShotSeconds = 0.06,
    RecoilMaxCorrectionPerSecond = 120, -- Единая плавность при 60/120+ FPS.
    RecoilMaxFrameSeconds = 0.16, -- Не компенсируем скачок камеры после лагов.
    RecoilMinPitchDegrees = 0.045, -- Не реагируем на микродрожание камеры.
    RecoilMaxPitchDegrees = 5.0, -- Не воспринимаем резкий разворот как отдачу.
    RecoilMaxCorrectionDegrees = 1.60, -- Ограничение коррекции за кадр.
    BoosterBatch = 96, -- Лимит объектов за один периодический проход.
    BoosterSliceMs = 0.90, -- Верхняя цель CPU-среза при нормальном FPS.
    BoosterLowFpsSliceMs = 0.45, -- Более короткий срез при низком FPS.
    BoosterInitialDelay = 0, BoosterLowFpsDelay = 0, -- Yield без искусственного ожидания.
    BoosterQueueBatch = 32, -- StreamingEnabled: меньше свойств за раз.
    BoosterQueueSliceMs = 0.45,
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

-- Блокировка запуска: основной код ещё не создавал state, GUI и обработчики.
-- Единый локальный ключ. Новый запуск всегда запрашивает ввод заново.
do
    local ACCESS_KEY = "124HUB"
    local GATE_GUI_NAME = "Army124AccessGate"
    local gateScreen = nil

    local function requireAccessKey()
        local old = PlayerGui:FindFirstChild(GATE_GUI_NAME)
        if old then old:Destroy() end

        local function create(className, properties, parent)
            local instance = Instance.new(className)
            local ok, err = pcall(function()
                for key, value in pairs(properties) do instance[key] = value end
                instance.Parent = parent
            end)
            if not ok then
                pcall(function() instance:Destroy() end)
                error(err, 2)
            end
            return instance
        end

        local screen = create("ScreenGui", {
            Name = GATE_GUI_NAME,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 9999,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, PlayerGui)
        gateScreen = screen

        -- Фоновая подложка и центральная карточка.
        create("Frame", {
            Name = "Backdrop",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(8, 8, 17),
            BackgroundTransparency = 0.24,
            BorderSizePixel = 0,
        }, screen)
        local shadow = create("Frame", {
            Name = "VioletGlow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, UserInputService.TouchEnabled and 0.43 or 0.5),
            Size = UDim2.new(0.94, 8, 0, 302),
            BackgroundColor3 = Color3.fromRGB(113, 61, 210),
            BackgroundTransparency = 0.68,
            BorderSizePixel = 0,
        }, screen)
        create("UISizeConstraint", {
            MaxSize = Vector2.new(440, 302),
        }, shadow)
        create("UICorner", {CornerRadius = UDim.new(0, 18)}, shadow)

        local panel = create("Frame", {
            Name = "AccessPanel",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, UserInputService.TouchEnabled and 0.43 or 0.5),
            Size = UDim2.new(0.90, 0, 0, 286),
            BackgroundColor3 = Color3.fromRGB(19, 18, 31),
            BorderSizePixel = 0,
        }, screen)
        create("UISizeConstraint", {
            MaxSize = Vector2.new(420, 286),
        }, panel)
        create("UICorner", {CornerRadius = UDim.new(0, 16)}, panel)
        -- На компактном экране элементы остаются в пределах видимой области.
        local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
        local height = viewport and viewport.Y or (UserInputService.TouchEnabled and 420 or 600)
        local scale = height < 340 and 0.70 or height < 460 and 0.84 or 1
        if scale < 1 then
            create("UIScale", {Scale = scale}, panel)
            create("UIScale", {Scale = scale}, shadow)
        end
        create("UIStroke", {
            Color = Color3.fromRGB(128, 86, 210),
            Thickness = 1.4,
            Transparency = 0.14,
        }, panel)
        create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(31, 27, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 28)),
            }),
            Rotation = 90,
        }, panel)

        create("TextLabel", {
            Name = "Brand",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 17),
            Size = UDim2.new(1, -36, 0, 29),
            Font = Enum.Font.GothamBold,
            Text = "124 VISUALS",
            TextColor3 = Color3.fromRGB(231, 220, 255),
            TextSize = 22,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, panel)
        create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 49),
            Size = UDim2.new(1, -36, 0, 44),
            Font = Enum.Font.Gotham,
            Text = "Доступ к функциям закрыт.\nВведи единый ключ для продолжения.",
            TextColor3 = Color3.fromRGB(177, 171, 196),
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, panel)

        local input = create("TextBox", {
            Name = "KeyInput",
            BackgroundColor3 = Color3.fromRGB(37, 32, 57),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 18, 0, 109),
            Size = UDim2.new(1, -36, 0, 46),
            ClearTextOnFocus = false,
            Font = Enum.Font.GothamMedium,
            Text = "",
            PlaceholderText = "Введи ключ доступа",
            PlaceholderColor3 = Color3.fromRGB(129, 119, 153),
            TextColor3 = Color3.fromRGB(245, 239, 255),
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, panel)
        create("UICorner", {CornerRadius = UDim.new(0, 10)}, input)
        create("UIStroke", {
            Color = Color3.fromRGB(104, 81, 151),
            Thickness = 1,
            Transparency = 0.3,
        }, input)

        local message = create("TextLabel", {
            Name = "Feedback",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 158),
            Size = UDim2.new(1, -36, 0, 24),
            Font = Enum.Font.GothamMedium,
            Text = "Ключ проверяется локально",
            TextColor3 = Color3.fromRGB(164, 148, 199),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, panel)

        local submit = create("TextButton", {
            Name = "Unlock",
            Position = UDim2.new(0, 18, 0, 189),
            Size = UDim2.new(1, -36, 0, 44),
            BackgroundColor3 = Color3.fromRGB(112, 66, 207),
            BorderSizePixel = 0,
            AutoButtonColor = true,
            Font = Enum.Font.GothamBold,
            Text = "АКТИВИРОВАТЬ",
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255),
        }, panel)
        create("UICorner", {CornerRadius = UDim.new(0, 10)}, submit)

        local cancel = create("TextButton", {
            Name = "Cancel",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 244),
            Size = UDim2.new(1, -36, 0, 25),
            Font = Enum.Font.Gotham,
            Text = "Закрыть",
            TextSize = 13,
            TextColor3 = Color3.fromRGB(174, 168, 188),
        }, panel)

        local response = Instance.new("BindableEvent")
        local completed = false
        local function resolve(accepted)
            if completed then return end
            completed = true
            response:Fire(accepted)
        end
        local function tryUnlock()
            if completed then return end
            local candidate = input.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if candidate == ACCESS_KEY then
                input.Text = ""
                resolve(true)
            else
                message.Text = "Неверный ключ. Попробуй ещё раз."
                message.TextColor3 = Color3.fromRGB(255, 130, 148)
                input.Text = ""
            end
        end
        submit.Activated:Connect(tryUnlock)
        input.FocusLost:Connect(function(enterPressed)
            -- Обычное касание вне поля не является отправкой ключа.
            if enterPressed then tryUnlock() end
        end)
        -- Явная кнопка Return мобильной клавиатуры. Старые клиенты могут
        -- не иметь этого события; обычная кнопка АКТИВИРОВАТЬ остаётся доступна.
        pcall(function()
            input.ReturnPressedFromOnScreenKeyboard:Connect(tryUnlock)
        end)
        cancel.Activated:Connect(function() resolve(false) end)
        screen.Destroying:Connect(function() resolve(false) end)

        local accepted = response.Event:Wait()
        if screen.Parent then screen:Destroy() end
        response:Destroy()
        return accepted == true
    end

    env.ARMY124_BOOT_PHASE = "key_required"
    local ok, accepted = pcall(requireAccessKey)
    if gateScreen and gateScreen.Parent then
        -- Если создание UI завершилось исключением, подложка не останется в PlayerGui.
        pcall(function() gateScreen:Destroy() end)
    end
    gateScreen = nil
    if not ok or not accepted then
        env.ARMY124_BOOT_PHASE = "key_denied"
        env.ARMY124_BOOT_ERROR = ok and "Ключ не введён" or "Экран ключа: " .. tostring(accepted)
        if not ok then warn("[124 Access] " .. tostring(accepted)) end
        return
    end
    env.ARMY124_BOOT_PHASE = "authorized"
    env.ARMY124_BOOT_ERROR = nil
end

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
    -- Weak object keys track values actively written by Booster.
    graphicsWritten = setmetatable({}, {__mode = "k"}),
    recoveryFailures = 0, recoveryNextAt = 0,
    restoreRetryAt = 0, restoreRetryRunning = false,
    terrainRestoreRetryAt = 0, -- Backoff on inaccessible Terrain: no recurring 1s spikes.
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
    errorAt = 0, scanErrorAt = 0, active = {}, projected = {}, ordered = {}, candidatePool = {},
    eligible = 0, missing = 0, omitted = 0, lastScanAt = 0,
    localReady = false, renderFailures = 0, watcherFailures = 0}
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

-- ESP: исходная Highlight/Billboard логика из v0.1, с удалением после респавна.
local function deleteRender(player)
    local item = renderData[player]
    if not item then return end
    -- Do not use ipairs on a table with possible nil holes. During a partial
    -- GUI build highlight/billboard/tracer may be missing independently.
    for _, property in ipairs({"highlight", "billboard", "tracer"}) do
        local instance = item[property]
        if instance then pcall(function() instance:Destroy() end) end
    end
    renderData[player] = nil
end

-- The Text Border control in the reference menu affects actual ESP labels.
local referenceStrokeEnabled = true
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
-- AUTO/ECO now controls refresh frequency and 2D geometry only: it must
-- never silently remove nearby players from the configured ESP radius.
local function espLimit()
    return math.clamp(math.floor(state.espMaxTargets or CONFIG.EspMaxPlayers), 8, 96)
end

-- StreamingEnabled may give us Head or Torso before HumanoidRootPart.
-- Use the first local visible BasePart as a temporary anchor, then upgrade
-- as parts arrive. No invisible position/identity is manufactured.
local function espVisiblePart(character, name)
    local object = character:FindFirstChild(name)
    return object and object:IsA("BasePart") and object or nil
end
local function espParts(character)
    if not character then return nil, nil, nil end
    -- Filter named objects before fallback. A non-BasePart "Head" should
    -- not hide a valid Torso/Root during StreamingEnabled.
    local root = espVisiblePart(character, "HumanoidRootPart")
    local head = espVisiblePart(character, "Head")
    local torso = espVisiblePart(character, "UpperTorso")
        or espVisiblePart(character, "Torso")
    local anchor = head or torso or root
    local positionPart = root or torso or anchor
    return anchor, positionPart, character:FindFirstChildOfClass("Humanoid")
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
    -- Publish the highlight immediately. If any following Gui constructor
    -- fails, the caller's protected error handler can destroy this partial
    -- object rather than leave an orphaned Highlight in the avatar.
    local item = {character = character, highlight = hl, inactiveSince = nil}
    renderData[player] = item
    local bb = mk("BillboardGui", {
        Name = "Army124ESPLabel",
        Adornee = head,
        AlwaysOnTop = true,
        LightInfluence = 0,
        -- BillboardGui.MaxDistance is camera-relative, while the ESP range
        -- is player-relative. Leave the engine cap off and filter below.
        MaxDistance = 0,
        Size = UDim2.fromOffset(CONFIG.EspLabelWidth, CONFIG.EspLabelHeight),
        StudsOffsetWorldSpace = Vector3.new(0, 2.1, 0),
        ResetOnSpawn = false,
    }, PlayerGui)
    item.billboard = bb
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
    item.nameLabel, item.healthLabel, item.distanceLabel =
        nameLabel, healthLabel, distanceLabel
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
    local head, root, hum = espParts(character)
    if not (character and head and root) or (hum and hum.Health <= 0) then
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
    local strokeAlpha = referenceStrokeEnabled and 0.55 or 1
    setIfDifferent(item.nameLabel, "TextStrokeTransparency", strokeAlpha)
    setIfDifferent(item.healthLabel, "TextStrokeTransparency", strokeAlpha)
    setIfDifferent(item.distanceLabel, "TextStrokeTransparency", strokeAlpha)
    setIfDifferent(item.billboard, "Adornee", head) -- Upgrade torso → Head after streaming.
    -- Переключение кэша, смена команды/ника/опций должны перерисовать текст
    -- сразу; throttling применяется только к неизменившимся дальним меткам.
    local wasInactive = item.inactiveSince ~= nil
    item.inactiveSince = nil
    setIfDifferent(item.highlight, "Enabled", true)
    setIfDifferent(item.billboard, "Enabled", state.names or state.health or state.distance)
    local offset = myRoot and (root.Position - myRoot.Position)
    local distanceSquared = offset and offset:Dot(offset) or 0
    local farThresholdStuds = CONFIG.EspLongRangeMeters / CONFIG.StudMeters
    local now = os.clock()
    local changedSettings = wasInactive
        or item.lastNames ~= state.names
        or item.lastHealth ~= state.health
        or item.lastDistance ~= state.distance
        or item.lastTeamColors ~= state.teamColors
        or item.lastColorPreset ~= state.espColorPreset
        or item.lastTeam ~= player.Team
        or item.lastTeamColor ~= player.TeamColor
        or item.lastDisplayName ~= player.DisplayName
    if not changedSettings
        and distanceSquared >= farThresholdStuds * farThresholdStuds
        and item.nextTextRefreshAt and now < item.nextTextRefreshAt then
        return
    end
    item.nextTextRefreshAt = distanceSquared >= farThresholdStuds * farThresholdStuds
        and (now + CONFIG.EspFarTextRefreshSeconds) or nil
    local color = getPlayerColor(player)
    local meters = math.floor(math.sqrt(distanceSquared) * CONFIG.StudMeters + 0.5)
    local near = meters < CONFIG.EspMidDistanceMeters
    local far = meters >= CONFIG.EspFarDistanceMeters
    local nameSize = far and CONFIG.EspNameSizeFar
        or not near and CONFIG.EspNameSizeMid or CONFIG.EspNameSizeNear
    local metaSize = near and CONFIG.EspMetaSizeNear or CONFIG.EspMetaSizeFar
    setIfDifferent(item.highlight, "FillColor", color)
    setIfDifferent(item.highlight, "OutlineColor", color)
    setIfDifferent(item.nameLabel, "Text", state.names and player.DisplayName or "")
    setIfDifferent(item.nameLabel, "TextSize", nameSize)
    setIfDifferent(item.nameLabel, "TextColor3", color)
    setIfDifferent(item.nameLabel, "Visible", state.names)
    setIfDifferent(item.distanceLabel, "Text", state.distance and (tostring(meters) .. " м") or "")
    setIfDifferent(item.distanceLabel, "TextSize", metaSize)
    setIfDifferent(item.distanceLabel, "Visible", state.distance)
    if state.health then
        if hum then
            local maxHp = math.max(hum.MaxHealth, 1)
            local hp = math.clamp(hum.Health / maxHp, 0, 1)
            setIfDifferent(item.healthLabel, "Text",
                string.format("HP %d/%d", math.ceil(hum.Health), math.ceil(maxHp)))
            setIfDifferent(item.healthLabel, "TextColor3",
                Color3.fromRGB(math.floor(255 * (1 - hp)), math.floor(255 * hp), 90))
        else
            setIfDifferent(item.healthLabel, "Text", "HP --")
        end
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
    -- Дешёвый кэш флагов: не создаём строки/таблицы при каждом кадре.
    item.lastNames = state.names
    item.lastHealth = state.health
    item.lastDistance = state.distance
    item.lastTeamColors = state.teamColors
    item.lastColorPreset = state.espColorPreset
    item.lastTeam = player.Team
    item.lastTeamColor = player.TeamColor
    item.lastDisplayName = player.DisplayName
end

local function sameTeamESP(player)
    return player.Team ~= nil and LocalPlayer.Team ~= nil
        and player.Team == LocalPlayer.Team
end

-- Одна разность Vector3 и без квадратного корня для 2D геометрии.
function perfCounters.espWithinRange(root, origin, radiusSquared)
    local delta = root.Position - origin.Position
    return delta:Dot(delta) <= radiusSquared
end

local espCandidateScratch = {}
local espKeepScratch = {}
local function refreshESP()
    -- Record attempts even while the local character is streaming in: without
    -- this event-triggered scans were permitted every 60ms indefinitely.
    perfCounters.espVisual.lastScanAt = os.clock()
    syncESPWatchers() -- No avatar event listeners while ESP is disabled.
    if not state.esp then
        perfCounters.espVisual.localReady = false
        for player in pairs(renderData) do deleteRender(player) end
        table.clear(perfCounters.espVisual.ordered)
        perfCounters.espCount = 0
        perfCounters.espVisual.eligible = 0
        perfCounters.espVisual.omitted = 0
        perfCounters.espVisual.missing = 0
        return
    end
    local character = LocalPlayer.Character
    local _, myRoot = espParts(character)
    perfCounters.espVisual.localReady = myRoot ~= nil
    if not myRoot then
        for player in pairs(renderData) do deleteRender(player) end
        table.clear(perfCounters.espVisual.ordered)
        perfCounters.espCount = 0
        perfCounters.espVisual.eligible = 0
        perfCounters.espVisual.omitted = 0
        perfCounters.espVisual.missing = 0
        return
    end
    -- Рисуем ближайших, чтобы не создавать десятки дорогих Highlight.
    local candidates = espCandidateScratch
    local pool = perfCounters.espVisual.candidatePool
    local maxStuds = state.espRangeMeters / CONFIG.StudMeters
    local maxDistanceSquared = maxStuds * maxStuds
    table.clear(candidates)
    local missingParts = 0
    for _, player in ipairs(perfCounters.roster) do
        if player ~= LocalPlayer and (not state.espEnemyOnly or not sameTeamESP(player)) then
            local ch = player.Character
            local _, root, hum = espParts(ch)
            if root and (not hum or hum.Health > 0) then
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
            elseif not ch or not root then
                -- We cannot invent positions for characters not replicated yet.
                missingParts = missingParts + 1
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
    perfCounters.espVisual.eligible = #candidates
    perfCounters.espVisual.omitted = #candidates - limit
    perfCounters.espVisual.missing = missingParts
    for i = 1, limit do
        local player = candidates[i].player
        keep[player] = true
        -- One broken/streaming avatar must not abort the entire ESP scan.
        local ok, err = pcall(updatePlayer, player, myRoot)
        if not ok then
            deleteRender(player)
            perfCounters.espVisual.renderFailures = perfCounters.espVisual.renderFailures + 1
            local now = os.clock()
            if now - perfCounters.espVisual.scanErrorAt > 3 then
                warn("[124 Community Visuals] ESP player " .. tostring(player.UserId)
                    .. ": " .. tostring(err))
                perfCounters.espVisual.scanErrorAt = now
            end
        end
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

-- Event-assisted ESP refresh. The periodic roster scan remains a fallback,
-- while CharacterAdded and late-arriving body parts trigger a batched update.
local espWatchers = {}
local espRefreshQueued = false
local espRefreshGeneration = 0
-- Частота событийных обновлений согласована с дальностью сканирования.
function perfCounters.espVisual.eventCooldown()
    if state.performanceMode ~= "QUALITY"
        or (state.performanceGuard and perfCounters.guard.level > 0) then
        if state.espRangeMeters >= CONFIG.EspExtremeRangeMeters then
            return math.max(CONFIG.EspEventMinSeconds, CONFIG.EspExtremeScanSeconds)
        end
        if state.espRangeMeters >= CONFIG.EspLongRangeMeters then
            return math.max(CONFIG.EspEventMinSeconds, CONFIG.EspLongScanSeconds)
        end
    end
    return CONFIG.EspEventMinSeconds
end
local function queueESPRefresh()
    if not alive or not state.esp or espRefreshQueued then return end
    espRefreshQueued = true
    local generation = espRefreshGeneration
    local elapsed = os.clock() - perfCounters.espVisual.lastScanAt
    local delaySeconds = math.max(0.06, perfCounters.espVisual.eventCooldown() - elapsed)
    task.delay(delaySeconds, function()
        if generation ~= espRefreshGeneration then return end
        espRefreshQueued = false
        if not alive or not state.esp then return end
        local cooldown = perfCounters.espVisual.eventCooldown()
        if os.clock() - perfCounters.espVisual.lastScanAt < cooldown then
            -- Фоновый проход уже обновил данные; очередь обработана.
            -- Нельзя ставить себя заново на таймер бесконечно.
            return
        end
        local ok, err = pcall(refreshESP)
        if not ok then
            local now = os.clock()
            if now - perfCounters.espVisual.scanErrorAt >= 3 then
                warn("[124 Community Visuals] ESP event refresh: " .. tostring(err))
                perfCounters.espVisual.scanErrorAt = now
            end
        end
    end)
end
local function isEspPart(obj)
    return obj:IsA("Humanoid") or (obj:IsA("BasePart") and
        (obj.Name == "Head" or obj.Name == "HumanoidRootPart"
            or obj.Name == "UpperTorso" or obj.Name == "Torso"))
end
local function disconnectEspCharacter(entry)
    if entry.partAdded then entry.partAdded:Disconnect(); entry.partAdded = nil end
    if entry.partRemoved then entry.partRemoved:Disconnect(); entry.partRemoved = nil end
end
local function bindEspCharacter(entry, character)
    disconnectEspCharacter(entry)
    entry.character = character
    if character then
        entry.partAdded = character.DescendantAdded:Connect(function(obj)
            if alive and isEspPart(obj) then queueESPRefresh() end
        end)
        entry.partRemoved = character.DescendantRemoving:Connect(function(obj)
            if alive and isEspPart(obj) then queueESPRefresh() end
        end)
    end
    queueESPRefresh()
end
local function unwatchEspPlayer(player)
    local entry = espWatchers[player]
    if not entry then return end
    disconnectEspCharacter(entry)
    if entry.added then entry.added:Disconnect() end
    if entry.removing then entry.removing:Disconnect() end
    espWatchers[player] = nil
    queueESPRefresh()
end
local function watchEspPlayer(player)
    if not state.esp or player == LocalPlayer or espWatchers[player] then return end
    local entry = {}
    espWatchers[player] = entry
    local ok, err = pcall(function()
        entry.added = player.CharacterAdded:Connect(function(character)
            local bound, why = pcall(bindEspCharacter, entry, character)
            if not bound then
                warn("[124 Community Visuals] ESP respawn watcher: " .. tostring(why))
                queueESPRefresh()
            end
        end)
        entry.removing = player.CharacterRemoving:Connect(function()
            local bound, why = pcall(bindEspCharacter, entry, nil)
            if not bound then
                warn("[124 Community Visuals] ESP removing watcher: " .. tostring(why))
                queueESPRefresh()
            end
        end)
        bindEspCharacter(entry, player.Character)
    end)
    if not ok then
        -- A broken character/event must not abort refreshESP for everyone.
        -- Reclaim any connections built before the exception.
        pcall(disconnectEspCharacter, entry)
        if entry.added then pcall(function() entry.added:Disconnect() end) end
        if entry.removing then pcall(function() entry.removing:Disconnect() end) end
        espWatchers[player] = nil
        perfCounters.espVisual.watcherFailures = perfCounters.espVisual.watcherFailures + 1
        local now = os.clock()
        if now - perfCounters.espVisual.scanErrorAt > 3 then
            warn("[124 Community Visuals] ESP watcher " .. tostring(player.UserId)
                .. ": " .. tostring(err))
            perfCounters.espVisual.scanErrorAt = now
        end
    end
end
stopESPWatchers = function()
    espRefreshGeneration = espRefreshGeneration + 1
    espRefreshQueued = false
    for player in pairs(espWatchers) do unwatchEspPlayer(player) end
end
syncESPWatchers = function()
    if not state.esp then
        stopESPWatchers()
        return
    end
    for _, player in ipairs(perfCounters.roster) do watchEspPlayer(player) end
end
connect(Players.PlayerAdded, watchEspPlayer)
connect(Players.PlayerRemoving, function(player)
    unwatchEspPlayer(player)
    deleteRender(player)
end)

-- Shared Lighting ownership: only properties actually written by this
-- script are restored. Dynamic day/night changes stay with the game.
local lightingProperties = {
    "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation", "GlobalShadows"
}
local lightingOwned = {} -- key -> last value this script imposed (false is valid).

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

local function restoreOwnedLighting(key)
    local imposed = lightingOwned[key]
    if imposed == nil then return true end
    local original = savedLighting and savedLighting[key]
    local ok = pcall(function()
        local current = Lighting[key]
        -- Another owner/game changed this property: never overwrite it.
        if original ~= nil and current == imposed and current ~= original then
            Lighting[key] = original
            if Lighting[key] ~= original then error("Lighting restore mismatch") end
        end
    end)
    if ok then
        lightingOwned[key] = nil
    else
        boosterPro.restoreFailures = boosterPro.restoreFailures + 1
        if boosterPro.restoreFailures <= 3 then
            warn("[124 Visuals] Lighting: восстановление " .. tostring(key) .. " будет повторено")
        end
    end
    return ok
end

local function enforceLightingProperty(key)
    if not alive or lightingApplying or not savedLighting then return end
    local wanted = wantedLightingValue(key)
    if wanted == nil then return end
    lightingApplying = true
    pcall(function()
        local current = Lighting[key]
        if current ~= wanted then
            -- Preserve the latest dynamic value from the game, not an old
            -- snapshot taken several day/night transitions ago.
            savedLighting[key] = current
            lightingOwned[key] = wanted
            Lighting[key] = wanted
        end
    end)
    lightingApplying = false
end

local function applyLighting()
    if lightingApplying then return end
    if not state.fullbright and not state.booster then
        if savedLighting then
            lightingApplying = true
            local complete = true
            for _, key in ipairs(lightingProperties) do
                if not restoreOwnedLighting(key) then complete = false end
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
                local current = Lighting[key]
                if current ~= wanted then
                    savedLighting[key] = current
                    lightingOwned[key] = wanted
                    Lighting[key] = wanted
                end
            end)
        else
            -- Example: FullBright OFF while Booster is still ON. Restore
            -- FullBright-owned colors, but leave unowned game lighting alone.
            restoreOwnedLighting(key)
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
-- CharacterAdded is owned by the player lifetime, not by the hub lifetime.
-- Keep one connection per active Player; disconnect immediately on leaving.
boosterPro.playerConnections = {}
function boosterPro.watchPlayer(person)
    if not alive or boosterPro.playerConnections[person] then return end
    boosterPro.protectedNames[person.Name] = true
    if person.Character then boosterPro.protectedCharacters[person.Character] = true end
    boosterPro.playerConnections[person] = person.CharacterAdded:Connect(function(character)
        if not alive then return end
        boosterPro.protectedCharacters[character] = true
        -- Keep late avatars out of graphic simplification.
        if boosterPro.restoreProtectedTree then
            boosterPro.restoreProtectedTree(character)
        end
    end)
end
function boosterPro.unwatchPlayer(person)
    local connection = boosterPro.playerConnections[person]
    if connection then
        pcall(function() connection:Disconnect() end)
        boosterPro.playerConnections[person] = nil
    end
    boosterPro.protectedNames[person.Name] = nil
end
function boosterPro.stopWatchingPlayers()
    for person, connection in pairs(boosterPro.playerConnections) do
        pcall(function() connection:Disconnect() end)
        boosterPro.playerConnections[person] = nil
    end
    table.clear(boosterPro.protectedNames)
end
for _, person in ipairs(perfCounters.roster) do boosterPro.watchPlayer(person) end
connect(Players.PlayerAdded, boosterPro.watchPlayer)
connect(Players.PlayerRemoving, boosterPro.unwatchPlayer)

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
local graphicsNoProperties = {} -- Shared immutable map avoids downgrade allocations.
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
    -- BALANCED не должен менять десятки тысяч BasePart ради одного тумблера.
    -- Глобальные тени отключает applyLighting; здесь только постэффекты.
    if level == "BALANCED" then
        return obj:IsA("PostEffect") and graphicsDisabled or nil
    end
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

-- Restore only a Booster-owned value. If the game or another script
-- changed this property after we wrote it, keep that new value intact.
function boosterPro.restoreBoosterProperty(obj, snapshot, key, original)
    local written = boosterPro.graphicsWritten[obj]
    local lastWritten = written and written[key] or nil
    local ok = pcall(function()
        if not obj.Parent then return end
        local current = obj[key]
        if current == original then return end
        if lastWritten ~= nil and current == lastWritten then
            obj[key] = original
            if obj[key] ~= original then error("Booster property restore mismatch") end
        end
        -- If current differs from lastWritten, the game owns the newer value.
    end)
    if ok or not obj.Parent then
        snapshot[key] = nil
        if written then
            written[key] = nil
            if not next(written) then boosterPro.graphicsWritten[obj] = nil end
        end
        return true
    end
    return false
end

-- Original snapshots survive BALANCED -> WHITE -> ULTRA changes.
local function optimizeObject(obj, alreadyScreened)
    if not alive or not state.booster then return end
    local desired = graphicsProperty(obj)
    local snap = savedGraphics[obj]
    if not desired and not snap then return end
    if not alreadyScreened and boosterPro.isProtected(obj) then return end
    desired = desired or graphicsNoProperties
    if snap then
        for key, original in pairs(snap) do
            if desired[key] == nil then
                if not boosterPro.restoreBoosterProperty(obj, snap, key, original) then
                    boosterPro.restoreFailures = boosterPro.restoreFailures + 1
                    if boosterPro.restoreFailures <= 3 then
                        warn("[124 Visuals] Booster mode downgrade failed for " .. tostring(key))
                    end
                end
            end
        end
    end
    for key, target in pairs(desired) do
        local read, current = pcall(function() return obj[key] end)
        if read and current ~= target then
            local previousWrite = boosterPro.graphicsWritten[obj]
            if snap and snap[key] ~= nil and previousWrite
                and previousWrite[key] ~= nil and current ~= previousWrite[key] then
                -- The game changed this property while Booster was active:
                -- remember the newer baseline before applying the new mode.
                snap[key] = current
            end
            local wrote = pcall(function() obj[key] = target end)
            if wrote then
                if not snap then snap = {}; savedGraphics[obj] = snap end
                if snap[key] == nil then snap[key] = current end
                local written = boosterPro.graphicsWritten[obj]
                if not written then written = {}; boosterPro.graphicsWritten[obj] = written end
                written[key] = target
                local checked, applied = pcall(function() return obj[key] end)
                if checked and applied == target then
                    boosterPro.changedProperties = boosterPro.changedProperties + 1
                end
            end
        end
    end
    if snap and not next(snap) then
        savedGraphics[obj] = nil
        boosterPro.graphicsWritten[obj] = nil
    end
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
            if count >= CONFIG.BoosterBatch or (count % 8 == 0 and
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
        if not boosterPro.restoreBoosterProperty(obj, snapshot, key, original) then
            left = true
            boosterPro.restoreFailures = boosterPro.restoreFailures + 1
            if boosterPro.restoreFailures <= 3 then
                warn("[124 Visuals] Booster: failed to restore " .. tostring(key)
                    .. " for " .. tostring(obj.Name))
            end
        end
    end
    if not left then
        savedGraphics[obj] = nil
        boosterPro.graphicsWritten[obj] = nil
    end
end

-- Снимки могли появиться раньше, чем Roblox объявил Model персонажем.
-- Инициируется CharacterAdded или поступлением Humanoid/частей тела.
function boosterPro.restoreGraphicsEmergency()
    local count, sliceStarted = 0, os.clock()
    for obj, snapshot in pairs(savedGraphics) do
        boosterPro.restoreObject(obj, snapshot)
        count = count + 1
        if count % 4 == 0 and ((os.clock() - sliceStarted) * 1000 >=
            CONFIG.BoosterSliceMs or count % CONFIG.BoosterBatch == 0) then
            task.wait()
            sliceStarted = os.clock()
        end
    end
    return next(savedGraphics) == nil
end

-- Late characters are NOT scanned when there are no graphics snapshots.
-- A single owner drains all character restorations in small, nonblocking slices.
-- This matters on accessory-heavy respawns/StreamingEnabled bursts.
boosterPro.protectedRestoreQueue = {}
boosterPro.protectedRestoreSeen = setmetatable({}, {__mode = "k"})
boosterPro.protectedRestoreRunning = false
function boosterPro.restoreProtectedTree(character)
    if not alive or not character or next(savedGraphics) == nil then return end
    if boosterPro.protectedRestoreSeen[character] then return end
    boosterPro.protectedRestoreSeen[character] = true
    local queue = boosterPro.protectedRestoreQueue
    queue[#queue + 1] = character
    if boosterPro.protectedRestoreRunning then return end
    boosterPro.protectedRestoreRunning = true
    task.spawn(function()
        local ok, err = pcall(function()
            while alive and #queue > 0 do
                local current = table.remove(queue, 1)
                if current then
                    local stack = {current}
                    local count, sliceStart = 0, os.clock()
                    while alive and #stack > 0 and next(savedGraphics) ~= nil do
                        local obj = stack[#stack]
                        stack[#stack] = nil
                        local snapshot = savedGraphics[obj]
                        if snapshot then boosterPro.restoreObject(obj, snapshot) end
                        local children = obj:GetChildren()
                        for i = 1, #children do
                            stack[#stack + 1] = children[i]
                        end
                        count = count + 1
                        if count >= 16 or (count % 4 == 0 and
                            (os.clock() - sliceStart) * 1000 >= CONFIG.BoosterLowFpsSliceMs) then
                            task.wait()
                            count, sliceStart = 0, os.clock()
                        end
                    end
                    boosterPro.protectedRestoreSeen[current] = nil
                end
            end
        end)
        -- Unexpected failures cannot leave the queue permanently latched.
        -- Unrestored snapshots remain in savedGraphics for normal retry.
        table.clear(queue)
        table.clear(boosterPro.protectedRestoreSeen)
        boosterPro.protectedRestoreRunning = false
        if not ok and alive then
            warn("[124 Community Visuals] Protected restore: " .. tostring(err))
        end
    end)
end

local function setBooster(enabled, keepBaseline)
    boosterRevision = boosterRevision + 1
    local revision = boosterRevision
    boosterPro.revision = revision
    -- Любая новая ревизия отменяет ожидающий фоновый откат старой.
    boosterPro.restoreRetryAt = 0
    boosterPro.restoreRetryRunning = false
    boosterPro.terrainRestoreRetryAt = 0
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
        -- Кнопка возвращает управление сразу. Тяжёлые операции Terrain/карты
        -- начинаются вне обработчика UI; каждая ревизия проверяет актуальность.
        task.spawn(function()
            local ok, err = pcall(function()
            if not alive or revision ~= boosterRevision or not state.booster then return end
            applyLighting()
            if state.boosterMode == "BALANCED" then
                restoreTerrainGrass()
                restoreTerrainColors()
            else
                hideTerrainGrass()
                whitenTerrain()
            end
            if not alive or revision ~= boosterRevision or not state.booster then return end
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
            -- BALANCED: быстрый путь, карта не перебирается и не изменяется.
            -- WHITE/ULTRA: полный обход по CPU-срезам, только по выбору игрока.
            if state.boosterMode ~= "BALANCED"
                and not optimizeHierarchy(Workspace, revision) then return end
            if not optimizeHierarchy(Lighting, revision) then return end
            if revision ~= boosterRevision or not state.booster then return end
            boosterPro.complete = true
            boosterPro.phase = state.boosterMode == "BALANCED" and "READY FAST" or "READY"
            boosterPro.readyAt = os.clock() + 1.5
            -- Compare FPS only after optimization actually finishes; earlier
            -- samples include initial workload and would trigger a false auto-rollback.
            boosterPro.afterFPS = {}
            boosterPro.after = nil
            boosterPro.guardLowSince = nil
            tell("FPS Booster Pro: " .. state.boosterMode .. " применён; просмотрено "
                .. tostring(boosterPro.scanned)
                .. (state.boosterMode == "BALANCED" and " объектов; карта без изменений; измеряем FPS"
                    or " объектов; измеряем FPS"))
            end)
            if not ok and alive and revision == boosterRevision and state.booster then
                boosterPro.complete = false
                boosterPro.phase = "FAILED"
                boosterPro.failed = tostring(err)
                boosterPro.lastError = boosterPro.failed
                warn("[124 Community Visuals] Booster: ошибка полного обхода: " .. boosterPro.failed)
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
        -- Отключение тоже не должно выполнять Terrain/Lighting-перезаписи
        -- внутри обработчика кнопки: всё выполняет контролируемый worker.
        task.spawn(function()
            local ok, err = pcall(function()
            if revision ~= boosterRevision or state.booster then return end
            restoreTerrainGrass()
            restoreTerrainColors()
            applyLighting()
            if revision ~= boosterRevision or state.booster then return end
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
                local terrainPending = savedTerrainDecoration ~= nil
                    or savedTerrainColors ~= nil
                -- Lighting kept intentionally by FullBright is not a pending
                -- Booster rollback: only unowned Lighting needs restoring.
                local restorePending = remaining > 0 or terrainPending
                    or (savedLighting ~= nil and not state.fullbright)
                boosterPro.phase = restorePending and "RESTORE PENDING"
                    or (boosterPro.lastError and "FAILED" or "OFF")
                if restorePending or boosterPro.restoreFailures > 0 then
                    tell("FPS Booster Pro: частичный откат, ошибок "
                        .. tostring(boosterPro.restoreFailures) .. ", объектов с остатком "
                        .. tostring(remaining))
                else
                    tell("FPS Booster Pro: исходные свойства восстановлены")
                end
            end
            end)
            if not ok and alive and revision == boosterRevision and not state.booster then
                boosterPro.phase = "RESTORE PENDING"
                boosterPro.lastError = "restore worker: " .. tostring(err)
                boosterPro.restoreRetryAt = 0
                warn("[124 Visuals] Booster rollback worker: " .. tostring(err))
            end
        end)
    end
end

-- AIM: поиск объекта в FOV, сохранение цели, необязательная проверка видимости.
-- ВАЖНО: отключение Visible Check пропускает Raycast, но объект должен быть перед камерой.
-- ПК: удерживание ПКМ. Android: кнопка AIM.
-- A streamed or malformed rig may contain a non-part named Head/Torso.
-- Filter candidates *before* accepting the first match.
local function aimPart(character, name)
    local candidate = character:FindFirstChild(name)
    return candidate and candidate:IsA("BasePart") and candidate or nil
end
local function targetPart(character)
    if state.aimMode == "head" then
        return aimPart(character, "Head")
    elseif state.aimMode == "body" then
        return aimPart(character, "UpperTorso")
            or aimPart(character, "Torso")
            or aimPart(character, "HumanoidRootPart")
    end
    return aimPart(character, "LeftLowerLeg")
        or aimPart(character, "RightLowerLeg")
        or aimPart(character, "Left Leg")
        or aimPart(character, "Right Leg")
        or aimPart(character, "LeftUpperLeg")
        or aimPart(character, "RightUpperLeg")
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
        local offset = velocity * state.predictionSeconds
        local distance = offset.Magnitude
        if distance > CONFIG.AimPredictionMaxStuds then
            offset = offset * (CONFIG.AimPredictionMaxStuds / distance)
        end
        point = point + offset
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
                center, fov * CONFIG.AimLockTolerance, false)
            if kept then
                if not state.visibleCheck or canSee(camera, chosen.Position, kept.character) then
                    aimPro.blockedSince = 0
                    return done(kept)
                end
                -- Keep the same target briefly without moving the camera
                -- through a wall. A single streaming/LOS miss won't retarget.
                local now = os.clock()
                if aimPro.blockedSince == 0 then aimPro.blockedSince = now end
                if now - aimPro.blockedSince < CONFIG.AimOcclusionGraceSeconds then
                    kept.blocked = true
                    return done(kept)
                end
            end
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
    local tested = 0
    for _, candidate in ipairs(candidates) do
        if tested >= CONFIG.AimLosCandidatesPerScan then break end
        tested = tested + 1
        if canSee(camera, candidate.part.Position, candidate.character) then
            aimPro.blockedSince = 0
            return done(candidate)
        end
    end
    aimPro.blockedSince = 0
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
        local previous = aimTarget
        aimTarget = findAimTarget(camera)
        if not aimTarget or (previous and previous.player ~= aimTarget.player) then
            aimPro.blockedSince = 0
        end
        scannedThisFrame = true
        if aimTarget then
            -- Новый поиск уже сделал LOS при включённом Visible Check.
            aimPro.nextLos = now + losInterval
        end
    end
    local current = aimTarget
    -- Отсутствие цели НЕ обнуляет таймер поиска (было до 60 сканов/с).
    if not current then return end
    -- Occluded lock is retained for stability but NEVER drives the camera.
    if current.blocked then return end
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
            if state.targetLock then
                if aimPro.blockedSince == 0 then aimPro.blockedSince = now end
                if now - aimPro.blockedSince < CONFIG.AimOcclusionGraceSeconds then
                    current.blocked = true
                    aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
                    return
                end
            end
            aimPro.blockedSince = 0
            aimTarget = nil
            aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
            return
        end
        aimPro.blockedSince = 0
        aimPro.nextLos = now + losInterval
    end
    local goal = CFrame.lookAt(origin, predictedPoint(part))
    if state.aimSmoothness == 0 then
        camera.CFrame = goal
    else
        -- Frame-rate independent smoothing with a bounded angular step.
        -- Avoid a sudden jump on a late frame without altering Smooth=0.
        local cx, cy, cz = camera.CFrame:ToOrientation()
        local gx, gy = goal:ToOrientation()
        local speed = CONFIG.AimSmoothnessBaseline / state.aimSmoothness
        local dtSafe = math.clamp(dt, 0, 0.05)
        local alphaX = math.clamp(1 - math.exp(-speed * state.aimSmoothX / 5 * dtSafe), 0, 1)
        local alphaY = math.clamp(1 - math.exp(-speed * state.aimSmoothY / 5 * dtSafe), 0, 1)
        local maxStep = math.rad(CONFIG.AimMaxTurnDegreesPerSecond) * dtSafe
        local pitchStep = math.clamp(signedAngle(cx, gx) * alphaY, -maxStep, maxStep)
        local yawStep = math.clamp(signedAngle(cy, gy) * alphaX, -maxStep, maxStep)
        camera.CFrame = CFrame.new(origin) * CFrame.fromOrientation(
            cx + pitchStep, cy + yawStep, cz)
    end
end

local recoil = (function()
local controller = {bound = false, shots = 0, bindingName = "Army124CommunityRecoil_" .. tostring(LocalPlayer.UserId)}
-- RECOIL CONTROL v1.1.63 — наблюдение камеры и локального ввода стрельбы.
-- Не обращается к RemoteEvent, не меняет параметры оружия и не даёт гарантий
-- против серверного разброса или нестандартных систем с другим camera pipeline.
-- Критический инвариант: без активного Tool + факта выстрела CFrame НЕ меняется.
local recoilTool = nil
local recoilToolConnections = {}
local recoilCharacterConnections = {}
local recoilLastCamera = nil
local recoilLastPitch = nil
local recoilLastCorrection = 0
local recoilFireUntil = 0
local recoilHolding = false
local recoilHoldStarted = 0
local recoilLastPulseAt = -math.huge
local recoilFireInput = nil

-- Клиентский No Spread: только явные параметры NumberValue/IntValue/
-- числовые атрибуты текущего Tool. ModuleScript и серверные траектории не меняем.
-- Снимок старого значения сохраняется до выключения функции/смены Tool.
local spreadParameterNames = {
    spread = true, bulletspread = true, hipspread = true, aimspread = true,
    minspread = true, maxspread = true, initialspread = true,
    spreadangle = true, spreaddegrees = true, spreadmultiplier = true,
    inaccuracy = true, bloom = true, bulletbloom = true,
    basespread = true, hipfirespread = true, adsspread = true,
    aimingspread = true, weaponspread = true, projectilespread = true,
    bloompershot = true, bloomperbullet = true, spreadpershot = true,
    spreadperbullet = true, accuracypenalty = true,
    coneangle = true, conespread = true,
}
controller.spread = {
    originals = setmetatable({}, {__mode = "k"}), modified = 0,
    nextCheckAt = 0, currentTool = nil, candidates = {}, lastErrorAt = 0,
    candidateSet = setmetatable({}, {__mode = "k"}),
    watchers = {}, generation = 0, queued = false, applying = false,
    lastReactiveAt = -math.huge,
}
local function isSpreadParameter(name)
    return type(name) == "string"
        and spreadParameterNames[string.lower(name):gsub("[^%w]", "")] == true
end
-- Индекс и наблюдатели удаляются при смене оружия или отключении функции.
local function clearSpreadIndex()
    local spread = controller.spread
    spread.generation = spread.generation + 1
    spread.queued = false
    spread.lastReactiveAt = -math.huge
    for _, group in pairs(spread.watchers) do
        for _, connection in ipairs(group) do
            pcall(function() connection:Disconnect() end)
        end
    end
    table.clear(spread.watchers)
    table.clear(spread.candidates)
    table.clear(spread.candidateSet)
    spread.currentTool = nil
end
local function queueSpreadRefresh()
    local spread = controller.spread
    if not alive or not state.noSpread or spread.queued or spread.applying then return end
    spread.queued = true
    local generation = spread.generation
    -- Один отложенный проход для множества Value/AttributeChanged за кадр.
    -- После короткой паузы система проверяет актуальное состояние Tool.
    local now = os.clock()
    local waitSeconds = math.max(0,
        CONFIG.SpreadEventMinSeconds - (now - spread.lastReactiveAt))
    task.delay(waitSeconds, function()
        if spread.generation ~= generation then return end
        spread.queued = false
        if alive and state.noSpread and recoilTool == spread.currentTool then
            spread.lastReactiveAt = os.clock()
            pcall(controller.applySpread)
        end
    end)
end
local function hasSpreadAttribute(instance)
    local ok, attrs = pcall(function() return instance:GetAttributes() end)
    if not ok then return false end
    for name in pairs(attrs) do
        if isSpreadParameter(name) then return true end
    end
    return false
end
local function registerSpreadCandidate(instance)
    local spread = controller.spread
    if not instance or spread.candidateSet[instance] then return end
    local numeric = (instance:IsA("NumberValue") or instance:IsA("IntValue"))
        and isSpreadParameter(instance.Name)
    local attrs = instance == recoilTool or instance:IsA("Configuration")
        or instance:IsA("Folder") or instance:IsA("ModuleScript")
        or hasSpreadAttribute(instance)
    if not numeric and not attrs then return end
    spread.candidateSet[instance] = true
    spread.candidates[#spread.candidates + 1] = instance
    if numeric then
        local ok, conn = pcall(function()
            return instance:GetPropertyChangedSignal("Value"):Connect(function()
                if not state.noSpread or spread.applying then return end
                local good, value = pcall(function() return instance.Value end)
                if good and type(value) == "number" and value > 0 then
                    queueSpreadRefresh()
                end
            end)
        end)
        if ok then
            local group = spread.watchers[instance]
            if not group then group = {}; spread.watchers[instance] = group end
            group[#group + 1] = conn
        end
    end
    if attrs then
        local ok, conn = pcall(function()
            return instance.AttributeChanged:Connect(function(name)
                if not state.noSpread or spread.applying
                    or not isSpreadParameter(name) then return end
                local good, value = pcall(function() return instance:GetAttribute(name) end)
                if good and type(value) == "number" and value > 0 then
                    queueSpreadRefresh()
                end
            end)
        end)
        if ok then
            local group = spread.watchers[instance]
            if not group then group = {}; spread.watchers[instance] = group end
            group[#group + 1] = conn
        end
    end
end

-- Удалённые дочерние объекты не должны удерживать старые подписки до смены Tool.
local function unregisterSpreadCandidate(instance)
    local spread = controller.spread
    local group = spread.watchers[instance]
    if group then
        for _, connection in ipairs(group) do
            pcall(function() connection:Disconnect() end)
        end
        spread.watchers[instance] = nil
    end
    spread.candidateSet[instance] = nil
    for i = #spread.candidates, 1, -1 do
        if spread.candidates[i] == instance then
            table.remove(spread.candidates, i)
            break
        end
    end
end

function controller.restoreSpread()
    -- Отмена подписок до восстановления не даёт возвращённым значениям
    -- вызвать повторное зануление.
    clearSpreadIndex()
    local originals = controller.spread.originals
    local allRestored = true
    for instance, saved in pairs(originals) do
        if not instance or not instance.Parent then
            -- Объект удалён самой игрой: возвращать свойства больше некуда.
            originals[instance] = nil
        else
            if saved.value ~= nil then
                local ok = pcall(function()
                    -- Если игра сама сменила значение, не перезаписываем его.
                    if instance.Value == 0 then
                        instance.Value = saved.value
                        if instance.Value ~= saved.value then
                            error("No Spread value restore mismatch")
                        end
                    end
                end)
                if ok then saved.value = nil else allRestored = false end
            end
            for attr, before in pairs(saved.attributes) do
                local ok = pcall(function()
                    if instance:GetAttribute(attr) == 0 then
                        instance:SetAttribute(attr, before)
                        if instance:GetAttribute(attr) ~= before then
                            error("No Spread attribute restore mismatch")
                        end
                    end
                end)
                if ok then saved.attributes[attr] = nil else allRestored = false end
            end
            -- При отказе Roblox API снимок остаётся для следующих попыток.
            if saved.value == nil and next(saved.attributes) == nil then
                originals[instance] = nil
            end
        end
    end
    if allRestored then controller.spread.modified = 0 end
    return allRestored
end

function controller.spread.pending()
    return next(controller.spread.originals) ~= nil
end

function controller.applySpread()
    local tool = recoilTool
    if not alive or not state.noSpread or not tool
        or tool.Parent ~= LocalPlayer.Character then return 0 end
    local originals = controller.spread.originals
    local spread = controller.spread
    if spread.currentTool ~= tool then
        clearSpreadIndex()
        spread.currentTool = tool
        registerSpreadCandidate(tool)
        local ok, descendants = pcall(function() return tool:GetDescendants() end)
        if not ok then
            spread.currentTool = nil -- Следующее событие сможет повторить индексацию.
            return 0
        end
        for _, descendant in ipairs(descendants) do
            registerSpreadCandidate(descendant)
        end
    end
    local changed = 0
    local function patch(instance)
        if (instance:IsA("NumberValue") or instance:IsA("IntValue"))
            and isSpreadParameter(instance.Name) then
            local value = instance.Value
            if value > 0 and value < 1000000 then
                local saved = originals[instance]
                if not saved then saved = {attributes = {}}; originals[instance] = saved end
                if saved.value == nil then saved.value = value end
                instance.Value = 0
                changed = changed + 1
            end
        end
        -- Атрибуты отслеживаем только у Tool и конфигурационных контейнеров,
        -- чтобы не обходить избыточные Attributes каждой геометрической детали.
        if spread.candidateSet[instance] then
            for name, value in pairs(instance:GetAttributes()) do
                if isSpreadParameter(name) and type(value) == "number"
                    and value > 0 and value < 1000000 then
                    local saved = originals[instance]
                    if not saved then saved = {attributes = {}}; originals[instance] = saved end
                    if saved.attributes[name] == nil then saved.attributes[name] = value end
                    instance:SetAttribute(name, 0)
                    changed = changed + 1
                end
            end
        end
    end
    local errors, firstError = 0, nil
    local candidates = spread.candidates
    spread.applying = true
    for i = #candidates, 1, -1 do
        local instance = candidates[i]
        local ok, err = pcall(function()
            if not instance.Parent
                or (instance ~= tool and not instance:IsDescendantOf(tool)) then
                unregisterSpreadCandidate(instance)
            else
                patch(instance)
            end
        end)
        if not ok then
            errors = errors + 1
            if not firstError then firstError = err end
        end
    end
    spread.applying = false
    if errors > 0 and os.clock() - spread.lastErrorAt >= 4 then
        spread.lastErrorAt = os.clock()
        warn("[124 Visuals] No Spread local: " .. tostring(firstError)
            .. " | failures=" .. tostring(errors))
    end
    controller.spread.modified = controller.spread.modified + changed
    return changed
end

local function stopRecoilFire()
    recoilHolding = false
    recoilFireUntil = 0
end

local function resetRecoilTracking()
    stopRecoilFire()
    recoilLastPulseAt = -math.huge
    recoilFireInput = nil
    recoilLastCamera = nil
    recoilLastPitch = nil
    recoilLastCorrection = 0
end

local function disconnectRecoilConnections(collection)
    for _, conn in ipairs(collection) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(collection)
end

local function markRecoilShot()
    if not alive or not recoilTool then return end
    local now = os.clock()
    -- Отложенная проверка после того, как оружие обновило локальные параметры.
    if state.noSpread and now >= controller.spread.nextCheckAt then
        controller.spread.nextCheckAt = now + CONFIG.SpreadShotRecheckSeconds
        local firedTool = recoilTool
        task.delay(CONFIG.SpreadPostShotSeconds, function()
            if alive and state.noSpread and recoilTool == firedTool then
                pcall(controller.applySpread)
            end
        end)
    end
    if not (state.controlRecoil or state.noRecoil) then return end
    -- Tool.Activated и физическое нажатие часто приходят одним пакетом.
    if now - recoilLastPulseAt >= CONFIG.RecoilInputDedupSeconds then
        controller.shots = controller.shots + 1
        recoilLastPulseAt = now
    end
    -- Первый выстрел после включения: до первого RenderStep ещё нет эталонного
    -- pitch. Берём его при Tool.Activated, чтобы не пропускать начальный подброс.
    if recoilLastPitch == nil then
        local camera = Workspace.CurrentCamera
        if camera then
            recoilLastCamera = camera
            recoilLastPitch = camera.CFrame:ToOrientation()
        end
    end
    -- Every Tool.Activated pulse renews the firing watchdog, even when
    -- an automatic weapon omits Deactivated between successive shots.
    recoilHoldStarted = now
    recoilHolding = true
    recoilFireUntil = now + CONFIG.RecoilFireWindowSeconds
end

-- Дополнительный сигнал для оружия без Tool.Activated.
-- На телефоне обычные касания камеры не считаются стрельбой.
local function isTouchFireButton(position)
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return false end
    local ok, objects = pcall(function()
        return playerGui:GetGuiObjectsAtPosition(position.X, position.Y)
    end)
    if not ok then return false end
    for _, object in ipairs(objects) do
        local current = object
        for _ = 1, 4 do
            if not current or current == playerGui then break end
            if current:IsA("GuiButton") then
                local name = string.lower(current.Name):gsub("[^%w]", "")
                if string.find(name, "fire", 1, true)
                    or string.find(name, "shoot", 1, true)
                    or string.find(name, "attack", 1, true)
                    or string.find(name, "trigger", 1, true) then
                    return true
                end
            end
            current = current.Parent
        end
    end
    return false
end
connect(UserInputService.InputBegan, function(input, processed)
    if not alive or not recoilTool or recoilTool.Parent ~= LocalPlayer.Character
        or not (state.controlRecoil or state.noRecoil) then return end
    if isRobloxMenuOpen() or UserInputService:GetFocusedTextBox() ~= nil then return end
    local kind = input.UserInputType
    local fire = (kind == Enum.UserInputType.MouseButton1 and not processed)
        or (kind == Enum.UserInputType.Gamepad1
            and input.KeyCode == Enum.KeyCode.ButtonR2 and not processed)
        or (kind == Enum.UserInputType.Touch and isTouchFireButton(input.Position))
    if fire then
        recoilFireInput = input
        markRecoilShot()
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input ~= recoilFireInput then return end
    recoilFireInput = nil
    recoilHolding = false
    recoilFireUntil = math.max(recoilFireUntil,
        os.clock() + CONFIG.RecoilShotGraceSeconds)
end)

local function equipRecoilTool(tool)
    if recoilTool == tool then return end
    controller.restoreSpread()
    controller.spread.nextCheckAt = 0
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
        if state.noSpread then controller.applySpread() end
        recoilToolConnections[#recoilToolConnections + 1] = tool.DescendantAdded:Connect(function(obj)
            if alive and state.noSpread and recoilTool == tool then
                registerSpreadCandidate(obj)
                if controller.spread.candidateSet[obj] then queueSpreadRefresh() end
            end
        end)
        recoilToolConnections[#recoilToolConnections + 1] = tool.DescendantRemoving:Connect(function(obj)
            -- Immediate/Deferred: проверяем Parent на следующем цикле.
            -- Быстро пересозданный/возвращённый объект нельзя забывать.
            task.defer(function()
                if recoilTool ~= tool or not alive then return end
                local ok, stillInside = pcall(function() return obj:IsDescendantOf(tool) end)
                if (not ok or not stillInside) and controller.spread.candidateSet[obj] then
                    unregisterSpreadCandidate(obj)
                end
            end)
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
    controller.restoreSpread()
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
    -- No Spread не зависит от состояния компенсации камеры.
    if alive and state.noSpread and recoilTool
        and recoilTool.Parent == LocalPlayer.Character then
        local now = os.clock()
        if now >= controller.spread.nextCheckAt then
            controller.spread.nextCheckAt = now + CONFIG.SpreadVerificationSeconds
            pcall(controller.applySpread)
        end
    end
    -- OFF: нулевые вычисления углов камеры.
    -- После включения первый кадр записывает базу, не компенсируя
    -- несуществующий скачок на границе состояний.
    if not alive or (not state.controlRecoil and not state.noRecoil)
        or (not state.noRecoil and state.recoilStrength <= 0)
        or recoilTool == nil or recoilTool.Parent ~= LocalPlayer.Character then
        recoilLastCamera, recoilLastPitch = nil, nil
        recoilLastCorrection = 0
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
    recoilLastCorrection = 0
    if not sameCamera or previousPitch == nil then return end
    if isRobloxMenuOpen() or UserInputService:GetFocusedTextBox() ~= nil then return end
    -- AIM owns the camera during active aiming, even when the target was
    -- just lost. Avoid alternating camera writers on intermittent LOS loss.
    if state.aimbot and (aimHeldMouse or aimHeldTouch or aimHeldKey) then return end
    local now = os.clock()
    local fireInputHeld = recoilFireInput ~= nil
    -- Tool.Activated бывает без InputBegan (обработанный ввод в gun framework).
    -- Реально зажатую кнопку мыши проверяем независимо от processed.
    if not fireInputHeld and recoilHolding and UserInputService.MouseEnabled then
        local ok, pressed = pcall(function()
            return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        end)
        fireInputHeld = ok and pressed == true
    end
    local firing = now <= recoilFireUntil
        or (recoilHolding and now - recoilHoldStarted
            <= (fireInputHeld and CONFIG.RecoilMaxHoldSeconds
                or CONFIG.RecoilOrphanHoldSeconds))
    if not firing or dt <= 0 or dt > CONFIG.RecoilMaxFrameSeconds then return end
    local pitchUp = signedAngle(previousPitch, currentPitch)
    if pitchUp < math.rad(CONFIG.RecoilMinPitchDegrees)
        or pitchUp > math.rad(CONFIG.RecoilMaxPitchDegrees) then return end
    -- No Recoil компенсирует весь обнаруженный подброс в пределах защитных
    -- порогов. Не маскируем серверный recoil и не подавляем ручные движения.
    local frameCap = state.noRecoil and math.rad(CONFIG.RecoilMaxPitchDegrees)
        or math.min(
            math.rad(CONFIG.RecoilMaxCorrectionDegrees),
            math.rad(CONFIG.RecoilMaxCorrectionPerSecond) * math.clamp(dt, 0, 0.05)
        )
    local strength = state.noRecoil and 1 or (state.recoilStrength / 100)
    local correction = math.min(pitchUp * strength, frameCap)
    if correction <= 0 then return end
    -- Limit time-based angular correction so high refresh rates don't
    -- amplify single-frame noise; preserve camera yaw and position.
    camera.CFrame = camera.CFrame * CFrame.Angles(-correction, 0, 0)
    recoilLastPitch = camera.CFrame:ToOrientation()
    recoilLastCorrection = math.deg(correction)
end

-- END RECOIL CONTROL v1.1.63
controller.reset = resetRecoilTracking
controller.shutdown = shutdownRecoilControl
controller.frame = recoilFrame
controller.inspect = function()
    return recoilTool and recoilTool.Name or "нет Tool",
        controller.shots, recoilLastCorrection
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
    state.noRecoil, state.noSpread = false, false
    state.speedEnabled, state.noclip, state.fly = false, false, false
    if boosterPro.privateMusic and boosterPro.privateMusic.shutdown then
        pcall(boosterPro.privateMusic.shutdown)
    end
    if boosterPro.movement and boosterPro.movement.shutdown then
        pcall(boosterPro.movement.shutdown)
    end
    pcall(function() recoil.shutdown() end)
    pcall(boosterPro.stopWatchingPlayers)
    pcall(stopESPWatchers)
    for player in pairs(renderData) do pcall(deleteRender, player) end
    if boosterPro.layoutCameraConnection then
        pcall(function() boosterPro.layoutCameraConnection:Disconnect() end)
        boosterPro.layoutCameraConnection = nil
    end
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
    -- Retryable recovery for any graphics, camera or character pose writes
    -- made before this UI initialization failed. Never silently discard
    -- original property snapshots on a failed early shutdown.
    local function tryPartialRestore()
        local graphicsOk, graphicsRestored = pcall(boosterPro.restoreGraphicsEmergency)
        pcall(restoreTerrainGrass)
        pcall(restoreTerrainColors)
        pcall(applyLighting)
        local uiOk, uiRestored = pcall(emergencyUIRollback)
        return graphicsOk and graphicsRestored == true
            and savedLighting == nil and savedTerrainDecoration == nil
            and savedTerrainColors == nil
            and uiOk and uiRestored == true
    end
    local previousRecovery = env.ARMY124_RECOVERY
    if not tryPartialRestore() then
        local retry
        retry = function()
            local previousDone = true
            if type(previousRecovery) == "function" then
                local ok, done = pcall(previousRecovery)
                previousDone = ok and done == true
            end
            local restored = tryPartialRestore()
            if previousDone and restored and env.ARMY124_RECOVERY == retry then
                env.ARMY124_RECOVERY = nil
            end
            return previousDone and restored
        end
        env.ARMY124_RECOVERY = retry
        warn("[124 Community Visuals] Аварийный откат не завершён; сохранено восстановление.")
    end
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
    -- CoreUISafeInsets keeps menu controls below Roblox chat/backpack buttons.
    IgnoreGuiInset = false,
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
    if not alive or not state.esp or not state.espBox then
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
    local ok = pcall(function()
        if camera.FieldOfView ~= old then camera.FieldOfView = old end
        if camera.FieldOfView ~= old then error("Camera FOV restore mismatch") end
    end)
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
            local ok = pcall(function()
                if object[property] ~= value then object[property] = value end
                if object[property] ~= value then error("Spin pending restore mismatch") end
            end)
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
        local ok = pcall(function()
            if spin.joint.C0 ~= spin.originalC0 then spin.joint.C0 = spin.originalC0 end
            if spin.joint.C0 ~= spin.originalC0 then error("Joint C0 restore mismatch") end
        end)
        if not ok then
            local pending = spin.pending[spin.joint] or {}
            -- Не заменяем ранее сохранённый оригинал новым повреждённым состоянием.
            if pending.C0 == nil then pending.C0 = spin.originalC0 end
            spin.pending[spin.joint] = pending
        end
    end
    if spin.humanoid and spin.originalAuto ~= nil then
        local ok = pcall(function()
            if spin.humanoid.AutoRotate ~= spin.originalAuto then
                spin.humanoid.AutoRotate = spin.originalAuto
            end
            if spin.humanoid.AutoRotate ~= spin.originalAuto then
                error("AutoRotate restore mismatch")
            end
        end)
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

-- LITE: no Bunny Hop or chat workers.
emergencyUIRollback = function()
    local cameraOK, cameraRestored = pcall(memoryFX.camera.reset)
    local spinOK, spinRestored = pcall(memoryFX.spin.reset)
    local spreadOK, spreadRestored = pcall(recoil.restoreSpread)
    return cameraOK and cameraRestored == true and spinOK and spinRestored == true
        and spreadOK and spreadRestored == true
end

-- Сохраняем только ограниченный набор настроек; код из JSON никогда не выполняется.
local HttpService = game:GetService("HttpService")
local storedKeys = {
    "esp", "tracers", "names", "health", "distance", "teamColors", "espBox",
    "espEnemyOnly", "crosshairLocal", "espRangeMeters", "espMaxTargets", "espColorPreset", "espLineThickness", "performanceMode",
    "performanceGuard", "moduleCpuMonitor", "lazyLoading",
    "sessionDiagnostics",
    "aimbot", "aimRangeMeters", "aimSmoothness", "aimSmoothX", "aimSmoothY",
    "prediction", "predictionSeconds", "targetLock", "aimFovPixels", "aimMode",
    "aimOnlyRegisteredWeapons", "aimWeaponNames",
    "fovVisible", "fovThickness", "visibleCheck", "teamCheck", "fullbright", "booster",
    "antiAfk", "airAlerts", "hud", "activeHud", "aimKeyName", "controlRecoil", "noRecoil", "noSpread", "recoilStrength", "boosterMode",
    "cameraFovEnabled", "cameraFovDegrees", "antiAim", "antiAimSpeed", "antiAimTilt",
    "speedEnabled", "speedValue", "noclip", "fly", "flySpeed",
    "musicId", "musicVolume", "musicLoop",
}
local numericRules = {
    espRangeMeters = {CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters}, espMaxTargets = {8, 96},
    espLineThickness = {1, 2},
    aimRangeMeters = {5, 180}, aimSmoothness = {0, 10},
    aimSmoothX = {1, 10}, aimSmoothY = {1, 10},
    predictionSeconds = {0, 0.25}, aimFovPixels = {40, 400},
    fovThickness = {1, 4}, recoilStrength = {0, 100},
    cameraFovDegrees = {55, 110}, antiAimSpeed = {180, 1440}, antiAimTilt = {0, 25},
    speedValue = {8, 120}, flySpeed = {10, 150},
    musicVolume = {0, 100},
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
local weaponPreferences = {}
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
                elseif key == "musicId" then
                    -- Только десятичный Roblox asset ID, не Lua/URL.
                    if incoming == "" or (#incoming <= 19 and incoming:match("^%d+$")) then
                        result[key] = incoming
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
    weaponPreferences.aimOnlyRegisteredWeapons = state.aimOnlyRegisteredWeapons
    weaponPreferences.aimWeaponNames = state.aimWeaponNames
    local data = {version = 1, current = profileName,
        profiles = {CUSTOM = profiles.CUSTOM or {}},
        weaponPreferences = weaponPreferences}
    CONFIG.PlaceCache.config = data
    -- Исходный PlaceId совместим со старой настройкой памяти.
    if game.PlaceId == CONFIG.OriginalPlaceId then env.ARMY124_CONFIG_V09 = data end
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

local saveWorkerPending = false
local saveLastRequested = 0
requestSave = function()
    if restoring or not alive then return end
    dirtyToken = dirtyToken + 1
    saveLastRequested = os.clock()
    if saveWorkerPending then return end
    saveWorkerPending = true
    task.spawn(function()
        while alive do
            local remaining = 1.4 - (os.clock() - saveLastRequested)
            if remaining <= 0 then break end
            task.wait(math.max(0.05, remaining))
        end
        saveWorkerPending = false
        if alive then
            storeCustomSnapshot()
            writeProfileFile()
        end
    end)
end

local function readProfileFile()
    local loaded = CONFIG.PlaceCache.config
    if loaded == nil and game.PlaceId == CONFIG.OriginalPlaceId then
        loaded = env.ARMY124_CONFIG_V09
    end
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
        profileName = "CUSTOM"
    end
end
readProfileFile()

local function applySettingsGuard(action)
    restoring = true
    local ok, err = xpcall(action, function(reason) return tostring(reason) end)
    -- Даже при исключении внутри применения профиля сохраняем возможность
    -- редактировать настройки и выполнить Safety Stop / следующий профиль.
    restoring = false
    return ok, err
end

local function applySettings(incoming, autoLoad)
    local ok, err = applySettingsGuard(function()
    local sanitized = validatedSettings(incoming)
    local wasBooster = state.booster
    local oldBoosterMode = state.boosterMode
    for key, value in pairs(sanitized) do state[key] = value end
    -- Любой профиль обязан соблюдать взаимоисключение ручного Recoil и No Recoil.
    if state.noRecoil and state.controlRecoil then state.controlRecoil = false end
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
        state.noRecoil = false
        state.noSpread = false
        state.speedEnabled = false
        state.noclip = false
        state.fly = false
        -- Prevent an old saved profile from activating Booster before a baseline.
        -- The user may still enable it manually after loading the game.
        state.booster = false
        -- Аварийная загрузка после Safety Stop: старая файловая копия
        -- (при ошибке writefile) не должна снова включать опасные функции.
        if CONFIG.PlaceCache.safeBoot == true or (game.PlaceId == CONFIG.OriginalPlaceId
            and env.ARMY124_SAFE_BOOT == true) then
            state.esp = false
            state.tracers = false
            state.espBox = false
            state.controlRecoil = false
            state.noRecoil = false
            state.noSpread = false
            state.fullbright = false
            state.booster = false
            state.cameraFovEnabled = false
            state.speedEnabled = false
            state.noclip = false
            state.fly = false
            -- Не стираем чужой пресет; обновляем только активный CUSTOM.
            if profileName == "CUSTOM" then
                profiles.CUSTOM = snapshotState()
            end
            -- Переходим к обычному сохранению. Если файловые API недоступны,
            -- синхронный env cache всё равно содержит безопасный снимок.
            if writeProfileFile() then
                CONFIG.PlaceCache.safeBoot = nil
                -- Legacy flag принадлежит только исходному PlaceId.
                if game.PlaceId == CONFIG.OriginalPlaceId then
                    env.ARMY124_SAFE_BOOT = nil
                end
            end -- При отказе записи сохраняем флаг для следующего запуска.
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
    memoryFX.spin.reset()
    memoryFX.camera.apply()
    if boosterPro.movement then boosterPro.movement.sync() end
    if state.noSpread then pcall(recoil.applySpread)
    else pcall(recoil.restoreSpread) end
    if boosterPro.privateMusic and boosterPro.privateMusic.refresh then
        pcall(boosterPro.privateMusic.refresh)
    end
    -- The crosshair GUI is built before the saved CUSTOM profile is applied.
    -- Repaint its actual visibility, not only the toggle label.
    if boosterPro.setLocalCrosshair then
        boosterPro.setLocalCrosshair(state.crosshairLocal == true)
    end
    aimTarget = nil
    aimNextScan = 0
    end)
    if not ok then
        warn("[124 Community Visuals] Ошибка применения профиля: " .. tostring(err))
        pcall(tell, "Ошибка применения профиля. Проверь Output.")
        return false
    end
    for _, update in pairs(refreshToggles) do pcall(update) end
    for _, update in pairs(refreshSliders) do pcall(update) end
    pcall(repaintAimMode)
    pcall(repaintAimKeybind)
    pcall(repaintColors)
    pcall(repaintPerf)
    if boosterPro.repaint then pcall(boosterPro.repaint) end
    local synced, syncErr = pcall(syncEspVisuals)
    if not synced then
        warn("[124 Community Visuals] Ошибка визуальной синхронизации профиля: "
            .. tostring(syncErr))
        return false
    end
    return true
end

local function loadCustomSettings()
    -- Existing CUSTOM settings persist automatically; no CFG/preset UI.
    local values = table.clone(defaultSettings)
    for key, value in pairs(profiles.CUSTOM or {}) do values[key] = value end
    if type(weaponPreferences.aimOnlyRegisteredWeapons) == "boolean" then
        values.aimOnlyRegisteredWeapons = weaponPreferences.aimOnlyRegisteredWeapons
    end
    if type(weaponPreferences.aimWeaponNames) == "string" then
        values.aimWeaponNames = weaponPreferences.aimWeaponNames
    end
    return applySettings(values, true)
end

local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(390, 720)
-- The ScreenGui respects Roblox UI insets; use the same safe size for layout.
local function uiSafeView(raw)
    local ok, topLeft, bottomRight = pcall(function()
        return GuiService:GetGuiInset()
    end)
    if ok and typeof(topLeft) == "Vector2" and typeof(bottomRight) == "Vector2" then
        return Vector2.new(
            math.max(160, raw.X - topLeft.X - bottomRight.X),
            math.max(160, raw.Y - topLeft.Y - bottomRight.Y))
    end
    return raw
end
local TweenService = game:GetService("TweenService")
-- Premium violet palette. UI-only: gameplay and ESP colors are unchanged.
-- Static gradients and borders are cheap; no blur, particles or RenderStepped FX.
local P = {
    background = Color3.fromRGB(14, 12, 23),
    panel = Color3.fromRGB(22, 19, 34),
    tile = Color3.fromRGB(33, 29, 48),
    border = Color3.fromRGB(75, 60, 99),
    text = Color3.fromRGB(245, 242, 255),
    dim = Color3.fromRGB(170, 160, 193),
    accent = Color3.fromRGB(176, 115, 255),
    off = Color3.fromRGB(67, 65, 84),
}
-- На телефоне даже альбомный экран остаётся одноколоночным: элементы
-- управления не должны уменьшаться до нечитабельного размера.
local function isReferenceLandscape(view)
    return UserInputService.TouchEnabled and view.X >= 480
        and view.Y >= 260 and view.X >= view.Y * 1.35
end
-- Mobile landscape uses the same full reference layout, with a single
-- uniform scale. Portrait and undersized desktop keep readable legacy lists.
local wideLayout = isReferenceLandscape(viewport)
    or ((not UserInputService.TouchEnabled) and viewport.X >= 770 and viewport.Y >= 560)
local function windowMetrics(view)
    view = uiSafeView(view)
    local mobile = UserInputService.TouchEnabled
    local screenshotMobile = isReferenceLandscape(view)
    local wide = screenshotMobile or ((not mobile) and view.X >= 770 and view.Y >= 560)
    if screenshotMobile then
        local scale = math.clamp(math.min((view.X - 12) / 950,
            (view.Y - 12) / 520), 0.36, 1)
        return 950, 520, true, scale
    end
    local landscape = view.X > view.Y
    local availableWidth = math.max(160, view.X - (mobile and 22 or 32))
    local preferredWidth = wide and 950 or (mobile and landscape and 520 or 410)
    local width = math.min(availableWidth, preferredWidth)
    local availableHeight = math.max(120, view.Y - (mobile and 22 or 38))
    local height = math.min(wide and 520 or 610, availableHeight)
    return width, height, wide, 1
end
local winWidth, winHeight, _, initialScale = windowMetrics(viewport)
local uiBaseScale = initialScale
-- Separate behind-the-panel aura: no UI-only painting over world geometry.
local aura = mk("Frame", {
    Name = "VioletAura", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(winWidth + 8, winHeight + 8),
    BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
}, gui)
round(aura, 18)
mk("UIStroke", {
    Color = Color3.fromRGB(133, 64, 241),
    Thickness = 10, Transparency = 0.82,
}, aura)
local auraInner = mk("Frame", {
    Name = "VioletAuraCore", Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, aura)
round(auraInner, 18)
mk("UIStroke", {
    Color = P.accent, Thickness = 3, Transparency = 0.53,
}, auraInner)
local auraScale = mk("UIScale", {Scale = uiBaseScale}, aura)
local panel = mk("Frame", {
    Name = "CommunityVisualsPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(winWidth, winHeight),
    BackgroundColor3 = P.background,
    BorderSizePixel = 0,
    Active = true, ClipsDescendants = true, ZIndex = 2,
}, gui)
round(panel, 18)
mk("UIStroke", {Color = P.accent, Transparency = 0.31, Thickness = 1.5}, panel)
local panelScale = mk("UIScale", {Scale = uiBaseScale}, panel)
local function syncVioletAura()
    if not panel.Parent or not aura.Parent then return end
    aura.Position = panel.Position
    aura.Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset + 8,
        panel.Size.Y.Scale, panel.Size.Y.Offset + 8)
    auraScale.Scale = panelScale.Scale
    aura.Visible = panel.Visible
end
connect(panel:GetPropertyChangedSignal("Position"), syncVioletAura)
connect(panel:GetPropertyChangedSignal("Size"), syncVioletAura)
connect(panel:GetPropertyChangedSignal("Visible"), syncVioletAura)
connect(panelScale:GetPropertyChangedSignal("Scale"), syncVioletAura)
syncVioletAura()
-- AnchorPoint-aware экранный clamp: возвращает панель / плавающую кнопку в кадр.
-- GUI работает с IgnoreGuiInset=true, поэтому размеры берём из ViewportSize.
function boosterPro.clampWindowPosition(position, size, anchor)
    local camera = Workspace.CurrentCamera
    local view = uiSafeView(camera and camera.ViewportSize or viewport)
    anchor = anchor or Vector2.new(0, 0)
    local width = view.X * size.X.Scale + size.X.Offset
    local height = view.Y * size.Y.Scale + size.Y.Offset
    -- Panel visual bounds differ from its nominal 950x520 frame when scaled
    -- for landscape mobile. Mini button is unaffected.
    if size == panel.Size then
        width = width * uiBaseScale
        height = height * uiBaseScale
    end
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
            Enum.EasingDirection.Out), {Scale = uiBaseScale * toScale})
    end)
    if ok and tween then panelTween = tween; tween:Play()
    else panelScale.Scale = uiBaseScale * toScale end
end
local function hidePanelAnimation()
    if panelTween then panelTween:Cancel(); panelTween = nil end
    panelScale.Scale = uiBaseScale
end
-- Static violet inner corner wash (no postprocessing or animated objects).
local cornerWash = mk("Frame", {
    Name = "VioletCornerWash", AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(310, 190),
    BackgroundColor3 = Color3.fromRGB(73, 29, 132),
    BackgroundTransparency = 0.58, BorderSizePixel = 0, Active = false,
}, panel)
round(cornerWash, 110)
mk("UIGradient", {
    Rotation = 30,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.24),
    }),
}, cornerWash)
mk("Frame", {
    Name = "TopAccent", BorderSizePixel = 0,
    BackgroundColor3 = P.accent,
    Position = UDim2.fromOffset(17, 0), Size = UDim2.fromOffset(110, 2),
}, panel)
local bar = mk("Frame", {
    Name = "DragBar", BackgroundColor3 = Color3.fromRGB(26, 20, 41),
    BackgroundTransparency = 0,
    Size = UDim2.new(1, 0, 0, 76), Active = true,
}, panel)
-- Static gradient only; no perpetual UI animation or extra frame hooks.
mk("UIGradient", {Rotation = 0,
    Color = ColorSequence.new(Color3.fromRGB(33, 24, 53),
        Color3.fromRGB(17, 15, 27))}, bar)
local emblem = mk("Frame", {
    Name = "BrandMark", Visible = false, BackgroundColor3 = P.tile,
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
    Position = UDim2.fromOffset(19, 14), Size = UDim2.new(1, -183, 0, 21),
    Text = "124 Visuals", TextColor3 = P.text, TextSize = 19,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, bar)
mk("TextLabel", {
    Name = "BrandCaption", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(21, 39), Size = UDim2.new(1, -183, 0, 16),
    Text = "v" .. CONFIG.Version,
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
    Position = UDim2.fromOffset(0, 75), Size = UDim2.new(1, 0, 0, 1),
}, panel)
-- Continuous glass content plate lives BEHIND independently scrollable pages.
local contentPlate = mk("Frame", {
    Name = "PremiumContentPlate",
    Position = UDim2.fromOffset(207, 81),
    Size = UDim2.new(1, -220, 1, -121),
    BackgroundColor3 = Color3.fromRGB(23, 19, 36),
    BorderSizePixel = 0, ClipsDescendants = true,
}, panel)
round(contentPlate, 15)
mk("UIStroke", {Color = P.accent, Transparency = 0.71, Thickness = 1}, contentPlate)
mk("UIGradient", {
    Rotation = 20,
    Color = ColorSequence.new(Color3.fromRGB(31, 24, 49),
        Color3.fromRGB(18, 16, 30)),
}, contentPlate)
local plateShine = mk("Frame", {
    Name = "VioletHeaderSheen", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0.52, 0, 0, 125),
    BackgroundColor3 = Color3.fromRGB(97, 38, 170),
    BackgroundTransparency = 0.75, BorderSizePixel = 0, Active = false,
}, contentPlate)
round(plateShine, 68)
mk("UIGradient", {
    Rotation = 0,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.39),
    }),
}, plateShine)

-- Reference 403VIP: permanent LEFT navigation in desktop and portrait layouts.
-- The narrow sidebar preserves a large invisible click region for each tab.
local tabs = mk("Frame", {
    Name = "VisualsNavigation", BackgroundColor3 = Color3.fromRGB(20, 16, 31),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, 196, 1, 0),
    ClipsDescendants = true,
}, panel)
mk("UIGradient", {Rotation = 90,
    Color = ColorSequence.new(Color3.fromRGB(28, 19, 47),
        Color3.fromRGB(15, 13, 26))}, tabs)
local sidebarAura = mk("Frame", {
    Name = "SidebarVioletSheen", AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 150),
    BackgroundColor3 = Color3.fromRGB(94, 35, 160),
    BackgroundTransparency = 0.85, BorderSizePixel = 0, Active = false,
}, tabs)
mk("UIGradient", {Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.17),
    })}, sidebarAura)
-- Отделяем декоративную линию от горизонтального UIListLayout.
-- В v1.0.0 линия занимала полный слот и выталкивала вкладки ЗА окно.
mk("Frame", {
    Name = "NavLine", BackgroundColor3 = Color3.fromRGB(98, 72, 142),
    BorderSizePixel = 0, BackgroundTransparency = 0.48,
    Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0),
}, tabs)
local navSlots = mk("Frame", {
    Name = "NavigationSlots", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 1, -190),
}, tabs)
mk("UIPadding", {
    PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
    PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
}, navSlots)
local navigationLayout = mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
}, navSlots)
local tabButtons, tabUnderline, tabOutlines, pages, pageColumns = {}, {}, {}, {}, {}
local referenceESP = nil
local currentPage = "ESP"
-- Защита от ложных нажатий: палец сдвигает страницу, а не переключатель.
local scrollFrames = {}
local touchGestures = setmetatable({}, {__mode = "k"})
local suppressTapUntil = 0
-- Do not treat a scroller from a *hidden ancestor page* as touch-active.
-- The previous check looked only at the direct parent and could suppress
-- clicks on unrelated pages after switching to compact/portrait layout.
local function uiVisibleThroughParents(obj)
    local current = obj
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") then return current.Enabled end
        current = current.Parent
    end
    return false
end
local function pointerOverScroll(position)
    if not position then return false end
    for _, scroll in ipairs(scrollFrames) do
        if scroll.Parent and uiVisibleThroughParents(scroll) then
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
    touchGestures[input] = nil -- Release finished touch identity immediately.
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
        if not alive or not allowTap(input) then return end
        local ok, err = pcall(callback, input, ...)
        if not ok then tell("Ошибка UI: " .. tostring(err)) end
    end)
end
-- Dashboard доступен через статус; 4 основные вкладки сохраняют раздельные функции.
local navigation = {
    {key = "HOME", label = "Overview", symbol = "⌂", hidden = true},
    {key = "ESP", label = "ESP", symbol = "◎"},
    {key = "AIM", label = "Aim", symbol = "⌁"},
    {key = "MEMORY", label = "Memory", symbol = "▦"},
    {key = "MISC", label = "Settings", symbol = "⚙"},
}
local function makeColumn(parent, name)
    local scroll = mk("ScrollingFrame", {
        Name = name, BackgroundColor3 = P.panel, BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = P.accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Active = true, ClipsDescendants = true,
    }, parent)
    round(scroll, 3)
    -- No individual scroll frame border: content plate owns the outline.
    mk("UIStroke", {Color = P.border, Thickness = 1, Transparency = 1}, scroll)
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
        Padding = UDim.new(0, 8),
    }, scroll)
    mk("UIPadding", {
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 13),
        PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 14),
    }, scroll)
    return scroll
end
for idx, tab in ipairs(navigation) do
    local key = tab.key
    local button = mk("TextButton", {
        Name = key .. "Tab", LayoutOrder = idx,
        BackgroundColor3 = P.panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -6, 0, 56),
        Text = tab.symbol .. "  " .. tab.label,
        Visible = not tab.hidden,
        Font = Enum.Font.GothamMedium, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = P.dim, AutoButtonColor = false,
    }, navSlots)
    round(button, 10)
    tabOutlines[key] = mk("UIStroke", {Color = P.accent, Transparency = 1, Thickness = 1.2}, button)
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
        Visible = key == "HOME", ClipsDescendants = true,
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
        Text = "124 Visuals", Font = Enum.Font.GothamBold,
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
        sideStatus.Visible = false -- Reserved for Roblox emblem in right sidebar
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
    ["CAMERA & LIGHTING"] = "left", ["ANTI-AIM"] = "right",
    ["MOVEMENT"] = "left", ["FLIGHT"] = "right", ["TELEPORT"] = "right",
    ["WEAPON CONTROL"] = "left", ["LOCAL MUSIC"] = "right",
    
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
    local width, height, wide, baseScale = windowMetrics(view)
    -- Responsive transitions must cancel the previous animation before
    -- replacing its base scale; otherwise menu can leave the viewport.
    if panelTween then panelTween:Cancel(); panelTween = nil end
    uiBaseScale = baseScale
    panelScale.Scale = uiBaseScale
    panel.Size = UDim2.fromOffset(width, height)
    panel.Position = boosterPro.clampWindowPosition(panel.Position, panel.Size, panel.AnchorPoint)
    if boosterPro.floatingButton then
        boosterPro.floatingButton.Position = boosterPro.clampWindowPosition(boosterPro.floatingButton.Position,
            boosterPro.floatingButton.Size, boosterPro.floatingButton.AnchorPoint)
    end
    wideLayout = wide
    contentPlate.Position = UDim2.fromOffset(wide and 207 or 101, 81)
    contentPlate.Size = UDim2.new(1, wide and -220 or -110, 1, wide and -121 or -120)
    pageHeader.Visible, pageSubHeader.Visible = false, false
    -- Four-tab measured layout: legacy navSlots used negative relative
    -- height and cut off Settings on short landscape viewports.
    local compactShort = not wide and height < 320
    local navTop = wide and 96 or (compactShort and 58 or 70)
    local bottomReserve = wide and 90 or (height < 300 and 9 or 53)
    local buttonHeight = wide and 55 or (compactShort and 31 or 39)
    tabs.Position = UDim2.fromOffset(0, 0)
    tabs.Size = UDim2.new(0, wide and 196 or 92, 1, 0)
    navSlots.Position = UDim2.fromOffset(0, navTop)
    navSlots.Size = UDim2.new(1, 0, 0, math.max(0, height - navTop - bottomReserve))
    navigationLayout.FillDirection = Enum.FillDirection.Vertical
    navigationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navigationLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    navigationLayout.Padding = UDim.new(0, wide and 8 or (compactShort and 3 or 5))
    for _, nav in ipairs(navigation) do
        local button = tabButtons[nav.key]
        if wide then
            button.Size = UDim2.new(1, -6, 0, buttonHeight)
            button.Text = "  " .. nav.symbol .. "     " .. nav.label
            button.TextSize = 14
            button.TextXAlignment = Enum.TextXAlignment.Left
        else
            button.Size = UDim2.new(1, -4, 0, buttonHeight)
            local short = nav.key == "MEMORY" and "MEM"
                or nav.key == "MISC" and "SET" or nav.key
            button.Text = nav.symbol .. "  " .. short
            button.TextSize = compactShort and 9 or 10
            button.TextXAlignment = Enum.TextXAlignment.Center
        end
        tabUnderline[nav.key].Position = UDim2.fromOffset(0, 5)
        tabUnderline[nav.key].Size = UDim2.new(0, 3, 1, -10)
    end
    for _, page in pairs(pages) do
        if wide then
            page.Position = UDim2.fromOffset(207, 81)
            page.Size = UDim2.new(1, -220, 1, -121)
        else
            page.Position = UDim2.fromOffset(101, 81)
            page.Size = UDim2.new(1, -110, 1, -120)
        end
        page.ClipsDescendants = true
        local info = pageColumns[page]
        if info then
            -- The ESP page matches the reference image: one full-width
            -- scrolling stack of violet cards instead of an old split preview.
            local singleColumn = (not wide) or page == pages.ESP
            if singleColumn then
                info.left.Position = UDim2.fromScale(0, 0)
                info.left.Size = UDim2.fromScale(1, 1)
                info.right.Visible = false
            else
                info.left.Position = UDim2.fromOffset(0, 0)
                info.left.Size = UDim2.new(0.5, -5, 1, 0)
                info.right.Position = UDim2.new(0.5, 5, 0, 0)
                info.right.Size = UDim2.new(0.5, -5, 1, 0)
                info.right.Visible = true
            end
            for _, item in ipairs(info.widgets) do
                local desired = singleColumn and info.left or info[item.side]
                if item.object.Parent ~= desired then item.object.Parent = desired end
            end
        end
    end
    if referenceESP then
        if referenceESP.cancelInteraction then referenceESP.cancelInteraction() end
        -- Keep legacy reference widgets allocated for compatibility but hidden.
        -- Native ESP cards are the only active / visible ESP controls.
        referenceESP.root.Visible = false
        local espColumns = pageColumns[pages.ESP]
        if espColumns then
            espColumns.left.Visible = true
            espColumns.right.Visible = false
        end
        referenceESP.layout(wide)
    end
    if boosterPro.dashboard then boosterPro.dashboard.layout(wide) end
    if boosterPro.uiFooter and boosterPro.uiFooter.Parent then
        boosterPro.uiFooter.Position = UDim2.new(0, wide and 207 or 101, 1, -29)
        boosterPro.uiFooter.Size = UDim2.new(1, wide and -220 or -110, 0, 22)
    end
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

local sliderDrag = nil
local function showPage(key)
    if not pages[key] then return end
    if key ~= "ESP" and referenceESP and referenceESP.clearSearch then
        referenceESP.clearSearch()
    end
    sliderDrag = nil -- Смена вкладки отменяет незавершённое перетаскивание.
    if referenceESP and referenceESP.cancelInteraction then
        referenceESP.cancelInteraction()
    end
    if key ~= "AIM" and captureAimKey then
        captureAimKey = false
        repaintAimKeybind()
    end
    currentPage = key
    local titles = {HOME = "Dashboard", ESP = "Visuals", AIM = "Aim",
        MISC = "Settings", MEMORY = "Performance"}
    local descriptions = {HOME = "Live game performance and optimization overview",
        ESP = "Player overlays and visibility controls",
        AIM = "Targeting, weapon filters and FOV",
        MISC = "Movement and character tools",
        MEMORY = "Client graphics, monitoring and performance"}
    pageHeader.Text = titles[key] or key
    pageSubHeader.Text = descriptions[key] or ""
    for name, page in pairs(pages) do
        local selected = name == key
        page.Visible = selected
        tabButtons[name].BackgroundColor3 = selected and Color3.fromRGB(66, 37, 105)
            or Color3.fromRGB(31, 27, 44)
        tabButtons[name].TextColor3 = selected and P.text or P.dim
        tabButtons[name].Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium
        tabUnderline[name].Visible = selected
        tabOutlines[name].Transparency = selected and 0.07 or 0.91
    end
end
for name, button in pairs(tabButtons) do
    safeActivate(button, function() showPage(name) end)
end
boosterPro.dashboard.openSettings = function() showPage("MEMORY") end
applyResponsiveLayout()
showPage("ESP")
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
        boosterPro.layoutCameraConnection = nil
    end
    currentLayoutCamera = camera
    if camera then
        -- Not inserted into the global connections list: replaced cameras
        -- otherwise leave disconnected entries retained until full Unload.
        cameraLayoutConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(queueResponsiveLayout)
        boosterPro.layoutCameraConnection = cameraLayoutConnection
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
    local _, myRoot = espParts(myCharacter)
    if not myRoot then clearTracers(); return end
    local radiusStuds = state.espRangeMeters / CONFIG.StudMeters
    local radiusSquared = radiusStuds * radiusStuds
    for player, data in pairs(renderData) do
        local ch = data.character
        local head, root, hum = data.head, data.root, data.humanoid
        local visible = false
        local screenPosition
        if data.inactiveSince == nil and player.Parent == Players and ch == player.Character
            and (not hum or (hum.Parent == ch and hum.Health > 0))
            and head and head.Parent == ch and root and root.Parent == ch
            and (not state.espEnemyOnly or not sameTeamESP(player))
            and perfCounters.espWithinRange(root, myRoot, radiusSquared) then
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

-- LITE 2D Box: only four reusable lines per visible player.
local shapeData = {}
local shapeNewContainersLeft = 0
local shapeNewLinesLeft = 0
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
    if shapeNewContainersLeft <= 0 then return nil end
    shapeNewContainersLeft = shapeNewContainersLeft - 1
    -- Респавн: старые кости относятся к другой модели, их нельзя переиспользовать.
    if item then pcall(function() item.container:Destroy() end) end
    local container = mk("Frame", {Name = "S" .. player.UserId, Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, Active = false}, shapeGui)
    item = {container = container, character = character, box = {}}
    shapeData[player] = item
    return item
end
local function hideShape(item)
    for _, line in ipairs(item.box) do setIfDifferent(line, "Visible", false) end
end
local function ensureShapeLines(item, kind, count)
    local lines = item[kind]
    while #lines < count and shapeNewLinesLeft > 0 do
        lines[#lines + 1] = shapeLine(item.container)
        shapeNewLinesLeft = shapeNewLinesLeft - 1
    end
    -- Incomplete shapes stay hidden and finish incrementally on later frames.
    return #lines >= count
end
local function refreshShapes()
    if not alive or not state.esp or not state.espBox then
        if next(shapeData) ~= nil then clearShapes() end
        return
    end
    local camera = Workspace.CurrentCamera
    if camera and (not shapeGui or not shapeGui.Parent) then
        perfCounters.lazy.ensureShapes()
    end
    if not camera or not shapeGui or not shapeGui.Parent then
        for _, item in pairs(shapeData) do hideShape(item) end
        perfCounters.shapeCount = 0
        return
    end
    local _, myRoot = espParts(LocalPlayer.Character)
    if not myRoot then
        for _, item in pairs(shapeData) do hideShape(item) end
        perfCounters.shapeCount = 0
        return
    end
    local activeCount, active = 0, perfCounters.espVisual.active
    local radiusStuds = state.espRangeMeters / CONFIG.StudMeters
    local radiusSquared = radiusStuds * radiusStuds
    local tier = visualPerfTier()
    local budget = tier == "ECO" and CONFIG.EspShapeEcoLimit
        or tier == "QUALITY" and CONFIG.EspShapeQualityLimit
        or CONFIG.EspShapeBalancedLimit
    if state.performanceGuard and perfCounters.guard.level == 2 then
        budget = math.min(budget, CONFIG.GuardShapeMaxL2)
    elseif state.performanceGuard and perfCounters.guard.level == 1 then
        budget = math.min(budget, CONFIG.GuardShapeMaxL1)
    end
    table.clear(active)
    for _, player in ipairs(perfCounters.espVisual.ordered) do
        if activeCount >= budget then break end
        local info = renderData[player]
        local char = info and info.character
        local head, root, hum = info and info.head, info and info.root, info and info.humanoid
        if info and player.Parent == Players and head and head.Parent == char
            and root and root.Parent == char
            and (not hum or (hum.Parent == char and hum.Health > 0))
            and player.Character == char
            and (not state.espEnemyOnly or not sameTeamESP(player))
            and perfCounters.espWithinRange(root, myRoot, radiusSquared) then
            -- Check visibility BEFORE allocating any Box GUI.
            local top, onTop = camera:WorldToViewportPoint(
                head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.25, 0))
            local bottom, onBottom = camera:WorldToViewportPoint(
                root.Position - Vector3.new(0, 3, 0))
            if onTop and onBottom and top.Z > 0 and bottom.Z > 0 then
                activeCount = activeCount + 1
                local item = shapeItem(player, char)
                if item then
                    active[player] = true
                    item.inactiveSince = nil
                    if ensureShapeLines(item, "box", 4) then
                        local color = getPlayerColor(player)
                        local half = math.clamp(math.abs(bottom.Y - top.Y) * 0.23, 4, 160)
                        local left, right = top.X - half, top.X + half
                        setLine(item.box[1], Vector2.new(left, top.Y),
                            Vector2.new(right, top.Y), state.espLineThickness, color)
                        setLine(item.box[2], Vector2.new(left, bottom.Y),
                            Vector2.new(right, bottom.Y), state.espLineThickness, color)
                        setLine(item.box[3], Vector2.new(left, top.Y),
                            Vector2.new(left, bottom.Y), state.espLineThickness, color)
                        setLine(item.box[4], Vector2.new(right, top.Y),
                            Vector2.new(right, bottom.Y), state.espLineThickness, color)
                    else
                        hideShape(item) -- Incomplete boxes never display partially.
                    end
                end
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
                and now - item.inactiveSince >= CONFIG.EspCacheIdleSeconds
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
    -- State toggles must not force roster sorting/geometry in input callbacks.
    if state.esp then queueESPRefresh() else refreshESP() end
    if not state.esp or not state.tracers then clearTracers() end
    if not state.esp or not state.espBox then clearShapes() end
end

-- Единая сетка компонентов. Стилизация не меняет обработчики состояний.
local function addSection(page, title, subtitle)
    local info = pageColumns[page]
    if info then info.side = sectionSides[title] or info.side end
    local hero = title == "VISUALS" or title == "TARGETING"
        or title == "MOVEMENT" or title == "UTILITY"
    local container = mk("Frame", {
        Name = title .. "Heading", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, hero and 62 or 42),
    }, columnFor(page))
    registerWidget(page, container)
    local sectionBar = mk("Frame", {Name = "SectionAccent", BackgroundColor3 = P.accent,
        BorderSizePixel = 0, Position = UDim2.fromOffset(4, hero and 11 or 14),
        Size = UDim2.fromOffset(hero and 4 or 19, hero and 23 or 2)}, container)
    round(sectionBar, 2)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(hero and 18 or 8, hero and 5 or 3),
        Size = UDim2.new(1, hero and -26 or -16, 0, hero and 29 or 19),
        Text = title, Font = Enum.Font.GothamBold, TextSize = hero and 18 or 12,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(hero and 19 or 8, hero and 39 or 24),
        Size = UDim2.new(1, hero and -25 or -12, 0, 14),
        Text = subtitle, Font = Enum.Font.Gotham,
        TextSize = hero and 10 or 9, TextColor3 = P.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, container)
end

local function addToggle(page, title, description, key, onChanged)
    local row = mk("TextButton", {
        Name = key, Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Color3.fromRGB(34, 29, 50), BorderSizePixel = 0,
        AutoButtonColor = false, Text = "",
    }, columnFor(page))
    registerWidget(page, row)
    round(row, 10)
    local rowBorder = mk("UIStroke", {Color = P.border, Transparency = 0.59, Thickness = 1}, row)
    mk("UIGradient", {Rotation = 0,
        Color = ColorSequence.new(Color3.fromRGB(40, 33, 58),
            Color3.fromRGB(26, 25, 39))}, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(13, 7), Size = UDim2.new(1, -72, 0, 20),
        Text = title, TextSize = 12, Font = Enum.Font.GothamBold,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(13, 30), Size = UDim2.new(1, -72, 0, 15),
        Text = description, TextSize = 9, Font = Enum.Font.Gotham,
        TextColor3 = P.dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local pill = mk("Frame", {
        Name = "Switch", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(34, 18), BackgroundColor3 = P.off,
        BorderSizePixel = 0,
    }, row)
    round(pill, 9)
    local pillBorder = mk("UIStroke", {Color = P.border, Transparency = 0.62, Thickness = 1}, pill)
    local knob = mk("Frame", {
        Name = "Knob", Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(222, 223, 227), BorderSizePixel = 0,
    }, pill)
    round(knob, 7)
    local function update()
        if not row.Parent then return end
        local enabled = state[key] == true
        pill.BackgroundColor3 = enabled and Color3.fromRGB(117, 62, 183) or P.off
        knob.Position = UDim2.fromOffset(enabled and 18 or 2, 2)
        knob.BackgroundColor3 = enabled and Color3.fromRGB(255, 251, 255)
            or Color3.fromRGB(222, 219, 235)
        pillBorder.Color = enabled and P.accent or P.border
        pillBorder.Transparency = enabled and 0.17 or 0.64
        rowBorder.Transparency = enabled and 0.29 or 0.63
    end
    refreshToggles[key] = update
    local lastMouseActivation = -1e8
    local function onRowActivated()
        if not alive then return end
        -- На некоторых клиентах MouseButton1Click и Activated приходят вместе.
        -- Запасной обработчик AIM не должен переключать его дважды.
        if key == "aimbot" then
            local now = os.clock()
            if now - lastMouseActivation < 0.12 then return end
            lastMouseActivation = now
        end
        local previous = state[key]
        state[key] = not previous
        if onChanged then
            local ok, err = pcall(onChanged, state[key])
            if not ok then
                -- Ошибка callback не должна сохранять нерабочий тумблер ON.
                state[key] = previous
                pcall(onChanged, previous)
                update()
                tell("Ошибка: " .. tostring(err))
                return
            end
        end
        update()
        requestSave()
    end
    safeActivate(row, onRowActivated)
    if key == "aimbot" then
        row.Active = true
        -- Запасной путь для клиентов, не отправляющих Activated на обычный клик.
        connect(row.MouseButton1Click, onRowActivated)
    end
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
    round(button, 10)
    mk("UIStroke", {Color = P.border, Transparency = 0.54, Thickness = 1}, button)
    mk("UIGradient", {Rotation = 0,
        Color = ColorSequence.new(Color3.fromRGB(42, 35, 61),
            Color3.fromRGB(29, 26, 43))}, button)
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
local function addSlider(page, title, description, key, minValue, maxValue, step, formatter, onChanged)
    local container = mk("Frame", {
        Name = key .. "Slider", Size = UDim2.new(1, 0, 0, 74),
        BackgroundColor3 = P.tile, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, container)
    round(container, 9)
    mk("UIStroke", {Color = P.border, Transparency = 0.54, Thickness = 1}, container)
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
        TextColor3 = P.accent, Font = Enum.Font.Code,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
    }, container)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 24),
        Size = UDim2.new(1, -20, 0, 13), Text = description,
        TextColor3 = P.dim, Font = Enum.Font.Gotham,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    local touchArea = mk("TextButton", {
        Name = "DragArea", BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(10, 44), Size = UDim2.new(1, -20, 0, 25),
    }, container)
    local track = mk("Frame", {
        Name = "Track", BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(70, 63, 88),
        Position = UDim2.new(0, 6, 0.5, -2),
        Size = UDim2.new(1, -12, 0, 4),
    }, touchArea)
    round(track, 2)
    local fill = mk("Frame", {
        Name = "Fill", BorderSizePixel = 0,
        BackgroundColor3 = P.accent, Size = UDim2.fromScale(0, 1),
    }, track)
    round(fill, 2)
    local thumb = mk("Frame", {
        Name = "Thumb", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(248, 239, 255), BorderSizePixel = 0,
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
            local previous = state[key]
            state[key] = snapped
            if onChanged then
                local ok, err = pcall(onChanged, snapped)
                if not ok then
                    -- Ошибка обработчика не оставляет скрытую новую настройку.
                    state[key] = previous
                    pcall(onChanged, previous)
                    repaint()
                    tell("Ошибка настройки " .. tostring(key) .. ": " .. tostring(err))
                    return
                end
            end
            -- Синхронизируем второй слайдер того же ключа без повторного скана.
            local synchronize = refreshSliders[key]
            if synchronize then pcall(synchronize) end
            requestSave()
        end
        repaint()
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
        BackgroundColor3 = P.tile, BorderSizePixel = 0,
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
                button.BackgroundColor3 = selected and Color3.fromRGB(111, 61, 170)
                    or Color3.fromRGB(42, 35, 57)
                button.TextColor3 = selected and P.text or P.dim
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
            TextColor3 = P.dim, AutoButtonColor = false,
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
        BackgroundColor3 = P.tile, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, container)
    round(container, 10)
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
        Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = P.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, container)
    keybindButton = mk("TextButton", {
        Name = "AssignAimKey", Position = UDim2.fromOffset(10, 43),
        Size = UDim2.new(1, -83, 0, 27),
        BackgroundColor3 = Color3.fromRGB(42, 43, 51),
        TextColor3 = P.accent, Font = Enum.Font.GothamBold,
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
        BackgroundColor3 = P.tile, BorderSizePixel = 0}, columnFor(page))
    registerWidget(page, row)
    round(row, 10)
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
                button.BackgroundColor3 = enabled and Color3.fromRGB(110, 60, 170)
                    or Color3.fromRGB(42, 35, 57)
                button.TextColor3 = enabled and P.text or P.dim
            end
        end
    end
    for i, option in ipairs(choices) do
        local button = mk("TextButton", {Text = option.label, BackgroundColor3 = P.tile,
            TextColor3 = P.dim, BorderSizePixel = 0, AutoButtonColor = true,
            TextSize = 9, Font = Enum.Font.GothamBold,
            Position = UDim2.new((i - 1) / #choices, 7, 0, 30),
            Size = UDim2.new(1 / #choices, -14 / #choices, 0, 27)}, row)
        round(button, 6)
        buttons[option.value] = button
        safeActivate(button, function()
            if not alive then return end
            local previous = state[key]
            state[key] = option.value
            if callback then
                local ok, err = pcall(callback, option.value)
                if not ok then
                    -- Возвращаем предыдущий выбор при сбое обработчика.
                    state[key] = previous
                    pcall(callback, previous)
                    repaint()
                    tell("Ошибка выбора " .. tostring(key) .. ": " .. tostring(err))
                    return
                end
            end
            repaint()
            requestSave()
        end)
    end
    repaint()
    return repaint
end

addSection(pages.ESP, "VISUALS", "Компактные подписи и тонкие ESP-линии")

addToggle(pages.ESP, "ESP подсветка", "Подсветка в выбранном радиусе до 1000 м", "esp", function()
    syncEspVisuals()
end)
addToggle(pages.ESP, "Линия над игроками", "От верха экрана к игрокам в радиусе ESP", "tracers", function(enabled)
    if not enabled then clearTracers() end
    if enabled and not state.esp then tell("Включи ESP, чтобы отображать линии") end
end)
addToggle(pages.ESP, "2D Box", "Контур (при включённом ESP)", "espBox", function(enabled)
    if not enabled then clearShapes() end
    if enabled and not state.esp then tell("Включи ESP для отображения 2D Box") end
end)
addToggle(pages.ESP, "Только противники", "Не отображать свою команду", "espEnemyOnly", function()
    queueESPRefresh()
end)
addSection(pages.ESP, "ESP OPTIONS", "Дальность, стиль и подписи")
addSlider(pages.ESP, "Дальность ESP", "Выбор радиуса до 1000 м; дальние метки обновляются реже", "espRangeMeters",
    CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters, CONFIG.EspRangeStepMeters,
    function(v) return tostring(v) .. " м" end,
    function() queueESPRefresh() end)
addSlider(pages.ESP, "Максимум игроков ESP",
    "Лимит объектов (8–96); при нехватке выбраны ближайшие",
    "espMaxTargets", 8, 96, 8, function(v) return tostring(v) .. " игроков" end,
    function() queueESPRefresh() end)
addButton(pages.ESP, "Диагностика ESP",
    "Игроки в радиусе, лимит, неполные модели и время обновления", function()
        local info = perfCounters.espVisual
        tell("ESP " .. (state.esp and "ON" or "OFF")
            .. " | Радиус " .. tostring(state.espRangeMeters) .. " м"
            .. " | В радиусе " .. tostring(info.eligible)
            .. " | На экране " .. tostring(perfCounters.espCount)
            .. " | Не вошло в лимит " .. tostring(info.omitted)
            .. " | Не загружены части " .. tostring(info.missing)
            .. " | Мой персонаж " .. (info.localReady and "READY" or "LOADING")
            .. " | Ошибки отрисовки/подписок "
            .. tostring(info.renderFailures) .. "/" .. tostring(info.watcherFailures)
            .. " | Лимит " .. tostring(espLimit())
            .. " | Возраст скана " .. string.format("%.2f", math.max(0,
                os.clock() - info.lastScanAt)) .. " сек")
    end)
addSlider(pages.ESP, "Толщина линий", "Box (1–2 px), Tracer всегда 1 px", "espLineThickness", 1, 2, 1,
    function(v) return tostring(v) .. " px" end)
repaintColors = addChoice(pages.ESP, "Цвет ESP", {
    {value="TEAM", label="TEAM"}, {value="GOLD", label="GOLD"},
    {value="GREEN", label="GREEN"}, {value="WHITE", label="WHITE"},
}, "espColorPreset", function() queueESPRefresh() end)
addToggle(pages.ESP, "Имена", "DisplayName над персонажами", "names")
addToggle(pages.ESP, "Здоровье", "HP над персонажами", "health")
addToggle(pages.ESP, "Дистанция", "Расстояние в метрах (≈)", "distance")
addToggle(pages.ESP, "Цвет команд", "Расцветка согласно TeamColor", "teamColors")
-- Local crosshair was previously reachable only in the hidden 403VIP preview.
-- Route it through the same native toggle UI without modifying ESP behavior.
addToggle(pages.ESP, "Локальный прицел", "Небольшой маркер в центре экрана", "crosshairLocal",
    function(enabled)
        if boosterPro.setLocalCrosshair then
            boosterPro.setLocalCrosshair(enabled)
        end
    end)

addSection(pages.AIM, "TARGETING", "Точка наведения и управление")
addToggle(pages.AIM, "Aimbot", "Кнопка и горячая клавиша включают наведение одинаково", "aimbot", function(enabled)
    -- Раньше меню включало модуль без aimHeldKey: без ПКМ наведения не было.
    setAimEnabled(enabled, enabled)
    tell(enabled and "AIM: ON (активирован кнопкой)" or "AIM: OFF")
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
addToggle(pages.AIM, "Control Recoil", "Работает при выстрелах из экипированного Tool", "controlRecoil", function(enabled)
    if enabled and state.noRecoil then
        state.noRecoil = false
        if refreshToggles.noRecoil then pcall(refreshToggles.noRecoil) end
    end
    recoil.reset()
end)
addSlider(pages.AIM, "Сила Control Recoil", "0–100%; увеличивай постепенно", "recoilStrength",
    0, 100, 5, function(value) return tostring(value) .. "%" end)
addButton(pages.AIM, "Проверить Control Recoil", "Показать обнаруженное оружие и количество активаций", function()
    local weapon, shots, lastCorrection = recoil.inspect()
    tell("Recoil | Tool: " .. tostring(weapon) .. " | Activations: "
        .. tostring(shots) .. " | Last correction: "
        .. string.format("%.2f deg", lastCorrection))
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

-- Один контроллер для Speed / Noclip / Fly: никаких вечных циклов.
-- Физика локальная; игровые серверы могут переопределять перемещение.
local movement = {
    character = nil, originalSpeed = nil, speedHumanoid = nil,
    originalAutoRotate = nil, flyHumanoid = nil, flyRoot = nil,
    attachment = nil, velocity = nil, orientation = nil,
    noclipCharacter = nil, noclipAdded = nil,
    collisionOriginals = setmetatable({}, {__mode = "k"}),
    stepConnection = nil, lastSpeedApply = 0, lastAppliedSpeed = nil, lastErrorAt = 0,
    nextPassiveAt = 0, nextNoclipAt = 0, lastFlatForward = Vector3.new(0, 0, -1),
    lastFacing = nil,
}
boosterPro.movement = movement

function movement.restoreSpeed()
    if movement.speedHumanoid and movement.originalSpeed ~= nil
        and movement.lastAppliedSpeed ~= nil then
        pcall(function()
            -- Если сама игра поменяла скорость после последней записи,
            -- не перезаписываем новое значение устаревшим снимком.
            if movement.speedHumanoid.Parent
                and movement.speedHumanoid.WalkSpeed == movement.lastAppliedSpeed then
                movement.speedHumanoid.WalkSpeed = movement.originalSpeed
            end
        end)
    end
    movement.speedHumanoid, movement.originalSpeed, movement.lastAppliedSpeed = nil, nil, nil
end

function movement.restoreCollision()
    if movement.noclipAdded then
        movement.noclipAdded:Disconnect()
        movement.noclipAdded = nil
    end
    for part, original in pairs(movement.collisionOriginals) do
        pcall(function()
            -- Noclip записывал только false. Не затираем true,
            -- установленное другой системой после активации.
            if part.Parent and original == true and part.CanCollide == false then
                part.CanCollide = true
            end
        end)
        movement.collisionOriginals[part] = nil
    end
    movement.noclipCharacter = nil
    movement.nextNoclipAt = 0
end

function movement.recordPart(obj)
    if not obj:IsA("BasePart") then return end
    if movement.collisionOriginals[obj] == nil then
        movement.collisionOriginals[obj] = obj.CanCollide
    end
    if obj.CanCollide then obj.CanCollide = false end
end

function movement.startNoclip(character)
    movement.restoreCollision()
    movement.noclipCharacter = character
    for _, obj in ipairs(character:GetDescendants()) do movement.recordPart(obj) end
    movement.noclipAdded = character.DescendantAdded:Connect(function(obj)
        if alive and state.noclip and movement.noclipCharacter == character then
            movement.recordPart(obj)
        end
    end)
end

function movement.restoreFly()
    if movement.velocity then pcall(function() movement.velocity:Destroy() end) end
    if movement.orientation then pcall(function() movement.orientation:Destroy() end) end
    if movement.attachment then pcall(function() movement.attachment:Destroy() end) end
    movement.velocity, movement.orientation, movement.attachment = nil, nil, nil
    if movement.flyHumanoid and movement.originalAutoRotate ~= nil then
        pcall(function()
            if movement.flyHumanoid.Parent then
                movement.flyHumanoid.AutoRotate = movement.originalAutoRotate
                if movement.flyHumanoid.Health > 0 and not movement.flyHumanoid.Sit
                    and movement.flyHumanoid.SeatPart == nil
                    and movement.flyHumanoid:GetState() == Enum.HumanoidStateType.Physics then
                    movement.flyHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end)
    end
    movement.flyHumanoid, movement.flyRoot, movement.originalAutoRotate = nil, nil, nil
    movement.lastFacing = nil
end

function movement.ensureFly(humanoid, root)
    if movement.flyRoot == root and movement.velocity and movement.velocity.Parent == root
        and movement.orientation and movement.orientation.Parent == root then
        return true
    end
    movement.restoreFly()
    local built = {}
    local originalRotate = humanoid.AutoRotate
    local ok, err = pcall(function()
        local attachment = Instance.new("Attachment")
        built[#built + 1] = attachment
        attachment.Name = "VisualsFlightAttachment"
        attachment.Parent = root
        local linear = Instance.new("LinearVelocity")
        built[#built + 1] = linear
        linear.Name = "VisualsFlightVelocity"
        linear.Attachment0 = attachment
        linear.RelativeTo = Enum.ActuatorRelativeTo.World
        linear.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        linear.ForceLimitsEnabled = false
        linear.VectorVelocity = Vector3.zero
        linear.Parent = root
        local align = Instance.new("AlignOrientation")
        built[#built + 1] = align
        align.Name = "VisualsFlightOrientation"
        align.Attachment0 = attachment
        align.Mode = Enum.OrientationAlignmentMode.OneAttachment
        align.RigidityEnabled = false
        align.MaxTorque = 10000000
        align.Responsiveness = 20
        align.Parent = root
        movement.originalAutoRotate = humanoid.AutoRotate
        humanoid.AutoRotate = false
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        movement.attachment, movement.velocity, movement.orientation =
            attachment, linear, align
        movement.flyHumanoid, movement.flyRoot = humanoid, root
    end)
    if not ok then
        for _, obj in ipairs(built) do pcall(function() obj:Destroy() end) end
        movement.restoreFly()
        pcall(function()
            if humanoid.Parent then
                humanoid.AutoRotate = originalRotate
                if humanoid.Health > 0 and not humanoid.Sit
                    and humanoid.SeatPart == nil
                    and humanoid:GetState() == Enum.HumanoidStateType.Physics then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end)
        state.fly = false
        if refreshToggles.fly then pcall(refreshToggles.fly) end
        -- Не оставляем пустой physics callback после отказа запуска.
        if not state.speedEnabled and not state.noclip and movement.stepConnection then
            movement.stepConnection:Disconnect()
            movement.stepConnection = nil
        end
        tell("Fly: не удалось включить: " .. tostring(err))
    end
    return ok
end

function movement.releaseCharacter()
    movement.restoreFly()
    movement.restoreSpeed()
    movement.restoreCollision()
    movement.character = nil
end

function movement.step()
    if not alive then return end
    local character = LocalPlayer.Character
    if movement.character ~= character then
        movement.releaseCharacter()
        movement.character = character
    end
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not (humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")) then
        movement.restoreFly()
        movement.restoreSpeed()
        movement.restoreCollision()
        return
    end

    if state.speedEnabled then
        if movement.speedHumanoid ~= humanoid then
            movement.restoreSpeed()
            movement.speedHumanoid = humanoid
            movement.originalSpeed = humanoid.WalkSpeed
            movement.lastAppliedSpeed = nil
            movement.lastSpeedApply = 0
        end
        if os.clock() - movement.lastSpeedApply >= 0.25 then
            if humanoid.WalkSpeed ~= state.speedValue then
                -- Фиксируем новое значение самой игры перед повторной записью,
                -- чтобы откат не возвращал устаревшую скорость.
                if movement.lastAppliedSpeed ~= nil
                    and humanoid.WalkSpeed ~= movement.lastAppliedSpeed then
                    movement.originalSpeed = humanoid.WalkSpeed
                end
                humanoid.WalkSpeed = state.speedValue
                movement.lastAppliedSpeed = state.speedValue
            end
            movement.lastSpeedApply = os.clock()
        end
    elseif movement.speedHumanoid then
        movement.restoreSpeed()
    end

    if state.noclip then
        if movement.noclipCharacter ~= character then
            movement.startNoclip(character)
        end
        -- При одновременном Fly не сканируем все части каждый Render/Physics кадр.
        -- DescendantAdded реагирует немедленно, регулярный контроль не чаще 30 Гц.
        local now = os.clock()
        if now >= movement.nextNoclipAt then
            movement.nextNoclipAt = now + 1 / CONFIG.MiscNoclipRefreshHz
            for part in pairs(movement.collisionOriginals) do
                if part.Parent and part.CanCollide then part.CanCollide = false end
            end
        end
    elseif movement.noclipCharacter then
        movement.restoreCollision()
    end

    if not state.fly or humanoid.Sit or humanoid.SeatPart ~= nil then
        -- Физика Fly не должна драться с SeatWeld / управлением транспортом.
        -- Флаг Fly сохраняется и продолжит работать после выхода из сиденья.
        if movement.flyRoot then movement.restoreFly() end
        return
    end
    if not movement.ensureFly(humanoid, root) then return end
    local camera = Workspace.CurrentCamera
    if not camera then
        movement.velocity.VectorVelocity = Vector3.zero
        return
    end
    -- W/S следуют за 3D-взглядом камеры: взгляд вверх + W = набор высоты;
    -- взгляд вниз + W = снижение. A/D дают горизонтальный стрейф.
    -- Клавиши Space и Q/Ctrl оставлены только для дополнительной вертикали.
    local look = camera.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude > 0.01 then
        movement.lastFlatForward = flatLook.Unit
    end
    local flatForward = movement.lastFlatForward -- Не скачет у вертикальной камеры.
    local right = Vector3.new(-flatForward.Z, 0, flatForward.X)
    local direction = Vector3.zero
    if not UserInputService:GetFocusedTextBox() and not isRobloxMenuOpen() then
        local forwardAxis = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
            - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
        local rightAxis = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
            - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
        local vertical = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0)
            - ((UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.Q)) and 1 or 0)

        -- Roblox virtual thumbstick/gamepad сообщают движение на земле.
        -- Преобразуем его в 3D-полёт с тем же наклоном камеры, что и для WASD.
        if forwardAxis == 0 and rightAxis == 0 then
            local move = humanoid.MoveDirection
            if move.Magnitude > 0.01 then
                forwardAxis = math.clamp(move:Dot(flatForward), -1, 1)
                rightAxis = math.clamp(move:Dot(right), -1, 1)
            end
        end
        if UserInputService.TouchEnabled and humanoid.Jump then
            vertical += 1
        end
        direction = look * forwardAxis + right * rightAxis + Vector3.yAxis * vertical
    end
    if direction.Magnitude > 1 then direction = direction.Unit end
    local target = direction * state.flySpeed
    if movement.velocity.VectorVelocity ~= target then
        movement.velocity.VectorVelocity = target
    end
    -- Персонаж остаётся прямо, даже если камера смотрит резко вверх/вниз.
    -- Нет смысла отправлять AlignOrientation один и тот же CFrame 60+ раз/сек.
    -- Обновляем только при заметном изменении направления камеры.
    if not movement.lastFacing or movement.lastFacing:Dot(flatForward) < 0.999995 then
        movement.orientation.CFrame = CFrame.lookAt(Vector3.zero, flatForward)
        movement.lastFacing = flatForward
    end
end

function movement.sync()
    if not alive then return end
    movement.nextPassiveAt = 0 -- Переключатели применяются без задержки.
    movement.nextNoclipAt = 0
    local needed = state.speedEnabled or state.noclip or state.fly
    if not needed then
        if movement.stepConnection then
            movement.stepConnection:Disconnect()
            movement.stepConnection = nil
        end
        movement.releaseCharacter()
        return
    end
    if not movement.stepConnection then
        local signal = RunService.PreSimulation or RunService.Stepped
        movement.stepConnection = signal:Connect(function()
            -- Fly остаётся покадровым. Для Speed/Noclip скан деталей ограничен.
            if not state.fly then
                local now = os.clock()
                if now < movement.nextPassiveAt then return end
                local rate = state.noclip and CONFIG.MiscNoclipRefreshHz
                    or CONFIG.MiscSpeedRefreshHz
                movement.nextPassiveAt = now + 1 / rate
            end
            local ok, err = pcall(movement.step)
            if not ok then
                if os.clock() - movement.lastErrorAt >= 3 then
                    movement.lastErrorAt = os.clock()
                    warn("[124 Visuals / Misc] " .. tostring(err))
                end
                -- Сбой физики не должен превращаться в ошибку на каждом кадре.
                pcall(movement.disableAll)
            end
        end)
    end
    local ok, err = pcall(movement.step)
    if not ok then tell("Misc: " .. tostring(err)) end
end

function movement.disableAll()
    state.speedEnabled, state.noclip, state.fly = false, false, false
    movement.sync()
    for _, key in ipairs({"speedEnabled", "noclip", "fly"}) do
        if refreshToggles[key] then pcall(refreshToggles[key]) end
    end
end

function movement.shutdown()
    if movement.stepConnection then
        movement.stepConnection:Disconnect()
        movement.stepConnection = nil
    end
    movement.releaseCharacter()
end

addSection(pages.MEMORY, "AIR MOTION WATCH", "Подозрительное перемещение — не определение модераторов")
addToggle(pages.MEMORY, "Оповещения о полёте", "6+ секунд стабильного движения в воздухе", "airAlerts", function(on)
    if not on and boosterPro.airMonitor then boosterPro.airMonitor.clear() end
end)
addButton(pages.MEMORY, "Нагрузка Air Watch", "Игроки / замеры / лучи / время прохода", function()
    local mon = boosterPro.airMonitor
    if mon and mon.diagnostics then tell(mon.diagnostics()) end
end)
addSection(pages.MEMORY, "SESSION DIAGNOSTICS", "Клиентские события, без обхода античита")
addToggle(pages.MEMORY, "Анализ логов",
    "OFF по умолчанию: LogService не обрабатывается в фоне",
    "sessionDiagnostics", function(enabled)
        perfCounters.session.setEnabled(enabled)
    end)
perfCounters.session.label = mk("TextLabel", {
    Name = "ClientSessionDiagnostics", BackgroundColor3 = P.tile,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38),
    Text = "Logs OFF | Warn 0 | Err 0 | Keywords 0",
    TextColor3 = P.dim, Font = Enum.Font.Code,
    TextSize = 10, TextWrapped = true,
}, columnFor(pages.MEMORY))
registerWidget(pages.MEMORY, perfCounters.session.label)
round(perfCounters.session.label, 6)
addButton(pages.MEMORY, "Проверка клиентских предупреждений",
    "Не видит серверный античит и не определяет риск бана", function()
    tell(perfCounters.session.summary() .. " | Совпадения не доказывают наличие античита")
end)
addButton(pages.MEMORY, "Safety Stop — закрыть Visuals",
    "Выключить модули и сохранить рискованные функции в состоянии OFF", function()
    tell("Safety Stop: выключаем Hub и сохраняем рискованные функции OFF")
    if cleanup then cleanup(true) end
end)
addSection(pages.MEMORY, "UTILITY", "Настройки клиента и графика")
addToggle(pages.MEMORY, "AntiAFK", "VirtualUser при событии Idled", "antiAfk", function(on)
    if not on then releaseAntiAfk() end
end)
addToggle(pages.MEMORY, "FPS Booster Pro", "Графика в 3 режимах, с откатом", "booster", setBooster)
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
addSection(pages.MEMORY, "GRAPHICS QUALITY", "Выбери степень оптимизации")
boosterPro.repaint = addChoice(pages.MEMORY, "Режим графики", {
    {value = "BALANCED", label = "BALANCED"},
    {value = "WHITE", label = "WHITE MAP"},
    {value = "ULTRA", label = "ULTRA LOW"},
}, "boosterMode", function(mode)
    if state.booster then setBooster(true, true) end
end)
boosterPro.label = mk("TextLabel", {
    Name = "BoosterProFPSComparison", BackgroundColor3 = P.tile,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 44),
    TextWrapped = true, Text = "До: н/д FPS | После: н/д",
    TextSize = 10, TextColor3 = Color3.fromRGB(221, 225, 227),
    Font = Enum.Font.Code,
}, columnFor(pages.MEMORY))
registerWidget(pages.MEMORY, boosterPro.label)
round(boosterPro.label, 6)
addButton(pages.MEMORY, "Сравнение FPS", "Реальные замеры после окончания обработки", function()
    tell("Booster Pro [" .. state.boosterMode .. "]: " .. boosterPro.readout()
        .. " | Проверено: " .. tostring(boosterPro.scanned)
        .. " | Очередь: " .. tostring(boosterPro.queueCount)
        .. " | Пропущено: " .. tostring(boosterPro.queueDropped)
        .. " | CPU max init/queue: "
        .. string.format("%.2f/%.2f ms", boosterPro.slicePeakMs,
            boosterPro.queuePeakMs))
end)
addButton(pages.MEMORY, "Диагностика Booster", "Режим, прогресс, изменения и ошибки обработки", function()
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
addToggle(pages.MEMORY, "Часы / FPS / Ping", "Информационный блок экрана", "hud")
addToggle(pages.MEMORY, "HUD активных функций", "Состояние AIM, ESP, Booster", "activeHud")
addSection(pages.MEMORY, "PERFORMANCE", "Режимы и диагностика")
repaintPerf = addChoice(pages.MEMORY, "Режим производительности", {
    {value = "AUTO", label = "AUTO"},
    {value = "ECO", label = "ECO"},
    {value = "QUALITY", label = "QUALITY"},
}, "performanceMode")
addToggle(pages.MEMORY, "Performance Guard",
    "При просадках снижает частоту Box/Skeleton, не число ESP-целей",
    "performanceGuard", function(enabled)
        perfCounters.guard.reset()
        perfCounters.guard.changed = os.clock() - CONFIG.GuardMinStepSeconds
        if not enabled then
            -- State is untouched; only effective visual budgets are restored.
            perfCounters.guard.reset()
        end
    end)
addToggle(pages.MEMORY, "Module CPU Monitor",
    "Измеряет время обработчиков AIM/Recoil/ESP; OFF для минимального overhead",
    "moduleCpuMonitor", function()
        perfCounters.cpu.reset()
    end)
addButton(pages.MEMORY, "Нагрузка модулей (avg / peak)",
    "Примерное время вызовов в мс, не общий процент CPU", function()
        tell(perfCounters.cpu.summary())
    end)
addToggle(pages.MEMORY, "Lazy Loading",
    "Создаёт ESP-слои только при первом включении функций",
    "lazyLoading", function()
        perfCounters.lazy.prepare()
    end)
addButton(pages.MEMORY, "Диагностика Performance",
    "Текущий Guard, число ESP-слоёв, AIM не ограничивается", function()
        tell(perfCounters.guard.description() .. " | lazy tracer "
            .. tostring(perfCounters.lazy.tracersCreated)
            .. " / shapes " .. tostring(perfCounters.lazy.shapesCreated)
            .. " | " .. (state.lazyLoading and "Lazy ON" or "Lazy OFF"))
    end)
perfCounters.guard.label = mk("TextLabel", {
    Name = "PerformanceGuardDiagnostics", Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = P.tile, BorderSizePixel = 0,
    Text = "Performance Guard: OFF", TextColor3 = P.dim,
    Font = Enum.Font.Code, TextSize = 10, TextWrapped = true,
}, columnFor(pages.MEMORY))
registerWidget(pages.MEMORY, perfCounters.guard.label)
round(perfCounters.guard.label, 6)
local perfLabel = mk("TextLabel", {Name = "PerfDiagnostics", BackgroundColor3 = P.tile,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35),
    Text = "ESP 0 · Box 0 · Scan 0ms", TextColor3 = P.dim,
    TextSize = 10, Font = Enum.Font.Code}, columnFor(pages.MEMORY))
registerWidget(pages.MEMORY, perfLabel)
round(perfLabel, 6)
perfCounters.frametime.label = mk("TextLabel", {
    Name = "FrameTimeDiagnostics",
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = P.tile, BorderSizePixel = 0,
    Text = "1% Low: замер... | p99: замер...",
    TextColor3 = P.dim, TextSize = 10,
    Font = Enum.Font.Code, TextWrapped = true,
}, columnFor(pages.MEMORY))
registerWidget(pages.MEMORY, perfCounters.frametime.label)
round(perfCounters.frametime.label, 6)
addButton(pages.MEMORY, "Проверка микрофризов",
    "Показать 1% Low, p99, худший кадр и число задержек от 50 мс", function()
        tell(perfCounters.frametime.summary())
    end)
addSection(pages.MISC, "MOVEMENT", "Управление скоростью и столкновениями")
addToggle(pages.MISC, "Speed", "Скорость ходьбы (8–120 studs/s)", "speedEnabled", function()
    movement.sync()
end)
addSlider(pages.MISC, "WalkSpeed", "Настраиваемое значение, обычная скорость восстановится при OFF",
    "speedValue", 8, 120, 1,
    function(value) return tostring(value) .. " studs/s" end,
    function() movement.sync() end)
addToggle(pages.MISC, "Noclip", "Временно отключить столкновения своего персонажа", "noclip", function()
    movement.sync()
end)

addSection(pages.MISC, "FLIGHT", "W/S — полёт по взгляду камеры, A/D — в стороны; Space и Q/Ctrl — дополнительно вверх/вниз")
addToggle(pages.MISC, "Fly", "W/S поднимают и опускают по наклону камеры; A/D стрейф", "fly", function(enabled)
    if enabled and state.antiAim then
        state.antiAim = false
        memoryFX.spin.reset()
        if refreshToggles.antiAim then pcall(refreshToggles.antiAim) end
    end
    movement.sync()
end)
addSlider(pages.MISC, "Fly Speed", "Скорость полёта 10–150 studs/s",
    "flySpeed", 10, 150, 5,
    function(value) return tostring(value) .. " studs/s" end)
addButton(pages.MISC, "Сбросить Movement", "Отключить Speed / Noclip / Fly и вернуть исходные свойства", function()
    movement.disableAll()
    requestSave()
    tell("Misc: Speed / Noclip / Fly выключены")
end)

addSection(pages.MISC, "CAMERA & LIGHTING", "Угол обзора и локальное освещение")
addToggle(pages.MISC, "Camera FOV", "Изменить вертикальный угол обзора, не радиус AIM", "cameraFovEnabled", function()
    memoryFX.camera.apply()
end)
addSlider(pages.MISC, "Угол камеры", "55–110°, исходный FOV вернётся при отключении",
    "cameraFovDegrees", 55, 110, 1,
    function(value) return tostring(value) .. "°" end,
    function() memoryFX.camera.apply() end)
addButton(pages.MISC, "Вернуть FOV камеры", "Отключить настройку и восстановить прежний угол", function()
    state.cameraFovEnabled = false
    memoryFX.camera.reset()
    if refreshToggles.cameraFovEnabled then refreshToggles.cameraFovEnabled() end
    requestSave()
    tell("Camera FOV: исходный угол восстановлен")
end)
addToggle(pages.MISC, "FullBright", "Локально осветлить карту; исходное освещение вернётся при OFF", "fullbright", function()
    applyLighting()
end)

-- Один клиентский Sound без RemoteEvent и без репликации другим игрокам.
-- При отсутствии прав на Roblox Audio ID трек не воспроизведётся.
local privateMusic = {sound = nil, currentId = nil, listeners = {}, status = nil, paused = false}
boosterPro.privateMusic = privateMusic
function privateMusic.statusText(message)
    if privateMusic.status and privateMusic.status.Parent then
        privateMusic.status.Text = message
    end
end
function privateMusic.stop()
    for _, connection in ipairs(privateMusic.listeners) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(privateMusic.listeners)
    if privateMusic.sound then
        pcall(function() privateMusic.sound:Stop() end)
        pcall(function() privateMusic.sound:Destroy() end)
    end
    privateMusic.sound, privateMusic.currentId, privateMusic.paused = nil, nil, false
end
function privateMusic.play(id)
    if type(id) ~= "string" or #id < 1 or #id > 19 or not id:match("^%d+$")
        or tonumber(id) == 0 then return false, "Укажи числовой Roblox Audio ID" end
    local ok, err = pcall(function()
        if privateMusic.sound and privateMusic.currentId ~= id then privateMusic.stop() end
        local sound = privateMusic.sound
        if not sound then
            sound = Instance.new("Sound")
            privateMusic.sound, privateMusic.currentId = sound, id
            sound.Name = "Army124Visuals_LocalMusic"
            sound.SoundId = "rbxassetid://" .. id
            sound.Volume = math.clamp(state.musicVolume / 100, 0, 1)
            sound.Looped = state.musicLoop == true
            sound.Parent = game:GetService("SoundService")
            privateMusic.listeners[#privateMusic.listeners + 1] = sound.Loaded:Connect(function()
                if alive and privateMusic.sound == sound then
                    privateMusic.statusText("Аудио загружено · ID " .. id)
                end
            end)
            privateMusic.listeners[#privateMusic.listeners + 1] = sound.Ended:Connect(function()
                if alive and privateMusic.sound == sound and not state.musicLoop then
                    privateMusic.statusText("Трек завершён · ID " .. id)
                end
            end)
            -- Play() успешен даже тогда, когда Asset не загружается из-за прав.
            -- Один отложенный осмотр нового ID, без бесконечного polling.
            task.delay(12, function()
                if not alive or privateMusic.sound ~= sound or not sound.Parent then return end
                local readyOk, loaded = pcall(function() return sound.IsLoaded end)
                if readyOk and not loaded then
                    privateMusic.statusText("Аудио не загрузилось за 12 с · проверь ID и доступ")
                end
            end)
        end
        sound.Looped = state.musicLoop == true
        sound.Volume = math.clamp(state.musicVolume / 100, 0, 1)
        if privateMusic.paused then sound:Resume()
        else sound:Play() end
        privateMusic.paused = false
    end)
    if not ok then
        privateMusic.stop()
        return false, tostring(err)
    end
    return true
end
function privateMusic.shutdown()
    privateMusic.stop()
end

addSection(pages.MISC, "WEAPON CONTROL", "Локальные свойства текущего Tool — не серверное оружие")
addToggle(pages.MISC, "No Recoil", "Компенсация камеры: Tool.Activated и локальный ввод стрельбы",
    "noRecoil", function(enabled)
        if enabled and state.controlRecoil then
            state.controlRecoil = false
            if refreshToggles.controlRecoil then pcall(refreshToggles.controlRecoil) end
        end
        recoil.reset()
end)
addToggle(pages.MISC, "No Spread", "Отслеживает локальные параметры Tool; серверный разброс не меняет",
    "noSpread", function(enabled)
        if enabled then
            local touched = recoil.applySpread()
            tell(touched > 0 and ("No Spread: изменено клиентских параметров: " .. tostring(touched))
                or "No Spread: подходящих параметров у текущего Tool нет; ждём оружие")
        else
            local restored = recoil.restoreSpread()
            tell(restored and "No Spread: локальные параметры восстановлены"
                or "No Spread: восстановление не завершено; снимки сохранены для повтора")
        end
end)
addButton(pages.MISC, "Диагностика оружия", "Показать Tool и число изменённых клиентских параметров", function()
    local tool, shots, lastCorrection = recoil.inspect()
    tell("Tool: " .. tostring(tool)
        .. " | No Spread changed: " .. tostring(recoil.spread.modified)
        .. " | Shot pulses: " .. tostring(shots)
        .. " | Recoil correction: " .. string.format("%.2f°", lastCorrection))
end)

addSection(pages.MISC, "LOCAL MUSIC", "Личный проигрыватель Roblox Audio ID, без передачи другим игрокам")
local musicInputRow = mk("Frame", {
    Name = "LocalMusicInputRow", Size = UDim2.new(1, 0, 0, 94),
    BackgroundColor3 = P.tile, BorderSizePixel = 0,
}, columnFor(pages.MISC))
registerWidget(pages.MISC, musicInputRow)
round(musicInputRow, 5)
mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, musicInputRow)
mk("TextLabel", {
    BackgroundTransparency = 1, Text = "Roblox Audio ID",
    Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = P.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 0, 20),
}, musicInputRow)
local musicIdInput = mk("TextBox", {
    Name = "LocalMusicId", Text = state.musicId,
    PlaceholderText = "Вставь числовой ID музыки",
    ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = P.text, PlaceholderColor3 = P.dim,
    BackgroundColor3 = P.tile, BorderSizePixel = 0,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(10, 31),
    Size = UDim2.new(1, -20, 0, 31),
}, musicInputRow)
round(musicIdInput, 4)
mk("UIPadding", {PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8)}, musicIdInput)
privateMusic.status = mk("TextLabel", {
    Name = "LocalMusicStatus", Text = "Локально · выбери аудио по ID",
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = P.dim, TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(10, 66), Size = UDim2.new(1, -20, 0, 18),
}, musicInputRow)
privateMusic.refresh = function()
    if musicIdInput.Parent and not musicIdInput:IsFocused() then
        musicIdInput.Text = state.musicId
    end
    if privateMusic.sound then
        pcall(function()
            privateMusic.sound.Volume = math.clamp(state.musicVolume / 100, 0, 1)
            privateMusic.sound.Looped = state.musicLoop == true
        end)
    end
end

addButton(pages.MISC, "▶ Play Music", "Начать воспроизведение указанного Roblox Audio ID", function()
    local id = musicIdInput.Text:match("^%s*(.-)%s*$")
    id = id:gsub("^rbxassetid://", "")
    if not id:match("^%d+$") or #id > 19 or tonumber(id) == 0 then
        privateMusic.statusText("Неверный ID · вставь только цифры")
        tell("Музыка: нужен числовой Roblox Audio ID")
        return
    end
    local ok, err = privateMusic.play(id)
    if not ok then
        privateMusic.statusText("Не удалось запустить: " .. tostring(err):sub(1, 80))
        tell("Музыка: " .. tostring(err))
        return
    end
    state.musicId = id
    requestSave()
    local loadedOK, loaded = pcall(function()
        return privateMusic.sound ~= nil and privateMusic.sound.IsLoaded
    end)
    privateMusic.statusText(loadedOK and loaded and ("Воспроизводится · ID " .. id)
        or ("Загрузка Audio ID " .. id .. " ..."))
end)
addButton(pages.MISC, "Ⅱ Pause Music", "Приостановить личную музыку", function()
    if not privateMusic.sound then
        tell("Музыка: сейчас ничего не играет")
        return
    end
    local ok, err = pcall(function() privateMusic.sound:Pause() end)
    if ok then
        privateMusic.paused = true
        privateMusic.statusText("На паузе · Play продолжит с этого места")
    else tell("Музыка: " .. tostring(err)) end
end)
addButton(pages.MISC, "■ Stop Music", "Остановить и удалить локальный Sound", function()
    privateMusic.stop()
    privateMusic.statusText("Остановлено · звук удалён")
end)
addSlider(pages.MISC, "Music Volume", "Только громкость музыки Visuals · 0–100%",
    "musicVolume", 0, 100, 5,
    function(v) return tostring(v) .. "%" end,
    function() privateMusic.refresh() end)
addToggle(pages.MISC, "Repeat Music", "Повторять трек после окончания", "musicLoop", function()
    privateMusic.refresh()
end)

addSection(pages.MISC, "TELEPORT", "Переход к игроку по Roblox username или DisplayName")
local tpEntry = mk("Frame", {
    Name = "TeleportToPlayerEntry", BackgroundColor3 = P.tile,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 76),
}, columnFor(pages.MISC))
registerWidget(pages.MISC, tpEntry)
round(tpEntry, 3)
mk("UIStroke", {Color = P.border, Transparency = 0.48, Thickness = 1}, tpEntry)
mk("TextLabel", {
    BackgroundTransparency = 1, Text = "TP to Player", Font = Enum.Font.GothamMedium,
    TextSize = 12, TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 0, 18),
}, tpEntry)
local tpInput = mk("TextBox", {
    Name = "TargetUsername", Text = "", PlaceholderText = "@username / DisplayName",
    ClearTextOnFocus = false, Font = Enum.Font.Gotham,
    TextSize = 12, TextColor3 = P.text, PlaceholderColor3 = P.dim,
    BackgroundColor3 = P.tile, BorderSizePixel = 0,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(10, 29), Size = UDim2.new(1, -20, 0, 36),
}, tpEntry)
round(tpInput, 5)
mk("UIPadding", {
    PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
}, tpInput)

addButton(pages.MISC, "TP to Player", "Ввести ник выше и телепортироваться рядом с игроком", function()
    local query = tpInput.Text:match("^%s*(.-)%s*$"):gsub("^@", "")
    query = string.lower(query)
    if #query < 2 then tell("TP: введи хотя бы 2 символа ника"); return end
    local exact, candidate, matches = nil, nil, 0
    -- Username имеет приоритет над неоднозначными DisplayName.
    for _, person in ipairs(perfCounters.roster) do
        if person ~= LocalPlayer and string.lower(person.Name) == query then
            exact = person
            break
        end
    end
    if not exact then
        for _, person in ipairs(perfCounters.roster) do
            if person ~= LocalPlayer then
                local username, display = string.lower(person.Name), string.lower(person.DisplayName)
                if username:sub(1, #query) == query or display == query
                    or display:sub(1, #query) == query then
                    candidate = person
                    matches += 1
                end
            end
        end
    end
    local target = exact or (matches == 1 and candidate or nil)
    if not target then
        tell(matches > 1 and "TP: найдено несколько игроков, уточни @username"
            or "TP: игрок не найден в текущем сервере")
        return
    end
    local theirChar = target.Character
    local theirRoot = theirChar and theirChar:FindFirstChild("HumanoidRootPart")
    local theirHum = theirChar and theirChar:FindFirstChildOfClass("Humanoid")
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not (theirRoot and theirRoot:IsA("BasePart")
        and theirHum and theirHum.Health > 0
        and myRoot and myRoot:IsA("BasePart")) then
        tell("TP: цель или твой персонаж ещё не загружены")
        return
    end
    local ok, err = pcall(function()
        myChar:PivotTo(theirRoot.CFrame * CFrame.new(0, 3, 5))
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end)
    if ok then
        tell("TP: перемещение рядом с " .. target.Name .. " отправлено")
    else
        tell("TP: ошибка: " .. tostring(err))
    end
end)

addSection(pages.MISC, "ANTI-AIM", "Локальное вращение тела; реальная репликация не гарантируется")
addToggle(pages.MISC, "Anti-Aim Spin", "Быстрая крутилка + наклон корпуса", "antiAim", function(enabled)
    if enabled and state.fly then
        state.fly = false
        movement.sync()
        if refreshToggles.fly then pcall(refreshToggles.fly) end
    end
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
-- LITE: Bunny Hop and chat panels removed entirely.
addButton(pages.MEMORY, "Reset Character", "Локальный сброс Humanoid", function()
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

-- CFG page removed; CUSTOM settings are still saved automatically.
applyResponsiveLayout()


local status = mk("TextLabel", {
    Name = "Footer", Position = UDim2.new(0, wideLayout and 207 or 101, 1, -29),
    Size = UDim2.new(1, wideLayout and -220 or -110, 0, 22),
    BackgroundTransparency = 0, BackgroundColor3 = P.background,
    BorderSizePixel = 0, ZIndex = 4,
    Text = "124 VISUALS · READY",
    TextSize = 9, Font = Enum.Font.Code,
    TextColor3 = P.dim,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, panel)
statusMessage = status
boosterPro.uiFooter = status

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
        if state.speedEnabled then table.insert(risks, "Speed") end
        if state.noclip then table.insert(risks, "Noclip") end
        if state.fly then table.insert(risks, "Fly") end
        if state.controlRecoil then table.insert(risks, "Control Recoil") end
        if state.noRecoil then table.insert(risks, "No Recoil") end
        if state.noSpread then table.insert(risks, "No Spread (local)") end
        if state.esp then table.insert(risks, "ESP / Visuals") end
        if state.fullbright then table.insert(risks, "FullBright") end
        if state.antiAfk then table.insert(risks, "AntiAFK") end
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
        state.noRecoil, state.noSpread = false, false
        recoil.restoreSpread()
        state.antiAim = false
        movement.disableAll()
        state.esp = false
        state.tracers = false
        state.espBox = false
        state.fullbright = false
        state.antiAfk = false
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

-- 124 VISUALS / UI FROM SUPPLIED REFERENCE. All controls go through
-- existing state, refresh, and save handlers; no changes to ESP targeting.
local function buildReferenceMenu()
    local bg = P.background
    local surface = P.panel
    local raised = P.tile
    local border = P.border
    local light = P.text
    local muted = P.dim
    local function corners(obj, radius)
        mk("UICorner", {CornerRadius = UDim.new(0, radius)}, obj)
        return obj
    end
    local function textLabel(parent, name, caption, position, size, fontSize, color, font)
        return mk("TextLabel", {Name = name, BackgroundTransparency = 1,
            Position = position, Size = size, Text = caption, TextSize = fontSize,
            TextColor3 = color or light, Font = font or Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd}, parent)
    end
    -- Screenshot's upper-left brand, with the actual script version below.
    local brand = textLabel(tabs, "ReferenceBrand", "124 Visuals",
        UDim2.fromOffset(19, 18), UDim2.fromOffset(168, 35), 23, light,
        Enum.Font.GothamBlack)
    local version = textLabel(tabs, "ReferenceVersion", "v" .. CONFIG.Version,
        UDim2.fromOffset(86, 50), UDim2.fromOffset(78, 17), 10, muted,
        Enum.Font.Gotham)
    -- Vector Roblox mark: tilted square with the distinctive square cutout.
    -- No remote image and no fragile undocumented Roblox asset ID.
    mk("Frame", {Name = "SidebarEdge", Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = P.accent,
        BorderSizePixel = 0, BackgroundTransparency = 0.24}, tabs)
    local robloxMark = corners(mk("Frame", {
        Name = "RobloxMark", Position = UDim2.new(0.5, -20, 1, -95),
        Size = UDim2.fromOffset(40, 40), Rotation = 25, BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(111, 113, 119),
    }, tabs), 2)
    mk("Frame", {Name = "RobloxCutout", Position = UDim2.fromOffset(13, 13),
        Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0,
        BackgroundColor3 = bg}, robloxMark)
    local robloxName = textLabel(tabs, "RobloxCaption", "ROBLOX",
        UDim2.new(0.5, -36, 1, -44), UDim2.fromOffset(80, 20), 11, muted,
        Enum.Font.GothamBold)
    robloxName.TextXAlignment = Enum.TextXAlignment.Center

    -- Topbar: search / local status / session uptime / dashboard.
    local search = corners(mk("TextBox", {Name = "ReferenceSearch",
        Position = UDim2.fromOffset(214, 15), Size = UDim2.fromOffset(315, 43),
        BackgroundColor3 = Color3.fromRGB(26, 27, 30),
        BorderSizePixel = 0, ClearTextOnFocus = false, Text = "",
        PlaceholderText = "⌕   Поиск ESP...",
        PlaceholderColor3 = Color3.fromRGB(124, 126, 131),
        Font = Enum.Font.Gotham, TextColor3 = light, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left}, bar), 12)
    mk("UIStroke", {Color = border, Transparency = 0.35, Thickness = 1}, search)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 9)}, search)
    local safe = corners(mk("TextLabel", {Name = "ReferenceSafe",
        AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(549, 17),
        Size = UDim2.fromOffset(75, 40), Text = "●  Ready",
        BackgroundColor3 = Color3.fromRGB(23, 24, 27),
        TextColor3 = Color3.fromRGB(115, 225, 135), TextSize = 13,
        Font = Enum.Font.GothamMedium, BorderSizePixel = 0}, bar), 10)
    mk("UIStroke", {Color = border, Transparency = 0.5}, safe)
    local clock = corners(mk("TextLabel", {Name = "ReferenceTimer",
        AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(636, 17),
        Size = UDim2.fromOffset(112, 40), Text = "◷  00:00:00",
        BackgroundColor3 = Color3.fromRGB(23, 24, 27),
        TextColor3 = light, TextSize = 12, Font = Enum.Font.Code,
        BorderSizePixel = 0}, bar), 10)
    mk("UIStroke", {Color = border, Transparency = 0.5}, clock)
    local active = corners(mk("TextButton", {Name = "ReferenceActive",
        AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(760, 17),
        Size = UDim2.fromOffset(95, 40), Text = "Active",
        BackgroundColor3 = Color3.fromRGB(23, 24, 27),
        TextColor3 = Color3.fromRGB(124, 220, 133), TextSize = 13,
        Font = Enum.Font.GothamMedium, AutoButtonColor = false,
        BorderSizePixel = 0}, bar), 10)
    mk("UIStroke", {Color = border, Transparency = 0.5}, active)
    safeActivate(active, function() showPage("HOME") end)
    -- Existing close/minimize actions remain wired, now less intrusive.
    hide.Text, hide.BackgroundTransparency = "‹", 1
    hide.TextColor3, hide.TextSize = muted, 22
    close.BackgroundTransparency, close.TextColor3 = 1, muted
    close.Position, close.Size = UDim2.new(1, -218, 0, 22), UDim2.fromOffset(17, 26)

    local root = mk("Frame", {Name = "ScreenshotESP", BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Visible = wideLayout,
        ClipsDescendants = true}, pages.ESP)
    local left = corners(mk("Frame", {Name = "ESPSettingsCard",
        Position = UDim2.fromScale(0, 0), Size = UDim2.new(0.452, -4, 1, 0),
        BackgroundColor3 = surface, BorderSizePixel = 0}, root), 12)
    local right = mk("Frame", {Name = "ReferenceRightColumn",
        Position = UDim2.new(0.452, 4, 0, 0),
        Size = UDim2.new(0.548, -4, 1, 0), BackgroundTransparency = 1}, root)
    mk("UIStroke", {Color = border, Transparency = 0.16, Thickness = 1}, left)
    mk("UIGradient", {Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(34, 35, 40),
            Color3.fromRGB(27, 28, 32))}, left)
    textLabel(left, "ESPHeader", "◎   ESP SETTINGS", UDim2.fromOffset(18, 11),
        UDim2.new(1, -28, 0, 22), 15, light, Enum.Font.GothamBold)
    local emptySearch = textLabel(left, "EmptySearch", "No matching functions",
        UDim2.new(0, 15, 0.5, -12), UDim2.new(1, -30, 0, 24), 12, muted,
        Enum.Font.Gotham)
    emptySearch.TextXAlignment = Enum.TextXAlignment.Center
    emptySearch.Visible = false
    local list = mk("ScrollingFrame", {Name = "ESPSettingsList",
        Position = UDim2.fromOffset(17, 45), Size = UDim2.new(1, -34, 1, -53),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0), Active = true}, left)
    table.insert(scrollFrames, list)
    mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)}, list)
    local rows = {}
    local toggleColorOn = Color3.fromRGB(202, 204, 210)
    local toggleColorOff = Color3.fromRGB(71, 73, 80)
    local function paintSwitch(track, knob, enabled, available)
        track.BackgroundColor3 = enabled and toggleColorOn or toggleColorOff
        knob.Position = UDim2.fromOffset(enabled and 16 or 2, 2)
        knob.BackgroundColor3 = available and light or Color3.fromRGB(165, 166, 171)
    end
    local function miniSwitch(parent, name, title, position, stateReader, action)
        local row = mk("TextButton", {Name = name, Text = "", AutoButtonColor = false,
            Position = position, Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Color3.fromRGB(69, 71, 79),
            BackgroundTransparency = 1, BorderSizePixel = 0}, parent)
        corners(row, 6)
        local caption = textLabel(row, "Title", title, UDim2.fromOffset(0, 1),
            UDim2.new(1, -51, 0, 25), 13, light, Enum.Font.Gotham)
        -- Switch is right-aligned exactly like the reference: soft grey rail,
        -- compact white circular knob, full-row click target for mouse/touch.
        local pill = corners(mk("Frame", {Name = "Switch",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -4, 0.5, 0),
            Size = UDim2.fromOffset(30, 16),
            BackgroundColor3 = toggleColorOff, BorderSizePixel = 0}, row), 8)
        mk("UIStroke", {Color = Color3.fromRGB(126, 129, 136),
            Transparency = 0.64, Thickness = 1}, pill)
        local knob = corners(mk("Frame", {Name = "Knob",
            Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = light, BorderSizePixel = 0}, pill), 6)
        local function update()
            if not row.Parent then return end
            paintSwitch(pill, knob, stateReader(), action ~= nil)
            caption.TextColor3 = action and light or muted
        end
        connect(row.MouseEnter, function()
            if alive and action and row.Parent then row.BackgroundTransparency = 0.82 end
        end)
        connect(row.MouseLeave, function()
            if row.Parent then row.BackgroundTransparency = 1 end
        end)
        safeActivate(row, function()
            if not action then
                tell(title .. ": модуль отсутствует в этой версии")
                return
            end
            action()
            update()
        end)
        update()
        return {row = row, label = title, update = update}
    end
    local controls = {
        {"ESP Master", "esp"}, {"Box ESP", "espBox"}, {"Line ESP", "tracers"},
        {"Health Bar", "health"}, {"Name", "names"}, {"Distance", "distance"},
        {"Weapon", nil}, {"Team ID", nil},
        {"Enemy Count", nil}, {"Game Info", nil},
    }
    for index, spec in ipairs(controls) do
        local key = spec[2]
        local item = miniSwitch(list, "ReferenceESP_" .. index, spec[1],
            UDim2.fromOffset(0, 0),
            function() return key ~= nil and state[key] == true end,
            key and function()
                local previous = state[key]
                state[key] = not previous
                -- An API failure must not leave a toggle saved as ON when
                -- the corresponding feature could not be refreshed.
                local ok, err = pcall(function()
                    if key == "esp" then
                        syncEspVisuals()
                    elseif key == "espBox" then
                        if not state.espBox then clearShapes() end
                    elseif key == "tracers" then
                        -- Keep OFF immediate; the existing visual frame owns
                        -- all ON redraws to avoid a camera-frame spike.
                        if not state.tracers then clearTracers() end
                    else
                        -- Labels/health/distance are refreshed by the shared
                        -- event queue, never synchronously in a tap callback.
                        queueESPRefresh()
                    end
                end)
                if not ok then
                    state[key] = previous
                    pcall(syncEspVisuals)
                    tell("ESP " .. tostring(key) .. ": " .. tostring(err))
                    return
                end
                local old = refreshToggles[key]
                if old then pcall(old) end
                requestSave()
            end or nil)
        item.row.LayoutOrder = index
        rows[#rows + 1] = item
        if key then
            local previous = refreshToggles[key]
            refreshToggles[key] = function()
                if previous then pcall(previous) end
                item.update()
            end
        end
    end

    local function card(name, y, h)
        local frame = corners(mk("Frame", {Name = name,
            Position = UDim2.new(0, 0, y, 0),
            Size = UDim2.new(1, 0, h, -6),
            BackgroundColor3 = surface, BorderSizePixel = 0}, right), 12)
        mk("UIStroke", {Color = border, Transparency = 0.16, Thickness = 1}, frame)
        mk("UIGradient", {Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(34, 35, 40),
                Color3.fromRGB(27, 28, 32))}, frame)
        return frame
    end
    local top = card("DistanceAndBorder", 0, 0.38)
    local skins = card("ModSkinn", 0.38, 0.31)
    local visual = card("VisualControls", 0.69, 0.31)
    skins.Position = UDim2.new(0, 0, 0.38, 4)
    visual.Position = UDim2.new(0, 0, 0.69, 8)
    visual.Size = UDim2.new(1, 0, 0.31, -8)
    local pointer = nil
    local function cancelPointer()
        local drag = pointer
        pointer = nil
        if drag and drag.finish then drag.finish() end
    end
    local function makeSlider(parent, label, key, lo, hi, step, formatter, y, onChanged)
        textLabel(parent, key .. "Title", label, UDim2.fromOffset(15, y),
            UDim2.new(1, -120, 0, 20), 13, light, Enum.Font.Gotham)
        local value = corners(mk("TextLabel", {Name = key .. "Value",
            Position = UDim2.new(1, -82, 0, y - 1), Size = UDim2.fromOffset(68, 24),
            BackgroundColor3 = raised, BorderSizePixel = 0, TextColor3 = light,
            Font = Enum.Font.GothamMedium, TextSize = 11}, parent), 9)
        local area = mk("TextButton", {Name = key .. "Area", Text = "",
            AutoButtonColor = false, BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, y + 25), Size = UDim2.new(1, -32, 0, 24)}, parent)
        local track = corners(mk("Frame", {Name = "SliderTrack",
            Position = UDim2.new(0, 4, 0.5, -2), Size = UDim2.new(1, -8, 0, 4),
            BackgroundColor3 = Color3.fromRGB(15, 16, 18), BorderSizePixel = 0}, area), 3)
        local fill = corners(mk("Frame", {Name = "SliderFill",
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(174, 175, 180),
            BorderSizePixel = 0}, track), 3)
        local thumb = corners(mk("Frame", {Name = "SliderThumb",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(16, 16), Position = UDim2.fromScale(0, 0.5),
            BackgroundColor3 = light, BorderSizePixel = 0}, track), 9)
        local committedValue = state[key]
        local dirty = false
        local lastApplyAt = -1e8
        local function update()
            -- The reference slider creates 'area', not 'container'.
            -- Referencing the undefined variable crashed initializeHubUI
            -- on the first update() call before the menu could be shown.
            if not area.Parent then return end
            local fraction = math.clamp((state[key] - lo) / (hi - lo), 0, 1)
            fill.Size = UDim2.fromScale(fraction, 1)
            thumb.Position = UDim2.fromScale(fraction, 0.5)
            value.Text = formatter(state[key])
        end
        local function commitValue()
            if not dirty then return end
            dirty = false
            if not alive then return end
            -- Avoid repeated ESP scans on every pixel of drag; always commit
            -- the final snapped value on release, resize or tab switch.
            local ok, err = true, nil
            if onChanged then ok, err = pcall(onChanged) end
            if not ok then
                state[key] = committedValue
                update()
                tell("Ошибка слайдера " .. tostring(key) .. ": " .. tostring(err))
                return
            end
            committedValue = state[key]
            lastApplyAt = os.clock()
            requestSave()
        end
        local old = refreshSliders[key]
        refreshSliders[key] = function()
            if old then pcall(old) end
            committedValue = state[key]
            dirty = false
            update()
        end
        local function setFromX(x)
            if not alive or not panel.Visible or not pages.ESP.Visible
                or not root.Visible or not track.Parent then return end
            local fraction = math.clamp((x - track.AbsolutePosition.X)
                / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local raw = lo + fraction * (hi - lo)
            local nextValue = math.clamp(lo + math.floor((raw - lo) / step + 0.5) * step, lo, hi)
            if state[key] ~= nextValue then
                state[key] = nextValue
                dirty = true
                -- Основной слайдер обновляется сразу, без дорогостоящего ESP-скана.
                if old then pcall(old) end
                -- At most about 9 expensive visual refreshes per second.
                if os.clock() - lastApplyAt >= 0.11 then commitValue() end
            end
            update()
        end
        connect(area.InputBegan, function(input)
            local kind = input.UserInputType
            if not alive or pointer or not panel.Visible or not root.Visible
                or not pages.ESP.Visible then return end
            if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
                local touch = kind == Enum.UserInputType.Touch
                pointer = {input = input, set = setFromX, finish = commitValue,
                    touch = touch, start = input.Position, active = not touch}
                -- A touch starting on the slider can still be a vertical scroll:
                -- don't change the value until a horizontal gesture is clear.
                if not touch then setFromX(input.Position.X) end
            end
        end)
        update()
    end
    connect(UserInputService.InputChanged, function(input)
        local drag = pointer
        if not drag then return end
        if not alive or not panel.Visible or not root.Visible
            or not pages.ESP.Visible then cancelPointer(); return end
        if drag.touch then
            if input ~= drag.input then return end
            local dx = input.Position.X - drag.start.X
            local dy = input.Position.Y - drag.start.Y
            if not drag.active then
                if math.abs(dy) >= 10 and math.abs(dy) > math.abs(dx) * 1.1 then
                    cancelPointer() -- Vertical scroll owns the gesture.
                    return
                end
                if math.abs(dx) < 10 or math.abs(dx) < math.abs(dy) * 1.15 then
                    return -- Wait for horizontal intent.
                end
                drag.active = true
            end
            drag.set(input.Position.X)
        elseif input.UserInputType == Enum.UserInputType.MouseMovement then
            drag.set(input.Position.X)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        local drag = pointer
        if drag and (input == drag.input or (not drag.touch
            and input.UserInputType == Enum.UserInputType.MouseButton1)) then
            if drag.touch and not drag.active then
                local dx = input.Position.X - drag.start.X
                local dy = input.Position.Y - drag.start.Y
                -- A deliberate tap should set the value on release, while
                -- touch-down alone remains harmless to vertical scrolling.
                if math.abs(dx) < 8 and math.abs(dy) < 8 then
                    drag.set(input.Position.X)
                end
            end
            cancelPointer()
        end
    end)
    -- Оба ползунка читают единые границы: пользователь выбирает любой радиус до 1000 м.
    makeSlider(top, "Max Distance", "espRangeMeters",
        CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters, CONFIG.EspRangeStepMeters,
        function(value) return tostring(value) .. "m" end, 17,
        function()
            -- Full roster sorting + 2D geometry must not run synchronously
            -- for every dragged slider tick. Queue at most one pending scan.
            queueESPRefresh()
        end)
    mk("Frame", {Name = "ReferenceDivider", Position = UDim2.fromOffset(15, 86),
        Size = UDim2.new(1, -30, 0, 1), BackgroundColor3 = border,
        BorderSizePixel = 0}, top)
    local borderSwitch = miniSwitch(top, "TextBorder", "Text Border",
        UDim2.new(0, 15, 0, 102), function() return referenceStrokeEnabled end,
        function()
            referenceStrokeEnabled = not referenceStrokeEnabled
            -- Текстовая обводка без полного обхода / сортировки ESP.
            local alpha = referenceStrokeEnabled and 0.55 or 1
            for _, item in pairs(renderData) do
                if isLive(item.nameLabel) then
                    setIfDifferent(item.nameLabel, "TextStrokeTransparency", alpha)
                end
                if isLive(item.healthLabel) then
                    setIfDifferent(item.healthLabel, "TextStrokeTransparency", alpha)
                end
                if isLive(item.distanceLabel) then
                    setIfDifferent(item.distanceLabel, "TextStrokeTransparency", alpha)
                end
            end
        end)
    borderSwitch.row.Size = UDim2.new(1, -30, 0, 28)
    textLabel(skins, "SkinsHeader", "◇   MOD SKINN", UDim2.fromOffset(16, 10),
        UDim2.new(1, -28, 0, 22), 15, light, Enum.Font.GothamBold)
    textLabel(skins, "UnavailableTag", "PREVIEW", UDim2.new(1, -73, 0, 12),
        UDim2.fromOffset(62, 18), 9, muted, Enum.Font.GothamMedium)
    local skinOptions = {"XSuit", "Bag", "Helmet"}
    for i, caption in ipairs(skinOptions) do
        local entry = miniSwitch(skins, "Unsupported_" .. caption, caption,
            UDim2.fromOffset(16, 35 + (i - 1) * 29), function() return false end, nil)
        entry.row.Size = UDim2.new(1, -32, 0, 28)
    end
    textLabel(visual, "VisualHeader", "◉   VISUALS", UDim2.fromOffset(16, 10),
        UDim2.new(1, -28, 0, 22), 15, light, Enum.Font.GothamBold)
    local crosshair = mk("Frame", {Name = "124VisualsCrosshair",
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1,
        Visible = false, ZIndex = 200}, gui)
    for _, rect in ipairs({
        {12, 0, 2, 9}, {12, 17, 2, 9}, {0, 12, 9, 2}, {17, 12, 9, 2},
    }) do
        mk("Frame", {Position = UDim2.fromOffset(rect[1], rect[2]),
            Size = UDim2.fromOffset(rect[3], rect[4]), BorderSizePixel = 0,
            BackgroundColor3 = light, ZIndex = 200}, crosshair)
    end
    local crosshairEnabled = state.crosshairLocal == true
    boosterPro.setLocalCrosshair = function(enabled)
        crosshairEnabled = enabled == true
        crosshair.Visible = crosshairEnabled
    end
    boosterPro.setLocalCrosshair(crosshairEnabled)
    local cross = miniSwitch(visual, "EnableCrosshair", "Enable Crosshair",
        UDim2.fromOffset(15, 36), function() return crosshairEnabled end,
        function()
            crosshairEnabled = not crosshairEnabled
            state.crosshairLocal = crosshairEnabled
            crosshair.Visible = crosshairEnabled
            if refreshToggles.crosshairLocal then
                pcall(refreshToggles.crosshairLocal)
            end
        end)
    cross.row.Size = UDim2.new(1, -30, 0, 26)
    makeSlider(visual, "FOV Circle", "aimFovPixels", CONFIG.AimFovMinPixels,
        CONFIG.AimFovMaxPixels, 5, function(value) return tostring(value) .. "px" end,
        72, refreshFovRing)

    -- Search the ACTUAL ESP cards: title, subtitle, and section headings.
    -- No polling; only reacts to TextBox edits. Avoid repeated toast spam.
    local searchEmpty = mk("TextLabel", {
        Name = "PremiumSearchEmpty", BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0.5, -16),
        Size = UDim2.new(1, -16, 0, 32),
        Text = "Ничего не найдено", TextSize = 12,
        Font = Enum.Font.GothamMedium, TextColor3 = P.dim,
        Visible = false, TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 8,
    }, pages.ESP)
    connect(search:GetPropertyChangedSignal("Text"), function()
        if not alive then return end
        local query = string.lower(search.Text):match("^%s*(.-)%s*$")
        local matches = 0
        local info = pageColumns[pages.ESP]
        if info then
            for _, item in ipairs(info.widgets) do
                local widget = item.object
                if widget and widget.Parent then
                    local found = true
                    if query ~= "" then
                        local fields = {widget.Name}
                        for _, label in ipairs(widget:GetDescendants()) do
                            if label:IsA("TextLabel") and label.Text ~= "" then
                                fields[#fields + 1] = label.Text
                            end
                        end
                        found = string.lower(table.concat(fields, " ")):find(query, 1, true) ~= nil
                    end
                    widget.Visible = found
                    if found then matches = matches + 1 end
                end
            end
        end
        searchEmpty.Visible = query ~= "" and matches == 0
        if query ~= "" then showPage("ESP") end
    end)
    local function clearSearch()
        if search.Text ~= "" then search.Text = "" end
    end
    local started = os.clock()
    local function tick()
        local elapsed = math.max(0, math.floor(os.clock() - started))
        clock.Text = string.format("◷  %02d:%02d:%02d",
            math.floor(elapsed / 3600), math.floor(elapsed / 60) % 60, elapsed % 60)
    end
    local function layout(wide)
        -- Reference logo now sits ABOVE the left-hand navigation.
        -- On short screens it scales down instead of covering any tabs.
        local tiny = not wide and panel.Size.Y.Offset < 320
        brand.Visible, version.Visible = true, not tiny
        brand.Text = wide and "124 VISUALS" or "124"
        brand.Position = wide and UDim2.fromOffset(60, 16)
            or UDim2.fromOffset(5, 30)
        brand.Size = wide and UDim2.fromOffset(128, 31)
            or UDim2.fromOffset(82, 19)
        brand.TextSize = wide and 16 or 14
        brand.TextXAlignment = wide and Enum.TextXAlignment.Left
            or Enum.TextXAlignment.Center
        version.Position = wide and UDim2.fromOffset(62, 49)
            or UDim2.fromOffset(7, 50)
        version.Size = wide and UDim2.fromOffset(115, 17)
            or UDim2.fromOffset(80, 14)
        version.TextSize = 9
        version.TextXAlignment = wide and Enum.TextXAlignment.Left
            or Enum.TextXAlignment.Center
        robloxMark.Visible = true
        robloxName.Visible = false
        robloxMark.Position = wide and UDim2.fromOffset(17, 18)
            or UDim2.fromOffset(34, 5)
        robloxMark.Size = wide and UDim2.fromOffset(32, 32)
            or UDim2.fromOffset(24, 24)
        robloxMark.BackgroundColor3 = P.accent
        local markHole = robloxMark:FindFirstChild("RobloxCutout")
        if markHole then
            markHole.Position = wide and UDim2.fromOffset(10, 10)
                or UDim2.fromOffset(8, 8)
            markHole.Size = wide and UDim2.fromOffset(12, 12)
                or UDim2.fromOffset(8, 8)
        end
        search.Visible, safe.Visible, clock.Visible, active.Visible = wide, wide, wide, wide
        local title = bar:FindFirstChild("BrandTitle")
        local caption = bar:FindFirstChild("BrandCaption")
        if title then title.Visible = false end
        if caption then caption.Visible = false end
        hide.Parent = wide and tabs or bar
        hide.Position = wide and UDim2.new(0, 4, 1, -54)
            or UDim2.new(1, -80, 0, 22)
        hide.Size = wide and UDim2.fromOffset(22, 30) or UDim2.fromOffset(27, 28)
        close.Position = wide and UDim2.new(1, -40, 0, 23)
            or UDim2.new(1, -43, 0, 22)
        close.Size = wide and UDim2.fromOffset(26, 26)
            or UDim2.fromOffset(27, 28)
    end
    tick()
    return {root = root, layout = layout, tick = tick,
        clearSearch = clearSearch, cancelInteraction = cancelPointer}
end
referenceESP = buildReferenceMenu()
applyResponsiveLayout()
showPage("ESP")

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
        movement.disableAll()
        state.controlRecoil = false
        state.noRecoil, state.noSpread = false, false
        recoil.restoreSpread()
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
    sliderDrag = nil
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
    panelScale.Scale = uiBaseScale * 0.98
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
    BackgroundColor3 = P.tile,
    TextColor3 = P.text,
    Text = "AIM: OFF", TextSize = 12,
    Font = Enum.Font.GothamMedium, Visible = false,
}, gui)
round(aimTouchButton, 5)
repaintAimTouch = function()
    if not aimTouchButton.Parent then return end
    -- GUI/F6 may activate aimHeldKey without setting aimHeldTouch.
    local active = state.aimbot and (aimHeldTouch or aimHeldKey or aimHeldMouse)
    aimTouchButton.Text = active and (aimPro.equippedTool() and "AIM: ON" or "AIM: NO GUN")
        or "AIM: OFF"
    aimTouchButton.BackgroundColor3 = active and P.accent or P.tile
    aimTouchButton.TextColor3 = active and P.background or P.text
end
aimPro.changed = function() if alive then repaintAimTouch() end end
connect(aimTouchButton.Activated, function()
    if not state.aimbot then return end
    if aimHeldTouch or aimHeldKey then
        -- Touch OFF also stops GUI/F6 activation (no phantom active mode).
        aimHeldTouch = false
        aimHeldKey = false
    else
        aimHeldTouch = true
    end
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
    TextColor3 = P.accent, TextSize = 10, Font = Enum.Font.Code,
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
    -- The header contains a searchable TextBox and clickable status controls.
    -- Do not start a window drag on top of any of those interactive elements.
    for _, control in ipairs(bar:GetChildren()) do
        if control:IsA("TextBox") or control:IsA("TextButton") then
            if control.Visible then
                local at, size = control.AbsolutePosition, control.AbsoluteSize
                if input.Position.X >= at.X and input.Position.X <= at.X + size.X
                    and input.Position.Y >= at.Y and input.Position.Y <= at.Y + size.Y then
                    return
                end
            end
        end
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
                sliderDrag = nil
                hidePanelAnimation()
                panel.Visible = false
                mini.Visible = true
                boosterPro.riskWarning.show()
            else
                hidePanelAnimation()
                panelScale.Scale = uiBaseScale * 0.98
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
    -- Track meaningful streaming activity only. Unrelated UI/models must not
    -- postpone rescan recovery of earlier dropped graphics indefinitely.
    if not graphicsProperty(obj) then return end
    boosterPro.queueLastAt = os.clock()
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
    if not alive or not state.booster or state.boosterMode == "BALANCED" then return end
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
                    return (state.boosterMode == "BALANCED"
                        or optimizeHierarchy(Workspace, repairRevision))
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
function boosterPro.restoreGraphicsSliced(expectedRevision)
    local started, count = os.clock(), 0
    for obj, snapshot in pairs(savedGraphics) do
        -- Async restore must stop when Booster is re-enabled. Unload/recovery
        -- calls without expectedRevision restore regardless of alive status.
        if expectedRevision and (expectedRevision ~= boosterRevision
            or state.booster or not alive) then return false end
        boosterPro.restoreObject(obj, snapshot)
        count = count + 1
        if count % 4 == 0 and ((os.clock() - started) * 1000 >=
            CONFIG.BoosterSliceMs or count % CONFIG.BoosterBatch == 0) then
            task.wait()
            started = os.clock()
        end
    end
    return next(savedGraphics) == nil
end

-- Failed property restores get a bounded, generation-safe retry while Booster
-- stays OFF. No recurring map scans when graphics are already restored.
function boosterPro.retryPendingGraphics()
    if not alive or state.booster or boosterPro.phase ~= "RESTORE PENDING" then return end
    local noObjects = next(savedGraphics) == nil
    if noObjects and savedTerrainDecoration == nil and savedTerrainColors == nil
        and (savedLighting == nil or state.fullbright) then
        boosterPro.phase = boosterPro.lastError and "FAILED" or "OFF"
        return
    end
    local now = os.clock()
    if noObjects or boosterPro.restoreRetryRunning
        or now < boosterPro.restoreRetryAt then return end
    local revision = boosterRevision
    boosterPro.restoreRetryRunning = true
    boosterPro.restoreRetryAt = now + 15
    task.spawn(function()
        local ok, complete = pcall(boosterPro.restoreGraphicsSliced, revision)
        if revision ~= boosterRevision then return end
        boosterPro.restoreRetryRunning = false
        if not alive or state.booster then return end
        boosterPro.restoreRetryAt = os.clock() + 20
        if not ok then
            boosterPro.lastError = "restore retry: " .. tostring(complete)
            warn("[124 Community Visuals] Booster restore retry: " .. tostring(complete))
        end
        if ok and complete and savedTerrainDecoration == nil
            and savedTerrainColors == nil
            and (savedLighting == nil or state.fullbright) then
            boosterPro.phase = boosterPro.lastError and "FAILED" or "OFF"
        end
    end)
end

cleanup = function(safeStop)
    if not alive then return end
    -- Only explicit Safety Stop stores disabled feature values. Normal unload
    -- leaves the selected CUSTOM profile intact for the next launch.
    if safeStop == true then
        state.aimbot = false
        state.antiAim = false
        state.controlRecoil = false
        state.noRecoil = false
        state.noSpread = false
        state.esp = false
        state.tracers = false
        state.espBox = false
        state.fullbright = false
        state.antiAfk = false
        state.sessionDiagnostics = false
        state.booster = false
        state.cameraFovEnabled = false
        state.speedEnabled = false
        state.noclip = false
        state.fly = false
        CONFIG.PlaceCache.safeBoot = true
        -- Legacy flag consumed once by migration; older versions remain safe.
        if game.PlaceId == CONFIG.OriginalPlaceId then env.ARMY124_SAFE_BOOT = true end
    end
    pcall(flushConfig)
    -- Stop new work *before* any yield, Terrain writes or graphics rollback.
    alive = false
    state.esp = false
    state.aimbot = false
    state.controlRecoil = false
    state.noRecoil, state.noSpread = false, false
    state.antiAim = false
    state.antiAfk = false
    state.booster = false
    state.fullbright = false
    state.cameraFovEnabled = false
    state.speedEnabled, state.noclip, state.fly = false, false, false
    aimHeldKey = false
    captureAimKey = false
    boosterRevision = boosterRevision + 1
    table.clear(boosterPro.protectedRestoreQueue)
    table.clear(boosterPro.protectedRestoreSeen)

    -- Освобождаем личную музыку, затем физику и локальные параметры оружия.
    if boosterPro.privateMusic then pcall(boosterPro.privateMusic.shutdown) end
    if boosterPro.movement then pcall(boosterPro.movement.shutdown) end
    -- A failure in one controller must not prevent unrelated disconnections.
    pcall(releaseAntiAfk)
    pcall(recoil.shutdown)
    pcall(perfCounters.session.setEnabled, false)
    pcall(memoryFX.spin.reset)
    pcall(memoryFX.camera.reset)
    if aimBound then
        pcall(function() RunService:UnbindFromRenderStep(aimBindingName) end)
        aimBound = false
    end
    if recoil.bound then
        pcall(function() RunService:UnbindFromRenderStep(recoil.bindingName) end)
        recoil.bound = false
    end
    if memoryFX.camera.bound then
        pcall(function() RunService:UnbindFromRenderStep(memoryFX.camera.bindingName) end)
        memoryFX.camera.bound = false
    end
    if perfCounters.espVisual.bound then
        pcall(function() RunService:UnbindFromRenderStep(perfCounters.espVisual.bindingName) end)
        perfCounters.espVisual.bound = false
    end
    pcall(boosterPro.stopWatchingPlayers)
    pcall(stopESPWatchers)
    if boosterPro.layoutCameraConnection then
        pcall(function() boosterPro.layoutCameraConnection:Disconnect() end)
        boosterPro.layoutCameraConnection = nil
    end
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)

    -- UI and player overlays are released before slow graphics restoration.
    for player in pairs(renderData) do pcall(deleteRender, player) end
    pcall(clearShapes)
    pcall(hidePanelAnimation)
    pcall(function() gui:Destroy() end)
    pcall(function() if tracerGui then tracerGui:Destroy() end end)
    pcall(function() if shapeGui then shapeGui:Destroy() end end)
    pcall(function() if fovGui then fovGui:Destroy() end end)

    -- Retain snapshots whenever an engine property cannot be restored.
    -- The next launch will execute ARMY124_RECOVERY before loading UI.
    pcall(restoreTerrainGrass)
    pcall(restoreTerrainColors)
    pcall(applyLighting)
    local graphicsOk, graphicsError = pcall(boosterPro.restoreGraphicsSliced)
    if not graphicsOk then
        warn("[124 Community Visuals] Cleanup graphics restore: "
            .. tostring(graphicsError))
    end
    if savedLighting or savedTerrainDecoration or savedTerrainColors
        or next(savedGraphics) ~= nil or next(memoryFX.camera.saved) ~= nil
        or next(memoryFX.spin.pending) ~= nil or recoil.spread.pending() then
        local previousRecovery = env.ARMY124_RECOVERY
        local pendingRecovery
        pendingRecovery = function()
            local oldDone = true
            if type(previousRecovery) == "function" then
                local ok, result = pcall(previousRecovery)
                oldDone = ok and result == true
            end
            local lightingOK = pcall(applyLighting)
            local grassOK = not savedTerrainDecoration or pcall(restoreTerrainGrass)
            local colorsOK = not savedTerrainColors or pcall(restoreTerrainColors)
            local graphicsOK = pcall(boosterPro.restoreGraphicsSliced)
            local cameraOK = pcall(memoryFX.camera.reset)
            local spinOK = pcall(memoryFX.spin.restorePending)
            local spreadOK, spreadRestored = pcall(recoil.restoreSpread)
            local done = lightingOK and grassOK and colorsOK and graphicsOK
                and cameraOK and spinOK and spreadOK and spreadRestored == true
                and not (savedLighting or savedTerrainDecoration or savedTerrainColors)
                and next(savedGraphics) == nil
                and next(memoryFX.camera.saved) == nil
                and next(memoryFX.spin.pending) == nil
                and not recoil.spread.pending()
            if done and oldDone and env.ARMY124_RECOVERY == pendingRecovery then
                env.ARMY124_RECOVERY = nil
            end
            return done and oldDone
        end
        env.ARMY124_RECOVERY = pendingRecovery
        warn("[124 Community Visuals] Graphics/camera/pose rollback incomplete; "
            .. "snapshots retained for another safe attempt")
    end
    if env.ARMY124_CLEANUP == cleanup then env.ARMY124_CLEANUP = nil end
    return true
end

env.ARMY124_CLEANUP = cleanup
-- LogService не подписывается при загрузке: включается только из Memory.
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
        -- Read the current mode before deciding whether this periodic pass
        -- is due. An event-triggered scan may have completed moments ago.
        local tier = visualPerfTier()
        local interval = tier == "ECO" and 0.55 or tier == "QUALITY" and 0.25
            or CONFIG.EspRefreshSeconds
        if state.performanceMode ~= "QUALITY"
            or (state.performanceGuard and perfCounters.guard.level > 0) then
            if state.espRangeMeters >= CONFIG.EspExtremeRangeMeters then
                interval = math.max(interval, CONFIG.EspExtremeScanSeconds)
            elseif state.espRangeMeters >= CONFIG.EspLongRangeMeters then
                interval = math.max(interval, CONFIG.EspLongScanSeconds)
            end
        end
        local needsCleanup = not state.esp and next(renderData) ~= nil
        local due = os.clock() - perfCounters.espVisual.lastScanAt >= interval
        if needsCleanup or (state.esp and due) then
            local ok, err = pcall(perfCounters.cpu.wrapped.ESPScan)
            if not ok then warn("[124 Community Visuals] ESP: " .. tostring(err)) end
        end
        task.wait(interval)
    end
end)

-- Smooth ESP v1.0.5: экранные рамки/кости/линии обновляются синхронно с
-- камерой (без интервала 0.08–0.25 с). Частота равна реальным кадрам игры;
-- новых игроков по-прежнему отбирает медленный refreshESP(), не рендер-цикл.
local espVisualElapsed = 0
perfCounters.espVisual.frame = function(dt)
    if not alive or not state.esp then espVisualElapsed = 0; return end
    if not state.tracers and not state.espBox then
        espVisualElapsed = 0
        return
    end
    -- AIM/Recoil идут каждый кадр. Только тяжёлые ESP GUI-примитивы
    -- обновляем с отдельным пределом кадров при AUTO/ECO.
    if type(dt) == "number" and dt > 0 then
        local tier = visualPerfTier()
        local hz = tier == "ECO" and CONFIG.EspVisualEcoHz
            or tier == "QUALITY" and 60 or CONFIG.EspVisualBalancedHz
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
        -- При большом радиусе снижаем частоту только 2D Box/Tracer.
        -- Ручной QUALITY сохраняет прежний максимум, пока Guard не включён.
        if state.performanceMode ~= "QUALITY"
            or (state.performanceGuard and perfCounters.guard.level > 0) then
            if state.espRangeMeters >= CONFIG.EspExtremeRangeMeters then
                hz = math.min(hz, CONFIG.EspExtremeVisualHz)
            elseif state.espRangeMeters >= CONFIG.EspLongRangeMeters then
                hz = math.min(hz, CONFIG.EspLongVisualHz)
            end
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
    if state.espBox then
        -- Allocation quotas reset only in this rate-limited draw callback.
        shapeNewContainersLeft = CONFIG.ShapeNewContainersPerDraw
        shapeNewLinesLeft = CONFIG.ShapeNewLinesPerDraw
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
    perfCounters.frametime.observe(dt) -- O(1); статистика вычисляется только в Memory.
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
        -- Повторяем неудачный откат No Spread только при наличии снимков.
        -- Это уже существующий редкий HUD-цикл, нового worker не создаём.
        if not state.noSpread and recoil.spread.pending() then
            pcall(recoil.restoreSpread)
        end
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
            -- NotScriptable Terrain setters can fail repeatedly in some clients.
            -- Retry only after backoff instead of hammering up to 20 materials
            -- every HUD refresh (a source of off-state microstutters).
            local now = os.clock()
            if now >= boosterPro.terrainRestoreRetryAt then
                local grassOk = not savedTerrainDecoration or restoreTerrainGrass()
                local colorsOk = not savedTerrainColors or restoreTerrainColors()
                boosterPro.terrainRestoreRetryAt =
                    now + ((grassOk and colorsOk) and 1.5 or 12)
            end
        end
        if not state.booster then boosterPro.retryPendingGraphics() end
        stats.Visible = state.hud
        if boosterPro.dashboard then boosterPro.dashboard.update() end
        if referenceESP and referenceESP.tick then referenceESP.tick() end
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
        if panel.Visible and pages.MEMORY.Visible and perfCounters.guard.label then
            local label = perfCounters.guard.description()
            if perfCounters.guard.label.Text ~= label then
                perfCounters.guard.label.Text = label
            end
        end
        if state.hud or state.activeHud or pages.MEMORY.Visible then
            local display = string.format("FPS %d | ESP %d | Shape %d | Scan %.1f ms | %s",
                measuredFps, perfCounters.espCount, perfCounters.shapeCount,
                perfCounters.aimScanMs, perfTier())
            if perfLabel.Text ~= display then perfLabel.Text = display end
        end
        -- O(N log N) percentile work only when the PERFORMANCE page is visible,
        -- and no more than once every three seconds. Never in RenderStepped.
        if panel.Visible and pages.MEMORY.Visible
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
            if state.noRecoil then table.insert(features, "NO-RECOIL") end
            if state.noSpread then table.insert(features, "NO-SPREAD") end
            if state.antiAim then table.insert(features, "SPIN") end
            if state.speedEnabled then table.insert(features, "SPEED") end
            if state.noclip then table.insert(features, "NOCLIP") end
            if state.fly then table.insert(features, "FLY") end
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
        if hudStart then
            perfCounters.cpu.record("HUD", (os.clock() - hudStart) * 1000)
        end
        task.wait((state.hud or state.activeHud) and 1.0 or 1.5)
    end
end)

-- Применяем профиль после создания всей GUI и привязок.
if not loadCustomSettings() then
    error("Профиль не был загружен полностью")
end
refreshFovRing()
print("[124 Community Visuals] " .. CONFIG.Version .. " загружен | MISC / MEMORY")
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
    -- A script that executed all callbacks but lost its GUI is not ready.
    -- Do not leave render hooks or graphics changes running invisibly.
    local registered = env.ARMY124_CLEANUP
    local cleanupOk, cleaned = pcall(function()
        if type(registered) == "function" then return registered() end
        return abortPartialHub()
    end)
    if not cleanupOk or cleaned == false then pcall(abortPartialHub) end
    bootFailure("GUI MISSING", "UI завершилась, но ScreenGui отсутствует.")
else
    env.ARMY124_BOOT_PHASE = "ready"
    env.ARMY124_BOOT_ERROR = nil
    pcall(function()
        local old = PlayerGui:FindFirstChild("Army124StartupError")
        if old then old:Destroy() end
    end)
end
