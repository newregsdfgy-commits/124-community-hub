-- 124 Community Hub v0.2 | Армия Роблокса РП
-- PlaceId: 18537079992
-- Локальный Luau-скрипт: ESP, Aim (тело/ноги), Misc, FPS/Ping/часы.
-- Все изменяющие параметры функции выключены по умолчанию.
-- При повторном запуске старая копия очищается и настройки сцены восстанавливаются.

local CONFIG = {
    PlaceId = 18537079992,
    EspRefreshSeconds = 0.25,
    EspMaxDistance = 2000,
    EspFillTransparency = 0.78,
    AimFovPixels = 175,
    AimMaxDistance = 2000,
    AimSpeed = 11, -- Чем выше значение, тем быстрее поворот камеры.
    BoosterBatch = 125,
    Accent = Color3.fromRGB(56, 209, 190),
    Neutral = Color3.fromRGB(255, 196, 100),
    Window = Color3.fromRGB(17, 23, 33),
    Surface = Color3.fromRGB(28, 37, 49),
    Muted = Color3.fromRGB(151, 164, 179),
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

local state = {
    esp = false,
    names = true,
    health = true,
    distance = true,
    teamColors = true,
    fullbright = false,
    aimbot = false,
    aimBody = true,
    teamCheck = true,
    antiAfk = false,
    booster = false,
    hud = true,
}

local alive = true
local connections = {}
local renderData = {}
local savedLighting = nil
local savedGraphics = setmetatable({}, { __mode = "k" })
local boosterRevision = 0
local aimHeldMouse = false
local aimHeldTouch = false
local aimBound = false
local aimBindingName = "Army124CommunityAim_" .. tostring(LocalPlayer.UserId)
local statusMessage = nil
local refreshToggles = {}

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
    for _, inst in ipairs({item.highlight, item.billboard}) do
        if inst then pcall(function() inst:Destroy() end) end
    end
    renderData[player] = nil
end

local function getPlayerColor(player)
    if state.teamColors and player.Team ~= nil then
        return player.TeamColor.Color
    end
    return CONFIG.Neutral
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
        MaxDistance = CONFIG.EspMaxDistance,
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
    item.highlight.FillColor = color
    item.highlight.OutlineColor = color
    local text = {}
    if state.names then table.insert(text, player.DisplayName) end
    if state.distance and myRoot then
        local studs = math.floor((root.Position - myRoot.Position).Magnitude + 0.5)
        table.insert(text, tostring(studs) .. " studs")
    end
    item.nameLabel.Text = table.concat(text, "  |  ")
    item.nameLabel.TextColor3 = color
    item.nameLabel.Visible = #text > 0
    local maxHp = math.max(hum.MaxHealth, 1)
    local hp = math.clamp(hum.Health / maxHp, 0, 1)
    item.healthLabel.Text = string.format("HP %d/%d", math.ceil(hum.Health), math.ceil(maxHp))
    item.healthLabel.TextColor3 = Color3.fromRGB(math.floor(255 * (1 - hp)), math.floor(255 * hp), 90)
    item.healthLabel.Visible = state.health
    item.billboard.Enabled = item.nameLabel.Visible or item.healthLabel.Visible
end

local function refreshESP()
    if not state.esp then
        for player in pairs(renderData) do deleteRender(player) end
        return
    end
    local character = LocalPlayer.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then updatePlayer(player, myRoot) end
    end
    for player in pairs(renderData) do
        if player.Parent ~= Players then deleteRender(player) end
    end
end

-- FullBright и FPS Booster имеют общую исходную копию освещения.
local function captureLighting()
    if savedLighting then return end
    savedLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        GlobalShadows = Lighting.GlobalShadows,
    }
end

local function applyLighting()
    if not state.fullbright and not state.booster then
        if savedLighting then
            for k, v in pairs(savedLighting) do
                pcall(function() Lighting[k] = v end)
            end
            savedLighting = nil
        end
        return
    end
    captureLighting()
    local originals = savedLighting
    if not originals then return end
    Lighting.Brightness = state.fullbright and 3 or originals.Brightness
    Lighting.ClockTime = state.fullbright and 14 or originals.ClockTime
    Lighting.Ambient = state.fullbright and Color3.fromRGB(180, 180, 180) or originals.Ambient
    Lighting.OutdoorAmbient = state.fullbright and Color3.fromRGB(180, 180, 180) or originals.OutdoorAmbient
    Lighting.GlobalShadows = (state.fullbright or state.booster) and false or originals.GlobalShadows
