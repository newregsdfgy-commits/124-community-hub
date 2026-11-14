"use strict";
const fs=require("node:fs");
const assert=require("node:assert/strict");
const gui=fs.readFileSync("src/06_gui_runtime.lua","utf8");
const ui=fs.readFileSync("src/08_ui_controls.lua","utf8");
function extract(text,start,end){
 const a=text.indexOf(start),b=text.indexOf(end,a+start.length);
 assert.ok(a>=0&&b>a,"missing source anchor "+start);
 return text.slice(a,b);
}
const safe=extract(gui,"local function allowTap(input)","-- Dashboard доступен");
const toggle=extract(ui,"local function addToggle(page, title, description, key, onChanged)","local function addButton(page, text, description, handler)");
const aim=extract(ui,'addToggle(pages.AIM, "Aimbot"',"\n-- Critical AIM fallback:");
const weather=extract(ui,'addToggle(pages.PLAYER, "Изменить погоду"',"\naddChoice(pages.PLAYER, \"Пресет погоды\"");
const aimEnable=extract(gui,"local repaintAimTouch = function() end","-- v1.1.0 MEMORY:");
const pre=String.raw`
local now=1
local os={clock=function()return now end}
local alive=true
local Enum={UserInputType={Keyboard="Keyboard",MouseButton1="MouseButton1",Touch="Touch"},
    EasingStyle={Quad="Quad"},EasingDirection={Out="Out"},
    Font={GothamBold="bold",Gotham="regular"},
    TextXAlignment={Left="Left"},
    TextTruncate={AtEnd="AtEnd"}}
local UserInputService={TouchEnabled=true, InputBegan=nil,InputEnded=nil}
local touchGestures=setmetatable({}, {__mode="k"})
local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        self.listeners[#self.listeners+1]=fn
        return {Disconnect=function() end}
    end
    function s:Fire(...)
        for _,fn in ipairs(self.listeners) do fn(...) end
    end
    return s
end
UserInputService.InputBegan=signal()
UserInputService.InputEnded=signal()
local function connect(event,fn)return event:Connect(fn)end
local messages={}
local function tell(msg)messages[#messages+1]=tostring(msg)end
local Color3={fromRGB=function(r,g,b)return {r=r,g=g,b=b}end}
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local ColorSequence={new=function(...)return {...}end}
local UDim2={new=function(...)return {...}end,
    fromOffset=function(...)return {...}end,
    fromScale=function(...)return {...}end}
local TweenInfo={new=function(...)return {...}end}
local TweenService={Create=function(_,obj,info,goal)
    return {Play=function()
        for k,v in pairs(goal)do obj[k]=v end
    end,Cancel=function()end}
end}
local P={accent={},off={},border={},text={},tile={}}
local function round()end
local pages={AIM={Visible=true},PLAYER={Visible=true}}
local gui={Enabled=true}
local panel={Visible=true}
local function columnFor(page)return page end
local function registerWidget(page,row)end
local rows={}
local function mk(kind,props,parent)
    local obj={Parent=parent or {},ClassName=kind,Visible=true,
        Activated=signal(),MouseButton1Click=signal(),InputBegan=signal()}
    for k,v in pairs(props)do obj[k]=v end
    function obj:IsA(c)return self.ClassName==c end
    if kind=="TextButton" then rows[props.Name]=obj end
    if props.Name=="aimbot" then
        obj.AbsolutePosition={X=100,Y=100}
        obj.AbsoluteSize={X=300,Y=54}
    end
    return obj
end
local PlayerGui={blocked=false}
function PlayerGui:GetGuiObjectsAtPosition(x,y)
    if self.blocked then
        return {{Name="CoverModal",IsDescendantOf=function()return false end}}
    end
    return {rows.AimFullRowHitSurface}
end
local boosterPro={}
local state={aimbot=false,playerWeatherEnabled=false,playerWeatherMode="CLEAR",
    aimOnlyRegisteredWeapons=true,aimWeaponNames=""}
local requestCount=0
local function requestSave()requestCount+=1 end
local refreshToggles={}
local refreshChoices={playerWeatherMode=function()end}
local aimHeldKey,aimHeldMouse,aimHeldTouch=false,false,false
local aimPro={equipped=nil,reset=function()end,
    equippedTool=function()return nil end}
local function refreshFovRing()end
local playerFX={weatherFallback=false,calls=0,fail=false}
function playerFX.syncWeather()
    playerFX.calls+=1
    if playerFX.fail then error("injected tone creation denied")end
    playerFX.weatherFallback=state.playerWeatherEnabled
end
`;
const checks=String.raw`
local aimRow=rows.aimbot
local surface=rows.AimFullRowHitSurface
local weatherRow=rows.playerWeatherEnabled
assert(aimRow and surface and weatherRow,"real addToggle must create AIM surface")
local debug=boosterPro.aimClickDebug
assert(debug and debug.presses==0)
local function pointer(kind,x,y)return {
    UserInputType=kind,Position={X=x or 140,Y=y or 120},
}end
-- Missing GuiButton.Activated: global mouse release remains functional.
local m1=pointer(Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Fire(m1)
UserInputService.InputEnded:Fire(m1)
assert(state.aimbot and aimHeldKey and debug.presses==1)
assert(debug.recovered==1)
-- Two separate physical presses 20ms apart must be accepted even though
-- a fallback-only event from the same press may arrive afterward.
now+=0.02
local m2=pointer(Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Fire(m2)
surface.Activated:Fire(m2)
surface.MouseButton1Click:Fire()
UserInputService.InputEnded:Fire(m2)
assert(not state.aimbot and not aimHeldKey and debug.presses==2,
    "double input should turn AIM OFF exactly once")
-- Another touch without InputBegan on the surface must work after cooldown.
now+=0.20
surface.Activated:Fire(pointer(Enum.UserInputType.Touch))
assert(state.aimbot and debug.presses==3)
-- Underlying row Activated remains a fallback when its new surface didn't fire.
now+=0.20
aimRow.Activated:Fire(pointer(Enum.UserInputType.MouseButton1))
assert(not state.aimbot and debug.presses==4)
-- A covered control must not receive a click through another modal.
now+=0.20
PlayerGui.blocked=true
local covered=pointer(Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Fire(covered)
UserInputService.InputEnded:Fire(covered)
assert(not state.aimbot and debug.blocked>0)
PlayerGui.blocked=false
-- Dragging across a ScrollingFrame must not toggle AIM.
now+=0.20
local drag=pointer(Enum.UserInputType.Touch,140,120)
UserInputService.InputBegan:Fire(drag)
drag.Position={X=190,Y=120}
UserInputService.InputEnded:Fire(drag)
assert(not state.aimbot and debug.presses==4)
-- A normal touch release in the hitbox works even with no Activated.
now+=0.20
local touch=pointer(Enum.UserInputType.Touch)
UserInputService.InputBegan:Fire(touch)
UserInputService.InputEnded:Fire(touch)
assert(state.aimbot and debug.presses==5)
now+=0.20
aimRow.Activated:Fire({UserInputType=Enum.UserInputType.Keyboard})
assert(not state.aimbot and debug.presses==6)
-- Legacy-only clicks with no fresh global InputBegan must not inherit the
-- previously consumed press serial for another half second.
now+=0.20
surface.MouseButton1Click:Fire()
assert(state.aimbot and debug.presses==7)
now+=0.20
surface.MouseButton1Click:Fire()
assert(not state.aimbot and debug.presses==8)
-- No delayed input may act on a hidden page.
now+=0.20
pages.AIM.Visible=false
surface.Activated:Fire(pointer(Enum.UserInputType.MouseButton1))
assert(not state.aimbot and debug.presses==8)
-- Generic Weather toggle still uses shared safeActivate, not AIM routing.
now+=0.20
local mouse=pointer(Enum.UserInputType.MouseButton1)
weatherRow.InputBegan:Fire(mouse)
weatherRow.Activated:Fire(mouse)
weatherRow.MouseButton1Click:Fire()
assert(state.playerWeatherEnabled and state.playerWeatherMode=="FOG")
assert(playerFX.calls==1 and playerFX.weatherFallback)
now+=0.20
weatherRow.Activated:Fire(mouse)
weatherRow.MouseButton1Click:Fire()
assert(not state.playerWeatherEnabled)
-- Failed weather tone creation must reset the switch and report an error.
now+=0.20
playerFX.fail=true
weatherRow.Activated:Fire(mouse)
assert(not state.playerWeatherEnabled and playerFX.calls>=3)
local hadError=false
for _,msg in ipairs(messages)do
    if string.find(msg,"Ошибка",1,true) then hadError=true end
end
assert(hadError)
assert(requestCount>=10)
print("PASS: v1.5.2 production Aimbot hitbox, global input release, rapid dedup, mouse, touch, modal blocker, hidden page and Weather")
`;
fs.writeFileSync("/tmp/Army124-AimClick150.luau",pre+"\n"+safe+"\n"+aimEnable+"\n"+toggle+"\n"+aim+"\n"+weather+"\n"+checks,"utf8");
console.log("Generated v1.5.2 production AIM hitbox and Weather Luau runtime");
