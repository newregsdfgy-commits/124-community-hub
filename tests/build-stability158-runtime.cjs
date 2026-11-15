"use strict";
const fs=require("node:fs");
const assert=require("node:assert/strict");
const movement=fs.readFileSync("src/08_ui_controls.lua","utf8");
const render=fs.readFileSync("src/10_run_and_cleanup.lua","utf8");
function between(src,start,stop,from=0){
 const a=src.indexOf(start,from),b=src.indexOf(stop,a+start.length);
 assert.ok(a>=0&&b>a,"Failed to extract production code: "+start);
 return src.slice(a,b);
}
const record=between(movement,"function movement.recordPart(obj)","function movement.startNoclip(character)");
const stepFrom=movement.indexOf("function movement.step()");
const partLoop=between(movement,
  "            for part in pairs(movement.collisionOriginals) do",
  "        end\n    elseif movement.noclipCharacter then",stepFrom);
const rate=between(render,
  '        if tier ~= "ECO" and (not state.performanceGuard',
  "        espVisualElapsed = ");
const code=String.raw`
do
    local movement={collisionOriginals=setmetatable({}, {__mode="k"})}
    ${record}
    local function part(mode)
        local value=true
        local object={Parent={}}
        function object:IsA(class) return class=="BasePart" end
        setmetatable(object,{
            __index=function(_,key)
                if key=="CanCollide" then return value end
            end,
            __newindex=function(self,key,newValue)
                if key~="CanCollide" then rawset(self,key,newValue); return end
                if mode=="blocked" then error("protected geometry") end
                value=newValue
                if mode=="post" then error("setter threw after mutation") end
            end
        })
        return object, function() return value end
    end
    local good,goodValue=part("ok")
    local blocked,blockedValue=part("blocked")
    local afterError,afterValue=part("post")
    assert(movement.recordPart(blocked)==false)
    assert(movement.recordPart(good)==true and goodValue()==false)
    assert(movement.recordPart(afterError)==true and afterValue()==false)
    assert(movement.collisionOriginals[good]==true and movement.collisionOriginals[blocked]==true)
    good.CanCollide=true
    ${partLoop}
    assert(goodValue()==false,"good part was skipped after another part failed")
    assert(blockedValue()==true and movement.collisionOriginals[blocked]==true,
        "protected part must keep snapshot for future rollback")
    blocked.Parent=nil
    ${partLoop}
    assert(movement.collisionOriginals[blocked]==nil,
        "destroyed part must not linger in the active noclip snapshot set")
    print("PASS: production Noclip partial API failure, independent parts, post-write exception, stale snapshot cleanup")
end

do
    local function visualRate(tier, mode, rangeMeters, fps, guardLevel, motionValid, initialHz)
        local state={performanceMode=mode,espRangeMeters=rangeMeters,performanceGuard=guardLevel>0}
        local CONFIG={EspCameraMotionMinFps=48, EspCameraMotionVisualHz=36, EspLongRangeMeters=350}
        local measuredFps=fps
        local perfCounters={guard={level=guardLevel}}
        local motion={motionUntil=motionValid and 500 or 0}
        local os={clock=function() return 100 end}
        local hz=initialHz
        ${rate}
        return hz
    end
    assert(visualRate("BALANCED","AUTO",200,60,0,true,24)==36)
    assert(visualRate("BALANCED","AUTO",350,60,0,true,18)==18)
    assert(visualRate("BALANCED","AUTO",700,60,0,true,10)==10)
    assert(visualRate("BALANCED","AUTO",1000,60,0,true,10)==10)
    assert(visualRate("BALANCED","AUTO",700,35,0,true,8)==8)
    assert(visualRate("BALANCED","AUTO",200,60,1,true,12)==12)
    assert(visualRate("ECO","AUTO",200,60,0,true,12)==12)
    assert(visualRate("BALANCED","AUTO",200,60,0,false,24)==24)
    assert(visualRate("BALANCED","QUALITY",1000,60,0,true,60)==60)
    print("PASS: production long-range ESP 10/18Hz preserved under camera motion; quality, ECO and Guard respected")
end
`;
fs.writeFileSync("/tmp/Army124-Stability158.luau",code,"utf8");
console.log("Generated v1.5.8 source-extracted Luau fault-injection runtime");
