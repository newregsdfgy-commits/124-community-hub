"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const test = require("node:test");
const src = fs.readFileSync("Visuals.lua", "utf8");
const compat = fs.readFileSync("Hub.lua", "utf8");
function setting(name) {
 const m=src.match(new RegExp(name + "\\s*=\\s*(\\d+)"));
 assert.ok(m,name); return Number(m[1]);
}
test("entrypoints remain identical", () => {
 assert.equal(src,compat); assert.ok(src.includes('Version = "1.1.20"'));
});
test("roster stays event-maintained and reused in hot paths", () => {
 assert.ok(src.includes("perfCounters.roster = Players:GetPlayers()"));
 assert.ok(src.includes("connect(Players.PlayerAdded"));
 assert.ok(src.includes("connect(Players.PlayerRemoving"));
 assert.equal(src.split("ipairs(perfCounters.roster) do").length-1,5); // 4 uses + index initialization
 assert.ok(src.includes("indices[last] = index"));
});
test("2D rendering caches and validates live avatar parts", () => {
 assert.ok(src.includes("item.head, item.root, item.humanoid = head, root, hum"));
 assert.ok(src.includes("head.Parent == ch"));
 assert.ok(src.includes("root.Parent == char"));
});
test("ESP visual budget caps are monotonic", () => {
 assert.ok(setting("EspCriticalFps") < setting("EspLowFps"));
 assert.ok(setting("EspCriticalHz") < setting("EspLowHz"));
 assert.ok(setting("EspVisualEcoHz") <= setting("EspVisualBalancedHz"));
 assert.ok(src.includes("espVisualElapsed = math.min(espVisualElapsed - period, period)"));
});
test("dashboard renders bars only after next sample", () => {
 assert.ok(src.includes("dash.historyVersion = (dash.historyVersion or 0) + 1"));
 assert.ok(src.includes("if dash.drawnVersion ~= dash.historyVersion then"));
 const push=src.slice(src.indexOf("dash.push = function"),src.indexOf("dash.update = function"));
 assert.ok(!push.includes("dash.bars[i].Size"));
});
