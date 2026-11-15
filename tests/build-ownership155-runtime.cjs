"use strict";
const fs=require("node:fs");
const assert=require("node:assert/strict");
const gui=fs.readFileSync("src/06_gui_runtime.lua","utf8");
const ui=fs.readFileSync("src/08_ui_controls.lua","utf8");
function extract(source,start,end){
    const a=source.indexOf(start),b=source.indexOf(end,a+start.length);
    assert.ok(a>=0&&b>a,"source region not found: "+start);
    assert.equal(source.indexOf(start,a+start.length),-1,"ambiguous source region");
    return source.slice(a,b);
}
const camera=extract(gui,"function memoryFX.camera.restore(camera)","-- Неудачные снимки C0/AutoRotate");
const music=extract(ui,"local privateMusic = {","-- PLAYER TAB:");
const cameraTest=String.raw`
do
    local alive=true
    local state={cameraFovEnabled=true,cameraFovDegrees=90}
    local Workspace={CurrentCamera={FieldOfView=70}}
    local memoryFX={camera={saved=setmetatable({}, {__mode="k"}),
        written=setmetatable({}, {__mode="k"}),current=nil}}
    ${camera}
    local camera1=Workspace.CurrentCamera
    memoryFX.camera.apply()
    assert(camera1.FieldOfView==90 and memoryFX.camera.written[camera1]==90)
    assert(memoryFX.camera.saved[camera1]==70)
    -- External game zoom after our write, before the next render callback.
    camera1.FieldOfView=62
    state.cameraFovEnabled=false
    assert(memoryFX.camera.reset()==true)
    assert(camera1.FieldOfView==62,"OFF overwrote newer game FOV")
    assert(next(memoryFX.camera.saved)==nil and next(memoryFX.camera.written)==nil)
    -- External game zoom while ON is the new original, not old 70.
    state.cameraFovEnabled=true
    memoryFX.camera.apply()
    assert(camera1.FieldOfView==90)
    camera1.FieldOfView=58
    memoryFX.camera.apply()
    assert(camera1.FieldOfView==90 and memoryFX.camera.saved[camera1]==58)
    state.cameraFovEnabled=false
    assert(memoryFX.camera.reset()==true and camera1.FieldOfView==58)
    -- Changing Camera instance must restore original camera before moving on.
    state.cameraFovEnabled=true
    memoryFX.camera.apply()
    local camera2={FieldOfView=74}
    Workspace.CurrentCamera=camera2
    memoryFX.camera.apply()
    assert(camera1.FieldOfView==58 and camera2.FieldOfView==90)
    state.cameraFovEnabled=false
    assert(memoryFX.camera.reset() and camera2.FieldOfView==74)
    -- Readonly/blocked setters must never generate fake ownership metadata.
    local held=75
    local refused=setmetatable({},{
        __index=function(_,key)if key=="FieldOfView" then return held end end,
        __newindex=function(_,key,value)error("setter rejected")end
    })
    Workspace.CurrentCamera=refused
    state.cameraFovEnabled=true
    memoryFX.camera.apply()
    assert(held==75 and memoryFX.camera.written[refused]==nil)
    state.cameraFovEnabled=false
    assert(memoryFX.camera.reset()==true and held==75)
    -- Post-mutation setter exception: verify readback and restore owned FOV.
    local actual=80
    local raised=setmetatable({},{
        __index=function(_,key)if key=="FieldOfView" then return actual end end,
        __newindex=function(_,key,value)
            actual=value
            error("setter wrote then raised")
        end
    })
    Workspace.CurrentCamera=raised
    state.cameraFovEnabled=true
    memoryFX.camera.apply()
    assert(actual==90 and memoryFX.camera.written[raised]==90)
    state.cameraFovEnabled=false
    assert(memoryFX.camera.reset()==true and actual==80)
    print("PASS: production Camera FOV ownership, external updates, denial, post-write throw and camera handoff")
end
`;
const musicTest=String.raw`
do
    local alive=true
    local state={musicVolume=50,musicLoop=false}
    local service={}
    local created=0
    local task={delay=function()end}
    local function signal()
        local o={}
        function o:Connect(callback)
            return {Disconnect=function()end}
        end
        return o
    end
    local Instance={new=function(class)
        assert(class=="Sound")
        created+=1
        local sound={Loaded=signal(),Ended=signal(),IsLoaded=true}
        function sound:Play()
            assert(not self.destroyed,"Destroyed Sound must never be reused")
            self.playCount=(self.playCount or 0)+1
        end
        function sound:Resume()self:Play()end
        function sound:Stop()self.stopped=true end
        function sound:Destroy()
            self.destroyed=true
            self.Parent=nil
        end
        return sound
    end}
    local game={GetService=function(_,key)
        assert(key=="SoundService")
        return service
    end}
    local boosterPro={}
    ${music}
    local ok,err=privateMusic.play("123")
    assert(ok,err)
    local first=privateMusic.sound
    assert(first.Parent==service and first.playCount==1 and created==1)
    first.Parent=nil  -- A game system removed the sound.
    ok,err=privateMusic.play("123")
    assert(ok,err)
    assert(first.destroyed and first.stopped)
    local second=privateMusic.sound
    assert(second~=first and second.Parent==service and second.playCount==1 and created==2)
    ok,err=privateMusic.play("456")
    assert(ok,err)
    assert(second.destroyed and privateMusic.currentId=="456" and created==3)
    local third=privateMusic.sound
    privateMusic.paused=true
    ok,err=privateMusic.play("456")
    assert(ok,err)
    assert(privateMusic.sound==third and third.playCount==2 and created==3)
    privateMusic.shutdown()
    assert(third.destroyed and privateMusic.sound==nil)
    assert(select(1,privateMusic.play("invalid"))==false)
    print("PASS: production Music same-ID destroyed Sound recovery, ID change, resume and shutdown")
end
`;
fs.writeFileSync("/tmp/Army124-Ownership155.luau",cameraTest+"\n"+musicTest,"utf8");
console.log("Generated v1.5.5 Camera + Music source-level runtime fault injection");
