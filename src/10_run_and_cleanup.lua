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
    if not alive or not state.esp then
        espVisualElapsed = 0
        perfCounters.espVisual.motionCamera = nil
        perfCounters.espVisual.motionFrame = nil
        return
    end
    -- Когда Tracer и Box выключены, не читаем CFrame камеры каждый кадр.
    if not state.tracers and not state.espBox then
        espVisualElapsed = 0
        perfCounters.espVisual.motionCamera = nil
        perfCounters.espVisual.motionFrame = nil
        return
    end
    -- Считываем камеру после её штатного обновления, AIM и Recoil.
    local motion = perfCounters.espVisual
    local camera = Workspace.CurrentCamera
    if camera then
        local current = camera.CFrame
        local old = motion.motionFrame
        if old and motion.motionCamera == camera
            and (old.LookVector:Dot(current.LookVector) < CONFIG.EspCameraMotionDot
            or (old.Position - current.Position).Magnitude > CONFIG.EspCameraMotionStuds) then
            motion.motionUntil = os.clock() + CONFIG.EspCameraMotionHoldSeconds
        end
        motion.motionCamera, motion.motionFrame = camera, current
    else
        motion.motionCamera, motion.motionFrame = nil, nil
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
        -- Ускоряем 2D проекцию только при движении камеры и свободном FPS.
        if tier ~= "ECO" and (not state.performanceGuard
            or perfCounters.guard.level == 0)
            and measuredFps >= CONFIG.EspCameraMotionMinFps
            and os.clock() < motion.motionUntil then
            hz = math.max(hz, CONFIG.EspCameraMotionVisualHz)
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
        -- Reuse the existing HUD worker to retry Movement recovery,
        -- never a new render or physics loop.
        if boosterPro.movement and not state.speedEnabled and not state.noclip
            and boosterPro.movement.pending() then
            pcall(boosterPro.movement.retryPending)
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

if env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then return CONFIG.BootToken end
env.ARMY124_BOOT_PHASE = "initializing-ui"
local initOk, initErr = xpcall(initializeHubUI, function(err)
    local msg = tostring(err)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        local ok, trace = pcall(debug.traceback, msg, 2)
        if ok and type(trace) == "string" then return trace end
    end
    return msg
end)
if env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then return CONFIG.BootToken end
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
    if env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then return CONFIG.BootToken end
    env.ARMY124_BOOT_PHASE = "ready"
    env.ARMY124_BOOT_ERROR = nil
    pcall(function()
        local old = PlayerGui:FindFirstChild("Army124StartupError")
        if old then old:Destroy() end
    end)
end
-- Даже при ошибке/отказе Start.lua проверяет, чей это результат.
return CONFIG.BootToken