end

local function graphicsProperty(obj)
    if obj:IsA("BasePart") then
        return {Material = Enum.Material.SmoothPlastic, CastShadow = false}
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        return {Transparency = 1}
    elseif obj:IsA("PostEffect") or obj:IsA("ParticleEmitter") or
        obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or
        obj:IsA("Fire") or obj:IsA("Sparkles") then
        return {Enabled = false}
    end
    return nil
end

local function optimizeObject(obj)
    if not alive or not state.booster or savedGraphics[obj] then return end
    local props = graphicsProperty(obj)
    if not props then return end
    local snapshot = {}
    for key, value in pairs(props) do
        local ok, old = pcall(function() return obj[key] end)
        if ok then
            snapshot[key] = old
            pcall(function() obj[key] = value end)
        end
    end
    if next(snapshot) then savedGraphics[obj] = snapshot end
end

local function setBooster(enabled)
    boosterRevision = boosterRevision + 1
    local revision = boosterRevision
    if enabled then
        applyLighting()
        task.spawn(function()
            local all = Workspace:GetDescendants()
            for _, obj in ipairs(all) do
                if not alive or not state.booster or revision ~= boosterRevision then return end
                optimizeObject(obj)
                if _ % CONFIG.BoosterBatch == 0 then task.wait() end
            end
            local effects = Lighting:GetDescendants()
            for _, obj in ipairs(effects) do
                if not alive or not state.booster or revision ~= boosterRevision then return end
                optimizeObject(obj)
                if _ % CONFIG.BoosterBatch == 0 then task.wait() end
            end
            tell("FPS Booster: оптимизация применена")
        end)
    else
        applyLighting()
        task.spawn(function()
            local counter = 0
            for obj, snapshot in pairs(savedGraphics) do
                if revision ~= boosterRevision then return end
                for key, original in pairs(snapshot) do
                    pcall(function() obj[key] = original end)
                end
                savedGraphics[obj] = nil
                counter = counter + 1
                if counter % CONFIG.BoosterBatch == 0 then task.wait() end
            end
            if alive then tell("FPS Booster: материалы восстановлены") end
        end)
    end
end

-- Aim: только игроки, находящиеся в поле зрения и доступные для Raycast.
-- Для ПК удерживай ПКМ, для телефона используй кнопку AIM.
local function targetPart(character)
    if state.aimBody then
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

local function canSee(camera, point, targetCharacter)
    local origin = camera.CFrame.Position
    local direction = point - origin
    if direction.Magnitude < 0.05 then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = LocalPlayer.Character and {LocalPlayer.Character} or {}
    rayParams.IgnoreWater = true
    local hit = Workspace:Raycast(origin, direction, rayParams)
    return not hit or hit.Instance:IsDescendantOf(targetCharacter)
end

local function findAimTarget(camera)
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local best, bestPixels = nil, CONFIG.AimFovPixels
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local sameTeam = state.teamCheck and player.Team ~= nil
                and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
            if not sameTeam then
                local char = player.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                local part = targetPart(char)
                if hum and hum.Health > 0 and part and part:IsA("BasePart") then
                    local dist = (part.Position - camera.CFrame.Position).Magnitude
                    if dist <= CONFIG.AimMaxDistance then
                        local screenPoint, visible = camera:WorldToViewportPoint(part.Position)
                        if visible and screenPoint.Z > 0 then
                            local pixels = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                            if pixels < bestPixels and canSee(camera, part.Position, char) then
                                best = part
                                bestPixels = pixels
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function aimFrame(dt)
    if not alive or not state.aimbot or not (aimHeldMouse or aimHeldTouch) then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local part = findAimTarget(camera)
    if not part or not part.Parent then return end
    local origin = camera.CFrame.Position
    local target = part.Position
    if (target - origin).Magnitude <= 0.05 then return end
    local goal = CFrame.lookAt(origin, target)
    local alpha = math.clamp(1 - math.exp(-CONFIG.AimSpeed * math.clamp(dt, 0, 0.1)), 0, 1)
    camera.CFrame = camera.CFrame:Lerp(goal, alpha)
end

