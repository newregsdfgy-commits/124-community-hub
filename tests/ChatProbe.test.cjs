"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const src = fs.readFileSync("ChatProbe.lua", "utf8");
const prod = fs.readFileSync("Visuals.lua", "utf8");
const alias = fs.readFileSync("Hub.lua", "utf8");
test("chat audit is read-only with respect to game chat and remotes", () => {
 for (const required of ["CanUserChatAsync","TextChannels","CanSend",
   "ReplicatedStorage:GetDescendants()","PlayerGui","env.ARMY124_CHAT_AUDIT"]) {
   assert.ok(src.includes(required), required);
 }
 for (const forbidden of [":FireServer(", ":InvokeServer(", ":SendAsync(",
   ":CaptureFocus(", ":ReleaseFocus(", "message.Text", "channel:"]) {
   assert.ok(!src.includes(forbidden), forbidden);
 }
});
test("on-screen report can be read without Xeno external console", () => {
 for(const field of ["Army124ChatAuditPanel", "AuditResults", "ReportText",
  "CopyReport", "CloseAudit", "reportOutput = output",
  'title.Text = "124 / CHAT AUDIT   |   ГОТОВО"']) {
   assert.ok(src.includes(field), field);
 }
 assert.ok(src.includes("scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y"));
 assert.ok(src.includes("panelGui.Parent = gui"));
});
test("probe only closes its own GUI and does not alter chat settings", () => {
 assert.ok(src.includes("close.Activated:Connect(function() panelGui:Destroy() end)"));
 assert.ok(src.includes("if previousPanel then previousPanel:Destroy() end"));
 assert.ok(!src.includes("RemoteEvent:FireServer("));
 assert.ok(!src.includes("TextChatService.ChatVersion ="));
});
test("production v1.1.23 source remains unchanged", () => {
 assert.equal(prod,alias);
 assert.ok(prod.includes('Version = "1.1.23"'));
});
test("audit omits entered chat content", () => {
 assert.ok(src.includes("obj.PlaceholderText"));
 assert.ok(!src.includes("obj.Text:gsub"));
 assert.ok(!src.includes("obj.Text:sub"));
});
