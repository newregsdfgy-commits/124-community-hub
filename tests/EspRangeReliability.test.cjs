"use strict";
const fs=require("node:fs");
const assert=require("node:assert/strict");
const test=require("node:test");
const src=fs.readFileSync("Visuals.lua","utf8");
const hub=fs.readFileSync("Hub.lua","utf8");
const loader=fs.readFileSync("Start.lua","utf8");
function scope(a,b) {
 const i=src.indexOf(a),j=src.indexOf(b,i+a.length);
 assert.ok(i>=0 && j>i,"missing source region: "+a+" ... "+b);
 return src.slice(i,j);
}
function val(key) {
 const match=src.match(new RegExp("\\b"+key+"\\s*=\\s*(\\d+(?:\\.\\d+)?)"));
 assert.ok(match,"missing numerical setting "+key);
 return Number(match[1]);
}
test("new ESP fix is published in both identical entrypoints and proper Start.lua",()=>{
 assert.equal(src,hub);
 assert.equal(val("EspMaxPlayers"),64);
 assert.match(src,/Version\s*=\s*"1\.1\.31"/);
 assert.ok(loader.includes("v1.1.31-deep-runtime-audit-test/Visuals.lua"));
});
test("200m is a true player-relative radius, not a camera-relative Billboard cap",()=>{
 const create=scope("local function createRender(","local function setIfDifferent(");
 const update=scope("local function updatePlayer(","local function sameTeamESP(");
 const scan=scope("local function refreshESP()","-- Event-assisted ESP refresh");
 assert.ok(create.includes("MaxDistance = 0,"));
 assert.ok(update.includes('setIfDifferent(item.billboard, "MaxDistance", 0)'));
 assert.ok(scan.includes("state.espRangeMeters / CONFIG.StudMeters"));
 assert.ok(scan.includes("dist2 <= maxDistanceSquared"));
 // Old logic: camera 55m behind, target 160m away ⇒ billboard reads 215m and cuts at 200m.
 const playerMeters=160,cameraOffsetMeters=55;
 assert.ok(playerMeters<=200);
 assert.ok(playerMeters+cameraOffsetMeters>200);
});
test("150m is only a label style change, not an ESP culling threshold",()=>{
 assert.equal(val("EspFarDistanceMeters"),150);
 const update=scope("local function updatePlayer(","local function sameTeamESP(");
 const scan=scope("local function refreshESP()","-- Event-assisted ESP refresh");
 assert.ok(update.includes("local far = meters >= CONFIG.EspFarDistanceMeters"));
 assert.ok(!scan.includes("CONFIG.EspFarDistanceMeters"));
 assert.ok(val("EspNameSizeFar") >= 10); // not a barely visible 8px label at 150m
 assert.ok(val("EspMetaSizeFar") >= 9);
});
test("performance AUTO/ECO cannot hide close players through implicit TOP 6/12 budget",()=>{
 const limit=scope("local function espLimit()","-- StreamingEnabled may give us");
 assert.ok(limit.includes("state.espMaxTargets"));
 assert.ok(!limit.includes("visualPerfTier()"));
 assert.ok(!limit.includes("performanceGuard"));
 assert.ok(src.includes("espMaxTargets = CONFIG.EspMaxPlayers"));
 assert.ok(src.includes("espMaxTargets = {8, 96}"));
 assert.ok(src.includes('"espMaxTargets"'));
 assert.ok(src.includes('addSlider(pages.ESP, "Максимум игроков ESP"'));
});
test("head or torso or root is enough to place a temporary ESP on partially loaded avatars",()=>{
 const parts=scope("local function espParts(character)","-- Тонкий ESP");
 for(const name of ["HumanoidRootPart","Head","UpperTorso","Torso"])assert.ok(parts.includes(name));
 const update=scope("local function updatePlayer(","local function sameTeamESP(");
 assert.ok(update.includes("local head, root, hum = espParts(character)"));
 assert.ok(update.includes("or (hum and hum.Health <= 0)"));
 assert.ok(update.includes('setIfDifferent(item.billboard, "Adornee", head)'));
 assert.ok(update.includes('setIfDifferent(item.healthLabel, "Text", "HP --")'));
});
test("partial character data is used by sorter, tracers and optional geometry",()=>{
 const scan=scope("local function refreshESP()","-- Event-assisted ESP refresh");
 assert.ok(scan.includes("local _, root, hum = espParts(ch)"));
 assert.ok(scan.includes("if root and (not hum or hum.Health > 0) then"));
 assert.ok(src.includes("local _, myRoot = espParts(myCharacter)"));
 assert.ok(src.includes("and (not hum or (hum.Parent == ch and hum.Health > 0))"));
 assert.ok(src.includes("and (not hum or (hum.Parent == char and hum.Health > 0))"));
});
test("streamed-in/out key parts and respawns schedule a coalesced refresh",()=>{
 const watches=scope("-- Event-assisted ESP refresh","-- FullBright");
 for(const phrase of [
  "local espRefreshQueued = false",
  "task.delay(delaySeconds, function()",
  "character.DescendantAdded:Connect",
  "character.DescendantRemoving:Connect",
  "player.CharacterAdded:Connect",
  "player.CharacterRemoving:Connect",
  "connect(Players.PlayerAdded, watchEspPlayer)",
  "connect(Players.PlayerRemoving, function(player)"
 ])assert.ok(watches.includes(phrase),phrase);
 assert.ok(watches.includes("if not alive or not state.esp or espRefreshQueued then return end"));
 assert.ok(src.includes("syncESPWatchers() -- No avatar event listeners while ESP is disabled."));
 assert.ok(src.includes("local delaySeconds = math.max(0.06, CONFIG.EspEventMinSeconds - elapsed)"));
 assert.ok(watches.includes("if not state.esp or player == LocalPlayer or espWatchers[player] then return end"));
 assert.ok(watches.includes("if not state.esp then\n        stopESPWatchers()"));
});
test("player event signals are always removed on Unload and failed initialization",()=>{
 const watches=scope("-- Event-assisted ESP refresh","-- FullBright");
 assert.ok(watches.includes("stopESPWatchers = function()"));
 assert.ok(watches.includes("entry.partAdded:Disconnect()"));
 assert.ok(watches.includes("entry.partRemoved:Disconnect()"));
 const abort=scope("local function abortPartialHub()","env.ARMY124_CLEANUP = abortPartialHub");
 const cleanup=scope("cleanup = function(safeStop)","env.ARMY124_CLEANUP = cleanup");
 assert.ok(abort.includes("pcall(stopESPWatchers)"));
 assert.ok(cleanup.includes("stopESPWatchers()"));
});
test("one broken player won't prevent the rest of nearby ESP from loading",()=>{
 const scan=scope("local function refreshESP()","-- Event-assisted ESP refresh");
 assert.ok(scan.includes("local ok, err = pcall(updatePlayer, player, myRoot)"));
 assert.ok(scan.includes("if not ok then"));
 assert.ok(scan.includes("deleteRender(player)"));
 assert.ok(scan.includes('perfCounters.espVisual.eligible = #candidates'));
 assert.ok(scan.includes('perfCounters.espVisual.omitted = #candidates - limit'));
});
test("FPS-friendly periodic ESP scan remains under 0.6s even in ECO",()=>{
 assert.ok(val("EspRefreshSeconds")<=0.4);
 assert.ok(src.includes('tier == "ECO" and 0.55 or tier == "QUALITY" and 0.25'));
 assert.ok(src.includes('or tier == "QUALITY" and 60 or CONFIG.EspVisualBalancedHz'));
 assert.ok(val("EspShapeQualityLimit")<=32);
 assert.equal((src.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
});
test("ESP diagnostics expose missing rigs vs density cap without touching game remotes",()=>{
 assert.ok(src.includes('addButton(pages.ESP, "Диагностика ESP"'));
 assert.ok(src.includes('Не загружены части '));
 assert.ok(src.includes('Не вошло в лимит '));
 assert.ok(!/:FireServer\s*\(/.test(src));
 assert.ok(!/:InvokeServer\s*\(/.test(src));
});