-- Пользовательский интерфейс: три вкладки и прокрутка для небольших экранов.
local gui = mk("ScreenGui", {
    Name = "Army124CommunityHubV02",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(400, 720)
local winWidth = math.max(250, math.min(338, viewport.X - 22))
local winHeight = math.max(280, math.min(475, viewport.Y - 35))
local panel = mk("Frame", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(winWidth, winHeight),
    BackgroundColor3 = CONFIG.Window,
    BorderSizePixel = 0,
    Active = true,
}, gui)
round(panel, 14)
outline(panel, Color3.fromRGB(58, 77, 91))

local bar = mk("Frame", {
    Name = "DragBar",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 66),
    Active = true,
}, panel)
mk("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(14, 9),
    Size = UDim2.new(1, -64, 0, 27),
    Text = "124 COMMUNITY HUB",
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    TextColor3 = CONFIG.Accent,
    TextXAlignment = Enum.TextXAlignment.Left,
}, bar)
mk("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(14, 35),
    Size = UDim2.new(1, -64, 0, 20),
    Text = "Армия RP  •  v0.2  •  Local",
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextColor3 = CONFIG.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, bar)
local hide = mk("TextButton", {
    Position = UDim2.new(1, -43, 0, 14),
    Size = UDim2.fromOffset(29, 27),
    BackgroundColor3 = Color3.fromRGB(44, 56, 70),
    Text = "−",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 20,
    Font = Enum.Font.GothamBold,
}, bar)
round(hide, 7)

local tabs = mk("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 64),
    Size = UDim2.new(1, -24, 0, 38),
}, panel)
local tabLayout = mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
}, tabs)
local tabButtons = {}
local pages = {}
local currentPage = "ESP"

for idx, key in ipairs({"ESP", "AIM", "MISC"}) do
    local button = mk("TextButton", {
        Name = key .. "Tab",
        LayoutOrder = idx,
        BackgroundColor3 = CONFIG.Surface,
        Size = UDim2.new(1/3, -4, 1, -2),
        Text = key,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = CONFIG.Muted,
        AutoButtonColor = false,
    }, tabs)
    round(button, 8)
    tabButtons[key] = button
    local scroll = mk("ScrollingFrame", {
        Name = key .. "Page",
        Position = UDim2.fromOffset(12, 109),
        Size = UDim2.new(1, -24, 1, -162),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CONFIG.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = key == "ESP",
    }, panel)
    mk("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, scroll)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 4),
    }, scroll)
    pages[key] = scroll
end

local function showPage(key)
    currentPage = key
    for name, page in pairs(pages) do
        local selected = name == key
        page.Visible = selected
        tabButtons[name].TextColor3 = selected and Color3.fromRGB(18, 29, 38) or CONFIG.Muted
        tabButtons[name].BackgroundColor3 = selected and CONFIG.Accent or CONFIG.Surface
    end
end
for name, button in pairs(tabButtons) do
    connect(button.Activated, function() showPage(name) end)
end
showPage("ESP")

local function addToggle(page, title, description, key, onChanged)
    local row = mk("TextButton", {
        Name = key,
        Size = UDim2.new(1, 0, 0, 49),
        BackgroundColor3 = CONFIG.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, page)
    round(row, 8)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -77, 0, 22),
        Text = title,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextColor3 = Color3.fromRGB(229, 238, 247),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 27),
        Size = UDim2.new(1, -77, 0, 16),
        Text = description,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextColor3 = CONFIG.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local pill = mk("TextLabel", {
        Position = UDim2.new(1, -62, 0, 13),
        Size = UDim2.fromOffset(51, 24),
        BackgroundColor3 = Color3.fromRGB(64, 76, 89),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "OFF",
    }, row)
    round(pill, 7)
    local function update()
        if not row.Parent then return end
        pill.Text = state[key] and "ON" or "OFF"
        pill.BackgroundColor3 = state[key] and Color3.fromRGB(22, 137, 109) or Color3.fromRGB(64, 76, 89)
        row.BackgroundColor3 = state[key] and Color3.fromRGB(28, 61, 61) or CONFIG.Surface
    end
    refreshToggles[key] = update
    connect(row.Activated, function()
        if not alive then return end
        state[key] = not state[key]
        if onChanged then
            local ok, err = pcall(onChanged, state[key])
            if not ok then tell("Ошибка: " .. tostring(err)) end
        end
        update()
    end)
    update()
    return row
end

