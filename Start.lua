-- 124 Visuals / serialized key-gate launcher (payload v1.1.65)
-- Второй запуск Start.lua не уничтожает уже открытую форму ключа.
local launchEnv = _G
if type(getgenv) == "function" then
    local okEnv, got = pcall(getgenv)
    if okEnv and type(got) == "table" then launchEnv = got end
end
if launchEnv.ARMY124_START_RUNNING == true then
    warn("[124 START] Ключевой экран уже открыт. Завершите или закройте предыдущий запуск.")
    return false
end
launchEnv.ARMY124_START_RUNNING = true
local function runLauncher()
-- Ошибка прошлой попытки не должна перекрывать окно ключа.
pcall(function()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
    local old = playerGui and playerGui:FindFirstChild("Army124StartupError")
    if old then old:Destroy() end
end)
-- 124 Visuals / v1.1.65 audited key-gated launcher
local url = "https://raw.githubusercontent.com/newregsdfgy-commits/124-community-hub/v1.1.65-purple-neon-ui-test/Visuals.lua"
local function failure(stage, reason)
    local text = "[124 START / " .. tostring(stage) .. "] " .. tostring(reason)
    warn(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "124 / загрузка", Text = text:sub(1, 180), Duration = 15
        })
    end)
    return false
end
local fetched, source = pcall(function() return game:HttpGet(url) end)
if not fetched then return failure("NETWORK", source) end
if type(source) ~= "string" or #source < 100000 then
    return failure("DOWNLOAD", "Неполный Lua: " .. tostring(type(source) == "string" and #source or type(source)))
end
if not source:find('Version = "1.1.65"', 1, true) then
    return failure("VERSION", "Вместо v1.1.65 GitHub вернул другую версию")
end
-- Проверяем наличие основного экрана допуска до исполнения Lua.
-- Это проверка целостности сборки, не серверная защита от редактирования.
if not source:find('local ACCESS_KEY = "124HUB"', 1, true) then
    return failure("KEY-GATE", "В загруженном исходнике отсутствует ключевая система")
end
if type(loadstring) ~= "function" then
    return failure("EXECUTOR", "loadstring отсутствует")
end
-- Some executor implementations throw instead of returning nil on parse errors.
local compiled, chunk, compileError = pcall(loadstring, source)
if not compiled then return failure("COMPILE", chunk) end
if type(chunk) ~= "function" then
    return failure("COMPILE", compileError or "Компилятор не вернул функцию")
end
local env = _G
if type(getgenv) == "function" then
    local ok, globals = pcall(getgenv)
    if ok and type(globals) == "table" then env = globals end
end
env.ARMY124_BOOT_PHASE = "launching"
env.ARMY124_BOOT_ERROR = nil
local ok, runError = xpcall(chunk, function(err)
    local message = tostring(err)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        local good, trace = pcall(debug.traceback, message, 2)
        if good and type(trace) == "string" then return trace end
    end
    return message
end)
if not ok then return failure("RUNTIME", runError) end
-- Закрытие окна ключа — обычный отказ от запуска, не runtime-ошибка.
if env.ARMY124_BOOT_PHASE == "key_denied"
    and env.ARMY124_BOOT_ERROR == "Ключ не введён" then
    return false
end
if env.ARMY124_BOOT_PHASE ~= "ready" then
    return failure(env.ARMY124_BOOT_PHASE or "UNKNOWN",
        env.ARMY124_BOOT_ERROR or "GUI не подтвердил запуск. Проверь PlayerGui и Output.")
end
print("[124 START] v1.1.65 GUI ready")
return true

end
local wrapperOK, wrapperResult = xpcall(runLauncher, function(reason)
    local message = tostring(reason)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        local okTrace, trace = pcall(debug.traceback, message, 2)
        if okTrace and type(trace) == "string" then return trace end
    end
    return message
end)
-- Mutex очищается и после ошибки, и после отмены пользователем.
launchEnv.ARMY124_START_RUNNING = nil
if not wrapperOK then
    warn("[124 START / WRAPPER] " .. tostring(wrapperResult))
    return false
end
return wrapperResult
