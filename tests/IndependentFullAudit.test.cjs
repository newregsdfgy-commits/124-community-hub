"use strict";
const fs=require("node:fs");
const test=require("node:test");
const assert=require("node:assert/strict");
const source=fs.readFileSync("Visuals.lua","utf8");
const alias=fs.readFileSync("Hub.lua","utf8");
const start=fs.readFileSync("Start.lua","utf8");
function scope(before,after){
 const i=source.indexOf(before),j=source.indexOf(after,i+before.length);
 assert.ok(i>=0 && j>i, "Missing scope "+before);
 return source.slice(i,j);
}
test("audit 1: sources and loader target the same exact v1.1.37 release",()=>{
 assert.equal(source,alias);
 assert.ok(source.includes('Version = "1.1.37"'));
 assert.ok(start.includes("v1.1.37-ui-startup-hotfix-test/Visuals.lua"));
});
test("audit 2: partial ESP render is registered before potentially failing billboard creation",()=>{
 const render=scope("local function createRender(", "local function setIfDifferent(");
 const highlight=render.indexOf('local hl = mk("Highlight"');
 const registered=render.indexOf("renderData[player] = item");
 const billboard=render.indexOf('local bb = mk("BillboardGui"');
 const ownership=render.indexOf("item.billboard = bb");
 const name=render.indexOf('local nameLabel = mk("TextLabel"');
 assert.ok(highlight>=0 && registered>highlight && billboard>registered);
 assert.ok(ownership>billboard && name>ownership);
 assert.ok(render.includes("item.nameLabel, item.healthLabel, item.distanceLabel ="));
});
test("audit 3: ESP cleanup must not use ipairs over sparse instance array",()=>{
 const del=scope("local function deleteRender(player)", "local cachedGreen");
 assert.ok(del.includes('for _, property in ipairs({"highlight", "billboard", "tracer"})'));
 assert.ok(del.includes("local instance = item[property]"));
 assert.ok(!del.includes("ipairs({item.highlight, item.billboard, item.tracer})"));
 // An old sparse array iterator stops on a nil first property.
 const broken=[undefined,{name:"Billboard"}];
 const oldRead=broken.findIndex(v=>v===undefined)===0;
 assert.ok(oldRead);
});
test("audit 4: malformed avatar Head cannot shadow valid torso fallback",()=>{
 const helper=scope("local function espVisiblePart(", "-- Тонкий ESP");
 assert.ok(helper.includes('object:IsA("BasePart")'));
 assert.ok(helper.indexOf('espVisiblePart(character, "Head")') <
   helper.indexOf('espVisiblePart(character, "UpperTorso")'));
 assert.ok(helper.includes('or espVisiblePart(character, "Torso")'));
 assert.ok(!helper.includes("local function asPart(")); // no allocation per avatar scan
});
test("audit 5: ESP event scans are bounded and coalesced",()=>{
 const block=scope("local function queueESPRefresh()", "local function isEspPart(");
 assert.ok(block.includes("espRefreshQueued then return"));
 assert.ok(block.includes("CONFIG.EspEventMinSeconds - elapsed"));
 assert.ok(block.includes("task.delay(delaySeconds, function()"));
 const minGap=0.18,last=15,now=15.02;
 const delay=Math.max(0.06,minGap-(now-last));
 assert.ok(delay>0.15 && delay<0.17);
 const interval=Number(source.match(/EspEventMinSeconds\s*=\s*([\d.]+)/)[1]);
 assert.ok(interval>=0.15 && interval<=0.3);
});
test("audit 6: per-player event errors cannot break whole roster scan",()=>{
 const watch=scope("local function watchEspPlayer(player)", "stopESPWatchers = function()");
 assert.ok(watch.includes("local ok, err = pcall(function()"));
 assert.ok(watch.includes("pcall(bindEspCharacter, entry, character)"));
 assert.ok(watch.includes("pcall(bindEspCharacter, entry, nil)"));
 assert.ok(watch.includes("espWatchers[player] = nil"));
 assert.ok(watch.includes("entry.added:Disconnect()"));
 assert.ok(watch.includes("entry.removing:Disconnect()"));
 const scan=scope("local function refreshESP()", "-- Event-assisted ESP refresh");
 assert.ok(scan.includes("pcall(updatePlayer, player, myRoot)"));
});
test("audit 7: no extra background ESP work when feature disabled",()=>{
 const sync=scope("syncESPWatchers = function()", "connect(Players.PlayerAdded, watchEspPlayer)");
 assert.ok(sync.includes("if not state.esp then"));
 assert.ok(sync.includes("stopESPWatchers()"));
 const watcher=scope("local function watchEspPlayer(player)", "stopESPWatchers = function()");
 assert.ok(watcher.includes("if not state.esp or player == LocalPlayer"));
});
test("audit 8: one failing UI control is caught and reported",()=>{
 const activate=scope("local function safeActivate(control, callback)", "local navigation =");
 assert.ok(activate.includes("local ok, err = pcall(callback, input, ...)"));
 assert.ok(activate.includes('tell("Ошибка UI: " .. tostring(err))'));
 assert.ok(activate.includes("not alive or not allowTap(input)"));
});
test("audit 9: fetch, compile and runtime failures are isolated",()=>{
 for(const p of [
  "pcall(function() return game:HttpGet(url) end)",
  "local compiled, chunk, compileError = pcall(loadstring, source)",
  'if not compiled then return failure("COMPILE", chunk) end',
  'if type(chunk) ~= "function" then',
  "xpcall(chunk, function(err)",
  'env.ARMY124_BOOT_PHASE ~= "ready"'
 ]) assert.ok(start.includes(p),p);
});
test("audit 10: Booster cooldown, snapshots and independent AIM remain intact",()=>{
 for(const p of [
  "function boosterPro.restoreObject(obj, snapshot)",
  "boosterPro.repairRetryAt = os.clock() + CONFIG.BoosterRepairCooldown",
  "if not boosterPro.complete then return end",
  "boosterPro.restoreGraphicsSliced()",
  "local function aimFrame(",
  "function chat.sendOnce()",
  "TextChatService:CanUserChatAsync(LocalPlayer.UserId)"
 ]) assert.ok(source.includes(p),p);
 assert.equal((source.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
});
test("audit 11: source makes no network RemoteEvent attempts",()=>{
 assert.ok(!/:FireServer\s*\(/.test(source));
 assert.ok(!/:InvokeServer\s*\(/.test(source));
 assert.ok(!/https?:\/\//.test(source));
});
