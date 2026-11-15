-- Единая сетка компонентов. Стилизация не меняет обработчики состояний.
local function addSection(page, title, subtitle)
    local info = pageColumns[page]
    if info then info.side = sectionSides[title] or info.side end
    local hero = title == "VISUALS" or title == "TARGETING"
        or title == "MOVEMENT" or title == "UTILITY"
    local container = mk("Frame", {
        Name = title .. "Heading", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, hero and 68 or 54),
    }, columnFor(page))
    registerWidget(page, container)
    mk("Frame", {
        Name = "SectionDivider", BackgroundColor3 = P.border,
        BackgroundTransparency = 0.77, BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 1, -3), Size = UDim2.new(1, -27, 0, 1),
        Active = false,
    }, container)
    -- Every heading uses a vertical rule with reserved text padding.
    -- The old 19px *horizontal* rule literally ran across "ADVANCED".
    local sectionBar = mk("Frame", {Name = "SectionAccent", BackgroundColor3 = P.accent,
        BorderSizePixel = 0, Position = UDim2.fromOffset(4, hero and 11 or 7),
        Size = UDim2.fromOffset(hero and 4 or 3, hero and 23 or 19)}, container)
    round(sectionBar, 2)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, hero and 5 or 3),
        Size = UDim2.new(1, -28, 0, hero and 29 or 21),
        Text = title, Font = Enum.Font.GothamBold, TextSize = hero and 17 or 13,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, container)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, hero and 40 or 29),
        Size = UDim2.new(1, -28, 0, 15),
        Text = subtitle, Font = Enum.Font.Gotham,
        TextSize = 10, TextColor3 = P.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, container)
end

