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
const aim=extract(ui,'addToggle(pages.AIM, "Aimbot"',"\naddAimModeSelector(pages.AIM)");
const weather=extract(ui,'addToggle(pages.PLAYER, "Изменить погоду"',"\naddChoice(pages.PLAYER, \"Пресет погоды\"");
const aimEnable=extract(gui,"local repaintAimTouch = function() end","-- v1.1.0 MEMORY:");
const pre=String.raw`
local now=1
local os={clock=function()return now end}
local alive=true
local Enum={UserInputType={Keyboard="Keyboard",MouseButton1="MouseButton1",Touch="Touch"},
    EasingStyle={Quad="Quad"},EasingDirection={Out="Out"}}
local UserInputService={TouchEnabled=true}
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
local function connect(event,fn)return event:Connect(fn)end
local messages={}
local function tell(msg) messages[#messages+1]=tostring(msg) end
local Color3={fromRGB=function(r,g,b) return {r=r,g=g,b=b} end}
local UDim2={
    new=function(...)return {...}end,
    fromOffset=function(...)return {...}end,
}
local TweenInfo={new=function(...) return {...}end}
local TweenService={Create=function(_,obj,info,goal)
    return {Play=function()
        for k,v in pairs(goal) do obj[k]=v end
    end,Cancel=function()end}
end}
local P={accent={},off={},border={},text={},tile={}}
local function round()end
local pages={AIM={},PLAYER={}}
local function columnFor(page)return page end
local function registerWidget(page,row)end
local rows={}
local function mk(kind,props,parent)
    local obj={Parent=parent or {},ClassName=kind,
        Activated=signal(),MouseButton1Click=signal(),InputBegan=signal()}
    for k,v in pairs(props)do obj[k]=v end
    function obj:IsA(c)return self.ClassName==c end
    if kind=="TextButton" then rows[props.Name]=obj end
    return obj
end
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
    if playerFX.fail then error("injected tone creation denied") end
    playerFX.weatherFallback=state.playerWeatherEnabled
end
`;
const checks=String.raw`
local aimRow=rows.aimbot
local weatherRow=rows.playerWeatherEnabled
assert(aimRow and weatherRow,"actual addToggle must create TextButton rows")
local mouse={UserInputType=Enum.UserInputType.MouseButton1}
local touch={UserInputType=Enum.UserInputType.Touch}
aimRow.InputBegan:Fire(mouse)
aimRow.Activated:Fire(mouse)
aimRow.MouseButton1Click:Fire()
assert(state.aimbot and aimHeldKey,"AIM GUI click must activate key-held mode")
-- No second InputBegan delivered; 200ms later control must still work.
now+=0.20
aimRow.Activated:Fire(mouse)
aimRow.MouseButton1Click:Fire()
assert(not state.aimbot and not aimHeldKey,"AIM GUI must toggle OFF after missing InputBegan")
now+=0.20
aimRow.Activated:Fire(touch)
assert(state.aimbot and aimHeldKey,"touch must turn on AIM again")
-- Rapid real separate presses must both toggle.
now+=0.02
aimRow.InputBegan:Fire(mouse)
aimRow.Activated:Fire(mouse)
aimRow.MouseButton1Click:Fire()
assert(not state.aimbot,"separate physical press not accepted")
-- Weather must apply a visible local fallback when world lighting is denied.
now+=0.30
weatherRow.InputBegan:Fire(mouse)
weatherRow.Activated:Fire(mouse)
weatherRow.MouseButton1Click:Fire()
assert(state.playerWeatherEnabled and state.playerWeatherMode=="FOG")
assert(playerFX.calls==1 and playerFX.weatherFallback)
now+=0.20
weatherRow.Activated:Fire(mouse)
weatherRow.MouseButton1Click:Fire()
assert(not state.playerWeatherEnabled,"weather OFF click ignored")
assert(playerFX.calls==2)
-- A failed UI tone constructor is still reported and the state rolls back.
now+=0.20
playerFX.fail=true
weatherRow.Activated:Fire(mouse)
assert(not state.playerWeatherEnabled)
assert(playerFX.calls==3)
local hadError=false
for _,msg in ipairs(messages) do
    if string.find(msg,"Ошибка",1,true) then hadError=true end
end
assert(hadError,"Weather must surface an actionable error message")
assert(requestCount>=5,"state changes must request persistence")
print("PASS: v1.4.9 production addToggle + safeActivate AIM click/hold, missing InputBegan, touch, weather fallback and failure rollback")
`;
fs.writeFileSync("/tmp/Army124-Buttons149.luau",pre+"\n"+safe+"\n"+aimEnable+"\n"+toggle+"\n"+aim+"\n"+weather+"\n"+checks,"utf8");
console.log("Generated actual production Aimbot & Weather GUI toggle Luau runtime");
