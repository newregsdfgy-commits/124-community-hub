"use strict";
const fs=require("node:fs"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
function extract(a,b){
 const i=src.indexOf(a),j=src.indexOf(b,i+a.length);
 assert.ok(i>=0&&j>i,"Cannot extract actual slider code");
 return src.slice(i,j).trimEnd();
}
const fragment=extract("    local pointer = nil\n    local function cancelPointer()","    -- Original ESP limit is 200 m;");
const program=String.raw`
-- Real Luau function from Visuals.lua executing under a minimal UI mock.
-- This test would reproduce the user's UI:INITIALIZATION nil.Parent crash
-- if 'container.Parent' were accidentally reintroduced.
local UDim2 = {
    new = function(...) return {...} end,
    fromOffset = function(...) return {...} end,
    fromScale = function(...) return {...} end
}
local Vector2 = {new = function(x,y) return {X=x,Y=y} end}
local Color3 = {fromRGB = function(...) return {...} end}
local Enum = {Font = {Gotham="Gotham",GothamMedium="Medium"},
    UserInputType = {Touch="Touch",MouseButton1="Left",MouseMovement="Move"}}
local function signal() return {handlers={}} end
local userChanged, userEnded = signal(), signal()
local UserInputService = {InputChanged=userChanged,InputEnded=userEnded}
local function connect(event,fn)
    table.insert(event.handlers,fn)
    return {Disconnect=function() end}
end
local function emit(event,arg)
    for _,cb in ipairs(event.handlers) do cb(arg) end
end
local nodes={}
local function mk(class,props,parent)
    local obj=props or {}
    obj.Parent=parent
    obj.ClassName=class
    obj.AbsolutePosition={X=0,Y=0}
    obj.AbsoluteSize={X=100,Y=24}
    obj.InputBegan=signal()
    table.insert(nodes,obj)
    return obj
end
local function corners(obj) return obj end
local function textLabel(parent,name,caption,position,size,fontSize,color,font)
    return mk("TextLabel",{Name=name,Text=caption,Position=position,Size=size},parent)
end
local function find(name)
    for _,node in ipairs(nodes) do
        if node.Name==name then return node end
    end
    error("missing UI node: "..name)
end
local light,raised={},{}
local panel={Visible=true}
local root={Visible=true}
local pages={ESP={Visible=true}}
local alive=true
local state={espRangeMeters=200,aimFovPixels=200}
local refreshSliders={}
local saved=0
local function requestSave() saved+=1 end
local function tell(msg) error("unexpected UI error: "..tostring(msg)) end
${fragment}
local changes=0
local parent={Name="UISliderParent"}
makeSlider(parent,"Max Distance","espRangeMeters",10,200,5,
    function(v) return tostring(v).."m" end,17,
    function() changes+=1 end)
assert(find("espRangeMetersValue").Text=="200m","initial paint of range failed")
assert(find("espRangeMetersArea").Parent==parent)
assert(#userChanged.handlers==1 and #userEnded.handlers==1)
assert(type(refreshSliders.espRangeMeters)=="function")
local left={UserInputType=Enum.UserInputType.MouseButton1,Position={X=30,Y=9}}
emit(find("espRangeMetersArea").InputBegan,left)
assert(state.espRangeMeters~=200 and changes==1 and saved==1,
    "mouse click did not apply and persist the first value")
emit(userChanged,{UserInputType=Enum.UserInputType.MouseMovement,Position={X=65,Y=9}})
emit(userEnded,{UserInputType=Enum.UserInputType.MouseButton1,Position={X=65,Y=9}})
assert(changes==2 and saved==2,"final slider value was not committed")
local old=state.espRangeMeters
local vertical={UserInputType=Enum.UserInputType.Touch,Position={X=25,Y=8}}
emit(find("espRangeMetersArea").InputBegan,vertical)
assert(state.espRangeMeters==old,"touch-down changed value")
vertical.Position={X=26,Y=40}
emit(userChanged,vertical)
emit(userEnded,vertical)
assert(state.espRangeMeters==old,"vertical scroll changed value")
local tap={UserInputType=Enum.UserInputType.Touch,Position={X=80,Y=8}}
emit(find("espRangeMetersArea").InputBegan,tap)
assert(state.espRangeMeters==old)
emit(userEnded,tap)
assert(state.espRangeMeters~=old,"deliberate tap failed")
assert(type(state.espRangeMeters)=="number")
-- Verify second slider creation, with different state key and range.
makeSlider(parent,"FOV Circle","aimFovPixels",40,400,5,
    function(v) return tostring(v).."px" end,72,function() end)
assert(find("aimFovPixelsValue").Text=="200px","FOV slider initial paint failed")
state.aimFovPixels=135
refreshSliders.aimFovPixels()
assert(find("aimFovPixelsValue").Text=="135px","FOV update failed")
print("LUAU UI RUNTIME PASS: both sliders constructed, tapped, dragged, scrolled and refreshed")
`;
fs.writeFileSync("/tmp/Army124-UIRuntimeAudit.luau",program,"utf8");
console.log("Generated real slider Luau runtime harness from Visuals.lua");
