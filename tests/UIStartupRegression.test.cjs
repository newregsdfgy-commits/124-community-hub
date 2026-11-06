"use strict";
const fs=require("node:fs"), test=require("node:test"), assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
const block=(()=>{const a=src.indexOf("    local pointer = nil\n    local function cancelPointer()");const b=src.indexOf("    -- Original ESP limit is 200 m;",a+10);assert.ok(a>=0&&b>a);return src.slice(a,b)})();
test("v1.1.37 references a real slider GUI node, never undefined container",()=>{
 assert.match(src,/Version = "1\.1\.37"/);
 assert.ok(block.includes("local area = mk("));
 assert.ok(block.includes("if not area.Parent then return end"));
 assert.ok(!block.includes("if not container.Parent then return end"));
});
test("both startup slider invocations remain connected to original settings",()=>{
 assert.ok(src.includes('makeSlider(top, "Max Distance", "espRangeMeters", 10, 200, 5'));
 assert.ok(src.includes('makeSlider(visual, "FOV Circle", "aimFovPixels", CONFIG.AimFovMinPixels'));
 assert.ok(block.includes("refreshSliders[key] = function()"));
 assert.ok(block.includes("connect(area.InputBegan"));
 assert.ok(block.includes("update()\n    end\n    connect(UserInputService.InputChanged"));
});
test("all source aliases agree and loader points only to hotfix",()=>{
 assert.equal(src,fs.readFileSync("Hub.lua","utf8"));
 const loader=fs.readFileSync("Start.lua","utf8");
 assert.ok(loader.includes("v1.1.37-ui-startup-hotfix-test/Visuals.lua"));
 assert.ok(loader.includes('Version = "1.1.37"'));
});
