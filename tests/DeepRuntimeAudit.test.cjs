"use strict";
const test=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs");
const src=fs.readFileSync("Visuals.lua","utf8");
const hub=fs.readFileSync("Hub.lua","utf8");
const start=fs.readFileSync("Start.lua","utf8");
const flow=fs.readFileSync(".github/workflows/luau-compile.yml","utf8");
function region(from,to) {
 const a=src.indexOf(from),b=src.indexOf(to,a+from.length);
 assert.ok(a>=0 && b>a,"missing "+from);
 return src.slice(a,b);
}
test("source, compatibility file, and launcher agree on v1.1.37",()=>{
 assert.equal(src,hub);assert.ok(src.includes('Version = "1.1.37"'));
 assert.ok(start.includes("v1.1.37-ui-startup-hotfix-test/Visuals.lua"));
});
test("factory does not leak unfinished Instances if property or Parent assignment throws",()=>{
 const mk=region("local function mk(class, properties, parent)","local function round(instance, radius)");
 assert.ok(mk.indexOf("local ok, err = pcall(")<mk.indexOf("if not ok then"));
 assert.ok(mk.includes('pcall(function() instance:Destroy() end)'));
 assert.ok(mk.includes("error(err, 2)"));
 assert.ok(mk.indexOf("if not ok then")<mk.indexOf('if class == "ScreenGui"'));
});
test("event-driven ESP scan records attempts even if local character is missing",()=>{
 const scan=region("local function refreshESP()","-- Event-assisted ESP refresh");
 const recorded=scan.indexOf("perfCounters.espVisual.lastScanAt = os.clock()");
 const missing=scan.indexOf("if not myRoot then");
 assert.ok(recorded>=0 && recorded<missing);
 assert.equal(scan.split("perfCounters.espVisual.lastScanAt = os.clock()").length-1,1);
 assert.ok(scan.includes("perfCounters.espVisual.localReady = myRoot ~= nil"));
 assert.ok(scan.includes("perfCounters.espVisual.missing = 0"));
});
test("stale queued ESP refresh callbacks cannot execute after OFF→ON",()=>{
 const fn=region("local function queueESPRefresh()","local function isEspPart(obj)");
 const stop=region("stopESPWatchers = function()\n    espRefreshGeneration", "syncESPWatchers = function()");
 assert.ok(fn.includes("local generation = espRefreshGeneration"));
 assert.ok(fn.includes("if generation ~= espRefreshGeneration then return end"));
 assert.ok(stop.includes("espRefreshGeneration = espRefreshGeneration + 1"));
 assert.ok(stop.includes("espRefreshQueued = false"));
});
test("ESP diagnostics separate no local character from missing opponent and render failures",()=>{
 assert.ok(src.includes('localReady = false, renderFailures = 0, watcherFailures = 0'));
 assert.ok(src.includes('perfCounters.espVisual.renderFailures = perfCounters.espVisual.renderFailures + 1'));
 assert.ok(src.includes('perfCounters.espVisual.watcherFailures = perfCounters.espVisual.watcherFailures + 1'));
 assert.ok(src.includes('info.localReady and "READY" or "LOADING"'));
 assert.ok(src.includes('" | Ошибки отрисовки/подписок "'));
});
test("ESP still uses the selected range, cap, and bounded periodic scans",()=>{
 const scan=region("local function refreshESP()","-- Event-assisted ESP refresh");
 assert.ok(scan.includes("state.espRangeMeters / CONFIG.StudMeters"));
 assert.ok(scan.includes("dist2 <= maxDistanceSquared"));
 assert.ok(src.includes("espMaxTargets = {8, 96}"));
 assert.ok(src.includes("EspEventMinSeconds = 0.18"));
 assert.ok(src.includes('local interval = tier == "ECO" and 0.55 or tier == "QUALITY" and 0.25'));
});
test("Booster/aim and other independent modules retain source guards",()=>{
 for(const k of [
  "boosterPro.autoRollback = function()",
  "if not boosterPro.complete then return end",
  "function boosterPro.restoreObject(obj, snapshot)",
  "boosterPro.queueCount >= boosterPro.queueCap",
  "boosterPro.restoreGraphicsSliced()",
  "local function findAimTarget(camera)",
  "local function recoilFrame(dt)",
  "TextChatService:CanUserChatAsync(LocalPlayer.UserId)",
  'Name = "Army124CommunityVisualsGUI"',
  "boosterPro.stopWatchingPlayers()",
  "stopESPWatchers()"
 ]) assert.ok(src.includes(k),k);
});
test("no unreviewed external network or gameplay remotes in Visuals source",()=>{
 for(const re of [/https?:\/\//,/:FireServer\s*\(/,/:InvokeServer\s*\(/,/\bloadstring\s*\(/])
  assert.ok(!re.test(src),String(re));
 assert.ok(start.includes("pcall(loadstring, source)"));
});
test("CI is configured for Luau runtime checks as well as source regressions",()=>{
 assert.ok(flow.includes("Luau.Repl.CLI"));
 assert.ok(flow.includes("tests/build-runtime-audit.cjs"));
 assert.ok(flow.includes("Army124-RuntimeAudit.luau"));
});
