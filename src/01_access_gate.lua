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
            TextSize = 16,
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
            Text = "Локальный ключ · максимум 5 ошибок",
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
            Text = "Закрыть (подтверждение)",
            TextSize = 13,
            TextColor3 = Color3.fromRGB(174, 168, 188),
        }, panel)

        local response = Instance.new("BindableEvent")
        local completed, wrongCount = false, 0
        local blockedUntil, lastSubmitAt = 0, -math.huge
        local cancelArmedAt = -math.huge
        local function resolve(accepted)
            if completed then return end
            completed = true
            response:Fire(accepted)
        end
        local function tryUnlock()
            if completed then return end
            local now = os.clock()
            -- Return и FocusLost могут срабатывать одновременно на Android.
            if now - lastSubmitAt < CONFIG.KeySubmitDedupSeconds then return end
            lastSubmitAt = now
            if now < blockedUntil then
                message.Text = "Повтори через " .. tostring(math.ceil(blockedUntil - now)) .. " сек."
                return
            end
            local candidate = input.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if candidate == "" then
                message.Text = "Введи ключ перед проверкой"
                return
            end
            input.Text = ""
            if candidate == ACCESS_KEY then resolve(true); return end
            wrongCount = wrongCount + 1
            local remaining = math.max(0, CONFIG.KeyMaxWrongAttempts - wrongCount)
            message.TextColor3 = Color3.fromRGB(255, 130, 148)
            if remaining == 0 then
                blockedUntil = now + CONFIG.KeyLocalCooldownSeconds
                message.Text = "Лимит попыток · " .. tostring(CONFIG.KeyLocalCooldownSeconds)
                    .. " сек. до повтора"
                submit.Active, submit.AutoButtonColor = false, false
                task.delay(CONFIG.KeyLocalCooldownSeconds, function()
                    if completed or not screen.Parent then return end
                    wrongCount, blockedUntil = 0, 0
                    submit.Active, submit.AutoButtonColor = true, true
                    message.TextColor3 = Color3.fromRGB(164, 148, 199)
                    message.Text = "Доступно попыток: " .. tostring(CONFIG.KeyMaxWrongAttempts)
                end)
            else
                message.Text = "Неверный ключ · осталось попыток: " .. tostring(remaining)
            end
        end
        submit.Activated:Connect(tryUnlock)
        local function moveForKeyboard(focused)
            if not UserInputService.TouchEnabled then return end
            local y = focused and 0.31 or 0.43
            panel.Position = UDim2.fromScale(0.5, y)
            shadow.Position = UDim2.fromScale(0.5, y)
        end
        input.Focused:Connect(function() moveForKeyboard(true) end)
        input.FocusLost:Connect(function(enterPressed)
            moveForKeyboard(false)
            if enterPressed then tryUnlock() end
        end)
        pcall(function()
            input.ReturnPressedFromOnScreenKeyboard:Connect(tryUnlock)
        end)
        cancel.Activated:Connect(function()
            if completed then return end
            local now = os.clock()
            if now - cancelArmedAt <= CONFIG.KeyCloseConfirmSeconds then
                resolve(false)
            else
                cancelArmedAt = now
                cancel.Text = "НАЖМИ ЕЩЁ РАЗ ДЛЯ ЗАКРЫТИЯ"
                message.Text = "Второе нажатие подтвердит закрытие"
            end
        end)
        -- Внешнее уничтожение GUI завершает ожидание, но НЕ открывает доступ.
        screen.Destroying:Connect(function() resolve(false) end)

        local accepted = response.Event:Wait()
        if screen.Parent then screen:Destroy() end
        response:Destroy()
        return accepted == true
    end

    env.ARMY124_BOOT_PHASE = "key_required"
    local ok, accepted = pcall(requireAccessKey)
    -- Если ключ проверял старый экземпляр, он не владеет состоянием нового.
    if env.ARMY124_BOOT_TOKEN ~= CONFIG.BootToken then return CONFIG.BootToken end
    if gateScreen and gateScreen.Parent then
        -- Если создание UI завершилось исключением, подложка не останется в PlayerGui.
        pcall(function() gateScreen:Destroy() end)
    end
    gateScreen = nil
    if not ok or not accepted then
        env.ARMY124_BOOT_PHASE = "key_denied"
        env.ARMY124_BOOT_ERROR = ok and "Ключ не введён" or "Экран ключа: " .. tostring(accepted)
        if not ok then warn("[124 Access] " .. tostring(accepted)) end
        return CONFIG.BootToken
    end
    env.ARMY124_BOOT_PHASE = "authorized"
    env.ARMY124_BOOT_ERROR = nil
end

