"use strict";
const fs=require("node:fs"), assert=require("node:assert/strict");
const tracker=fs.readFileSync("src/03_esp_tracker.lua","utf8");
const from=tracker.indexOf("local function compactEspFlags(meters, namesEnabled, healthEnabled, distanceEnabled)");
const to=tracker.indexOf("local function createRender(player, character, head)",from);
assert.ok(from>=0&&to>from,"actual compactEspFlags production helper not found");
const helper=tracker.slice(from,to);
const script=String.raw`
local CONFIG={EspCompactDetailsMaxMeters=90,EspCompactNameMaxMeters=155}
${helper}
local function check(meters,n,h,d,nWant,hWant,dWant)
    local nn,hh,dd=compactEspFlags(meters,n,h,d)
    assert(nn==nWant and hh==hWant and dd==dWant,
        "compact ESP flags wrong for "..tostring(meters).." m")
end
-- At close range, all three independent toggles work.
check(0,true,true,true,true,true,true)
check(61,true,true,true,true,true,true)
check(90,true,true,true,true,true,true)
check(90,true,false,true,true,false,true)
check(90,false,true,false,false,true,false)
check(90,false,false,false,false,false,false)
-- Just above the details threshold: no HP/distance clutter.
check(91,true,true,true,true,false,false)
check(120,true,true,true,true,false,false)
check(155,true,true,true,true,false,false)
-- Far range keeps ESP highlight/corners outside this text-only helper.
check(156,true,true,true,false,false,false)
check(294,true,true,true,false,false,false)
check(1000,true,true,true,false,false,false)
check(1000,false,false,false,false,false,false)
print("PASS: production compact ESP distance transitions, independent toggles, no far text")
`;
fs.writeFileSync("/tmp/Army124-EspCompact157.luau",script,"utf8");
console.log("Generated production ESP compact distances/feature flags Luau suite");
