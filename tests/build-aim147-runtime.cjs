"use strict";
const fs=require("node:fs");
const assert=require("node:assert/strict");
const src=fs.readFileSync("src/04_lighting_and_booster.lua","utf8");
const start=src.indexOf("-- AIM: поиск объекта в FOV");
assert.ok(start>=0,"missing production AIM block");
const production=src.slice(start);
assert.ok(production.includes("local function findAimTarget(camera)"));
assert.ok(production.includes("local function aimFrame(dt)"));
const pre=String.raw`
local vec
local mt={}
vec=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},mt) end
mt.__index=function(self,key)
    if key=="Magnitude" then
        return math.sqrt(self.X*self.X+self.Y*self.Y+self.Z*self.Z)
    elseif key=="Unit" then
        local m=(self.X*self.X+self.Y*self.Y+self.Z*self.Z)^0.5
        return vec(self.X/m,self.Y/m,self.Z/m)
    elseif key=="Dot" then
        return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
    elseif key=="Lerp" then
        return function(a,b,t)
            return vec(a.X+(b.X-a.X)*t,a.Y+(b.Y-a.Y)*t,a.Z+(b.Z-a.Z)*t)
        end
    end
end
mt.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
mt.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
mt.__mul=function(a,b)
    if type(a)=="number" then return vec(a*b.X,a*b.Y,a*b.Z) end
    return vec(a.X*b,a.Y*b,a.Z*b)
end
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local typeof=function(v)
    if getmetatable(v)==mt then return "Vector3" end
    return type(v)
end
local cfMeta={}
cfMeta.__index={
    VectorToObjectSpace=function(_,direction) return direction end,
}
cfMeta.__mul=function(a,rotation)
    return setmetatable({
        Position=a.Position,
        yaw=rotation.yaw,pitch=rotation.pitch,
    },cfMeta)
end
local CFrame={Angles=function(pitch,yaw,roll)
    return {pitch=pitch,yaw=yaw,roll=roll}
end}
local function camera()
    local cam={ViewportSize={X=900,Y=600},
        CFrame=setmetatable({Position=vec(0,0,0)},cfMeta)}
    function cam:WorldToViewportPoint(point)
        return {X=450+point.X*20,Y=300-point.Y*20,Z=-point.Z},
            point.Z<0 and math.abs(point.X)<45 and math.abs(point.Y)<30
    end
    return cam
end
local Players={}
local myRoot={Position=vec(0,0,0),IsA=function(_,k)return k=="BasePart"end}
local localCharacter={
    Parent=Players,
    FindFirstChild=function(_,name)if name=="HumanoidRootPart"then return myRoot end end,
}
local LocalPlayer={Character=localCharacter,Team=nil,Parent=Players}
local function newPlayer(name,x)
    local player={Name=name,Team=nil,Parent=Players}
    local character={Parent=Players}
    local humanoid={Health=100}
    local part={Position=vec(x,0,-20),AssemblyLinearVelocity=vec(0,0,0)}
    part.Parent=character
    function part:IsA(k) return k=="BasePart" end
    function part:IsDescendantOf(other) return other==character end
    function character:FindFirstChild(k)
        if k=="UpperTorso" then return part end
    end
    function character:FindFirstChildOfClass(k)
        if k=="Humanoid" then return humanoid end
    end
    player.Character=character
    return player,part,humanoid
end
local playerA,partA,humA=newPlayer("A",7)
local playerB,partB,humB=newPlayer("B",24)
local perfCounters={aimScanMs=0,roster={playerA,playerB}}
local state={
    aimbot=true,aimOnlyRegisteredWeapons=false,targetLock=true,
    teamCheck=false,visibleCheck=true,aimRangeMeters=180,
    aimMode="body",aimFovPixels=175,aimStability=3,
    aimDeadzonePixels=2,aimSmoothness=0,aimSmoothX=5,aimSmoothY=5,
    prediction=false,predictionSeconds=0.08,
}
local CONFIG={
    StudMeters=0.28,AimLockTolerance=1.18,AimVisibleRaycastChecks=6,
    AimLosCandidatesPerScan=8,AimPredictionMaxStuds=10,
    AimOcclusionGraceSeconds=0.16,AimLockLostGraceSeconds=0.20,
    AimSwitchConfirmSeconds=0.16,AimPredictionResponseHz=18,
    AimMaxTurnDegreesPerSecond=360,AimSmoothnessBaseline=33,
    AimLosEcoSeconds=0.075,AimLosQualitySeconds=0.02,
    AimLosBalancedSeconds=0.045,AimScanInterval=0.12,
    AimLostRescanSeconds=0.06,
}
local wall={Transparency=0}
function wall:IsDescendantOf(_)return false end
function wall:IsA(k)return k=="BasePart"end
local blockA=false
local rayFailure=false
local workspaceCamera=camera()
local Workspace={CurrentCamera=workspaceCamera}
function Workspace:Raycast(origin,direction,params)
    if rayFailure then error("temporary raycast denied") end
    if blockA and direction.X>6 then return {Instance=wall} end
    return nil
end
local UserInputService={GetFocusedTextBox=function()return nil end}
local GuiService={MenuIsOpen=false}
local alive=true
local aimHeldMouse=false
local aimHeldTouch=false
local aimHeldKey=true
local aimTarget=nil
local aimNextScan=0
local now=1
local os={clock=function()return now end}
local aimPro={
    rayParams={},rayIgnore={},candidates={},
    blockedSince=0,lostSince=0,switchCandidate=nil,switchSince=0,
    nextLos=0,leadPart=nil,leadPoint=nil,lastCamera=nil,lastLocalCharacter=nil,
}
function aimPro.equippedTool()return true end
function aimPro.reset()
    aimTarget=nil
    aimNextScan=0
    aimPro.nextLos=0
    aimPro.blockedSince=0
    aimPro.lostSince=0
    aimPro.switchCandidate=nil
    aimPro.switchSince=0
    aimPro.leadPart,aimPro.leadPoint=nil,nil
end
local function perfTier()return "QUALITY" end
`;
const checks=String.raw`
local function tick(t)
    now=t
    aimNextScan=0
    local before=Workspace.CurrentCamera.CFrame
    aimFrame(1/60)
    return before~=Workspace.CurrentCamera.CFrame
end
assert(tick(1.0),"initial visible target should turn camera")
assert(aimTarget and aimTarget.player==playerA)
local maxStep=math.rad(CONFIG.AimMaxTurnDegreesPerSecond)/60
local first=Workspace.CurrentCamera.CFrame
assert(first.yaw and math.abs(first.yaw)>0)
assert(math.sqrt(first.yaw^2+first.pitch^2)<=maxStep+1e-6,
    "Smoothness=0 must not teleport camera")
-- Target moves outside locked FOV, competitor moves inside:
-- short FOV interruption must not immediately switch target.
partA.Position=vec(16,0,-20)
partB.Position=vec(4,0,-20)
assert(not tick(1.1),"streaming/FOV grace must not rotate")
assert(aimTarget.player==playerA and aimTarget.blocked)
assert(not tick(1.45),"first alternate-target scan needs confirmation")
assert(aimTarget.player==playerA and aimTarget.blocked)
assert(aimPro.switchCandidate==playerB)
assert(tick(1.65),"confirmed alternative should be aimed at")
assert(aimTarget.player==playerB and not aimTarget.blocked)
local turn=Workspace.CurrentCamera.CFrame
assert(math.sqrt(turn.yaw^2+turn.pitch^2)<=maxStep+1e-6)
-- Deadzone catches micro-jitter from target around the crosshair.
partB.Position=vec(0.05,0,-20)
assert(not tick(1.8),"deadzone should suppress tiny camera changes")
-- LOS failure must hold identity and never aim through a wall.
aimPro.reset()
partA.Position=vec(7,0,-20)
partB.Position=vec(24,0,-20)
blockA=false
assert(tick(2.0))
assert(aimTarget.player==playerA)
blockA=true
assert(not tick(2.07))
assert(aimTarget and aimTarget.blocked)
assert(not tick(2.3),"blocked target should never steer")
assert(aimTarget==nil or aimTarget.blocked)
-- A failing Raycast must fail closed and not throw/render through an obstruction.
aimPro.reset()
blockA=false
rayFailure=true
assert(not tick(2.6))
assert(aimTarget==nil)
rayFailure=false
-- Prediction spikes (NaN/Inf) cannot corrupt camera math.
partA.AssemblyLinearVelocity=vec(0/0,0,0)
state.prediction=true
local safe=predictedPoint(partA)
assert(safe==partA.Position,"NaN velocity should preserve raw target point")
state.prediction=false
partA.AssemblyLinearVelocity=vec(0,0,0)
-- Dead or reparented players must be abandoned without steering.
aimPro.reset()
assert(tick(3.0))
humA.Health=0
assert(not tick(3.1))
assert(not aimTarget or aimTarget.player~=playerA)
print("PASS: v1.4.7 production AIM lock, FOV grace, switch confirmation, LOS, smoothing, deadzone, prediction safety")
`;
fs.writeFileSync("/tmp/Army124-Aim147.luau",pre+"\n"+production+"\n"+checks,"utf8");
console.log("Generated v1.4.7 production AIM Luau behavioral harness");
