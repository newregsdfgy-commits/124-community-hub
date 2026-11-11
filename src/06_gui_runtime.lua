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
    state.playerAuraEnabled, state.playerGlowEnabled = false, false
    state.playerWeatherEnabled, state.playerEnvironmentEnabled = false, false
    -- No scene-owned FX can survive an abort during UI initialization.
    pcall(playerFX.shutdown)
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
        local weatherOk, weatherRestored = pcall(playerFX.restoreWeather)
        local uiOk, uiRestored = pcall(emergencyUIRollback)
        return graphicsOk and graphicsRestored == true
            and weatherOk and weatherRestored == true and not playerFX.pending()
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
    "playerAuraEnabled", "playerGlowEnabled", "playerAuraColor", "playerGlowPower",
    "playerWeatherEnabled", "playerWeatherMode",
    "playerEnvironmentEnabled", "playerEnvironmentColor", "playerEnvironmentStrength",
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
    playerGlowPower = {1, 5}, playerEnvironmentStrength = {0, 100},
}
local textRules = {
    aimMode = {head = true, body = true, legs = true},
    espColorPreset = {TEAM = true, GOLD = true, GREEN = true, WHITE = true},
    performanceMode = {AUTO = true, ECO = true, QUALITY = true},
    boosterMode = {BALANCED = true, WHITE = true, ULTRA = true},
    playerAuraColor = {PURPLE = true, CYAN = true, GOLD = true, GREEN = true},
    playerWeatherMode = {CLEAR = true, FOG = true, RAIN = true, NIGHT = true},
    playerEnvironmentColor = {VIOLET = true, CYAN = true, WARM = true, GREEN = true},
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
        -- Player visuals may retain a color preset, but must be enabled manually.
        state.playerAuraEnabled = false
        state.playerGlowEnabled = false
        state.playerWeatherEnabled = false
        state.playerEnvironmentEnabled = false
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
            state.playerAuraEnabled = false
            state.playerGlowEnabled = false
            state.playerWeatherEnabled = false
            state.playerEnvironmentEnabled = false
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
    if playerFX then playerFX.sync() end
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
    background = Color3.fromRGB(14, 12, 26),
    panel = Color3.fromRGB(23, 18, 39),
    tile = Color3.fromRGB(36, 28, 57),
    border = Color3.fromRGB(108, 72, 157),
    text = Color3.fromRGB(249, 245, 255),
    dim = Color3.fromRGB(195, 178, 220),
    accent = Color3.fromRGB(189, 139, 255),
    off = Color3.fromRGB(68, 55, 91),
}
-- На телефоне даже альбомный экран остаётся одноколоночным: элементы
-- управления не должны уменьшаться до нечитабельного размера.
local function isReferenceLandscape(view)
    -- Avoid shrinking tap targets on short landscape touch displays.
    return UserInputService.TouchEnabled and view.X >= 960
        and view.Y >= 540 and view.X >= view.Y * 1.35
end
-- Mobile landscape uses the same full reference layout, with a single
-- uniform scale. Portrait and undersized desktop keep readable legacy lists.
local wideLayout = isReferenceLandscape(uiSafeView(viewport))
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
    local preferredWidth = wide and 950 or (mobile and landscape and 610 or 460)
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
mk("UIStroke", {Color = P.accent, Transparency = 0.24, Thickness = 1.5}, panel)
mk("UIGradient", {Rotation = 110,
    Color = ColorSequence.new(Color3.fromRGB(22, 17, 41),
        Color3.fromRGB(11, 10, 23))}, panel)
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
    Text = "124 VISUALS", TextColor3 = P.text, TextSize = 19,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, bar)
