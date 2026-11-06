-- 124 Community Visuals / verified v1.1.39 launcher
local url = "https://raw.githubusercontent.com/newregsdfgy-commits/124-community-hub/v1.1.39-lite-performance-test/Visuals.lua"
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
if not source:find('Version = "1.1.39"', 1, true) then
    return failure("VERSION", "Вместо v1.1.39 GitHub вернул другую версию")
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
if env.ARMY124_BOOT_PHASE ~= "ready" then
    return failure(env.ARMY124_BOOT_PHASE or "UNKNOWN",
        env.ARMY124_BOOT_ERROR or "GUI не подтвердил запуск. Проверь PlaceId и PlayerGui.")
end
print("[124 START] v1.1.39 GUI ready")
return true
