"use strict";
const fs=require("node:fs"),assert=require("node:assert/strict");
const src=fs.readFileSync("src/08_ui_controls.lua","utf8");
function extract(a,b){
 const start=src.indexOf(a),end=src.indexOf(b,start+a.length);
 assert.ok(start>=0&&end>start,"Missing production Movement block "+a);
 return src.slice(start,end).trim();
}
const speed=extract("function movement.restoreSpeed()","function movement.recordPart(obj)");
const fly=extract("function movement.retryAutoRotates()","function movement.ensureFly(humanoid, root)");
const pre=String.raw`
local movement={
    speedHumanoid=nil,originalSpeed=nil,lastAppliedSpeed=nil,
    pendingSpeeds=setmetatable({}, {__mode="k"}),
    pendingAutoRotates=setmetatable({}, {__mode="k"}),
    collisionOriginals=setmetatable({}, {__mode="k"}),
    noclipAdded=nil,noclipCharacter=nil,nextNoclipAt=0,
    flyHumanoid=nil,flyRoot=nil,originalAutoRotate=nil,
    velocity=nil,orientation=nil,attachment=nil,
}
local state={noclip=false}
local Enum={HumanoidStateType={Physics="Physics",GettingUp="GettingUp"}}
local function proxy(initial,key)
    local store={Parent={},failBefore=false,failAfter=false}
    store[key]=initial
    local object=setmetatable({}, {
        __index=function(_,name)
            if name=="GetState" then
                return function() return store.state or "Idle" end
            elseif name=="ChangeState" then
                return function(_,to) store.state=to end
            end
            return store[name]
        end,
        __newindex=function(_,name,value)
            if name==key then
                if store.failBefore then error("setter failed before write") end
                store[name]=value
                if store.failAfter then error("setter failed AFTER write") end
            else
                store[name]=value
            end
        end,
    })
    return object,store
end
`;
const checks=String.raw`
-- 1. Failed Speed restore must retain original until next successful retry.
local humanoid,h=proxy(32,"WalkSpeed")
movement.speedHumanoid=humanoid
movement.originalSpeed=16
movement.lastAppliedSpeed=32
h.failBefore=true
assert(movement.restoreSpeed()==false)
assert(movement.pendingSpeeds[humanoid]~=nil)
assert(movement.speedHumanoid==nil)
h.failBefore=false
assert(movement.retryPending()==true)
assert(h.WalkSpeed==16 and movement.pendingSpeeds[humanoid]==nil)

-- 2. A setter can mutate and THEN throw. Readback proves restoration.
local second,s2=proxy(32,"WalkSpeed")
movement.speedHumanoid=second
movement.originalSpeed=16
movement.lastAppliedSpeed=32
s2.failAfter=true
assert(movement.restoreSpeed()==true)
assert(s2.WalkSpeed==16 and movement.pendingSpeeds[second]==nil)

-- 3. External game-owned update must survive script deactivation.
local external,e=proxy(22,"WalkSpeed")
movement.speedHumanoid=external
movement.originalSpeed=16
movement.lastAppliedSpeed=32
assert(movement.restoreSpeed()==true)
assert(e.WalkSpeed==22)

-- 4. Failed CanCollide restore may not forget a true baseline.
local part,p=proxy(false,"CanCollide")
movement.collisionOriginals[part]=true
p.failBefore=true
assert(movement.restoreCollision()==false)
assert(movement.collisionOriginals[part]==true)
p.failBefore=false
assert(movement.retryPending()==true)
assert(p.CanCollide==true and movement.collisionOriginals[part]==nil)

-- 5. Post-mutation setter throw is a completed collision rollback.
local part2,p2=proxy(false,"CanCollide")
movement.collisionOriginals[part2]=true
p2.failAfter=true
assert(movement.restoreCollision()==true)
assert(p2.CanCollide==true and movement.collisionOriginals[part2]==nil)

-- 6. Original false collisions must remain false.
local part3,p3=proxy(false,"CanCollide")
movement.collisionOriginals[part3]=false
assert(movement.restoreCollision()==true)
assert(p3.CanCollide==false)

-- 7. Fly originally changed AutoRotate=false. A denied restore is pending.
local flyHumanoid,f=proxy(false,"AutoRotate")
f.Health=100
f.Sit=false
f.SeatPart=nil
f.state="Physics"
movement.flyHumanoid=flyHumanoid
movement.originalAutoRotate=true
f.failBefore=true
assert(movement.restoreFly()==false)
assert(movement.pendingAutoRotates[flyHumanoid]==true)
assert(f.state=="GettingUp","Physics recovery must be independent from setter")
f.failBefore=false
assert(movement.retryPending()==true)
assert(f.AutoRotate==true and movement.pendingAutoRotates[flyHumanoid]==nil)

-- 8. Post-mutation AutoRotate exception also counts as completed restore.
local fly2,f2=proxy(false,"AutoRotate")
f2.Health=100
f2.state="Physics"
movement.flyHumanoid=fly2
movement.originalAutoRotate=true
f2.failAfter=true
assert(movement.restoreFly()==true)
assert(f2.AutoRotate==true and movement.pendingAutoRotates[fly2]==nil)

-- 9. A failed speed must never skip Noclip and Fly rollback attempts.
local pendingSpeed,ps=proxy(32,"WalkSpeed")
ps.failBefore=true
movement.pendingSpeeds[pendingSpeed]={original=16,last=32}
local freeCollision,fc=proxy(false,"CanCollide")
movement.collisionOriginals[freeCollision]=true
local freeFly,ff=proxy(false,"AutoRotate")
movement.pendingAutoRotates[freeFly]=true
assert(movement.retryPending()==false)
assert(fc.CanCollide==true and ff.AutoRotate==true)
assert(movement.collisionOriginals[freeCollision]==nil
    and movement.pendingAutoRotates[freeFly]==nil)
assert(movement.pendingSpeeds[pendingSpeed]~=nil)
ps.failBefore=false
assert(movement.retryPending()==true and ps.WalkSpeed==16)

-- 10. Active Noclip must not be accidentally undone by recovery.
local activePart,ap=proxy(false,"CanCollide")
movement.collisionOriginals[activePart]=true
state.noclip=true
assert(movement.retryPending()==true)
assert(ap.CanCollide==false)
state.noclip=false
assert(movement.retryPending()==true and ap.CanCollide==true)
assert(not movement.pending())
print("PASS: v1.4.8 real Movement rollback, setter errors, external writes, Fly and independent recovery")
`;
fs.writeFileSync("/tmp/Army124-Movement148.luau",pre+"\n"+speed+"\n"+fly+"\n"+checks,"utf8");
console.log("Generated production Movement rollback Luau fault-injection suite");
