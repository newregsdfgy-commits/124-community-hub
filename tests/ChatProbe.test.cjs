"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const source = fs.readFileSync("ChatProbe.lua", "utf8");
const original = fs.readFileSync("Visuals.lua", "utf8");
const alias = fs.readFileSync("Hub.lua", "utf8");
test("read-only chat audit does not mutate chat, send messages, or call remotes", () => {
 assert.ok(source.includes("CanUserChatAsync"));
 assert.ok(source.includes("TextChannels"));
 assert.ok(source.includes("CanSend"));
 assert.ok(source.includes("GetDescendants"));
 for (const forbidden of [":FireServer(", ":InvokeServer(", ":SendAsync(", ":CaptureFocus(",
     ":ReleaseFocus(", ".Text =", "TextBox.Text", ":Destroy()"]) {
   // Destruction of its own diagnostic ScreenGui is not needed: no GUI is created.
   assert.ok(!source.includes(forbidden), forbidden);
 }
});
test("audit preserves existing production source unchanged", () => {
 assert.equal(original, alias);
 assert.ok(original.includes('Version = "1.1.23"'));
});
test("captures only UI metadata and no other player's chat content", () => {
 assert.ok(source.includes('obj.PlaceholderText'));
 assert.ok(source.includes('env.ARMY124_CHAT_AUDIT = output'));
 assert.ok(!source.includes('message.Text'));
});
