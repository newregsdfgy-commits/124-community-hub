"use strict";
const fs = require("node:fs");
const assert = require("node:assert/strict");
const source = fs.readFileSync("Visuals.lua", "utf8");
function extract(start, end) {
 const a = source.indexOf(start);
 const b = source.indexOf(end, a + start.length);
 assert.ok(a >= 0 && b > a, "Luau extraction missing: " + start);
 return source.slice(a, b).trim();
}
const mk = extract("local function mk(class, properties, parent)", "local function round(instance, radius)");
const queue = extract("local function queueESPRefresh()", "local function isEspPart(obj)");
const objectRestore = extract("function boosterPro.restoreObject(obj, snapshot)", "-- Снимки могли появиться раньше");
const graphicsRestore = extract("function boosterPro.restoreGraphicsSliced(expectedRevision)", "cleanup = function(safeStop)");
const settingsGuard = extract("local function applySettingsGuard(action)", "local function applySettings(incoming, autoLoad)");
const program = `
-- Pure Luau execution of actual extracted Visuals.lua functions.
-- Roblox API objects are mocked; real engine behavior is NOT simulated.
local boosterPro = {bootRoots = {}}
local PlayerGui = {}
local all = {}
local Instance = {}
Instance.new = function(class)
    local obj = {className = class, destroyed = false}
    function obj:Destroy()
        self.destroyed = true
    end
    setmetatable(obj, {__newindex = function(self, key, value)
        if key == "Broken" or (key == "Parent" and value == "INVALID") then
            error("forced setter failure")
        end
        rawset(self, key, value)
    end})
    table.insert(all, obj)
    return obj
end
${mk}
local ok1 = pcall(function() mk("TextLabel", {Broken = true}, PlayerGui) end)
assert(not ok1 and all[#all].destroyed, "failed setter leaked an object")
local ok2 = pcall(function() mk("Frame", {Name = "ok"}, "INVALID") end)
assert(not ok2 and all[#all].destroyed, "failed Parent assignment leaked an object")
local screen = mk("ScreenGui", {Name = "Owned"}, PlayerGui)
assert(screen.Parent == PlayerGui and boosterPro.bootRoots[1] == screen)
local ordinary = mk("Frame", {Name = "Child"}, screen)
assert(ordinary.Parent == screen and #boosterPro.bootRoots == 1)
print("LUAU AUDIT PASS: constructor failure destroys partial Instances")

local CONFIG = {EspEventMinSeconds = 0.18}
local state = {esp = true}
local alive = true
local perfCounters = {espVisual = {lastScanAt = os.clock()}}
local espRefreshQueued = false
local espRefreshGeneration = 0
local scheduled = {}
local task = {
    delay = function(delaySeconds, cb)
        table.insert(scheduled, {delay = delaySeconds, cb = cb})
    end
}
local scans = 0
local function refreshESP() scans = scans + 1 end
${queue}
queueESPRefresh()
queueESPRefresh()
assert(#scheduled == 1, "duplicated scheduled event scan")
assert(scheduled[1].delay >= 0.06 and scheduled[1].delay <= 0.25)
local old = scheduled[1].cb
state.esp = false
espRefreshGeneration = espRefreshGeneration + 1
espRefreshQueued = false
state.esp = true
old()
assert(scans == 0, "old scan ran after feature was toggled")
queueESPRefresh()
assert(#scheduled == 2)
scheduled[2].cb()
assert(scans == 0, "event scan duplicated a recent periodic scan")
assert(espRefreshQueued == false)
perfCounters.espVisual.lastScanAt = os.clock() - 1
queueESPRefresh()
assert(#scheduled == 3)
scheduled[3].cb()
assert(scans == 1, "new event scan did not run after quiet interval")
assert(espRefreshQueued == false)
print("LUAU AUDIT PASS: queued ESP scans are coalesced and revocable")

do
    local restoring = false
    ${settingsGuard}
    local okFail, why = applySettingsGuard(function() error("forced profile failure") end)
    assert(not okFail and restoring == false)
    assert(string.find(tostring(why), "forced profile failure", 1, true))
    local okSuccess = applySettingsGuard(function() return true end)
    assert(okSuccess and restoring == false)
    print("LUAU AUDIT PASS: profile errors always release restoring flag")
end

do
    local alive = true
    local state = {booster = false}
    local boosterRevision = 42
    local boosterPro = {restoreFailures = 0, phase = "RESTORE PENDING",
        restoreRetryRunning = false, restoreRetryAt = 0}
    local CONFIG = {BoosterSliceMs = 1, BoosterBatch = 12}
    local savedTerrainDecoration, savedTerrainColors = nil, nil
    local savedGraphics = setmetatable({}, {__mode = "k"})
    local retryJob = nil
    local task = {wait = function() end, spawn = function(fn) retryJob = fn end}
    local function warn(_) end
    ${objectRestore}
    ${graphicsRestore}
    local current, blockWrite = false, true
    local obj = {Parent = {}, Name = "MockPart"}
    setmetatable(obj, {
        __index = function(_, key)
            if key == "CastShadow" then return current end
        end,
        __newindex = function(_, key, value)
            if key == "CastShadow" then
                if blockWrite then error("write blocked") end
                current = value
            else
                rawset(obj, key, value)
            end
        end
    })
    savedGraphics[obj] = {CastShadow = true}
    assert(not boosterPro.restoreGraphicsSliced(42))
    assert(savedGraphics[obj] ~= nil and current == false)
    assert(not boosterPro.restoreGraphicsSliced(41), "stale revision must not write")
    assert(savedGraphics[obj] ~= nil)
    blockWrite = false
    boosterPro.retryPendingGraphics()
    assert(boosterPro.restoreRetryRunning and retryJob ~= nil)
    retryJob()
    assert(current == true and savedGraphics[obj] == nil)
    assert(boosterPro.phase == "OFF" and not boosterPro.restoreRetryRunning)
    savedGraphics[obj] = {CastShadow = true}
    current = false
    state.booster = true
    assert(not boosterPro.restoreGraphicsSliced(42))
    assert(current == false and savedGraphics[obj] ~= nil)
    print("LUAU AUDIT PASS: booster retries only after failure and cancels across revisions")
end

`;
fs.writeFileSync("/tmp/Army124-RuntimeAudit.luau",program,"utf8");
console.log("Generated Luau fault-injection harness from production functions");
