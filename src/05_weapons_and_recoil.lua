local recoil = (function()
local controller = {
    bound = false, shots = 0, correctionFrames = 0,
    lastRecoilStatus = "ожидание", lastShotAt = 0,
    inputSignals = {tool = 0, mouse = 0, touch = 0, gamepad = 0},
    bindingName = "Army124CommunityRecoil_" .. tostring(LocalPlayer.UserId),
}
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
    discoveryList = nil, discoveryIndex = 1, nextDiscoveryAt = 0,
    stats = {writes = 0, checks = 0, errors = 0,
        restoreFailures = 0, lastError = "", lastAppliedAt = 0},
}
-- Базу отката обновляем при каждом новом значении от оружейного скрипта.
local function rememberSpreadBaseline(instance, name, value)
    local originals = controller.spread.originals
    local saved = originals[instance]
    if not saved then saved = {attributes = {}}; originals[instance] = saved end
    if name then saved.attributes[name] = value else saved.value = value end
end
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
    spread.discoveryList = nil
    spread.discoveryIndex = 1
    spread.nextDiscoveryAt = 0
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
local safeApplySpread
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
            safeApplySpread()
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
    if allRestored then
        controller.spread.modified = 0
    else
        controller.spread.stats.restoreFailures = controller.spread.stats.restoreFailures + 1
    end
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
        spread.nextDiscoveryAt = os.clock() + CONFIG.SpreadDiscoverySeconds
    elseif spread.discoveryList == nil and os.clock() >= spread.nextDiscoveryAt then
        -- Атрибут Spread может появиться у уже существующего объекта:
        -- обходим постепенно, не делаем полный GetAttributes в одном кадре.
        local ok, items = pcall(function() return tool:GetDescendants() end)
        spread.nextDiscoveryAt = os.clock() + CONFIG.SpreadDiscoverySeconds
        if ok then
            spread.discoveryList = items
            spread.discoveryIndex = 1
        end
    end
    if spread.discoveryList then
        local items = spread.discoveryList
        local last = math.min(#items,
            spread.discoveryIndex + CONFIG.SpreadDiscoveryBatch - 1)
        for i = spread.discoveryIndex, last do
            local obj = items[i]
            if obj and obj.Parent and not spread.candidateSet[obj] then
                registerSpreadCandidate(obj)
            end
        end
        spread.discoveryIndex = last + 1
        if spread.discoveryIndex > #items then
            spread.discoveryList = nil
            spread.discoveryIndex = 1
        end
    end
    local changed = 0
    local function patch(instance)
        if (instance:IsA("NumberValue") or instance:IsA("IntValue"))
            and isSpreadParameter(instance.Name) then
            local value = instance.Value
            if value > 0 and value < CONFIG.SpreadMaxWritableValue then
                rememberSpreadBaseline(instance, nil, value)
                instance.Value = 0
                if instance.Value ~= 0 then error("No Spread: запись Value не удержалась") end
                changed = changed + 1
            end
        end
        -- Атрибуты отслеживаем только у Tool и конфигурационных контейнеров,
        -- чтобы не обходить избыточные Attributes каждой геометрической детали.
        if spread.candidateSet[instance] then
            for name, value in pairs(instance:GetAttributes()) do
                if isSpreadParameter(name) and type(value) == "number"
                    and value > 0 and value < CONFIG.SpreadMaxWritableValue then
                    rememberSpreadBaseline(instance, name, value)
                    instance:SetAttribute(name, 0)
                    if instance:GetAttribute(name) ~= 0 then
                        error("No Spread: запись Attribute не удержалась")
                    end
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
    spread.stats.checks = spread.stats.checks + 1
    spread.stats.writes = spread.stats.writes + changed
    spread.stats.lastAppliedAt = os.clock()
    if errors > 0 then
        spread.stats.errors = spread.stats.errors + errors
        spread.stats.lastError = tostring(firstError)
        if os.clock() - spread.lastErrorAt >= CONFIG.SpreadErrorLogSeconds then
            spread.lastErrorAt = os.clock()
            warn("[124 Visuals] No Spread local: " .. tostring(firstError)
                .. " | failures=" .. tostring(errors))
        end
    end
    controller.spread.modified = controller.spread.modified + changed
    return changed
end

-- Ошибка API не должна прерывать кадр или уничтожать диагностическую статистику.
safeApplySpread = function()
    local ok, result = pcall(controller.applySpread)
    if not ok then
        local spread = controller.spread
        spread.stats.errors = spread.stats.errors + 1
        spread.stats.lastError = tostring(result)
        return 0
    end
    return result
end
controller.safeApplySpread = safeApplySpread

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

