"use strict";
const fs=require("node:fs");
const state=fs.readFileSync("src/02_state_and_services.lua","utf8");
const esp=fs.readFileSync("src/03_esp_tracker.lua","utf8");
function block(s,start,end){
 const a=s.indexOf(start),b=s.indexOf(end,a+start.length);
 if(a<0||b<a)throw Error("source missing: "+start);
 return s.slice(a,b);
}
const guard=block(state,"perfCounters.guard = {","-- Optional per-call wall-time instrumentation.");
const limit=block(esp,"local function espLimit()","-- StreamingEnabled may give us");
const luau=`local now = 0
local os = {clock = function() return now end}
local state = {performanceGuard = true, espMaxTargets = 64}
local CONFIG = {GuardLowFps=39, GuardCriticalFps=29,
 GuardRecoveryFps=55, GuardLowSamples=3, GuardRecoverSamples=8,
 GuardMinStepSeconds=12, GuardEscalateSeconds=3,
 GuardEspMaxL1=6, GuardEspMaxL2=4, EspMaxPlayers=64}
local perfCounters = {}
${guard}
${limit}
local g=perfCounters.guard
assert(espLimit()==64, "baseline")
for i=1,3 do now=i; g.update(24,6) end
assert(g.level==2 and espLimit()==64, "critical stutter guard response")
g.reset()
for i=1,3 do now=19+i; g.update(35,3) end
assert(g.level==1 and espLimit()==64, "low FPS response")
for i=1,3 do now=22+i; g.update(24,6) end
assert(g.level==2 and espLimit()==64, "escalation after minimum guard dwell")
for i=1,8 do now=25+i; g.update(60,0) end
assert(g.level==2, "premature recovery")
now=37; g.update(60,0)
assert(g.level==1 and espLimit()==64, "conservative recovery")
state.performanceGuard=false
g.update(20,6)
assert(g.level==0 and espLimit()==64, "opt-out preserves full limit")
g.update(0/0,6)
assert(g.level==0,"NaN FPS ignored")
print("PASS: v1.6.2 Luau Guard transitions without ESP player loss")
`;
fs.mkdirSync(".tools",{recursive:true});
fs.writeFileSync(".tools/Guard161.luau",luau);
console.log("Generated Guard161 Luau regression");