local function addToggle(page, title, description, key, onChanged)
    local row = mk("TextButton", {
        Name = key, Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = P.tile, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "",
    }, columnFor(page))
    registerWidget(page, row)
    round(row, 11)
    local rowBorder = mk("UIStroke", {Color = P.border, Transparency = 0.67, Thickness = 1}, row)
    local activeAccent = mk("Frame", {
        Name = "ToggleActiveRail", BackgroundColor3 = P.accent,
        BackgroundTransparency = 0.12, BorderSizePixel = 0,
        Position = UDim2.fromOffset(4, 12), Size = UDim2.fromOffset(3, 38),
        Visible = false, Active = false,
    }, row)
    round(activeAccent, 2)
    mk("UIGradient", {Rotation = 0,
        Color = ColorSequence.new(Color3.fromRGB(41, 37, 61),
            Color3.fromRGB(29, 27, 45))}, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 9), Size = UDim2.new(1, -79, 0, 22),
        Text = title, TextSize = 13, Font = Enum.Font.GothamBold,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 35), Size = UDim2.new(1, -79, 0, 17),
        Text = description, TextSize = 10, Font = Enum.Font.Gotham,
        TextColor3 = P.dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local pill = mk("Frame", {
        Name = "Switch", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0),
        Size = UDim2.fromOffset(40, 22), BackgroundColor3 = P.off,
        BorderSizePixel = 0,
    }, row)
    round(pill, 11)
    local pillBorder = mk("UIStroke", {Color = P.border, Transparency = 0.62, Thickness = 1}, pill)
    local knob = mk("Frame", {
        Name = "Knob", Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(235, 230, 245), BorderSizePixel = 0,
    }, pill)
    round(knob, 9)
    local knobTween = nil
    local function update(animate)
        if not row.Parent then return end
        local enabled = state[key] == true
        activeAccent.Visible = enabled
        pill.BackgroundColor3 = enabled and P.accent or P.off
        local targetPosition = UDim2.fromOffset(enabled and 20 or 2, 2)
        -- Fast double taps must not leave the knob with an obsolete tween.
        if knobTween then pcall(function() knobTween:Cancel() end); knobTween = nil end
        if animate == true then
            local okTween, tween = pcall(function()
                return TweenService:Create(knob, TweenInfo.new(0.14,
                    Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = targetPosition})
            end)
            if okTween and tween then
                knobTween = tween
                tween:Play()
            else
                knob.Position = targetPosition
            end
        else
            knob.Position = targetPosition
        end
        knob.BackgroundColor3 = enabled and Color3.fromRGB(255, 251, 255)
            or Color3.fromRGB(222, 219, 235)
        pillBorder.Color = enabled and P.accent or P.border
        pillBorder.Transparency = enabled and 0.17 or 0.64
        rowBorder.Color = enabled and P.accent or P.border
        rowBorder.Transparency = enabled and 0.24 or 0.70
    end
    refreshToggles[key] = update
    local function onRowActivated()
        if not alive then return end
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
        update(true)
        requestSave()
    end
    row.Active = true
    if key == "aimbot" then
        -- AIM INPUT HOTFIX: the legacy generic button was not reliably
        -- receiving Activated when a switch/label or another UI layer was
        -- chosen as the input target. Give AIM its own full-row hit surface.
        -- The global InputEnded path is a fallback, not an extra activation.
        local surface = mk("TextButton", {
            Name = "AimFullRowHitSurface", Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, Active = true,
            Selectable = true, ZIndex = 25,
        }, row)
        local debug = {
            presses = 0, activated = 0, recovered = 0,
            blocked = 0, lastSource = "ready", lastError = "",
        }
        boosterPro.aimClickDebug = debug
        local serial, consumedSerial = 0, -1
        local lastStarted, lastFired = -1e8, -1e8
        local latestInput, downInput, downPosition = nil, nil, nil
        local function inside(position)
            if not position or not alive or not gui.Enabled
                or not panel.Visible or not page.Visible
                or not row.Parent or not row.Visible then return false end
            local at, size = row.AbsolutePosition, row.AbsoluteSize
            if not at or not size or size.X < 24 or size.Y < 24 then return false end
            return position.X >= at.X and position.X <= at.X + size.X
                and position.Y >= at.Y and position.Y <= at.Y + size.Y
        end
        local function exposed(position)
            -- Do not route a click through an unrelated topmost modal/button.
            local ok, objects = pcall(PlayerGui.GetGuiObjectsAtPosition,
                PlayerGui, position.X, position.Y)
            if not ok or type(objects) ~= "table" or #objects == 0 then
                return true -- Degraded executor API: geometry still works.
            end
            local first = objects[1]
            if not first then return true end
            local insideRow = first == row or first == surface
            if not insideRow then
                local checkOk, value = pcall(function() return first:IsDescendantOf(row) end)
                insideRow = checkOk and value
            end
            if not insideRow then
                debug.blocked = debug.blocked + 1
                debug.lastError = "UI covered by " .. tostring(first.Name or "?")
            end
            return insideRow
        end
        local function activate(source, token)
            if not alive or not gui.Enabled or not panel.Visible or not page.Visible
                or not row.Parent then return end
            local now = os.clock()
            if token ~= nil and consumedSerial == token then return end
            if token == nil and now - lastFired < 0.14 then return end
            if token ~= nil then consumedSerial = token end
            lastFired = now
            debug.presses = debug.presses + 1
            debug.lastSource = source
            local previous = state.aimbot
            local ok, err = pcall(onRowActivated)
            if not ok then
                debug.lastError = tostring(err)
                tell("AIM button callback: " .. tostring(err))
            elseif previous == state.aimbot then
                debug.lastError = "state unchanged; see Output"
                tell("AIM: нажатие получено, но состояние не изменилось")
            else
                debug.lastError = ""
            end
        end
        -- These events come from UserInputService, so a dropped TextButton
        -- Activated does not leave the visible switch completely unresponsive.
        connect(UserInputService.InputBegan, function(input)
            local kind = input.UserInputType
            if kind ~= Enum.UserInputType.MouseButton1
                and kind ~= Enum.UserInputType.Touch then return end
            local position = input.Position
            if inside(position) and exposed(position) then
                serial = serial + 1
                lastStarted = os.clock()
                latestInput, downInput, downPosition = input, input, position
            end
        end)
        connect(UserInputService.InputEnded, function(input)
            if input ~= downInput then return end
            downInput = nil
            local position = input.Position
            if not inside(position) or not exposed(position) then return end
            if downPosition then
                local dx = position.X - downPosition.X
                local dy = position.Y - downPosition.Y
                if dx * dx + dy * dy > 144 then return end
            end
            debug.recovered = debug.recovered + 1
            activate("input-ended", serial)
        end)
        local function eventToken(input)
            -- An actual InputObject remains bound to its physical press
            -- (including long touch holds). MouseButton1Click has no input
            -- identity: only pair it with a recent InputBegan, otherwise a
            -- *new* legacy-only click must not inherit an old consumed token.
            if serial > 0 and input ~= nil and input == latestInput then
                return serial
            end
            if serial > 0 and input == nil
                and os.clock() - lastStarted < 0.14 then
                return serial
            end
            return nil
        end
        connect(surface.Activated, function(input)
            if not allowTap(input) then return end
            debug.activated = debug.activated + 1
            activate("surface-activated", eventToken(input))
        end)
        connect(surface.MouseButton1Click, function()
            activate("surface-click", eventToken(nil))
        end)
        -- If the Roblox client does not emit Activated on the surface but
        -- emits it on the underlying row, still route it through one token.
        connect(row.Activated, function(input)
            if not allowTap(input) then return end
            activate("row-activated", eventToken(input))
        end)
    else
        safeActivate(row, onRowActivated)
    end
    update()
    return row
end

