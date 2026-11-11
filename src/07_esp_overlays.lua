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

