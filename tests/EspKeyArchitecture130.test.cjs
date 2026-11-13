"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const read = (relative) => fs.readFileSync(path.join(root, relative), "utf8");
const hub = read("Hub.lua"), visuals = read("Visuals.lua"), launcher = read("Start.lua");
const modules = [
    "00_config.lua", "01_access_gate.lua", "02_state_and_services.lua",
    "03_esp_tracker.lua", "04_lighting_and_booster.lua",
    "05_weapons_and_recoil.lua", "05_player_visuals.lua", "06_gui_runtime.lua", "07_esp_overlays.lua",
    "08_ui_controls.lua", "09_misc_and_diagnostics.lua",
    "10_run_and_cleanup.lua",
].map(x => read("src/" + x));

const part = (a, b) => {
    const start = hub.indexOf(a);
    const end = b ? hub.indexOf(b, start + 1) : hub.length;
    assert.ok(start >= 0 && end > start, "segment marker: " + a);
    return hub.slice(start, end);
};
const gate = part("-- Блокировка запуска:", "local state = {");
const esp = part("-- ESP: исходная Highlight/Billboard", "-- Shared Lighting ownership:");
const runtime = part("-- Camera FOV сразу после штатной камеры", undefined);

test("module bundle is byte-equivalent and 12 fragments appear in order", () => {
    assert.equal(hub, visuals);
    assert.equal(modules.join(""), hub);
    assert.equal(modules.length, 12);
});
test("entrypoint version and launcher point to isolated test branch", () => {
    assert.match(hub, /Version = "1\.4\.2"/);
    assert.match(launcher, /v1\.4\.2-ui-layout-repair-test\/Visuals\.lua/);
    assert.match(launcher, /Version = "1\.4\.2"/);
    assert.match(launcher, /ARMY124_START_RUNNING = true/);
    assert.match(launcher, /ARMY124_START_RUNNING = nil/);
});
test("key gate remains before any runtime state creation", () => {
    assert.ok(hub.indexOf("local ACCESS_KEY") < hub.indexOf("local state = {"));
    assert.match(gate, /local ACCESS_KEY = "124HUB"/);
    assert.match(gate, /response:Fire\(resolvedValue\)/);
});
test("wrong keys tracked; empty input does not consume an attempt", () => {
    assert.match(gate, /local completed, wrongCount = false, 0/);
    assert.ok(gate.indexOf('if candidate == "" then') < gate.indexOf("wrongCount = wrongCount + 1"));
    assert.match(gate, /KeyMaxWrongAttempts - wrongCount/);
});
test("local failed attempts cooldown is bounded and unlocks once", () => {
    assert.match(hub, /KeyMaxWrongAttempts = 5/);
    assert.match(hub, /KeyLocalCooldownSeconds = 25/);
    assert.match(gate, /blockedUntil = now \+ CONFIG\.KeyLocalCooldownSeconds/);
    assert.match(gate, /if completed or not screen\.Parent then return end/);
    assert.match(gate, /wrongCount, blockedUntil = 0, 0/);
});
test("accidental cancel is fail-closed and requires a second tap", () => {
    assert.match(gate, /cancelArmedAt = -math\.huge/);
    assert.match(gate, /now - cancelArmedAt <= CONFIG\.KeyCloseConfirmSeconds/);
    assert.match(gate, /resolve\(false\)/);
    assert.match(gate, /screen\.Destroying:Connect\(function\(\) resolve\(false\) end\)/);
});
test("Android return and FocusLost are deduplicated and never submit on blur alone", () => {
    assert.match(gate, /KeySubmitDedupSeconds/);
    assert.match(gate, /input\.ReturnPressedFromOnScreenKeyboard:Connect\(tryUnlock\)/);
    assert.match(gate, /if enterPressed then tryUnlock\(\) end/);
    assert.match(gate, /input\.Focused:Connect\(function\(\) moveForKeyboard\(true\) end\)/);
    assert.match(gate, /panel\.Position = UDim2\.fromScale\(0\.5, y\)/);
});
test("ESP event queue isolates fast respawn from long range cooldown", () => {
    assert.match(esp, /local function queueESPRefresh\(urgent\)/);
    const fast = esp.slice(esp.indexOf("if urgent == true then"),
        esp.indexOf("if espRefreshQueued then return end"));
    assert.match(fast, /espUrgentQueued = true/);
    assert.match(fast, /task\.delay\(delaySeconds, function\(\)/);
    assert.match(fast, /generation ~= espRefreshGeneration/);
    assert.match(fast, /pcall\(refreshESP\)/);
    assert.doesNotMatch(fast, /eventCooldown\(\)/);
});
test("coalesced respawn path bounds full scans", () => {
    assert.match(hub, /EspRespawnCoalesceSeconds = 0\.045/);
    assert.match(hub, /EspRespawnMinIntervalSeconds = 0\.10/);
    assert.match(esp, /local espUrgentLastAt = -math\.huge/);
    assert.match(esp, /CONFIG\.EspRespawnMinIntervalSeconds - elapsed/);
});
test("remote respawns and late parts trigger immediate refresh", () => {
    assert.match(esp, /entry\.added = player\.CharacterAdded:Connect/);
    assert.match(esp, /entry\.partAdded = character\.DescendantAdded:Connect/);
    assert.match(esp, /entry\.partRemoved = character\.DescendantRemoving:Connect/);
    assert.ok((esp.match(/queueESPRefresh\(true\)/g) || []).length >= 5);
    assert.match(esp, /deleteRender\(player\) -- Не оставляем старое выделение/);
});
test("local respawn and late local root replication trigger urgent refresh", () => {
    assert.match(esp, /local function bindLocalEspCharacter\(character\)/);
    assert.match(esp, /connect\(LocalPlayer\.CharacterAdded, function\(character\)/);
    assert.match(esp, /connect\(LocalPlayer\.CharacterRemoving, function\(\)/);
    assert.match(esp, /localEspEntry\.added = character\.DescendantAdded:Connect/);
});
test("unload invalidates pending ESP tasks and disconnects local watchers", () => {
    assert.match(esp, /espRefreshGeneration = espRefreshGeneration \+ 1/);
    assert.match(esp, /espUrgentQueued = false/);
    assert.match(esp, /bindLocalEspCharacter\(nil\)/);
    assert.match(hub, /pcall\(stopESPWatchers\)/);
});
test("far distance text and scan have explicit independent limits", () => {
    assert.match(hub, /EspFarTextRefreshSeconds = 0\.50/);
    assert.match(hub, /EspLongScanSeconds = 0\.45/);
    assert.match(hub, /EspExtremeScanSeconds = 0\.65/);
    assert.match(esp, /item\.nextTextRefreshAt/);
});
test("2D motion is driven by camera, not player re-scans", () => {
    assert.match(runtime, /local motion = perfCounters\.espVisual/);
    assert.match(runtime, /old\.LookVector:Dot\(current\.LookVector\)/);
    assert.match(runtime, /motion\.motionUntil = os\.clock\(\) \+ CONFIG\.EspCameraMotionHoldSeconds/);
    assert.match(runtime, /CONFIG\.EspCameraMotionVisualHz/);
    assert.match(runtime, /measuredFps >= CONFIG\.EspCameraMotionMinFps/);
    assert.match(runtime, /tier ~= "ECO"/);
    assert.match(runtime, /perfCounters\.guard\.level == 0/);
});
test("ESP overlay updates after camera and recoil in render priorities", () => {
    assert.match(runtime, /Enum\.RenderPriority\.Camera\.Value \+ 1/);
    assert.match(runtime, /Enum\.RenderPriority\.Camera\.Value \+ 2/);
    assert.match(runtime, /Enum\.RenderPriority\.Camera\.Value \+ 3/);
    assert.match(runtime, /Enum\.RenderPriority\.Camera\.Value \+ 4/);
});
test("latest Weapons 2.0 and Purple Neon UI are preserved", () => {
    for (const term of ["controller.diagnostics = function()", "function controller.restoreSpread()",
        "local function recoilFrame(dt)", "PURPLE NEON 2.0",
        "function boosterPro.restoreGraphicsSliced(", "local function aimFrame(dt)"]) {
        assert.ok(hub.includes(term), term);
    }
});
test("failed key entry and disabled features do not implicitly start modifiers", () => {
    assert.ok(hub.indexOf("if not ok or not accepted then") < hub.indexOf("local state = {"));
    for (const disabled of ["state.noRecoil = false", "state.noSpread = false",
        "state.aimbot = false", "state.booster = false"]) assert.ok(hub.includes(disabled));
});
