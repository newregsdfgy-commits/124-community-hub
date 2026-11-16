const fs = require('node:fs');
const path = require('node:path');
const source = fs.readFileSync('src/04_lighting_and_booster.lua', 'utf8');
function block(start, end) { return source.slice(source.indexOf(start), source.indexOf(end, source.indexOf(start))); }
const prediction = block('local function predictedPoint(part)', 'local function signedAngle');
const ranking = block('local function aimCandidateBefore', 'local function findAimTarget');
const frame = source.slice(source.indexOf('local function aimFrame(dt)'));
const pre = `
local mt = {}
local function vec(x,y,z) return setmetatable({X=x,Y=y,Z=z},mt) end
mt.__index = function(v,k) if k == 'Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end end
mt.__mul = function(v,s) return vec(v.X*s,v.Y*s,v.Z*s) end
mt.__add = function(a,b) return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
local function typeof(v) return getmetatable(v)==mt and 'Vector3' or type(v) end
local state = {prediction=true,predictionSeconds=0.1,aimbot=true}
local CONFIG = {AimPredictionMaxStuds=10,AimScanInterval=0.12,AimLosBalancedSeconds=0.04}
local part = {Position=vec(1,2,3),AssemblyLinearVelocity=vec(10,0,0)}
`;
const tests = `
assert(predictedPoint(part).X == 2, 'valid prediction')
state.prediction=false
assert(predictedPoint(part)==part.Position, 'prediction OFF')
state.prediction=true
for _,s in ipairs({0/0,math.huge,-math.huge,-1,'bad',false}) do
 state.predictionSeconds=s
 assert(predictedPoint(part)==part.Position, 'invalid seconds')
end
state.predictionSeconds=nil
assert(predictedPoint(part)==part.Position)
state.predictionSeconds=0.1
for _,v in ipairs({vec(0/0,0,0),vec(0,math.huge,0),vec(0,0,-math.huge),vec(1e308,0,0),'bad'}) do
 part.AssemblyLinearVelocity=v
 assert(predictedPoint(part)==part.Position, 'invalid velocity')
end
part.AssemblyLinearVelocity=vec(1000,0,0)
assert(math.abs(predictedPoint(part).X-11)<1e-6, 'prediction cap')
part=setmetatable({Position=vec(1,2,3)}, {__index=function() error('streamed out') end})
assert(predictedPoint(part)==part.Position, 'velocity read failure')
local a={pixelsSquared=4,player={UserId=10}}
local b={pixelsSquared=4,player={UserId=20}}
local c={pixelsSquared=1,player={UserId=30}}
for _,list in ipairs({{a,b,c},{c,b,a},{b,a,c}}) do
 table.sort(list,aimCandidateBefore)
 assert(list[1]==c and list[2]==a and list[3]==b,'stable score/UserId order')
end
assert(not aimCandidateBefore(a,a),'strict comparison')
local alive=true
local aimHeldMouse,aimHeldTouch,aimHeldKey=true,false,false
local aimTarget={old=true}
local aimNextScan=math.huge
local resets,scans=0,0
local aimPro={camera={},nextLos=99,blockedSince=99,equippedTool=function()return true end}
function aimPro.reset() resets+=1;aimTarget=nil;aimNextScan=0;aimPro.nextLos=0;aimPro.blockedSince=0 end
local Workspace={CurrentCamera={}}
local UserInputService={GetFocusedTextBox=function()return nil end}
local function isRobloxMenuOpen() return false end
local function perfTier() return 'BALANCED' end
local function findAimTarget(camera)
 assert(camera==Workspace.CurrentCamera)
 assert(aimTarget==nil and aimPro.nextLos==0 and aimPro.blockedSince==0,'old target/LOS cleared')
 scans+=1
 return nil
end
`;
const checks = `
aimFrame(1/60)
assert(resets==1 and scans==1,'replacement rescans immediately')
aimFrame(1/60)
assert(resets==1 and scans==1,'same camera respects scan timer')
Workspace.CurrentCamera=nil
aimFrame(1/60)
assert(resets==2 and aimTarget==nil,'camera removed')
Workspace.CurrentCamera={}
aimFrame(1/60)
assert(resets==3 and scans==2,'camera restored')
state.aimbot=false
Workspace.CurrentCamera={}
aimFrame(1/60)
assert(resets==4 and scans==2,'disabled AIM does not reacquire')
assert(state.prediction and state.predictionSeconds==0.1,'settings preserved')
print('PASS: AIM 1.6 camera lifecycle, prediction validation, stable ranking (mock Roblox API)')
`;
fs.mkdirSync('.tools', {recursive:true});
fs.writeFileSync(path.join('.tools','Aim160.luau'), pre+prediction+ranking+tests+frame+checks);
