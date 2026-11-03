"use strict";
const test = require("node:test");
const fs = require("node:fs");
const assert = require("node:assert/strict");
const src = fs.readFileSync("Visuals.lua", "utf8");
const hub = fs.readFileSync("Hub.lua", "utf8");
const start = fs.readFileSync("Start.lua", "utf8");
const send = src.slice(src.indexOf("function chat.sendOnce()"), src.indexOf("-- Сохраняем только ограниченный набор настроек"));
test("v1.1.30 entrypoints and loader target are identical",()=>{
 assert.equal(src,hub);
 assert.ok(src.includes('Version = "1.1.30"'));
 assert.ok(start.includes("v1.1.30-full-stability-audit-test"));
});
test("manual sending checks account-wide permission before selecting channel",()=>{
 const check = send.indexOf("TextChatService:CanUserChatAsync(LocalPlayer.UserId)");
 const localChannel = send.indexOf("currentChatChannel()");
 const sendAsync = send.indexOf("channel:SendAsync(message)");
 assert.ok(check > 0 && localChannel > check && sendAsync > localChannel);
 assert.ok(send.includes('chat.sendStatus = okAccess and "BLOCKED BY ROBLOX" or "PERMISSION UNKNOWN"'));
 assert.ok(send.includes("if not okAccess or permitted ~= true then"));
});
test("denied or unknown permissions never route through game-specific remotes",()=>{
 assert.ok(!send.includes(":FireServer("));
 assert.ok(!send.includes(":InvokeServer("));
 assert.ok(!send.includes("ReplicatedStorage"));
 assert.ok(send.includes("Кастомный чат игры не отменяет настройки общения."));
});
test("manual send has lock covering permission yields and correct failure cleanup",()=>{
 const lock = send.indexOf("chat.inFlight = true");
 const permission = send.indexOf("CanUserChatAsync");
 const unlock = send.indexOf('chat.inFlight = false', permission);
 assert.ok(lock > 0 && lock < permission && permission < unlock);
 assert.ok(send.includes("if not alive or permissionToken ~= chat.token then"));
 assert.ok(send.includes("if not channel then\n            chat.inFlight = false"));
});
test("Chat Timer does not auto send and status button does not transmit",()=>{
 const timer = src.slice(src.indexOf("function chat.sync()"), src.indexOf("local function currentChatChannel()"));
 assert.ok(!timer.includes("channel:SendAsync("));
 assert.ok(src.includes('addButton(pages.MISC, "Проверить доступ к чату"'));
 const button = src.slice(src.indexOf('addButton(pages.MISC, "Проверить доступ к чату"'),src.indexOf('addButton(pages.MISC, "Статус чата"'));
 assert.ok(button.includes("CanUserChatAsync"));
 assert.ok(!button.includes("SendAsync"));
});
