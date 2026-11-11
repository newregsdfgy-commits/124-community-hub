#!/usr/bin/env python3
"""Build isolated executable Luau tests from exact project source functions."""
from pathlib import Path
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def extract(filename: str, start: str, end: str) -> str:
    source = (ROOT / filename).read_text(encoding="utf-8")
    pos = source.find(start)
    stop = source.find(end, pos + len(start))
    if pos < 0 or stop < 0 or source.find(start, pos + 1) >= 0:
        raise ValueError(f"Cannot isolate unique Luau block: {start}")
    return source[pos:stop]


esp = extract("src/03_esp_tracker.lua",
              "local function queueESPRefresh(urgent)", "local function isEspPart(obj)")
key = extract("src/01_access_gate.lua",
              "local function resolve(accepted)", "submit.Activated:Connect(tryUnlock)")

script = r'''
-- Real ESP scheduling function with deterministic fake Roblox clock/task queue.
do
    local now = 100
    local os = {clock = function() return now end}
    local CONFIG = {EspRespawnCoalesceSeconds = 0.045,
        EspRespawnMinIntervalSeconds = 0.10, EspEventMinSeconds = 0.18}
    local alive, state = true, {esp = true}
    local perfCounters = {espVisual = {
        urgentEvents = 0, urgentScans = 0, urgentSkipped = 0,
        lastScanAt = 0, localReady = true, scanErrorAt = -math.huge,
    }}
    function perfCounters.espVisual.eventCooldown() return 0.18 end
    local espRefreshQueued, espUrgentQueued = false, false
    local espRefreshGeneration = 0
    local espUrgentLastAt, espUrgentDirtyAt = -math.huge, -math.huge
    local jobs = {}
    local task = {delay = function(delay, callback)
        jobs[#jobs + 1] = {time = now + delay, callback = callback}
    end}
    local warn = function(message) error(message) end
    local scans = 0
    local refreshESP = function()
        scans = scans + 1
        perfCounters.espVisual.lastScanAt = now
    end

''' + esp + r'''
    local function drain()
        assert(#jobs > 0, "Expected queued task")
        table.sort(jobs, function(a, b) return a.time < b.time end)
        local job = table.remove(jobs, 1)
        now = job.time
        job.callback()
    end

    queueESPRefresh(true)
    for _ = 1, 20 do queueESPRefresh(true) end
    assert(#jobs == 1, "Avatar events failed to coalesce")
    drain()
    assert(scans == 1 and perfCounters.espVisual.urgentScans == 1)
    assert(perfCounters.espVisual.urgentEvents == 21)

    now = 200
    queueESPRefresh(true)
    perfCounters.espVisual.lastScanAt = 200.02
    drain()
    assert(scans == 1 and perfCounters.espVisual.urgentSkipped == 1,
        "Redundant scan was not skipped")

    now = 300
    queueESPRefresh(true)
    perfCounters.espVisual.lastScanAt = 300.01
    now = 300.02
    queueESPRefresh(true)
    drain()
    assert(scans == 2 and perfCounters.espVisual.urgentScans == 2,
        "New dirty event after periodic scan was lost")

    now = 400
    queueESPRefresh(true)
    espRefreshGeneration = espRefreshGeneration + 1
    espUrgentQueued = false
    drain()
    assert(scans == 2, "Old generation scanned after shutdown")

    now = 500
    state.esp = false
    queueESPRefresh(true)
    assert(#jobs == 0, "ESP OFF scheduled new work")
    print("PASS: ESP source scheduler burst, dedup, fresh event, generation, OFF")
end

-- Real Key System callback with deterministic fake Android events and timer.
do
    local now = 1000
    local os = {clock = function() return now end}
    local CONFIG = {KeyMaxWrongAttempts = 5,
        KeyLocalCooldownSeconds = 25, KeySubmitDedupSeconds = 0.18}
    local Color3 = {fromRGB = function() return 1 end}
    local completed, wrongCount = false, 0
    local resolvedValue = false
    local blockedUntil, lastSubmitAt = 0, -math.huge
    local fired = 0
    local response = {Fire = function(_, accepted)
        fired = fired + 1
        assert(accepted == resolvedValue)
    end}
    local input, message = {Text = ""}, {Text = "", TextColor3 = nil}
    local submit, screen = {Active = true, AutoButtonColor = true}, {Parent = true}
    local ACCESS_KEY = "124HUB"
    local jobs = {}
    local task = {delay = function(delay, callback)
        jobs[#jobs + 1] = {time = now + delay, callback = callback}
    end}

''' + key + r'''
    tryUnlock()
    assert(wrongCount == 0 and message.Text == "Введи ключ перед проверкой")
    now = now + 0.01
    input.Text = "wrong"
    tryUnlock()
    assert(wrongCount == 1)
    local feedback = message.Text
    now = now + 0.01
    tryUnlock()
    assert(wrongCount == 1 and message.Text == feedback,
        "Android duplicate empty Return overwrote error")
    for i = 2, 5 do
        now = now + 0.01
        input.Text = "bad" .. tostring(i)
        tryUnlock()
        assert(wrongCount == i, "New key attempt incorrectly suppressed")
    end
    assert(not submit.Active and blockedUntil > now and #jobs == 1)
    input.Text = ACCESS_KEY
    tryUnlock()
    assert(not completed, "Key accepted during cooldown")
    now = jobs[1].time
    jobs[1].callback()
    assert(wrongCount == 0 and blockedUntil == 0 and submit.Active)
    tryUnlock()
    assert(completed and resolvedValue and fired == 1)
    resolve(false)
    assert(resolvedValue and fired == 1, "Accepted decision was overwritten")
    print("PASS: Key source callback empty, five failures, cooldown, one-shot")
end
print("PASS: v1.3.1 executable Luau fault injection")
'''

path = Path(tempfile.gettempdir()) / "Army124-FullAudit131.luau"
path.write_text(script, encoding="utf-8")
print(f"Created runtime harness: {path}")
