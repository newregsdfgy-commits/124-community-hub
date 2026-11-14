"use strict";
const fs=require("node:fs"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
function extract(a,b) {
 const i=src.indexOf(a),j=src.indexOf(b,i+a.length);
 assert.ok(i>=0&&j>i,"Missing production Luau block: "+a);
 return src.slice(i,j).trim();
}
const rig=extract("local function aimPart(character, name)","local function sameTeam(");
const prediction=extract("local function predictedPoint(part)","local function signedAngle(");
const findTarget=extract("local function findAimTarget(camera)","local function isRobloxMenuOpen()");


const program=String.raw`
-- Real production aim/recoil methods running with isolated Luau mocks.
local vMT={}
local vec
vec=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vMT) end
vMT.__index=function(self,k)
    if k=="Magnitude" then
        return math.sqrt(self.X*self.X+self.Y*self.Y+self.Z*self.Z)
    end
end
vMT.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vMT.__mul=function(a,k) return vec(a.X*k,a.Y*k,a.Z*k) end
local typeof=function(value)
    if getmetatable(value)==vMT then return "Vector3" end
    return type(value)
end
local state={aimMode="body",prediction=true,predictionSeconds=0.25,
    targetLock=true,visibleCheck=true,aimFovPixels=175}
local CONFIG={AimPredictionMaxStuds=10,AimLockTolerance=1.18,
    AimOcclusionGraceSeconds=0.12,AimLosCandidatesPerScan=8}
${rig}
${prediction}
local good={IsA=function(self,cls) return cls=="BasePart" end}
local fake={IsA=function() return false end}
local character={
    FindFirstChild=function(self,k)
        if k=="UpperTorso" then return fake end
        if k=="Torso" then return good end
    end
}
assert(targetPart(character)==good,"malformed torso hid valid R6 fallback")
state.aimMode="head"
assert(targetPart(character)==nil,"head mode selected unrelated object")
state.aimMode="body"
local p={Position=vec(0,0,0),AssemblyLinearVelocity=vec(200,0,0)}
local point=predictedPoint(p)
assert(math.abs(point.X-10)<0.001,"lead exceeded safe prediction cap")
state.prediction=false
assert(predictedPoint(p).X==0,"disabled prediction changed target point")
print("LUAU AIM RIG/PREDICTION PASS")

do
    local aimPro={blockedSince=0,candidates={}}
    local perfCounters={aimScanMs=0,roster={}}
    local Players={}
    local LocalPlayer={Character={FindFirstChild=function() return {} end}}
    local Vector2={new=function(x,y) return {X=x,Y=y} end}
    local camera={ViewportSize={X=900,Y=600}}
    local aimTarget=nil
    local visible=false
    local losChecks=0
    local function canSee(cam,at,char) losChecks+=1; return visible end
    local function sameTeam(player) return false end
    local function examineTarget(cam,player,part,root,center,fov,withLOS)
        return {player=player,part=part,character=player.Character,
            humanoid={},pixelsSquared=player.rank}
    end
    ${findTarget}
    local ch={FindFirstChild=function(self,key)
        if key=="UpperTorso" then return {Position=vec(0,0,0),IsA=function() return true end} end
    end}
    local player={Parent=Players,Character=ch,rank=1}
    perfCounters.roster={player}
    aimTarget={player=player,character=ch,part=good}
    local blocked=findAimTarget(camera)
    assert(blocked and blocked.blocked and aimPro.blockedSince~=0,
        "temporary LOS loss should hold but mark target as occluded")
    visible=true
    local clear=findAimTarget(camera)
    assert(clear and not clear.blocked and aimPro.blockedSince==0,
        "visible target should recover without switching")
    visible=false
    aimPro.blockedSince=os.clock()-1
    local expired=findAimTarget(camera)
    assert(expired==nil,"long-occluded target was retained indefinitely")
    aimTarget=nil
    table.clear(perfCounters.roster)
    for i=1,15 do
        local c={FindFirstChild=ch.FindFirstChild}
        perfCounters.roster[i]={Parent=Players,Character=c,rank=i}
    end
    losChecks=0
    local result=findAimTarget(camera)
    assert(result==nil and losChecks==8,"too many LOS raycasts in dense server")
    print("LUAU AIM LOCK/LOS PASS: no wall tracking, transient hold, 8-candidate cap")
end

`;
fs.writeFileSync("/tmp/Army124-LegacyAim149.luau",program,"utf8");
console.log("Generated extracted production Luau legacy AIM targeting regression");
