"use strict";
const fs=require("node:fs");
const assert=require("node:assert/strict");
const tr=fs.readFileSync("src/03_esp_tracker.lua","utf8");
const gui=fs.readFileSync("src/06_gui_runtime.lua","utf8");
const overlays=fs.readFileSync("src/07_esp_overlays.lua","utf8");
function between(src,start,stop){
 const a=src.indexOf(start),b=src.indexOf(stop,a+start.length);
 assert.ok(a>=0&&b>a,"missing production region "+start);
 return src.slice(a,b);
}
const flags=between(tr,"local function compactEspFlags(meters, namesEnabled, healthEnabled, distanceEnabled)","local function createRender(player, character, head)");
const validate=between(gui,"local function validatedSettings(values)","local function writeProfileFile()");
const radius=[...overlays.matchAll(/local radiusStuds = ([^\r\n]+)\/ CONFIG\.StudMeters/g)].map(x=>x[1].trim());
assert.equal(radius.length,2,"two independent radius expressions required");
assert.ok(radius[0].includes("espTracerMaxMeters")&&radius[1].includes("espBoxMaxMeters"));
let script=fs.readFileSync("tests/EspRanges159.luau","utf8");
for(const [tag,source] of [
 ["--@@ESP_FLAGS@@",flags],
 ["--@@PROFILE_VALIDATOR@@",validate],
 ["--@@TRACER_RADIUS@@",radius[0]],
 ["--@@BOX_RADIUS@@",radius[1]]]){
 assert.equal(script.split(tag).length,2,"missing/duplicated token "+tag);
 script=script.replace(tag,source);
}
fs.writeFileSync("/tmp/Army124-EspRanges159.luau",script,"utf8");
console.log("Generated source-extracted ESP independent ranges regression");
