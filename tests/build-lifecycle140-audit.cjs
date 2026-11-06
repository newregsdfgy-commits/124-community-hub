"use strict";
const fs=require("node:fs"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
function block(a,b){
 const i=src.indexOf(a),j=src.indexOf(b,i+a.length);
 assert.ok(i>=0&&j>i,"Cannot extract real Luau: "+a);
 return src.slice(i,j).trim();
}
const protectedTree=block("function boosterPro.restoreProtectedTree(character)","local function setBooster(");
const teardown=block("cleanup = function(safeStop)","env.ARMY124_CLEANUP = cleanup");
const code=String.raw`
-- Real v1.1.40 production functions execute in pure Luau with failure mocks.
do
    local alive=true
    local savedGraphics=setmetatable({},{__mode="k"})
    local boosterPro={restoreFailures=0}
    local CONFIG={BoosterLowFpsSliceMs=0.35}
    local jobs,waits,restored,lookups={},0,0,0
    local task={
        spawn=function(fn) jobs[#jobs+1]=fn end,
        wait=function() waits+=1 end
    }
    local function warn(msg) end
    function boosterPro.restoreObject(obj,snap)
        restored+=1
        savedGraphics[obj]=nil
    end
    ${protectedTree}
    local function node(kids)
        return {kids=kids or {},GetChildren=function(self)
            lookups+=1
            return self.kids
        end}
    end
    local children={}
    for i=1,46 do children[i]=node() end
    local target=node()
    table.insert(children,1,target) -- LIFO traverses target after other children
    local char1=node(children)
    local secondTarget=node()
    local char2=node({secondTarget})
    boosterPro.restoreProtectedTree(char1)
    assert(#jobs==0 and lookups==0,"empty snapshots launched a full character scan")
    savedGraphics[target]={CastShadow=true}
    savedGraphics[secondTarget]={CastShadow=true}
    boosterPro.restoreProtectedTree(char1)
    boosterPro.restoreProtectedTree(char1)
    boosterPro.restoreProtectedTree(char2)
    assert(#jobs==1,"expected one worker for multiple respawns")
    assert(#boosterPro.protectedRestoreQueue==2,"duplicate character enqueued")
    jobs[1]()
    assert(restored==2 and waits>=2,"bounded restoration did not finish")
    assert(#boosterPro.protectedRestoreQueue==0 and not boosterPro.protectedRestoreRunning)
    assert(next(boosterPro.protectedRestoreSeen)==nil)
    local before=lookups
    boosterPro.restoreProtectedTree(char1)
    assert(#jobs==1 and lookups==before,"restoration ran without snapshots")
    -- Fault in GetChildren must not latch the worker forever.
    local broken=node()
    broken.GetChildren=function() error("simulated streamed Model failure") end
    savedGraphics[target]={CastShadow=true}
    boosterPro.restoreProtectedTree(broken)
    assert(#jobs==2)
    jobs[2]()
    assert(not boosterPro.protectedRestoreRunning and #boosterPro.protectedRestoreQueue==0)
    assert(savedGraphics[target]~=nil,"failure lost retryable snapshots")
    print("LUAU BOOSTER QUEUE PASS: idle short-circuit, single owner, bounded slices, failure unlock")
end

do
    local alive=true
    local state={esp=true,aimbot=true,controlRecoil=true,antiAim=true,antiAfk=true,
        booster=true,fullbright=true,cameraFovEnabled=true,sessionDiagnostics=false}
    local boosterRevision=2
    local boosterPro={
        protectedRestoreQueue={1,2},protectedRestoreSeen={[1]=true},
        stopWatchingPlayers=function() error("injected player watcher failure") end,
    }
    local savedGraphics=setmetatable({},{__mode="k"})
    local problemObject={Parent={}}
    savedGraphics[problemObject]={CastShadow=true}
    local savedLighting,savedTerrainDecoration,savedTerrainColors=nil,nil,nil
    local failGraphics=true
    boosterPro.restoreGraphicsSliced=function()
        if failGraphics then error("injected graphics restore failure") end
        for obj in pairs(savedGraphics) do savedGraphics[obj]=nil end
        return true
    end
    local memoryFX={
        spin={pending={}, reset=function() error("injected spin reset failure") end,
            restorePending=function() return true end},
        camera={saved={},bound=true,bindingName="CAM",
            reset=function() error("injected camera reset failure") end}
    }
    local eventDisconnected=0
    local connections={}
    for i=1,3 do
        connections[i]={Disconnect=function(self)
            if i==2 then error("injected disconnected event") end
            eventDisconnected+=1
        end}
    end
    local rebound={}
    local RunService={UnbindFromRenderStep=function(self,key)
        rebound[#rebound+1]=key
    end}
    local aimBound=true
    local aimBindingName="AIM"
    local recoil={bound=true,bindingName="RECOIL",
        shutdown=function() error("injected recoil failure") end}
    local perfCounters={session={setEnabled=function() error("injected session failure") end},
        espVisual={bound=true,bindingName="ESP"}}
    local releaseAntiAfk=function() error("injected AntiAFK failure") end
    local stopESPWatchers=function() error("injected ESP watcher failure") end
    local renderData={[{}]={}}
    local deleteRender=function() error("injected GUI render failure") end
    local clearShapes=function() error("injected Box release failure") end
    local hidePanelAnimation=function() error("injected panel animation failure") end
    local gui={Destroy=function(self)self.destroyed=true end}
    local tracerGui,shapeGui,fovGui=nil,nil,nil
    local flushConfig=function() error("injected file save failure") end
    local restoreTerrainGrass=function() return true end
    local restoreTerrainColors=function() return true end
    local applyLighting=function() return true end
    local warn=function() end
    local env={}
    local aimHeldKey,captureAimKey=true,true
    local cleanup
    ${teardown}
    env.ARMY124_CLEANUP=cleanup
    assert(cleanup()==true,"teardown must continue past isolated errors")
    assert(not alive and not state.esp and not state.booster)
    assert(eventDisconnected==2 and #connections==0,"event cleanup was skipped")
    assert(#rebound==4,"render bindings were not released")
    assert(gui.destroyed,"GUI was not released")
    assert(env.ARMY124_CLEANUP==nil,"stale cleanup owner remained")
    assert(type(env.ARMY124_RECOVERY)=="function","failed graphics lost recovery hook")
    assert(savedGraphics[problemObject]~=nil,"failed graphics snapshot was discarded")
    -- Restore mock engine operations so recovery can complete.
    failGraphics=false
    memoryFX.camera.reset=function() return true end
    assert(env.ARMY124_RECOVERY()==true,"recovery failed after engine resumed")
    assert(next(savedGraphics)==nil and env.ARMY124_RECOVERY==nil)
    print("LUAU CLEANUP PASS: fault isolation, disconnect before rollback, retryable recovery")
end
`.replaceAll("${protectedTree}",protectedTree).replaceAll("${teardown}",teardown);
fs.writeFileSync("/tmp/Army124-Lifecycle140.luau",code,"utf8");
console.log("Generated v1.1.40 executable Luau lifecycle/Booster fault injection");
