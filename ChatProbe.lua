-- 124 Community Visuals v1.1.24 / CUSTOM CHAT AUDIT (on-screen)
-- Does not send chat messages or invoke remotes; only owns its report panel.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
if not player then warn("[CHAT AUDIT] LocalPlayer missing"); return end
local gui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
if not gui then warn("[CHAT AUDIT] PlayerGui missing"); return end
-- Dedicated in-game report: external Xeno console doesn't always display Luau prints.
local previousPanel = gui:FindFirstChild("Army124ChatAuditPanel")
if previousPanel then previousPanel:Destroy() end
local panelGui = Instance.new("ScreenGui")
panelGui.Name = "Army124ChatAuditPanel"
panelGui.ResetOnSpawn = false
panelGui.IgnoreGuiInset = false
panelGui.DisplayOrder = 20000
panelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local window = Instance.new("Frame")
window.Name = "AuditWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.new(0.94, 0, 0.82, 0)
window.BackgroundColor3 = Color3.fromRGB(22, 27, 32)
window.BorderSizePixel = 0
window.Parent = panelGui
local widthLimit = Instance.new("UISizeConstraint")
widthLimit.MinSize = Vector2.new(250, 205)
widthLimit.MaxSize = Vector2.new(620, 560)
widthLimit.Parent = window
local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Color3.fromRGB(77, 87, 96)
windowStroke.Thickness = 1
windowStroke.Parent = window
local title = Instance.new("TextLabel")
title.Name = "AuditTitle"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(13, 7)
title.Size = UDim2.new(1, -26, 0, 24)
title.Text = "124 / CHAT AUDIT   |   ЗАГРУЗКА..."
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(223, 227, 231)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = window
local instructions = Instance.new("TextLabel")
instructions.BackgroundTransparency = 1
instructions.Position = UDim2.fromOffset(13, 31)
instructions.Size = UDim2.new(1, -26, 0, 20)
instructions.Text = "Только чтение. Сообщения не отправляются."
instructions.TextSize = 11
instructions.Font = Enum.Font.Gotham
instructions.TextColor3 = Color3.fromRGB(150, 161, 172)
instructions.TextXAlignment = Enum.TextXAlignment.Left
instructions.Parent = window
local scroller = Instance.new("ScrollingFrame")
scroller.Name = "AuditResults"
scroller.BackgroundColor3 = Color3.fromRGB(15, 18, 21)
scroller.BorderSizePixel = 0
scroller.Position = UDim2.fromOffset(12, 58)
scroller.Size = UDim2.new(1, -24, 1, -112)
scroller.ScrollBarThickness = 5
scroller.ScrollingDirection = Enum.ScrollingDirection.Y
scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
scroller.Parent = window
local outputLabel = Instance.new("TextLabel")
outputLabel.Name = "ReportText"
outputLabel.BackgroundTransparency = 1
outputLabel.Position = UDim2.fromOffset(8, 8)
outputLabel.Size = UDim2.new(1, -24, 0, 0)
outputLabel.AutomaticSize = Enum.AutomaticSize.Y
outputLabel.Text = "[CHAT AUDIT] Считываю настройки и интерфейс игры..."
outputLabel.TextColor3 = Color3.fromRGB(221, 226, 230)
outputLabel.Font = Enum.Font.Code
outputLabel.TextSize = 12
outputLabel.TextWrapped = true
outputLabel.TextXAlignment = Enum.TextXAlignment.Left
outputLabel.TextYAlignment = Enum.TextYAlignment.Top
outputLabel.Parent = scroller
local copy = Instance.new("TextButton")
copy.Name = "CopyReport"
copy.Position = UDim2.new(0, 12, 1, -45)
copy.Size = UDim2.new(0.55, -16, 0, 34)
copy.Text = "СКОПИРОВАТЬ ОТЧЁТ"
copy.Font = Enum.Font.GothamMedium
copy.TextSize = 11
copy.TextColor3 = Color3.fromRGB(242, 242, 242)
copy.BackgroundColor3 = Color3.fromRGB(56, 67, 76)
copy.BorderSizePixel = 0
copy.Parent = window
local close = Instance.new("TextButton")
close.Name = "CloseAudit"
close.Position = UDim2.new(0.55, 2, 1, -45)
close.Size = UDim2.new(0.45, -14, 0, 34)
close.Text = "ЗАКРЫТЬ"
close.Font = Enum.Font.GothamMedium
close.TextSize = 11
close.TextColor3 = Color3.fromRGB(236, 237, 239)
close.BackgroundColor3 = Color3.fromRGB(46, 51, 57)
close.BorderSizePixel = 0
close.Parent = window
local reportOutput = ""
close.Activated:Connect(function() panelGui:Destroy() end)
copy.Activated:Connect(function()
    if type(setclipboard) ~= "function" then
        instructions.Text = "Нет функции копирования. Сделай скриншот окна."
        return
    end
    local ok = pcall(setclipboard, reportOutput)
    instructions.Text = ok and "Отчёт скопирован." or
        "Не получилось скопировать. Сделай скриншот."
end)
panelGui.Parent = gui

