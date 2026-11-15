"use strict";
const fs=require("node:fs");
const assert=require("node:assert/strict");
const ui=fs.readFileSync("src/08_ui_controls.lua","utf8");
const first=ui.indexOf("-- Critical AIM fallback:");
const last=ui.indexOf("\naddAimModeSelector(pages.AIM)",first);
assert.ok(first>=0&&last>first,"Pinned AIM production block missing");
const pinned=ui.slice(first,last);

const pre=String.raw`
local now = 1
local os={clock=function()return now end}
local alive=true
local Enum={UserInputType={Keyboard="Keyboard",MouseButton1="MouseButton1",Touch="Touch"},
    Font={GothamBold="GothamBold"}}
local Color3={fromRGB=function(r,g,b)return {r=r,g=g,b=b}end}
local UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end}
local function signal()
    local s={listeners={}}
    function s:Connect(fn)self.listeners[#self.listeners+1]=fn
        return {Disconnect=function()end}end
    function s:Fire(...)
        for _,fn in ipairs(self.listeners)do fn(...)end
    end
    return s
end
local UserInputService={InputBegan=signal(),InputEnded=signal()}
local function connect(event,fn)return event:Connect(fn)end
local P={panel={},tile={},border={},text={}}
local function round()end
local objects={}
local function mk(kind,props,parent)
    local o={ClassName=kind,Parent=parent,Visible=true,
        Activated=signal(),MouseButton1Click=signal()}
    for k,v in pairs(props)do o[k]=v end
    function o:IsDescendantOf(ancestor)
        local p=self.Parent
        while p do if p==ancestor then return true end p=p.Parent end
        return false
    end
    if props.Name=="AimPinnedSwitch" then
        o.AbsolutePosition={X=102,Y=90}
        o.AbsoluteSize={X=280,Y=39}
    end
    if props.Name then objects[props.Name]=o end
    return o
end
local PlayerGui={overlay=false}
function PlayerGui:GetGuiObjectsAtPosition(x,y)
    if self.overlay then
        return {{Name="CoverModal",IsDescendantOf=function()return false end}}
    end
    return {objects.AimPinnedSwitch}
end
local gui={Enabled=true}
local panel={Visible=true}
local pages={AIM={Visible=true}}
local state={aimbot=false}
local message={}
local function tell(text)table.insert(message,text)end
local setCalls=0
local refreshToggles={aimbot=function()end}
local repaintCount=0
refreshToggles.aimbot=function()repaintCount+=1 end
local function setAimEnabled(value,active)
    setCalls+=1
    state.aimbot=value==true
    assert(active==value,"button must start/stop held aiming exactly with enable")
    refreshToggles.aimbot()
end
local function allowTap(input)return true end
local boosterPro={}
`;
const checks=String.raw`
local btn=objects.AimPinnedSwitch
local dock=objects.AimPinnedControlDock
local stats=boosterPro.pinnedAimClickDebug
assert(btn and dock and stats)
assert(btn.Text:find("OFF",1,true) and stats.presses==0)
local function pointer(kind,x,y)
    return {UserInputType=kind,Position={X=x or 145,Y=y or 110}}
end
-- Native callback on the standalone, non-scrolling AIM button.
local a1=pointer(Enum.UserInputType.MouseButton1)
btn.Activated:Fire(a1)
btn.MouseButton1Click:Fire()
assert(state.aimbot and setCalls==1 and stats.presses==1)
assert(btn.Text:find("ON",1,true) and repaintCount==1)
-- No Activated delivered: fallback InputEnded on native coordinates.
now+=0.30
local a2=pointer(Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Fire(a2)
UserInputService.InputEnded:Fire(a2)
assert(not state.aimbot and stats.released==1 and setCalls==2)
-- Separate rapid physical presses are not throttled.
now+=0.01
local a3=pointer(Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Fire(a3)
btn.Activated:Fire(a3)
btn.MouseButton1Click:Fire()
UserInputService.InputEnded:Fire(a3)
assert(state.aimbot and setCalls==3 and stats.presses==3)
now+=0.01
local a4=pointer(Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Fire(a4)
btn.Activated:Fire(a4)
UserInputService.InputEnded:Fire(a4)
assert(not state.aimbot and stats.presses==4)
-- No global InputBegan: consecutive independent native-only clicks remain valid.
now+=0.20
btn.MouseButton1Click:Fire()
assert(state.aimbot and stats.presses==5)
now+=0.20
btn.MouseButton1Click:Fire()
assert(not state.aimbot and stats.presses==6)
-- InputObject identity may differ at mouse-button release.
now+=0.20
local a5=pointer(Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Fire(a5)
UserInputService.InputEnded:Fire(pointer(Enum.UserInputType.MouseButton1))
assert(state.aimbot and stats.presses==7)
-- Touch drag beyond threshold must not switch.
now+=0.20
local dragged=pointer(Enum.UserInputType.Touch)
UserInputService.InputBegan:Fire(dragged)
dragged.Position={X=195,Y=110}
UserInputService.InputEnded:Fire(dragged)
assert(state.aimbot and stats.presses==7)
-- A modal covers the button: do not click through it.
now+=0.20
PlayerGui.overlay=true
local covered=pointer(Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Fire(covered)
UserInputService.InputEnded:Fire(covered)
assert(state.aimbot and stats.rejected>0 and stats.presses==7)
PlayerGui.overlay=false
-- Hidden AIM tab and disabled GUI reject attempts.
pages.AIM.Visible=false
now+=0.20
btn.Activated:Fire(pointer(Enum.UserInputType.MouseButton1))
assert(stats.presses==7)
pages.AIM.Visible=true
gui.Enabled=false
btn.Activated:Fire(pointer(Enum.UserInputType.MouseButton1))
assert(stats.presses==7)
gui.Enabled=true
-- Keyboard support independent of pointer-release fallback.
now+=0.20
btn.Activated:Fire(pointer(Enum.UserInputType.Keyboard))
assert(not state.aimbot and stats.presses==8)
print("PASS: v1.5.3 independent pinned AIM toggle actual production Luau: native, fallback, drag, overlay, rapid clicks, state repaint")
`;
fs.writeFileSync("/tmp/Army124-PinnedAim152.luau",pre+"\n"+pinned+"\n"+checks,"utf8");
console.log("Generated executable production v1.5.3 pinned AIM switch test");
