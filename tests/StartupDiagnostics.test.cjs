"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const src = fs.readFileSync("Visuals.lua", "utf8");
const hub = fs.readFileSync("Hub.lua", "utf8");
const launcher = fs.readFileSync("Start.lua", "utf8");
test("canonical and legacy script identical", () => {
 assert.equal(src, hub);
 assert.ok(src.includes('Version = "1.1.22"'));
 assert.ok(launcher.includes("v1.1.22-startup-check-test"));
});
test("loader distinguishes download and execution problems", () => {
 for (const stage of ["NETWORK","DOWNLOAD","VERSION","EXECUTOR","COMPILE","RUNTIME"]) {
  assert.ok(launcher.includes('"' + stage + '"'), stage);
 }
 assert.ok(launcher.includes('env.ARMY124_BOOT_PHASE ~= "ready"'));
});
test("early failure is made visible in game", () => {
 for (const phase of ["PREVIOUS CLEANUP","RECOVERY","UI INITIALIZATION","GUI MISSING"]) {
  assert.ok(src.includes('bootFailure("' + phase + '"'), phase);
 }
 assert.ok(src.includes('screen.Name, screen.ResetOnSpawn = "Army124StartupError", false'));
 assert.ok(src.includes('env.ARMY124_BOOT_PHASE = "ready"'));
});
test("no extra per-frame bindings and existing features retained", () => {
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 assert.ok(src.includes("local function aimFrame"));
 assert.ok(src.includes("local function refreshESP"));
 assert.ok(src.includes("function boosterPro.restoreGraphicsSliced"));
});
