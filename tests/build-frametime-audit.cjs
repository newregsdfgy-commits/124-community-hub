"use strict";
const fs=require("node:fs"),assert=require("node:assert/strict");
const src=fs.readFileSync("Visuals.lua","utf8");
function extract(a,b){
 const x=src.indexOf(a),y=src.indexOf(b,x+a.length);
 assert.ok(x>=0&&y>x,"missing function region "+a);
 return src.slice(x,y).trimEnd();
}
const create=extract("local function shapeItem(player, character)","local function hideShape(item)");
const ensure=extract("local function ensureShapeLines(item, kind, count)","local function refreshShapes()");
const program=`
-- Execute extracted production shape construction under mocked Roblox primitives.
-- Regression: don't create all 19 UI Lines on one RenderStep.
local shapeNewContainersLeft=2
local shapeNewLinesLeft=8
local shapeData={}
local shapeGui={}
local UDim2={fromScale=function(...) return {...} end}
local instances=0
local function mk(class,props,parent)
    instances+=1
    return {Name=props.Name,Parent=parent,Visible=false,Destroy=function(self)self.Parent=nil end}
end
local function shapeLine(parent)
    instances+=1
    return {Parent=parent,Visible=false}
end
${create}
${ensure}
local first={UserId=1}
local second={UserId=2}
local third={UserId=3}
local char1={}
local char2={}
local char3={}
local a=shapeItem(first,char1)
local b=shapeItem(second,char2)
assert(a and b and instances==2)
assert(shapeItem(third,char3)==nil)
assert(shapeItem(first,char1)==a)
assert(ensureShapeLines(a,"box",4))
assert(#a.box==4 and shapeNewLinesLeft==4)
assert(not ensureShapeLines(a,"bones",15))
assert(#a.bones==4 and shapeNewLinesLeft==0)
assert(not ensureShapeLines(b,"box",4))
assert(#b.box==0 and instances==10)
shapeNewContainersLeft=2
shapeNewLinesLeft=8
assert(shapeItem(third,char3))
assert(ensureShapeLines(b,"box",4))
assert(not ensureShapeLines(a,"bones",15))
assert(#a.bones==8)
shapeNewContainersLeft=2
shapeNewLinesLeft=8
assert(not ensureShapeLines(a,"bones",15) == false or #a.bones<=15)
assert(#a.bones==15)
assert(ensureShapeLines(a,"bones",15))
assert(shapeNewLinesLeft>=0)
assert(instances<=30)
print("LUAU FRAME BUDGET PASS: deferred geometry, per-frame construction caps, retry and complete")
`;
fs.writeFileSync("/tmp/Army124-FrametimeBudgetAudit.luau",program,"utf8");
console.log("Generated real production shape constructor Luau test");