local report = {}
local function line(text)
    report[#report + 1] = "[CHAT AUDIT] " .. tostring(text)
end
local function short(text, limit)
    local value = tostring(text or ""):gsub("[\r\n]", " ")
    return #value > (limit or 80) and (value:sub(1, limit or 80) .. "...") or value
end
local function pathUnder(obj, root)
    local parts = {}
    while obj and obj ~= root and #parts < 7 do
        table.insert(parts, 1, short(obj.Name, 42))
        obj = obj.Parent
    end
    return table.concat(parts, "/")
end

line("START v1.1.24 / PlaceId " .. tostring(game.PlaceId))
local permissionOK, canChat = pcall(function()
    return TextChatService:CanUserChatAsync(player.UserId)
end)
line("Roblox CanUserChatAsync: " ..
    (permissionOK and tostring(canChat) or ("unavailable: " .. short(canChat, 120))))
local channels = TextChatService:FindFirstChild("TextChannels")
local available = 0
if channels then
    for _, child in ipairs(channels:GetChildren()) do
        if child:IsA("TextChannel") then
            local localSource = nil
            for _, member in ipairs(child:GetChildren()) do
                if member:IsA("TextSource") and member.UserId == player.UserId then
                    localSource = member
                    break
                end
            end
            local sendable = false
            if localSource then
                local ok, value = pcall(function() return localSource.CanSend end)
                sendable = ok and value == true
            end
            available = available + 1
            line("TextChannel #" .. tostring(available) .. " " .. short(child.Name, 70)
                .. " / own membership=" .. tostring(localSource ~= nil)
                .. " / CanSend=" .. tostring(sendable))
        end
    end
else
    line("TextChatService.TextChannels: absent")
end
if available == 0 then line("No native TextChannels visible") end

local roots = 0
for _, child in ipairs(gui:GetChildren()) do
    if child:IsA("ScreenGui") and
        (child.Name:lower():find("chat", 1, true) or child.Name:lower():find("message", 1, true)) then
        roots = roots + 1
        line("Chat-related ScreenGui: " .. short(child.Name, 90)
            .. " / Enabled=" .. tostring(child.Enabled))
    end
end
line("Chat-like ScreenGui roots: " .. tostring(roots))

local textBoxes, tabs, UIcount = 0, 0, 0
for _, obj in ipairs(gui:GetDescendants()) do
    UIcount = UIcount + 1
    if obj:IsA("TextBox") and textBoxes < 20 then
        textBoxes = textBoxes + 1
        -- Never read or log TextBox.Text or other players' message content.
        line("TextBox #" .. tostring(textBoxes) .. " " .. pathUnder(obj, gui)
            .. " / Visible=" .. tostring(obj.Visible)
            .. " / Placeholder=" .. short(obj.PlaceholderText, 66))
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local ok, label = pcall(function() return obj.Text end)
        if ok and type(label) == "string" then
            local matches = label == "Here" or label == "КОНТРАБАНДИСТЫ"
                or label:find("chat settings prevent", 1, true)
            if matches and tabs < 12 then
                tabs = tabs + 1
                line("Known chat UI marker #" .. tostring(tabs) .. ": "
                    .. pathUnder(obj, gui) .. " / Visible=" .. tostring(obj.Visible))
            end
        end
    end
end
line("PlayerGui descendants scanned: " .. tostring(UIcount)
    .. "; text inputs found: " .. tostring(textBoxes)
    .. "; known tab markers: " .. tostring(tabs))

-- Remote discovery is read-only. A matching name does not prove a chat API.
local remoteNames, remoteCount = {}, 0
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        local name = obj.Name:lower()
        if name:find("chat", 1, true) or name:find("message", 1, true)
            or name:find("send", 1, true) then
            remoteCount = remoteCount + 1
            if #remoteNames < 16 then
                remoteNames[#remoteNames + 1] = pathUnder(obj, ReplicatedStorage)
            end
        end
    end
end
line("ReplicatedStorage chat-related remote names: " .. tostring(remoteCount))
for _, name in ipairs(remoteNames) do line("Candidate (not invoked): " .. name) end
line("END / No messages sent; no game state changed.")
local output = table.concat(report, "\n")
local env = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then env = result end
end
env.ARMY124_CHAT_AUDIT = output
reportOutput = output
if panelGui.Parent and outputLabel.Parent then
    outputLabel.Text = output
    title.Text = "124 / CHAT AUDIT   |   ГОТОВО"
end
print(output)
print("[CHAT AUDIT] Copy console output, or run: print(getgenv().ARMY124_CHAT_AUDIT)")
return output