local function addButton(page, text, description, handler)
    local button = mk("TextButton", {
        BackgroundColor3 = P.tile,
        Size = UDim2.new(1, 0, 0, 61),
        Text = "", AutoButtonColor = true, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, button)
    round(button, 11)
    mk("UIStroke", {Color = P.border, Transparency = 0.66, Thickness = 1}, button)
    mk("Frame", {
        Name = "ActionAccent", BackgroundColor3 = P.accent, BorderSizePixel = 0,
        BackgroundTransparency = 0.15, Position = UDim2.fromOffset(5, 18),
        Size = UDim2.fromOffset(3, 25), Active = false,
    }, button)
    mk("UIGradient", {Rotation = 0,
        Color = ColorSequence.new(Color3.fromRGB(39, 35, 60),
            Color3.fromRGB(30, 28, 47))}, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(17, 9), Size = UDim2.new(1, -51, 0, 22),
        Text = text, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = P.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(17, 36), Size = UDim2.new(1, -51, 0, 16),
        Text = description, Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = P.dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, button)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -35, 0.5, -11),
        Size = UDim2.fromOffset(22, 22), Text = "›", Font = Enum.Font.GothamBold,
        TextSize = 20, TextColor3 = P.accent,
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
        Name = key .. "Slider", Size = UDim2.new(1, 0, 0, 92),
        BackgroundColor3 = P.tile, BorderSizePixel = 0,
    }, columnFor(page))
    registerWidget(page, container)
    round(container, 11)
    mk("UIStroke", {Color = P.border, Transparency = 0.68, Thickness = 1}, container)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(15, 10),
        Size = UDim2.new(1, -115, 0, 20), Text = title,
        TextColor3 = P.text,
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    local valueLabel = mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -112, 0, 10),
        Size = UDim2.fromOffset(98, 20),
        TextColor3 = P.accent, Font = Enum.Font.Code,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
    }, container)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(15, 35),
        Size = UDim2.new(1, -30, 0, 16), Text = description,
        TextColor3 = P.dim, Font = Enum.Font.Gotham,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    local touchArea = mk("TextButton", {
        Name = "DragArea", BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(10, 52), Size = UDim2.new(1, -20, 0, 32),
    }, container)
    local track = mk("Frame", {
        Name = "Track", BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(68, 61, 90),
        Position = UDim2.new(0, 6, 0.5, -3),
        Size = UDim2.new(1, -12, 0, 6),
    }, touchArea)
    round(track, 3)
    local fill = mk("Frame", {
        Name = "Fill", BorderSizePixel = 0,
        BackgroundColor3 = P.accent, Size = UDim2.fromScale(0, 1),
    }, track)
    round(fill, 3)
    local thumb = mk("Frame", {
        Name = "Thumb", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.fromRGB(248, 243, 255), BorderSizePixel = 0,
    }, track)
    round(thumb, 8)

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
            aimPro.reset()
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
    local row = mk("Frame", {Name = key .. "Choices", Size = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = P.tile, BorderSizePixel = 0}, columnFor(page))
    registerWidget(page, row)
    round(row, 11)
    mk("UIStroke", {Color = P.border, Transparency = 0.64, Thickness = 1}, row)
    mk("TextLabel", {Text = label, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
        TextSize = 12, TextColor3 = P.text,
        Position = UDim2.fromOffset(13, 7), Size = UDim2.new(1, -26, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left}, row)
    local buttons = {}
    local function repaint()
        for _, option in ipairs(choices) do
            local button = buttons[option.value]
            if button and button.Parent then
                local enabled = state[key] == option.value
                button.BackgroundColor3 = enabled and Color3.fromRGB(91, 59, 139)
                    or Color3.fromRGB(45, 41, 64)
                button.TextColor3 = enabled and P.text or P.dim
            end
        end
    end
    for i, option in ipairs(choices) do
        local button = mk("TextButton", {Text = option.label, BackgroundColor3 = P.tile,
            TextColor3 = P.dim, BorderSizePixel = 0, AutoButtonColor = true,
            TextSize = 10, Font = Enum.Font.GothamBold,
            Position = UDim2.new((i - 1) / #choices, 7, 0, 34),
            Size = UDim2.new(1 / #choices, -14 / #choices, 0, 30)}, row)
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
    refreshChoices[key] = repaint
    repaint()
    return repaint
end

addSection(pages.ESP, "VISUALS", "Compact HUD: ближние метки, дальние только контуры")

addToggle(pages.ESP, "ESP подсветка", "Подсветка в выбранном радиусе до 1000 м", "esp", function()
    syncEspVisuals()
end)
addToggle(pages.ESP, "Линия над игроками", "От верха экрана к игрокам в радиусе ESP", "tracers", function(enabled)
    if not enabled then clearTracers() end
    if enabled and not state.esp then tell("Включи ESP, чтобы отображать линии") end
end)
addToggle(pages.ESP, "2D Box", "Угловые скобки вместо сплошного контура", "espBox", function(enabled)
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
addSlider(pages.ESP, "Толщина линий", "Короткие углы (1–2 px), Tracer — 1 px", "espLineThickness", 1, 2, 1,
    function(v) return tostring(v) .. " px" end)
repaintColors = addChoice(pages.ESP, "Цвет ESP", {
    {value="TEAM", label="TEAM"}, {value="GOLD", label="GOLD"},
    {value="GREEN", label="GREEN"}, {value="WHITE", label="WHITE"},
}, "espColorPreset", function() queueESPRefresh() end)
addToggle(pages.ESP, "Имена", "DisplayName над персонажами", "names")
addToggle(pages.ESP, "Здоровье", "HP над персонажами", "health")
addToggle(pages.ESP, "Дистанция", "Расстояние в метрах (≈)", "distance")
addToggle(pages.ESP, "Цвет команд", "Расцветка согласно TeamColor", "teamColors")

-- Each slider controls one existing ESP visual. The master ESP range still
-- caps visibility, so these sliders never expand global target discovery.
addSection(pages.ESP, "ДАЛЬНОСТЬ ЭЛЕМЕНТОВ",
    "Отдельно для имени, HP, расстояния, рамки и линий")
addSlider(pages.ESP, "Дальность ника", "До какого расстояния показывать имя игрока",
    "espNameMaxMeters", CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters,
    CONFIG.EspRangeStepMeters, function(v) return tostring(v) .. " м" end,
    function() queueESPRefresh() end)
addSlider(pages.ESP, "Дальность HP", "Полоска и число здоровья; независимо от имени",
    "espHealthMaxMeters", CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters,
    CONFIG.EspRangeStepMeters, function(v) return tostring(v) .. " м" end,
    function() queueESPRefresh() end)
addSlider(pages.ESP, "Дальность расстояния", "До какого расстояния показывать метры",
    "espDistanceMaxMeters", CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters,
    CONFIG.EspRangeStepMeters, function(v) return tostring(v) .. " м" end,
    function() queueESPRefresh() end)
addSlider(pages.ESP, "Дальность 2D Box", "Угловая рамка; общий радиус ESP остаётся пределом",
    "espBoxMaxMeters", CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters,
    CONFIG.EspRangeStepMeters, function(v) return tostring(v) .. " м" end)
addSlider(pages.ESP, "Дальность линий", "Трассеры от верхней части экрана к целям",
    "espTracerMaxMeters", CONFIG.EspRangeMinMeters, CONFIG.EspRangeMaxMeters,
    CONFIG.EspRangeStepMeters, function(v) return tostring(v) .. " м" end)
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
    if enabled then
        local held = aimPro.equippedTool()
        local message = "AIM: ON (активирован кнопкой)"
        if not held then
            if not aimPro.equipped then
                message = message .. " | Возьми Tool в руки"
            elseif state.aimOnlyRegisteredWeapons then
                message = message .. " | Запомни оружие либо отключи фильтр оружия"
            else
                message = message .. " | Подожди загрузки Tool/персонажа"
            end
        end
        tell(message)
    else
        tell("AIM: OFF")
    end
end)
-- Critical AIM fallback: an independent, permanently visible button outside
-- ScrollingFrame. The old row remains for backwards-compatible comparison.
-- This is deliberately NOT a second handler on the same TextButton.
do
    local aimDock = mk("Frame", {
        Name = "AimPinnedControlDock", BackgroundColor3 = P.panel,
        BackgroundTransparency = 0.08, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 50),
        ZIndex = 30, Active = false,
    }, pages.AIM)
    round(aimDock, 7)
    mk("UIStroke", {Color = P.border, Transparency = 0.45, Thickness = 1}, aimDock)
    local directButton = mk("TextButton", {
        Name = "AimPinnedSwitch", Position = UDim2.fromOffset(5, 5),
        Size = UDim2.new(1, -10, 0, 39),
        BackgroundColor3 = P.tile, BorderSizePixel = 0,
        AutoButtonColor = true, Active = true, Selectable = true,
        Text = "", TextColor3 = P.text, TextSize = 13,
        Font = Enum.Font.GothamBold, ZIndex = 31,
    }, aimDock)
    round(directButton, 9)
    local directOutline = mk("UIStroke", {
        Color = P.accent, Transparency = 0.74, Thickness = 1,
    }, directButton)
    local counter = {presses = 0, released = 0, activated = 0,
        rejected = 0, source = "ready", error = ""}
    boosterPro.pinnedAimClickDebug = counter
    local function repaintPinned()
        local enabled = state.aimbot == true
        directButton.Text = enabled
            and "AIM ON  •  ВЫКЛЮЧИТЬ"
            or "AIM OFF  •  ВКЛЮЧИТЬ"
        directButton.BackgroundColor3 = enabled and Color3.fromRGB(82, 55, 129)
            or Color3.fromRGB(44, 39, 63)
        directOutline.Transparency = enabled and 0.22 or 0.74
    end
    local previousAimUpdate = refreshToggles.aimbot
    refreshToggles.aimbot = function(...)
        if previousAimUpdate then previousAimUpdate(...) end
        repaintPinned()
    end
    repaintPinned()

    local serial, consumed = 0, -1
    local latestInput, pressedInput, pressedPosition = nil, nil, nil
    local pressAt, firedAt = -1e8, -1e8
    local function inDock(position)
        if not position or not alive or not gui.Enabled or not panel.Visible
            or not pages.AIM.Visible or not directButton.Visible
            or not directButton.Parent then return false end
        local at, sz = directButton.AbsolutePosition, directButton.AbsoluteSize
        return sz.X >= 30 and sz.Y >= 25
            and position.X >= at.X and position.X <= at.X + sz.X
            and position.Y >= at.Y and position.Y <= at.Y + sz.Y
    end
    local function hasInputPriority(position)
        local ok, hit = pcall(PlayerGui.GetGuiObjectsAtPosition,
            PlayerGui, position.X, position.Y)
        if not ok or type(hit) ~= "table" or #hit == 0 then
            return true
        end
        local first = hit[1]
        if first == directButton or first == aimDock then return true end
        local owns = false
        if first then
            local success, value = pcall(function()
                return first:IsDescendantOf(aimDock)
            end)
            owns = success and value == true
        end
        if not owns then
            counter.rejected = counter.rejected + 1
            counter.error = "Кнопку перекрывает " .. tostring(first and first.Name or "?")
        end
        return owns
    end
    local function switch(source, token)
        if not alive or not gui.Enabled or not panel.Visible
            or not pages.AIM.Visible or not directButton.Parent then return end
        local now = os.clock()
        if token ~= nil and token == consumed then return end
        if token == nil and now - firedAt < 0.16 then return end
        if token ~= nil then consumed = token end
        firedAt = now
        counter.presses = counter.presses + 1
        counter.source = source
        local desired = not state.aimbot
        local ok, err = pcall(setAimEnabled, desired, desired)
        if not ok then
            counter.error = tostring(err)
            tell("Ошибка AIM переключателя: " .. counter.error)
        else
            counter.error = ""
            repaintPinned()
            tell("AIM: " .. (state.aimbot and "ON" or "OFF")
                .. " | отдельная кнопка | " .. source)
        end
    end
    local function tokenFor(input)
        if input and input == latestInput then return serial end
        if not input and serial > 0 and os.clock() - pressAt < 0.16 then
            return serial
        end
        return nil
    end
    connect(directButton.Activated, function(input)
        if not allowTap(input) then return end
        counter.activated = counter.activated + 1
        switch("Activated", tokenFor(input))
    end)
    connect(directButton.MouseButton1Click, function()
        switch("MouseButton1Click", tokenFor(nil))
    end)
    -- Native events are preferred. Fallback supports the case where the
    -- Roblox GUI never raises Activated for the visibly pressed TextButton.
    connect(UserInputService.InputBegan, function(input)
        local kind = input.UserInputType
        if kind ~= Enum.UserInputType.MouseButton1
            and kind ~= Enum.UserInputType.Touch then return end
        if not inDock(input.Position) or not hasInputPriority(input.Position) then return end
        serial = serial + 1
        latestInput, pressedInput, pressedPosition = input, input, input.Position
        pressAt = os.clock()
    end)
    connect(UserInputService.InputEnded, function(input)
        if not pressedInput then return end
        local kind = pressedInput.UserInputType
        if input ~= pressedInput and not (kind == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1) then return end
        local before = pressedPosition
        pressedInput, pressedPosition = nil, nil
        if not inDock(input.Position) or not hasInputPriority(input.Position) then return end
        if before then
            local dx = input.Position.X - before.X
            local dy = input.Position.Y - before.Y
            if dx * dx + dy * dy > 144 then return end
        end
        counter.released = counter.released + 1
        switch("InputEnded", serial)
    end)
end

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
    aimPro.reset()
end)
addToggle(pages.AIM, "Visible Check", "ON: только видимые | OFF: через стены", "visibleCheck", function()
    aimPro.reset()
end)
addToggle(pages.AIM, "Target Lock", "Удерживать выбранную цель", "targetLock", function()
    aimPro.reset()
end)
addSection(pages.AIM, "ADVANCED", "Точность и упреждение")
addToggle(pages.AIM, "Prediction", "Упреждение движения персонажа", "prediction", function()
    aimPro.reset()
end)
addSlider(pages.AIM, "Упреждение", "Прогноз 0–0.25 секунды", "predictionSeconds", 0, 0.25, 0.01,
    function(v) return string.format("%.2f s", v) end,
    function() aimPro.reset() end)
addSlider(pages.AIM, "Скорость по горизонтали", "Множитель плавности X", "aimSmoothX", 1, 10, 1,
    function(v) return tostring(v) .. " / 10" end)
addSlider(pages.AIM, "Скорость по вертикали", "Множитель плавности Y", "aimSmoothY", 1, 10, 1,
    function(v) return tostring(v) .. " / 10" end)
addSection(pages.AIM, "FOV EDITOR", "Круг захвата отображается на экране")
addToggle(pages.AIM, "Показывать FOV", "Круг на экране при включённом AIM", "fovVisible", refreshFovRing)
addSlider(pages.AIM, "Радиус FOV", "40–400 пикселей, размер зоны захвата", "aimFovPixels",
    CONFIG.AimFovMinPixels, CONFIG.AimFovMaxPixels, 5,
    function(value) return tostring(value) .. " px" end,
    function() aimPro.reset(); refreshFovRing() end)
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
    function() aimPro.reset() end)
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
    local clicks = boosterPro.aimClickDebug
    if clicks then
        tell("AIM button | Нажатий: " .. tostring(clicks.presses)
            .. " | Activated: " .. tostring(clicks.activated)
            .. " | InputEnd: " .. tostring(clicks.recovered)
            .. " | Перекрытий: " .. tostring(clicks.blocked)
            .. " | Источник: " .. tostring(clicks.lastSource)
            .. " | Ошибка: " .. tostring(clicks.lastError))
    end
    local pinned = boosterPro.pinnedAimClickDebug
    if pinned then
        tell("AIM PINNED | Нажатий: " .. tostring(pinned.presses)
            .. " | GUI: " .. tostring(pinned.activated)
            .. " | Release: " .. tostring(pinned.released)
            .. " | Blocked: " .. tostring(pinned.rejected)
            .. " | Source: " .. tostring(pinned.source)
            .. " | Error: " .. tostring(pinned.error))
    end
end)

-- Один контроллер для Speed / Noclip / Fly: никаких вечных циклов.
-- Физика локальная; игровые серверы могут переопределять перемещение.
local movement = {
    character = nil, originalSpeed = nil, speedHumanoid = nil,
    originalAutoRotate = nil, flyHumanoid = nil, flyRoot = nil,
    attachment = nil, velocity = nil, orientation = nil,
    noclipCharacter = nil, noclipAdded = nil,
    collisionOriginals = setmetatable({}, {__mode = "k"}),
    pendingSpeeds = setmetatable({}, {__mode = "k"}),
    pendingAutoRotates = setmetatable({}, {__mode = "k"}),
    stepConnection = nil, lastSpeedApply = 0, lastAppliedSpeed = nil, lastErrorAt = 0,
    nextPassiveAt = 0, nextNoclipAt = 0, lastFlatForward = Vector3.new(0, 0, -1),
    lastFacing = nil,
}
boosterPro.movement = movement

-- Pending writes are independent of the active character: a failed Roblox
-- setter must never lose the previous humanoid's baseline on respawn/unload.
function movement.restoreSpeed()
    if movement.speedHumanoid and movement.originalSpeed ~= nil
        and movement.lastAppliedSpeed ~= nil then
        movement.pendingSpeeds[movement.speedHumanoid] = {
            original = movement.originalSpeed, last = movement.lastAppliedSpeed,
        }
    end
    movement.speedHumanoid, movement.originalSpeed, movement.lastAppliedSpeed = nil, nil, nil
    return movement.retrySpeeds()
end

function movement.retrySpeeds()
    local complete = true
    for humanoid, snapshot in pairs(movement.pendingSpeeds) do
        local readOK, current = pcall(function()
            if not humanoid.Parent then return nil end
            return humanoid.WalkSpeed
        end)
        if not readOK then
            complete = false
        elseif current == nil or current ~= snapshot.last then
            -- A newer game-owned value must not be overwritten.
            movement.pendingSpeeds[humanoid] = nil
        else
            -- Even a setter that mutates then throws is considered restored
            -- when readback confirms the original value.
            pcall(function() humanoid.WalkSpeed = snapshot.original end)
            local ok, after = pcall(function() return humanoid.WalkSpeed end)
            if ok and after == snapshot.original then
                movement.pendingSpeeds[humanoid] = nil
            elseif ok and after ~= snapshot.last then
                -- Another script took ownership or the engine clamped it.
                movement.pendingSpeeds[humanoid] = nil
            else
                complete = false
            end
        end
    end
    return complete
end

function movement.restoreCollision()
    if movement.noclipAdded then
        pcall(function() movement.noclipAdded:Disconnect() end)
        movement.noclipAdded = nil
    end
    local complete = true
    for part, original in pairs(movement.collisionOriginals) do
        local readOK, current = pcall(function()
            if not part.Parent then return nil end
            return part.CanCollide
        end)
        if not readOK then
            complete = false
        elseif current == nil or original == false or current == true then
            movement.collisionOriginals[part] = nil
        else
            -- Only restore false -> true if this feature originally changed it.
            pcall(function() part.CanCollide = true end)
            local ok, after = pcall(function() return part.CanCollide end)
            if ok and after == true then
                movement.collisionOriginals[part] = nil
            else
                complete = false
            end
        end
    end
    movement.noclipCharacter = nil
    movement.nextNoclipAt = 0
    return complete
end

function movement.pending()
    return movement.speedHumanoid ~= nil and movement.lastAppliedSpeed ~= nil
        or next(movement.pendingSpeeds) ~= nil
        or next(movement.collisionOriginals) ~= nil
        or next(movement.pendingAutoRotates) ~= nil
end

function movement.retryPending()
    -- Only invoke while Noclip is OFF: its active snapshots must stay intact.
    local speedOK = movement.retrySpeeds()
    local autoRotateOK = movement.retryAutoRotates()
    if not state.noclip then
        local collisionOK = movement.restoreCollision()
        return speedOK and autoRotateOK and collisionOK and not movement.pending()
    end
    return speedOK and autoRotateOK
end

-- A single protected/streaming BasePart must not disable Speed/Fly/Noclip.
-- Readback covers setters that mutate CanCollide and then throw an error.
function movement.recordPart(obj)
    if not obj:IsA("BasePart") then return true end
    local readOK, collides = pcall(function() return obj.CanCollide end)
    if not readOK then return false end
    if movement.collisionOriginals[obj] == nil then
        movement.collisionOriginals[obj] = collides
    end
    if collides then
        pcall(function() obj.CanCollide = false end)
        local checked, after = pcall(function() return obj.CanCollide end)
        return checked and after == false
    end
    return true
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

function movement.retryAutoRotates()
    local complete = true
    for humanoid, original in pairs(movement.pendingAutoRotates) do
        local readOK, current = pcall(function()
            if not humanoid.Parent then return nil end
            return humanoid.AutoRotate
        end)
        if not readOK then
            complete = false
        elseif current == nil or current == original or current ~= false then
            -- A newer game setting must be preserved.
            movement.pendingAutoRotates[humanoid] = nil
        else
            pcall(function() humanoid.AutoRotate = original end)
            local ok, after = pcall(function() return humanoid.AutoRotate end)
            if ok and after == original then
                movement.pendingAutoRotates[humanoid] = nil
            else
                complete = false
            end
        end
    end
    return complete
end

function movement.restoreFly()
    if movement.velocity then pcall(function() movement.velocity:Destroy() end) end
    if movement.orientation then pcall(function() movement.orientation:Destroy() end) end
    if movement.attachment then pcall(function() movement.attachment:Destroy() end) end
    movement.velocity, movement.orientation, movement.attachment = nil, nil, nil
    local humanoid = movement.flyHumanoid
    if humanoid and movement.originalAutoRotate ~= nil then
        movement.pendingAutoRotates[humanoid] = movement.originalAutoRotate
        -- Restore humanoid physics independently from the AutoRotate setter.
        pcall(function()
            if humanoid.Parent and humanoid.Health > 0 and not humanoid.Sit
                and humanoid.SeatPart == nil
                and humanoid:GetState() == Enum.HumanoidStateType.Physics then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
    movement.flyHumanoid, movement.flyRoot, movement.originalAutoRotate = nil, nil, nil
    movement.lastFacing = nil
    return movement.retryAutoRotates()
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
        movement.flyHumanoid, movement.flyRoot = humanoid, root
        humanoid.AutoRotate = false
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        movement.attachment, movement.velocity, movement.orientation =
            attachment, linear, align
    end)
    if not ok then
        for _, obj in ipairs(built) do pcall(function() obj:Destroy() end) end
        movement.restoreFly()
        -- If this second best-effort rollback also fails, retain the
        -- true preflight baseline for next worker/relaunch recovery.
        pcall(function()
            if humanoid.Parent then humanoid.AutoRotate = originalRotate end
        end)
        local restored = false
        pcall(function() restored = humanoid.AutoRotate == originalRotate end)
        if not restored then movement.pendingAutoRotates[humanoid] = originalRotate end
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
                -- Record intent BEFORE the setter: engine writes may mutate
                -- then throw, and shutdown must still know what to restore.
                movement.lastAppliedSpeed = state.speedValue
                humanoid.WalkSpeed = state.speedValue
                -- Some games clamp WalkSpeed without throwing.
                movement.lastAppliedSpeed = humanoid.WalkSpeed
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
                local existsOK, exists = pcall(function() return part.Parent ~= nil end)
                if not existsOK or not exists then
                    -- Drop destroyed parts rather than indefinitely retrying them.
                    movement.collisionOriginals[part] = nil
                else
                    -- Isolate rejected setters; a single accessory must never
                    -- turn off independent Speed/Fly controls.
                    movement.recordPart(part)
                end
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
    return movement.retryPending()
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
        .. " | Неудачные записи: " .. tostring(boosterPro.deniedWrites)
        .. " | Непроверенные записи: " .. tostring(boosterPro.unverifiedWrites)
        .. " | Ошибка: " .. errorText)
