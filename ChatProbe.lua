-- 124 Community Visuals v1.1.24 / CUSTOM CHAT AUDIT (read-only)
-- Does not send chat messages, interact with remotes or modify game UI.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
if not player then warn("[CHAT AUDIT] LocalPlayer missing"); return end
local gui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
if not gui then warn("[CHAT AUDIT] PlayerGui missing"); return end
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
print(output)
print("[CHAT AUDIT] Copy console output, or run: print(getgenv().ARMY124_CHAT_AUDIT)")
return output
