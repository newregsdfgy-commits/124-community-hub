addSection(pages.MISC, "WEAPONS 2.0", "Локальная совместимость, диагностика и откат значений")
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
            local touched = recoil.safeApplySpread()
            local report = recoil.diagnostics()
            tell(touched > 0 and ("No Spread: локальных записей: " .. tostring(touched)
                    .. " (эффект в игре не подтверждён)")
                or ("No Spread: " .. report.spreadStatus))
        else
            local restored = recoil.restoreSpread()
            tell(restored and "No Spread: локальные параметры восстановлены"
                or "No Spread: восстановление не завершено; снимки сохранены для повтора")
        end
end)
addButton(pages.MISC, "Диагностика Weapons 2.0", "Tool, ввод, кадры, параметры, ошибки и откат", function()
    local d = recoil.diagnostics()
    tell("Weapons 2.0 | " .. tostring(d.tool) .. " | Spread: "
        .. tostring(d.numericParameters + d.attributeParameters)
        .. " параметров | Pulses: " .. tostring(d.shotPulses)
        .. " | Ошибки: " .. tostring(d.errors))
    print("[124 Weapons 2.0] Tool=" .. tostring(d.tool)
        .. " | Recoil=" .. d.recoilMode .. " | " .. d.recoilStatus
        .. " | correctionFrames=" .. tostring(d.recoilCorrections)
        .. " | lastCorrection=" .. string.format("%.2f", d.lastCorrectionDegrees)
        .. " | inputs=" .. tostring(d.inputSignals.tool) .. "/"
            .. tostring(d.inputSignals.mouse) .. "/"
            .. tostring(d.inputSignals.touch) .. "/"
            .. tostring(d.inputSignals.gamepad)
        .. " (Tool/Mouse/Touch/Gamepad)"
        .. " | Spread=" .. d.spreadStatus
        .. " | indexed=" .. tostring(d.candidates)
        .. " | numeric=" .. tostring(d.numericParameters)
        .. " | attrs=" .. tostring(d.attributeParameters)
        .. " | writes=" .. tostring(d.writes)
        .. " | checks=" .. tostring(d.checks)
        .. " | errors=" .. tostring(d.errors)
        .. " | restoreFailures=" .. tostring(d.restoreFailures)
        .. " | pendingRestore=" .. tostring(d.pendingRestore)
        .. " | lastError=" .. tostring(d.lastError))
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

-- v1.4.2: retired experimental screenshot-only menu.
-- Its search/Ready/timer/Active controls were parented directly to the global
-- DragBar even while the screenshot ESP pane was hidden. They obscured the
-- genuine header and reparented close/minimize into unrelated sidebar slots.
-- Native ESP controls are in 08_ui_controls.lua and remain fully functional.
-- referenceESP deliberately stays nil; its optional legacy hooks are inert.

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
                boosterPro.workers.repair = boosterPro.workers.repair + 1
                local ok, result = pcall(function()
                    return (state.boosterMode == "BALANCED"
                        or optimizeHierarchy(Workspace, repairRevision))
                        and optimizeHierarchy(Lighting, repairRevision)
                end)
                boosterPro.workers.repair = math.max(0, boosterPro.workers.repair - 1)
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
    local complete = next(savedGraphics) == nil
    boosterPro.lastRestoredAt = os.clock()
    boosterPro.lastRestoredComplete = complete
    return complete
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
        state.playerAuraEnabled, state.playerGlowEnabled = false, false
        state.playerWeatherEnabled, state.playerEnvironmentEnabled = false, false
        CONFIG.PlaceCache.safeBoot = true
        -- Legacy flag consumed once by migration; older versions remain safe.
        if game.PlaceId == CONFIG.OriginalPlaceId then env.ARMY124_SAFE_BOOT = true end
    end
    pcall(flushConfig)
    -- Stop new work *before* any yield, Terrain writes or graphics rollback.
    alive = false
    -- Отключаем старый экземпляр до каких-либо ожидающих task.wait().
    boosterPro.cleanupStartedAt = os.clock()
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
    state.playerAuraEnabled, state.playerGlowEnabled = false, false
    state.playerWeatherEnabled, state.playerEnvironmentEnabled = false, false
    aimHeldKey = false
    captureAimKey = false
    boosterRevision = boosterRevision + 1
    table.clear(boosterPro.protectedRestoreQueue)
    table.clear(boosterPro.protectedRestoreSeen)

    -- Player FX owns only our local objects; restore Fog before recovery checks.
    local playerFxOk, playerFxRestored = pcall(playerFX.shutdown)
    if not playerFxOk or playerFxRestored ~= true then
        warn("[124 Visuals] Player FX: fog restore pending; recovery saved")
    end
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
        or next(memoryFX.spin.pending) ~= nil or recoil.spread.pending()
        or playerFX.pending() then
        local previousRecovery = env.ARMY124_RECOVERY
        local pendingRecovery
        pendingRecovery = function()
            local oldDone = true
            if type(previousRecovery) == "function" then
                local ok, result = pcall(previousRecovery)
                oldDone = ok and result == true
            end
            local lightingOK = pcall(applyLighting)
            local weatherOK, weatherRestored = pcall(playerFX.restoreWeather)
            local grassOK = not savedTerrainDecoration or pcall(restoreTerrainGrass)
            local colorsOK = not savedTerrainColors or pcall(restoreTerrainColors)
            local graphicsOK = pcall(boosterPro.restoreGraphicsSliced)
            local cameraOK = pcall(memoryFX.camera.reset)
            local spinOK = pcall(memoryFX.spin.restorePending)
            local spreadOK, spreadRestored = pcall(recoil.restoreSpread)
            local done = lightingOK and weatherOK and weatherRestored == true
                and grassOK and colorsOK and graphicsOK
                and cameraOK and spinOK and spreadOK and spreadRestored == true
                and not (savedLighting or savedTerrainDecoration or savedTerrainColors)
                and next(savedGraphics) == nil
                and next(memoryFX.camera.saved) == nil
                and next(memoryFX.spin.pending) == nil
                and not recoil.spread.pending() and not playerFX.pending()
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