end)
addButton(pages.MEMORY, "Аудит ресурсов / восстановления",
    "Снимки графики, рабочие задачи, подписки и возможный незавершённый откат", function()
        tell(boosterPro.diagnosticStatus())
    end)
addButton(pages.MEMORY, "Самопроверка стабильности",
    "7 проверок текущего запущенного экземпляра, только чтение", function()
        local passed, total, failures = boosterPro.selfCheck()
        tell("STABILITY " .. tostring(passed) .. "/" .. tostring(total)
            .. (#failures > 0 and " | Ошибки: " .. table.concat(failures, ", ")
                or " | локальные инварианты в норме"))
    end)
addButton(pages.MEMORY, "Проверка адаптации UI 2.0",
    "Проверить реальные размеры, вкладки и кнопки на текущем экране", function()
        local ok, result = pcall(function()
            return boosterPro.uiAudit and boosterPro.uiAudit()
                or "UI audit ещё не инициализирован"
        end)
        tell(ok and result or ("UI AUDIT ERROR: " .. tostring(result)))
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
        local soundService = game:GetService("SoundService")
        -- Roblox can destroy/reparent our Sound while a saved ID remains.
        -- Never reuse an unparented or externally replaced audio instance.
        if privateMusic.sound and (privateMusic.currentId ~= id
            or privateMusic.sound.Parent ~= soundService) then
            privateMusic.stop()
        end
        local sound = privateMusic.sound
        if not sound then
            sound = Instance.new("Sound")
            privateMusic.sound, privateMusic.currentId = sound, id
            sound.Name = "Army124Visuals_LocalMusic"
            sound.SoundId = "rbxassetid://" .. id
            sound.Volume = math.clamp(state.musicVolume / 100, 0, 1)
            sound.Looped = state.musicLoop == true
            sound.Parent = soundService
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


-- PLAYER TAB: avatar-only particles / glow + camera-local weather and color grading.
addSection(pages.PLAYER, "PLAYER AURA", "Мягкие частицы вокруг собственного персонажа")
addToggle(pages.PLAYER, "Аура тела", "Локальное сияние без изменения персонажа на сервере",
    "playerAuraEnabled", function() playerFX.syncAvatar() end)
addSlider(pages.PLAYER, "Интенсивность ауры", "Объём, искры и свет · 1–5",
    "playerGlowPower", 1, 5, 1, function(v) return tostring(v) .. " / 5" end,
    function() playerFX.syncAvatar() end)
addChoice(pages.PLAYER, "Цвет ауры и свечения", {
    {value = "PURPLE", label = "PURPLE"},
    {value = "CYAN", label = "CYAN"},
    {value = "GOLD", label = "GOLD"},
    {value = "GREEN", label = "GREEN"},
}, "playerAuraColor", function() playerFX.syncAvatar() end)
addChoice(pages.PLAYER, "Качество эффектов", {
    {value = "AUTO", label = "AUTO"},
    {value = "ECO", label = "ECO"},
    {value = "ULTRA", label = "ULTRA"},
}, "playerAuraQuality", function() playerFX.syncAvatar() end)

addSection(pages.PLAYER, "PLAYER GLOW", "Контур и PointLight только у своего тела")
addToggle(pages.PLAYER, "Свечение тела", "Контур + мягкий локальный свет, без замены материалов",
    "playerGlowEnabled", function() playerFX.syncAvatar() end)
addToggle(pages.PLAYER, "Пульсация сияния", "Плавное дыхание контура и света · без постоянного RenderStep",
    "playerGlowPulse", function() playerFX.syncAvatar() end)

addSection(pages.PLAYER, "LOCAL WEATHER", "Клиентская погода · туман, дождь, ночной фильтр")
addToggle(pages.PLAYER, "Изменить погоду", "Включить погоду. CLEAR при первом запуске станет FOG",
    "playerWeatherEnabled", function(enabled)
        local previousMode = state.playerWeatherMode
        if enabled and previousMode == "CLEAR" then
            state.playerWeatherMode = "FOG"
        end
        local ok, err = pcall(playerFX.syncWeather)
        if not ok then
            state.playerWeatherMode = previousMode
            error(err)
        end
        if refreshChoices.playerWeatherMode then refreshChoices.playerWeatherMode() end
        tell(enabled and ("Погода: " .. state.playerWeatherMode
            .. (playerFX.weatherFallback and " (локальный фильтр: Atmosphere недоступна)" or ""))
            or "Погода: CLEAR / OFF")
    end)
addChoice(pages.PLAYER, "Пресет погоды", {
    {value = "CLEAR", label = "CLEAR"},
    {value = "FOG", label = "FOG"},
    {value = "RAIN", label = "RAIN"},
    {value = "NIGHT", label = "NIGHT"},
}, "playerWeatherMode", function(mode)
    -- A mode choice is a real action, not a hidden preference behind another
    -- OFF toggle. Choosing CLEAR restores the game's weather immediately.
    local previousEnabled = state.playerWeatherEnabled
    state.playerWeatherEnabled = mode ~= "CLEAR"
    local ok, err = pcall(playerFX.syncWeather)
    if not ok then
        state.playerWeatherEnabled = previousEnabled
        error(err)
    end
    if refreshToggles.playerWeatherEnabled then refreshToggles.playerWeatherEnabled() end
    tell(mode == "CLEAR" and "Погода: исходная / OFF"
        or ("Погода: " .. mode
            .. (playerFX.weatherFallback and " (локальный фильтр)" or "")))
end)

addSection(pages.PLAYER, "ENVIRONMENT COLOR", "Тон окружения, не меняет детали карты")
addToggle(pages.PLAYER, "Цвет окружения", "Собственный ColorCorrectionEffect без репликации",
    "playerEnvironmentEnabled", function() playerFX.syncEnvironment() end)
addChoice(pages.PLAYER, "Оттенок мира", {
    {value = "VIOLET", label = "VIOLET"},
    {value = "CYAN", label = "CYAN"},
    {value = "WARM", label = "WARM"},
    {value = "GREEN", label = "GREEN"},
}, "playerEnvironmentColor", function() playerFX.syncEnvironment() end)
addSlider(pages.PLAYER, "Насыщенность оттенка", "От нейтрального до выбранного цвета, 0–100%",
    "playerEnvironmentStrength", 0, 100, 5,
    function(v) return tostring(v) .. "%" end,
    function() playerFX.syncEnvironment() end)
addButton(pages.PLAYER, "Выключить эффекты Player",
    "Отключить ауру, свечение, погоду и вернуть исходные значения Fog", function()
        state.playerAuraEnabled = false
        state.playerGlowEnabled = false
        state.playerWeatherEnabled = false
        state.playerEnvironmentEnabled = false
        playerFX.sync()
        for _, key in ipairs({
            "playerAuraEnabled", "playerGlowEnabled",
            "playerWeatherEnabled", "playerEnvironmentEnabled",
        }) do
            if refreshToggles[key] then refreshToggles[key]() end
        end
        requestSave()
        tell("Player: локальные эффекты отключены")
    end)
addButton(pages.PLAYER, "Диагностика Player FX",
    "Только локальные объекты, режим погоды и состояние отката", function()
        tell("Player 2.0 | " .. playerFX.diagnostics())
    end)