local function addButton(page, text, description, handler)
    local button = mk("TextButton", {
        BackgroundColor3 = Color3.fromRGB(42, 63, 76),
        Size = UDim2.new(1, 0, 0, 45),
        Text = "",
        AutoButtonColor = true,
    }, page)
    round(button, 8)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 3),
        Size = UDim2.new(1, -20, 0, 21),
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(234, 245, 249),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 25),
        Size = UDim2.new(1, -20, 0, 14),
        Text = description,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = CONFIG.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)
    connect(button.Activated, handler)
    return button
end

addToggle(pages.ESP, "ESP подсветка", "Игроки за объектами", "esp", function() refreshESP() end)
addToggle(pages.ESP, "Имена", "DisplayName над персонажами", "names")
addToggle(pages.ESP, "Здоровье", "HP над персонажами", "health")
addToggle(pages.ESP, "Дистанция", "Расстояние в studs", "distance")
addToggle(pages.ESP, "Цвет команд", "Расцветка согласно TeamColor", "teamColors")

addToggle(pages.AIM, "Aimbot", "Включить наведение камеры", "aimbot", function(enabled)
    if not enabled then
        aimHeldTouch = false
    end
end)
addToggle(pages.AIM, "Прицел в тело", "ON = тело, OFF = ноги", "aimBody")
addToggle(pages.AIM, "Проверка команды", "Игнорировать союзников", "teamCheck")
addButton(pages.AIM, "Как пользоваться", "ПК: удерживать ПКМ | Android: кнопка AIM", function()
    tell("Для наведения удерживай ПКМ или кнопку AIM")
end)
addButton(pages.AIM, "Параметры", "FOV 175 px | сглаживание 11 | видимая цель", function()
    tell("AIM: FOV 175px, LOS проверяется, автострельбы нет")
end)

addToggle(pages.MISC, "AntiAFK", "VirtualUser при событии Idled", "antiAfk")
addToggle(pages.MISC, "FPS Booster", "SmoothPlastic, без эффектов и теней", "booster", setBooster)
addToggle(pages.MISC, "FullBright", "Осветлить сцену локально", "fullbright", function() applyLighting() end)
addToggle(pages.MISC, "Часы / FPS / Ping", "Информационный блок экрана", "hud")
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

local status = mk("TextLabel", {
    Position = UDim2.new(0, 12, 1, -48),
    Size = UDim2.new(1, -24, 0, 17),
    BackgroundTransparency = 1,
    Text = "v0.2 готов | Все основные функции OFF",
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextColor3 = CONFIG.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, panel)
statusMessage = status
local unload = mk("TextButton", {
    Name = "Unload",
    Position = UDim2.new(0, 12, 1, -29),
    Size = UDim2.new(1, -24, 0, 25),
    BackgroundColor3 = Color3.fromRGB(91, 42, 54),
    Text = "Выгрузить Hub и вернуть графику",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(255, 218, 226),
}, panel)
round(unload, 7)

local mini = mk("TextButton", {
    Name = "OpenHub",
    Position = UDim2.new(0, 12, 0.39, 0),
    Size = UDim2.fromOffset(81, 40),
    BackgroundColor3 = CONFIG.Accent,
    TextColor3 = Color3.fromRGB(18, 29, 38),
    Text = "124 HUB",
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    Visible = false,
}, gui)
round(mini, 11)
connect(hide.Activated, function() panel.Visible = false; mini.Visible = true end)
connect(mini.Activated, function() panel.Visible = true; mini.Visible = false end)

local aimTouchButton = mk("TextButton", {
    Name = "AimHold",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -115),
    Size = UDim2.fromOffset(93, 42),
    BackgroundColor3 = Color3.fromRGB(44, 67, 79),
    TextColor3 = Color3.fromRGB(237, 250, 250),
    Text = "AIM: OFF",
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    Visible = false,
}, gui)
round(aimTouchButton, 10)
connect(aimTouchButton.Activated, function()
    if state.aimbot then
        aimHeldTouch = not aimHeldTouch
        aimTouchButton.Text = aimHeldTouch and "AIM: ON" or "AIM: OFF"
        aimTouchButton.BackgroundColor3 = aimHeldTouch and Color3.fromRGB(21, 143, 114) or Color3.fromRGB(44, 67, 79)
    end
end)