mk("TextLabel", {
    Name = "BrandCaption", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(21, 39), Size = UDim2.new(1, -183, 0, 16),
    Text = "PURPLE NEON 2.0  •  v" .. CONFIG.Version,
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
    Name = "Minimize", Position = UDim2.new(1, -100, 0, 17),
    Size = UDim2.fromOffset(42, 42), BackgroundColor3 = P.tile,
    Text = "—", TextColor3 = P.dim, TextSize = 16,
    Font = Enum.Font.GothamMedium, AutoButtonColor = true,
}, bar)
round(hide, 6)
local close = mk("TextButton", {
    Name = "CloseHub", Position = UDim2.new(1, -51, 0, 17),
    Size = UDim2.fromOffset(42, 42), BackgroundColor3 = P.tile,
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
    Position = UDim2.fromOffset(0, 76), Size = UDim2.new(0, 196, 1, -76),
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
local navSlots = mk("ScrollingFrame", {
    Name = "NavigationSlots", BackgroundTransparency = 1, BorderSizePixel = 0,
    Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 1, -190),
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 2, ScrollBarImageColor3 = P.accent,
    Active = true, ClipsDescendants = true,
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
local scrollFrames = {navSlots}
local touchGestures = setmetatable({}, {__mode = "k"})
local suppressTapUntil = 0
connect(navSlots:GetPropertyChangedSignal("CanvasPosition"), function()
    if UserInputService.TouchEnabled then
        suppressTapUntil = os.clock() + 0.24
    end
end)
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
    {key = "AIM", label = "Aim", symbol = "⌖"},
    {key = "PLAYER", label = "Player", symbol = "✦"},
    {key = "MISC", label = "Misc", symbol = "⚙"},
    {key = "MEMORY", label = "Memory", symbol = "▦"},
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
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 9),
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
    ["PLAYER AURA"] = "left", ["PLAYER GLOW"] = "right",
    ["LOCAL WEATHER"] = "left", ["ENVIRONMENT COLOR"] = "right",
    
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
local sliderDrag = nil -- Cancel an active thumb gesture when viewport changes.
local function applyResponsiveLayout()
    sliderDrag = nil
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
    -- Compact touch sidebar: prioritize readable content and actual tap areas.
    -- No global scale on small phones; navigation remains scrollable.
    local sidebarWidth = wide and 196 or (width < 340 and 68 or width < 430 and 78 or 94)
    local contentX = sidebarWidth + (wide and 11 or 9)
    local contentRight = wide and 13 or 9
    contentPlate.Position = UDim2.fromOffset(contentX, 81)
    contentPlate.Size = UDim2.new(1, -contentX - contentRight, 1, wide and -121 or -120)
    -- On very short displays, keep the footer outside the scrollable content.
    contentPlate.ClipsDescendants = true
    pageHeader.Visible, pageSubHeader.Visible = wide, wide
    -- Единая шапка 76px не перекрывается навигацией.
    local sidebarHeader = 76
    local compactShort = not wide and height < 320
    local navTop = wide and 20 or (compactShort and 5 or 11)
    local bottomReserve = wide and 90 or (height < 300 and 9 or 53)
    local buttonHeight = wide and 55 or 44 -- Scroll navigation, never shrink touch targets.
    tabs.Position = UDim2.fromOffset(0, sidebarHeader)
    tabs.Size = UDim2.new(0, sidebarWidth, 1, -sidebarHeader)
    navSlots.Position = UDim2.fromOffset(0, navTop)
    navSlots.Size = UDim2.new(1, 0, 0,
        math.max(0, height - sidebarHeader - navTop - bottomReserve))
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
            button.TextSize = compactShort and 9 or 11
            button.TextXAlignment = Enum.TextXAlignment.Center
        end
        tabUnderline[nav.key].Position = UDim2.fromOffset(0, 5)
        tabUnderline[nav.key].Size = UDim2.new(0, 3, 1, -10)
    end
    for _, page in pairs(pages) do
        if wide then
            page.Position = UDim2.fromOffset(contentX, 81)
            page.Size = UDim2.new(1, -contentX - contentRight, 1, -121)
        else
            page.Position = UDim2.fromOffset(contentX, 81)
            page.Size = UDim2.new(1, -contentX - contentRight, 1, -120)
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
        boosterPro.uiFooter.Position = UDim2.new(0, contentX, 1, -29)
        boosterPro.uiFooter.Size = UDim2.new(1, -contentX - contentRight, 0, 22)
    end
    local brandTitle = bar:FindFirstChild("BrandTitle")
    local brandCaption = bar:FindFirstChild("BrandCaption")
    if brandTitle then
        brandTitle.Size = wide and UDim2.fromOffset(168, 21) or UDim2.new(1, -130, 0, 21)
        brandTitle.TextSize = 15
    end
    if brandCaption then
        brandCaption.Size = wide and UDim2.fromOffset(169, 16) or UDim2.new(1, -130, 0, 16)
    end
end

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
        MISC = "Misc", MEMORY = "Memory"}
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
        tabButtons[name].BackgroundColor3 = selected and Color3.fromRGB(96, 52, 153)
            or Color3.fromRGB(31, 25, 48)
        tabButtons[name].TextColor3 = selected and P.text or P.dim
        tabButtons[name].Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium
        tabUnderline[name].Visible = selected
        tabOutlines[name].Transparency = selected and 0.02 or 0.87
    end
end
for name, button in pairs(tabButtons) do
    safeActivate(button, function() showPage(name) end)
end
boosterPro.dashboard.openSettings = function() showPage("MEMORY") end
applyResponsiveLayout()
showPage("ESP")
-- On-demand layout audit; no RenderStepped loops or geometry mutation.
boosterPro.uiAudit = function()
    local camera = Workspace.CurrentCamera
    local raw = camera and camera.ViewportSize or viewport
    local buttons = 0
    local minHeight = math.huge
    for _, nav in ipairs(navigation) do
        if not nav.hidden then
            local button = tabButtons[nav.key]
            if button and button.Parent and button.Visible then
                buttons = buttons + 1
                minHeight = math.min(minHeight, button.AbsoluteSize.Y)
            end
        end
    end
    local checks = {
        {"панель", panel.Parent ~= nil and panel.AbsoluteSize.X >= 150
            and panel.AbsoluteSize.Y >= 110},
        {"область настроек", contentPlate.AbsoluteSize.X >= 140
            and contentPlate.AbsoluteSize.Y >= 20},
        {"левая навигация", tabs.AbsoluteSize.X >= 60
            and navSlots.AbsoluteSize.Y >= 15},
        {"разделы ESP/Aim/Misc/Memory", buttons == 4},
        {"размер кнопок", minHeight >= 38},
        {"кнопки закрытия/сворачивания", close.AbsoluteSize.X >= 38
            and hide.AbsoluteSize.X >= 38},
        {"активная страница", pages[currentPage] ~= nil
            and pages[currentPage].Visible},
    }
    local failures, passed = {}, 0
    for _, entry in ipairs(checks) do
        if entry[2] then passed = passed + 1
        else failures[#failures + 1] = entry[1] end
    end
    return string.format("UI 2.0 %d/%d | экран %dx%d | меню %dx%d"
            .. " | контент %dpx | навигация %dpx | %s",
        passed, #checks, raw.X, raw.Y,
        panel.AbsoluteSize.X, panel.AbsoluteSize.Y,
        contentPlate.AbsoluteSize.X, navSlots.AbsoluteSize.X,
        #failures == 0 and "OK" or ("ПРОВЕРИТЬ: " .. table.concat(failures, ", ")))
end
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

