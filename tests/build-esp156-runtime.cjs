"use strict";
const fs=require("node:fs"),assert=require("node:assert/strict");
const overlay=fs.readFileSync("src/07_esp_overlays.lua","utf8");
const start=overlay.indexOf("local function drawCornerBox(item, top, bottom, thickness, color)");
const end=overlay.indexOf("local function refreshShapes()",start);
assert.ok(start>=0 && end>start,"modern corner-box helper was not found");
const production=overlay.slice(start,end);
const code=String.raw`
local Vector2 = {new=function(x,y)return {X=x,Y=y} end}
local calls,hides={},0
local function setLine(line, a, b, thick, color)
    calls[#calls + 1]={id=line.id,a=a,b=b,thick=thick,color=color}
end
local function hideShape(item)
    hides+=1
end
${production}
local box={}
for i=1,8 do box[i]={id=i} end
local item={box=box}
local teamColor={team="blue"}
drawCornerBox(item,{X=100,Y=40},{X=100,Y=240},2,teamColor)
assert(#calls==8 and hides==0,"exactly 8 segments must be drawn")
local xmin,xmax=math.huge,-math.huge
for _,line in ipairs(calls) do
    assert(line.thick==2 and line.color==teamColor)
    local dx,dy=line.b.X-line.a.X,line.b.Y-line.a.Y
    assert((math.abs(dx)>0 and dy==0) or (math.abs(dy)>0 and dx==0),
        "corners must consist of horizontal or vertical line segments")
    xmin=math.min(xmin,line.a.X,line.b.X)
    xmax=math.max(xmax,line.a.X,line.b.X)
end
assert(xmin==54 and xmax==146,"box width must follow projected height")
local topY=40
assert(calls[1].a.X==xmin and calls[1].a.Y==topY,"top-left corner missing")
assert(calls[8].a.X==xmax and calls[8].b.Y==240,"bottom-right corner missing")
assert(calls[1].b.X < calls[3].a.X,"top edge must have central gap")
assert(calls[2].b.Y < calls[6].a.Y,"side edges must have central gap")
table.clear(calls)
drawCornerBox(item,{X=100,Y=240},{X=100,Y=40},1,teamColor)
assert(#calls==8 and calls[1].a.Y==40,"inverted camera sample must be stable")
table.clear(calls)
drawCornerBox(item,{X=100,Y=40},{X=100,Y=42},2,teamColor)
assert(hides==1 and #calls==0,"collapsed geometry must hide old segments")
print("PASS: production v1.5.6 8-corner geometry, color, width, inverted samples, short-box hiding")
`;
fs.writeFileSync("/tmp/Army124-EspCorners156.luau",code,"utf8");
console.log("Generated executable v1.5.6 production corner-box runtime");