local stats = mk("TextLabel", {
    Name = "Stats",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 12),
    Size = UDim2.fromOffset(218, 27),
    BackgroundColor3 = Color3.fromRGB(20, 29, 41),
    BackgroundTransparency = 0.22,
    BorderSizePixel = 0,
    TextColor3 = Color3.fromRGB(224, 244, 241),
    Text = "--:--:-- | FPS -- | Ping --",
    Font = Enum.Font.Code,
    TextSize = 11,
    Visible = state.hud,
}, gui)
round(stats, 7)

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
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimHeldMouse = true
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
    panel.Position = UDim2.new(
        panelOrigin.X.Scale, panelOrigin.X.Offset + delta.X,
        panelOrigin.Y.Scale, panelOrigin.Y.Offset + delta.Y
    )
end)

connect(LocalPlayer.Idled, function()
    if not alive or not state.antiAfk then return end
    local ok, err = pcall(function()
        local camera = Workspace.CurrentCamera
        VirtualUser:CaptureController()
        VirtualUser:Button2Down(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
        task.wait(0.1)
        if alive and state.antiAfk then
            VirtualUser:Button2Up(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
        end
    end)
    if not ok then tell("AntiAFK: VirtualUser недоступен — " .. tostring(err)) end
end)

connect(Workspace.DescendantAdded, function(obj)
    if alive and state.booster then
        task.defer(function() optimizeObject(obj) end)
    end
end)
connect(Lighting.DescendantAdded, function(obj)
    if alive and state.booster then
        task.defer(function() optimizeObject(obj) end)
    end
end)

local function cleanup()
    if not alive then return end
    alive = false
    state.esp = false
    state.aimbot = false
    state.antiAfk = false
    state.booster = false
    state.fullbright = false
    boosterRevision = boosterRevision + 1
    if aimBound then
        pcall(function() RunService:UnbindFromRenderStep(aimBindingName) end)
    end
    pcall(applyLighting)
    for obj, saved in pairs(savedGraphics) do
        for key, value in pairs(saved) do
            pcall(function() obj[key] = value end)
        end
        savedGraphics[obj] = nil
    end
    for player in pairs(renderData) do deleteRender(player) end
    for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
    table.clear(connections)
    pcall(function() gui:Destroy() end)
    if env.ARMY124_CLEANUP == cleanup then env.ARMY124_CLEANUP = nil end
end

env.ARMY124_CLEANUP = cleanup
connect(unload.Activated, cleanup)
connect(Players.PlayerRemoving, deleteRender)

local okBind, errBind = pcall(function()
    RunService:BindToRenderStep(aimBindingName, Enum.RenderPriority.Camera.Value + 1, aimFrame)
end)
if okBind then
    aimBound = true
else
    tell("BindToRenderStep недоступен; используем RenderStepped")
    connect(RunService.RenderStepped, aimFrame)
end

task.spawn(function()
    while alive do
        local ok, err = pcall(refreshESP)
        if not ok then warn("[124 Community Hub] ESP: " .. tostring(err)) end
        task.wait(CONFIG.EspRefreshSeconds)
    end
end)

local frames, accumulated, measuredFps = 0, 0, 0
connect(RunService.RenderStepped, function(dt)
    if not alive then return end
    frames = frames + 1
    accumulated = accumulated + math.max(dt, 0)
    if accumulated >= 0.8 then
        measuredFps = math.floor(frames / math.max(accumulated, 0.01) + 0.5)
        frames, accumulated = 0, 0
    end
end)

task.spawn(function()
    local lastLightingSync = 0
    while alive do
        if os.clock() - lastLightingSync >= 2 and (state.fullbright or state.booster) then
            lastLightingSync = os.clock()
            pcall(applyLighting)
        end
        stats.Visible = state.hud
        aimTouchButton.Visible = state.aimbot and UserInputService.TouchEnabled
        if state.aimbot == false then
            aimHeldTouch = false
            aimTouchButton.Text = "AIM: OFF"
            aimTouchButton.BackgroundColor3 = Color3.fromRGB(44, 67, 79)
        end
        local ping = "--"
        local ok, value = pcall(function() return LocalPlayer:GetNetworkPing() end)
        if ok and type(value) == "number" then
            ping = tostring(math.floor(value * 1000 + 0.5))
        end
        stats.Text = string.format("%s | FPS %d | %sms", os.date("%H:%M:%S"), measuredFps, ping)
        task.wait(0.7)
    end
end)

print("[124 Community Hub] v0.2 загружен | ESP / AIM / MISC")
