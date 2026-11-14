#!/usr/bin/env python3
"""Execute actual v1.4.4 GUI input and weather callbacks in Luau.

Deterministic fakes for Roblox signal and state are used; UI rendering must
still be manually verified in a Roblox client.
"""
from pathlib import Path
from tempfile import gettempdir

ROOT=Path(__file__).resolve().parents[1]
gui=(ROOT/"src/06_gui_runtime.lua").read_text(encoding="utf-8")
ui=(ROOT/"src/08_ui_controls.lua").read_text(encoding="utf-8")

def extract(src, start, end):
    a=src.index(start)
    b=src.index(end, a+len(start))
    assert src.count(start)==1, f"ambiguous {start}"
    return src[a:b]

core=extract(gui, "local function allowTap(input)", "-- Dashboard доступен")
selector=extract(gui, "local function columnFor(page)", "local function registerWidget(page, widget)")

start=ui.index('"playerWeatherEnabled", function(enabled)')
end=ui.index('\n    end)\naddChoice(pages.PLAYER, "Пресет погоды"', start)
toggle=ui[start+len('"playerWeatherEnabled", '):end]+"\n    end"

start=ui.index('}, "playerWeatherMode", function(mode)')
end=ui.index('\nend)\n\naddSection(pages.PLAYER, "ENVIRONMENT COLOR"', start)
choice=ui[start+len('}, "playerWeatherMode", '):end]+"\nend"

pre=r'''
local now=1
local os={clock=function() return now end}
local alive=true
local Enum={UserInputType={Keyboard="Keyboard",MouseButton1="MouseButton1",Touch="Touch"}}
local UserInputService={TouchEnabled=true}
local touchGestures=setmetatable({}, {__mode="k"})
local function signal()
   local x={callbacks={}}
   function x:Connect(fn)
      self.callbacks[#self.callbacks+1]=fn
      return {Disconnect=function() end}
   end
   function x:Fire(...)
      for _,fn in ipairs(self.callbacks) do fn(...) end
   end
   return x
end
local function connect(ev,cb) return ev:Connect(cb) end
local eventErrors={}
local function tell(s) eventErrors[#eventErrors+1]=s end
'''
after_core=r'''
local function newButton()
    local x={Activated=signal(), MouseButton1Click=signal()}
    function x:IsA(cls) return cls=="TextButton" end
    return x
end
local calls=0
local button=newButton()
safeActivate(button, function() calls=calls+1 end)
local mouse={UserInputType=Enum.UserInputType.MouseButton1}
button.Activated:Fire(mouse)
button.MouseButton1Click:Fire()
assert(calls==1,"double-click handler toggled twice")
now=now+0.5
button.MouseButton1Click:Fire()
assert(calls==2,"fallback click should work independently")
now=now+0.5
local dragged={UserInputType=Enum.UserInputType.Touch}
touchGestures[dragged]={dragged=true,endedAt=now}
button.Activated:Fire(dragged)
assert(calls==2,"drag must not become click")
local tapped={UserInputType=Enum.UserInputType.Touch}
touchGestures[tapped]={dragged=false,endedAt=now}
button.Activated:Fire(tapped)
assert(calls==3,"real touch tap must work despite previous scrolling")
assert(#eventErrors==0)

-- Production columnFor must take the initial responsive result even if
-- widgets are appended later, before a second ViewportSizeChanged event.
local left, right={},{}
local page={}
local pageColumns={[page]={left=left,right=right,side="right",singleColumn=true}}
local wideLayout=true
'''
after_selector=r'''
assert(columnFor(page)==left,"late UI must use currently visible column")
pageColumns[page].singleColumn=false
assert(columnFor(page)==right,"later wide layout may restore right column")

local state={playerWeatherEnabled=false,playerWeatherMode="CLEAR"}
local weatherCalls=0
local failWeather=false
local playerFX={
    syncWeather=function()
        weatherCalls=weatherCalls+1
        if failWeather then error("weather denied") end
    end
}
local choiceRefresh=0
local toggleRefresh=0
local refreshChoices={playerWeatherMode=function() choiceRefresh=choiceRefresh+1 end}
local refreshToggles={playerWeatherEnabled=function() toggleRefresh=toggleRefresh+1 end}
'''
checks=r'''
-- Exact callbacks extracted from addToggle and addChoice below.
assert(state.playerWeatherMode=="CLEAR")
state.playerWeatherEnabled=true
onWeatherToggle(true)
assert(state.playerWeatherMode=="FOG" and weatherCalls==1 and choiceRefresh==1)
state.playerWeatherEnabled=false
onWeatherToggle(false)
assert(weatherCalls==2 and state.playerWeatherMode=="FOG")
state.playerWeatherMode="RAIN"
onWeatherChoice("RAIN")
assert(state.playerWeatherEnabled and weatherCalls==3)
state.playerWeatherMode="CLEAR"
onWeatherChoice("CLEAR")
assert(not state.playerWeatherEnabled and weatherCalls==4)
-- Failed toggle returns the previously selected mode to generic addToggle.
state.playerWeatherEnabled=true
failWeather=true
local ok=pcall(onWeatherToggle,true)
assert(not ok and state.playerWeatherMode=="CLEAR")
state.playerWeatherEnabled=false
failWeather=false
-- Failed selection reverts enabled flag; addChoice also reverts selected mode.
state.playerWeatherMode="FOG"
state.playerWeatherEnabled=false
failWeather=true
ok=pcall(onWeatherChoice,"FOG")
assert(not ok and state.playerWeatherEnabled==false)
print("PASS: real Gui safeActivate double-click/touch; late responsive columns; weather callbacks and rollback")
'''
content=pre+"\n"+core+"\n"+after_core+"\n"+selector+"\n"+after_selector
content+="\nlocal onWeatherToggle = "+toggle
content+="\nlocal onWeatherChoice = "+choice
content+="\n"+checks
out=Path(gettempdir())/"Army124-Controls144.luau"
out.write_text(content,encoding="utf-8")
print("Created actual controls/weather Luau harness:",out)
