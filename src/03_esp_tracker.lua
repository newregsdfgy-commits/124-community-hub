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
    local configured = math.clamp(math.floor(state.espMaxTargets or CONFIG.EspMaxPlayers), 8, 96)
    -- Guard is opt-in. Restrict expensive visible GUI while retaining the
    -- user's saved target limit for automatic recovery.
    if state.performanceGuard then
        if perfCounters.guard.level == 2 then
            return math.min(configured, CONFIG.GuardEspMaxL2)
        elseif perfCounters.guard.level == 1 then
            return math.min(configured, CONFIG.GuardEspMaxL1)
        end
    end
    return configured
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

-- Compact Tactical ESP: сжатый HUD с автоматическим облегчением дальних меток.
-- Все функции ESP сохраняются; отключается только лишний текст на дистанции.
local function compactEspFlags(meters, namesEnabled, healthEnabled, distanceEnabled)
    -- Distances are independent, saved to CUSTOM and still limited by master ESP.
    -- Keep feature toggles as the single source of enabled/disabled state.
    return namesEnabled and meters <= state.espNameMaxMeters,
        healthEnabled and meters <= state.espHealthMaxMeters,
        distanceEnabled and meters <= state.espDistanceMaxMeters
end
local function createRender(player, character, head)
    local hl = mk("Highlight", {
        Name = "Army124ESPHighlight",
        Adornee = character,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        FillTransparency = CONFIG.EspFillTransparency,
        OutlineTransparency = CONFIG.EspOutlineTransparency,
    }, character)
    -- Публикуем запись до следующих Instance.new: частичный GUI можно убрать.
    local item = {character = character, highlight = hl, inactiveSince = nil}
    renderData[player] = item
    local bb = mk("BillboardGui", {
        Name = "Army124ESPLabel",
        Adornee = head,
        AlwaysOnTop = true, LightInfluence = 0,
        MaxDistance = 0, -- Радиус по-прежнему рассчитывается от LocalPlayer.
        Size = UDim2.fromOffset(CONFIG.EspLabelWidth, CONFIG.EspLabelHeight),
        StudsOffsetWorldSpace = Vector3.new(0, 1.95, 0),
        ResetOnSpawn = false,
    }, PlayerGui)
    item.billboard = bb

    local identity = mk("Frame", {
        Name = "Army124ESPIdentity", Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.fromRGB(17, 20, 32),
        BackgroundTransparency = 0.28, BorderSizePixel = 0,
    }, bb)
    mk("UICorner", {CornerRadius = UDim.new(0, 4)}, identity)
    local identityBorder = mk("UIStroke", {
        Color = CONFIG.Neutral, Transparency = 0.52, Thickness = 1,
    }, identity)
    local identityRail = mk("Frame", {
        Name = "TeamAccent", Position = UDim2.fromOffset(5, 3),
        Size = UDim2.fromOffset(2, 10), BackgroundColor3 = CONFIG.Neutral,
        BorderSizePixel = 0,
    }, identity)
    mk("UICorner", {CornerRadius = UDim.new(0, 2)}, identityRail)
    local nameLabel = mk("TextLabel", {
        Name = "EspName", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -14, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = CONFIG.EspNameSizeNear,
        TextScaled = false, TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamBold,
        TextStrokeTransparency = 0.87,
        TextColor3 = Color3.fromRGB(245, 246, 253), Text = "",
    }, identity)

    local healthChip = mk("Frame", {
        Name = "Army124ESPHealthBadge",
        Position = UDim2.fromOffset(0, 18),
        Size = UDim2.new(0.5, -2, 0, 11),
        BackgroundColor3 = Color3.fromRGB(18, 23, 31),
        BackgroundTransparency = 0.38, BorderSizePixel = 0,
    }, bb)
    mk("UICorner", {CornerRadius = UDim.new(0, 3)}, healthChip)
    local healthLabel = mk("TextLabel", {
        Name = "EspHealth", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(4, -1), Size = UDim2.new(1, -8, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = CONFIG.EspMetaSizeNear, TextScaled = false,
        TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamMedium, TextStrokeTransparency = 0.87,
        TextColor3 = Color3.fromRGB(100, 220, 157), Text = "",
    }, healthChip)
    local healthTrack = mk("Frame", {
        Name = "HpTrack", Position = UDim2.new(0, 4, 1, -2),
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundColor3 = Color3.fromRGB(61, 69, 77),
        BorderSizePixel = 0,
    }, healthChip)
    local healthFill = mk("Frame", {
        Name = "HpFill", Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(100, 220, 157),
        BorderSizePixel = 0,
    }, healthTrack)

    local distanceChip = mk("Frame", {
        Name = "Army124ESPDistanceBadge",
        Position = UDim2.new(0.5, 2, 0, 18),
        Size = UDim2.new(0.5, -2, 0, 11),
        BackgroundColor3 = Color3.fromRGB(18, 23, 31),
        BackgroundTransparency = 0.38, BorderSizePixel = 0,
    }, bb)
    mk("UICorner", {CornerRadius = UDim.new(0, 3)}, distanceChip)
    local distanceLabel = mk("TextLabel", {
        Name = "EspDistance", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(4, -1),
        Size = UDim2.new(1, -8, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextSize = CONFIG.EspMetaSizeNear, TextScaled = false,
        TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamMedium, TextStrokeTransparency = 0.87,
        TextColor3 = Color3.fromRGB(220, 224, 235), Text = "",
    }, distanceChip)
    item.nameChip, item.identityBorder, item.identityRail = identity, identityBorder, identityRail
    item.healthChip, item.healthFill, item.distanceChip = healthChip, healthFill, distanceChip
    item.nameLabel, item.healthLabel, item.distanceLabel =
        nameLabel, healthLabel, distanceLabel
    return item
end

local function setIfDifferent(instance, property, value)
    if instance[property] ~= value then instance[property] = value end
end

local function updatePlayer(player, myRoot, allowCreate)
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
        or not isLive(item.billboard) or not isLive(item.nameChip)
        or not isLive(item.healthFill) or not isLive(item.distanceLabel)) then
        deleteRender(player)
        item = nil
    end
    local created = false
    if not item then
        if not allowCreate then return false end
        item = createRender(player, character, head)
        created = true
    end
    -- Кешируем части, которые рендерятся чаще, чем обновляется список игроков.
    item.head, item.root, item.humanoid = head, root, hum
    local strokeAlpha = referenceStrokeEnabled and 0.80 or 1
    setIfDifferent(item.nameLabel, "TextStrokeTransparency", strokeAlpha)
    setIfDifferent(item.healthLabel, "TextStrokeTransparency", strokeAlpha)
    setIfDifferent(item.distanceLabel, "TextStrokeTransparency", strokeAlpha)
    setIfDifferent(item.billboard, "Adornee", head) -- Upgrade torso → Head after streaming.
    -- Переключение кэша, смена команды/ника/опций должны перерисовать текст
    -- сразу; throttling применяется только к неизменившимся дальним меткам.
    local wasInactive = item.inactiveSince ~= nil
    item.inactiveSince = nil
    setIfDifferent(item.highlight, "Enabled", true)
    local offset = myRoot and (root.Position - myRoot.Position)
    local distanceSquared = offset and offset:Dot(offset) or 0
    local meters = math.floor(math.sqrt(distanceSquared) * CONFIG.StudMeters + 0.5)
    local showName, showHealth, showDistance =
        compactEspFlags(meters, state.names, state.health, state.distance)
    local visibilityMask = (showName and 1 or 0) + (showHealth and 2 or 0)
        + (showDistance and 4 or 0)
    -- A range threshold can change even while far-text refresh is throttled.
    setIfDifferent(item.billboard, "Enabled", visibilityMask ~= 0)
    local farThresholdStuds = CONFIG.EspLongRangeMeters / CONFIG.StudMeters
    local now = os.clock()
    local changedSettings = wasInactive
        or item.lastCompactVisibility ~= visibilityMask
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
    local near = meters < CONFIG.EspMidDistanceMeters
    local far = meters >= CONFIG.EspFarDistanceMeters
    local nameSize = far and CONFIG.EspNameSizeFar
        or not near and CONFIG.EspNameSizeMid or CONFIG.EspNameSizeNear
    local metaSize = near and CONFIG.EspMetaSizeNear or CONFIG.EspMetaSizeFar
    setIfDifferent(item.highlight, "FillColor", color)
    setIfDifferent(item.highlight, "OutlineColor", color)
    setIfDifferent(item.identityBorder, "Color", color)
    setIfDifferent(item.identityRail, "BackgroundColor3", color)
    setIfDifferent(item.nameLabel, "Text", showName and player.DisplayName or "")
    setIfDifferent(item.nameLabel, "TextSize", nameSize)
    setIfDifferent(item.nameChip, "Visible", showName)
    setIfDifferent(item.distanceLabel, "Text", showDistance and (tostring(meters) .. " м") or "")
    setIfDifferent(item.distanceLabel, "TextSize", metaSize)
    setIfDifferent(item.distanceChip, "Visible", showDistance)
    local hpFraction = 0
    if showHealth then
        if hum then
            local maxHp = math.max(hum.MaxHealth, 1)
            hpFraction = math.clamp(hum.Health / maxHp, 0, 1)
            setIfDifferent(item.healthLabel, "Text",
                tostring(math.ceil(hum.Health)))
        else
            setIfDifferent(item.healthLabel, "Text", "HP --")
        end
        local hpColor = Color3.fromRGB(math.floor(232 - 145 * hpFraction),
            math.floor(86 + 141 * hpFraction), math.floor(108 + 23 * hpFraction))
        setIfDifferent(item.healthLabel, "TextColor3", hpColor)
        setIfDifferent(item.healthFill, "BackgroundColor3", hpColor)
        setIfDifferent(item.healthFill, "Size", UDim2.new(hpFraction, 0, 1, 0))
    end
    setIfDifferent(item.healthLabel, "TextSize", metaSize)
    setIfDifferent(item.healthChip, "Visible", showHealth)
    -- The single visible badge expands; disabled rows leave no blank space.
    local hasMeta = showHealth or showDistance
    local lowerY = showName and 18 or 0
    local both = showHealth and showDistance
    setIfDifferent(item.healthChip, "Position", UDim2.fromOffset(0, lowerY))
    setIfDifferent(item.healthChip, "Size", both
        and UDim2.new(0.5, -2, 0, 11) or UDim2.new(1, 0, 0, 11))
    setIfDifferent(item.distanceChip, "Position", both
        and UDim2.new(0.5, 2, 0, lowerY) or UDim2.fromOffset(0, lowerY))
    setIfDifferent(item.distanceChip, "Size", both
        and UDim2.new(0.5, -2, 0, 11) or UDim2.new(1, 0, 0, 11))
    local height = showName and (hasMeta and CONFIG.EspLabelHeight or 16) or 11
    setIfDifferent(item.billboard, "Size", UDim2.fromOffset(CONFIG.EspLabelWidth, height))
    setIfDifferent(item.billboard, "Enabled", visibilityMask ~= 0)
    -- Дешёвый кэш флагов: не создаём строки/таблицы при каждом кадре.
    item.lastCompactVisibility = visibilityMask
    item.lastNames = state.names
    item.lastHealth = state.health
    item.lastDistance = state.distance
    item.lastTeamColors = state.teamColors
    item.lastColorPreset = state.espColorPreset
    item.lastTeam = player.Team
    item.lastTeamColor = player.TeamColor
    item.lastDisplayName = player.DisplayName
    return created
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
        perfCounters.espVisual.deferredCreates = 0
        return
    end
    local character = LocalPlayer.Character
    local _, myRoot = espParts(character)
    perfCounters.espVisual.localReady = myRoot ~= nil
    if not myRoot then
        -- Локальный респавн / StreamingEnabled: временно скрываем, а не
        -- уничтожаем все дорогостоящие Highlight/Billboard. При появлении
        -- Root следующий событийный scan снова использует валидные объекты.
        for _, item in pairs(renderData) do
            if item.inactiveSince == nil then item.inactiveSince = os.clock() end
            if isLive(item.highlight) then item.highlight.Enabled = false end
            if isLive(item.billboard) then item.billboard.Enabled = false end
            if item.tracer and item.tracer.Parent then item.tracer.Visible = false end
        end
        table.clear(perfCounters.espVisual.ordered)
        perfCounters.espCount = 0
        perfCounters.espVisual.eligible = 0
        perfCounters.espVisual.omitted = 0
        perfCounters.espVisual.missing = 0
        perfCounters.espVisual.deferredCreates = 0
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
    perfCounters.espVisual.deferredCreates = 0
    local createBudget = CONFIG.EspNewRendersPerScan
    if state.performanceGuard and perfCounters.guard.level > 0 then
        createBudget = math.min(createBudget, 2)
    end
    for i = 1, limit do
        local player = candidates[i].player
        keep[player] = true
        -- Distribute heavyweight GUI allocation over several scans.
        local ok, createdOrError = pcall(updatePlayer, player, myRoot, createBudget > 0)
        if not ok then
            deleteRender(player)
            perfCounters.espVisual.renderFailures = perfCounters.espVisual.renderFailures + 1
            local now = os.clock()
            if now - perfCounters.espVisual.scanErrorAt > 3 then
                warn("[124 Community Visuals] ESP player " .. tostring(player.UserId)
                    .. ": " .. tostring(createdOrError))
                perfCounters.espVisual.scanErrorAt = now
            end
        elseif createdOrError then
            createBudget = createBudget - 1
        end
        if renderData[player] then
            ordered[#ordered + 1] = player
        else
            perfCounters.espVisual.deferredCreates = perfCounters.espVisual.deferredCreates + 1
        end
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
local espUrgentQueued = false
local espUrgentLastAt = -math.huge
local espUrgentDirtyAt = -math.huge
local localEspEntry = {character = nil, added = nil, removing = nil}
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
local function queueESPRefresh(urgent)
    if not alive or not state.esp then return end
    if urgent == true then
        perfCounters.espVisual.urgentEvents = perfCounters.espVisual.urgentEvents + 1
        -- Во время коалесцирования запоминаем самое НОВОЕ событие:
        -- обычный scan мог закончиться между первым и последним событием.
        espUrgentDirtyAt = os.clock()
        if espUrgentQueued then return end
        espUrgentQueued = true
        local generation = espRefreshGeneration
        local elapsed = os.clock() - espUrgentLastAt
        local delaySeconds = math.max(CONFIG.EspRespawnCoalesceSeconds,
            CONFIG.EspRespawnMinIntervalSeconds - elapsed)
        task.delay(delaySeconds, function()
            if generation ~= espRefreshGeneration then return end
            espUrgentQueued = false
            if not alive or not state.esp then return end
            -- Не дублируем уже выполненный периодический scan, но никогда
            -- не теряем новое событие, пришедшее ПОСЛЕ этого scan.
            if perfCounters.espVisual.localReady
                and perfCounters.espVisual.lastScanAt >= espUrgentDirtyAt then
                perfCounters.espVisual.urgentSkipped =
                    perfCounters.espVisual.urgentSkipped + 1
                return
            end
            espUrgentLastAt = os.clock()
            local ok, err = pcall(refreshESP)
            if ok then
                perfCounters.espVisual.urgentScans = perfCounters.espVisual.urgentScans + 1
            else
                local now = os.clock()
                if now - perfCounters.espVisual.scanErrorAt >= 3 then
                    perfCounters.espVisual.scanErrorAt = now
                    warn("[124 Visuals] ESP fast respawn: " .. tostring(err))
                end
            end
        end)
        return
    end
    if espRefreshQueued then return end
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
            if alive and isEspPart(obj) then queueESPRefresh(true) end
        end)
        entry.partRemoved = character.DescendantRemoving:Connect(function(obj)
            if alive and isEspPart(obj) then queueESPRefresh(true) end
        end)
    end
    queueESPRefresh(true)
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
            deleteRender(player) -- Не оставляем старое выделение после респавна.
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
local function bindLocalEspCharacter(character)
    if localEspEntry.added then localEspEntry.added:Disconnect(); localEspEntry.added = nil end
    if localEspEntry.removing then localEspEntry.removing:Disconnect(); localEspEntry.removing = nil end
    localEspEntry.character = character
    if character and state.esp then
        localEspEntry.added = character.DescendantAdded:Connect(function(obj)
            if alive and isEspPart(obj) then queueESPRefresh(true) end
        end)
        localEspEntry.removing = character.DescendantRemoving:Connect(function(obj)
            if alive and isEspPart(obj) then queueESPRefresh(true) end
        end)
    end
    queueESPRefresh(true)
end
stopESPWatchers = function()
    espRefreshGeneration = espRefreshGeneration + 1
    espRefreshQueued = false
    espUrgentQueued = false
    espUrgentDirtyAt = -math.huge
    espUrgentLastAt = -math.huge
    for player in pairs(espWatchers) do unwatchEspPlayer(player) end
    bindLocalEspCharacter(nil)
end
syncESPWatchers = function()
    if not state.esp then
        if next(espWatchers) ~= nil or localEspEntry.character ~= nil then
            stopESPWatchers()
        end
        return
    end
    if localEspEntry.character ~= LocalPlayer.Character then
        bindLocalEspCharacter(LocalPlayer.Character)
    end
    for _, player in ipairs(perfCounters.roster) do watchEspPlayer(player) end
end
connect(LocalPlayer.CharacterAdded, function(character)
    if alive and state.esp then bindLocalEspCharacter(character) end
end)
connect(LocalPlayer.CharacterRemoving, function()
    if alive and state.esp then bindLocalEspCharacter(nil) end
end)
connect(Players.PlayerAdded, watchEspPlayer)
connect(Players.PlayerRemoving, function(player)
    unwatchEspPlayer(player)
    deleteRender(player)
end)