local function markRecoilShot(source)
    if not alive or not recoilTool then return end
    source = type(source) == "string" and source or "tool"
    controller.inputSignals[source] = (controller.inputSignals[source] or 0) + 1
    local now = os.clock()
    -- Отложенная проверка после того, как оружие обновило локальные параметры.
    if state.noSpread and now >= controller.spread.nextCheckAt then
        controller.spread.nextCheckAt = now + CONFIG.SpreadShotRecheckSeconds
        local firedTool = recoilTool
        local generation = controller.spread.generation
        task.delay(CONFIG.SpreadPostShotSeconds, function()
            if alive and state.noSpread and recoilTool == firedTool
                and controller.spread.generation == generation then
                safeApplySpread()
            end
        end)
    end
    -- Считаем входные пульсы независимо от No Recoil (режим No Spread-only).
    if now - recoilLastPulseAt >= CONFIG.RecoilInputDedupSeconds then
        controller.shots = controller.shots + 1
        controller.lastShotAt = now
        recoilLastPulseAt = now
    end
    if not (state.controlRecoil or state.noRecoil) then return end
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
        markRecoilShot(kind == Enum.UserInputType.Touch and "touch"
            or kind == Enum.UserInputType.MouseButton1 and "mouse" or "gamepad")
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
        if state.noSpread then safeApplySpread() end
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
                if not ok or not stillInside then
                    -- При удалении контейнера очищаем подписки его потомков.
                    local candidates = controller.spread.candidates
                    for i = #candidates, 1, -1 do
                        local candidate = candidates[i]
                        local insideOK, inside = pcall(function()
                            return candidate:IsDescendantOf(tool)
                        end)
                        if candidate ~= tool and (not insideOK or not inside) then
                            unregisterSpreadCandidate(candidate)
                        end
                    end
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
        -- При удалении активного Tool сразу подхватываем другой оставшийся.
        if child == recoilTool then
            equipRecoilTool(character:FindFirstChildOfClass("Tool"))
        end
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
            safeApplySpread()
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
        controller.lastRecoilStatus = recoilTool and "режим выключен" or "Tool не экипирован"
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        recoilLastCamera, recoilLastPitch = nil, nil
        controller.lastRecoilStatus = "нет камеры"
        return
    end
    local currentPitch = camera.CFrame:ToOrientation()
    local previousPitch = recoilLastPitch
    local sameCamera = recoilLastCamera == camera
    recoilLastCamera = camera
    recoilLastPitch = currentPitch
    recoilLastCorrection = 0
    if not sameCamera or previousPitch == nil then
        controller.lastRecoilStatus = "первый кадр камеры"
        return
    end
    if isRobloxMenuOpen() or UserInputService:GetFocusedTextBox() ~= nil then
        controller.lastRecoilStatus = "интерфейс в фокусе"
        return
    end
    -- AIM owns the camera during active aiming, even when the target was
    -- just lost. Avoid alternating camera writers on intermittent LOS loss.
    if state.aimbot and (aimHeldMouse or aimHeldTouch or aimHeldKey) then
        controller.lastRecoilStatus = "камера управляется AIM"
        return
    end
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
    if not firing then
        controller.lastRecoilStatus = "нет подтверждения стрельбы"
        return
    end
    if dt <= 0 or dt > CONFIG.RecoilMaxFrameSeconds then
        controller.lastRecoilStatus = "пропуск после задержки кадра"
        return
    end
    local pitchUp = signedAngle(previousPitch, currentPitch)
    if pitchUp < math.rad(CONFIG.RecoilMinPitchDegrees)
        or pitchUp > math.rad(CONFIG.RecoilMaxPitchDegrees) then
        controller.lastRecoilStatus = "подброс не распознан"
        return
    end
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
    controller.correctionFrames = controller.correctionFrames + 1
    controller.lastRecoilStatus = "локальная коррекция камеры"
end

-- END RECOIL CONTROL / WEAPONS 2.0
controller.reset = resetRecoilTracking
controller.shutdown = shutdownRecoilControl
controller.frame = recoilFrame
controller.inspect = function()
    return recoilTool and recoilTool.Name or "нет Tool",
        controller.shots, recoilLastCorrection
end
-- Подробный анализ вызывается по кнопке; в RenderStep не сканируем атрибуты.
controller.diagnostics = function()
    local spread = controller.spread
    local tool = recoilTool
    local d = {
        tool = tool and tool.Name or "нет Tool",
        equipped = tool ~= nil and tool.Parent == LocalPlayer.Character,
        recoilMode = state.noRecoil and "No Recoil"
            or state.controlRecoil and "Control Recoil" or "OFF",
        recoilStatus = controller.lastRecoilStatus,
        recoilCorrections = controller.correctionFrames,
        lastCorrectionDegrees = recoilLastCorrection,
        inputSignals = table.clone(controller.inputSignals),
        shotPulses = controller.shots,
        spreadEnabled = state.noSpread,
        numericParameters = 0, attributeParameters = 0,
        candidates = #spread.candidates,
        writes = spread.stats.writes, checks = spread.stats.checks,
        errors = spread.stats.errors,
        restoreFailures = spread.stats.restoreFailures,
        lastError = spread.stats.lastError,
        pendingRestore = spread.pending(),
    }
    if d.equipped then
        for _, instance in ipairs(spread.candidates) do
            pcall(function()
                if instance == tool or instance:IsDescendantOf(tool) then
                    if (instance:IsA("NumberValue") or instance:IsA("IntValue"))
                        and isSpreadParameter(instance.Name) then
                        d.numericParameters = d.numericParameters + 1
                    end
                    for name, value in pairs(instance:GetAttributes()) do
                        if isSpreadParameter(name) and type(value) == "number" then
                            d.attributeParameters = d.attributeParameters + 1
                        end
                    end
                end
            end)
        end
    end
    d.spreadStatus = not d.equipped and "Tool не экипирован"
        or not d.spreadEnabled and "функция выключена"
        or (d.numericParameters + d.attributeParameters == 0)
            and "совместимые клиентские параметры не обнаружены"
        or "параметры найдены; влияние на траекторию не подтверждено"
    return d
end
return controller
end)()

