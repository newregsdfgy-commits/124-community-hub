"use strict";
const fs=require("node:fs");
const test=require("node:test");
const assert=require("node:assert/strict");
const source=fs.readFileSync("Visuals.lua","utf8");
function section(a,b){
 const x=source.indexOf(a),y=source.indexOf(b,x+a.length);
 assert.ok(x>=0&&y>x,"Missing "+a); return source.slice(x,y);
}
test("landscape touch devices use the reference layout instead of the old bottom tabs",()=>{
 const b=section("local function isReferenceLandscape(view)","local winWidth, winHeight");
 assert.ok(b.includes("UserInputService.TouchEnabled"));
 assert.ok(b.includes("view.X >= 480"));
 assert.ok(b.includes("view.Y >= 260"));
 assert.ok(b.includes("view.X >= view.Y * 1.35"));
 assert.ok(b.includes("return 950, 520, true, scale"));
 assert.ok(b.includes("return width, height, wide, 1"));
});
test("menu uses a single uniform base scale across start, resize, minimize and reopen",()=>{
 const b=section("local winWidth, winHeight, _, initialScale", "-- Sidebar on desktop");
 for(const needle of ["local uiBaseScale = initialScale",
  'mk("UIScale", {Scale = uiBaseScale}, panel)',
  "if size == panel.Size then",
  "width = width * uiBaseScale",
  "height = height * uiBaseScale",
  "{Scale = uiBaseScale * toScale}",
  "panelScale.Scale = uiBaseScale"])
  assert.ok(b.includes(needle),needle);
 assert.equal((source.match(/panelScale.Scale = uiBaseScale \* 0\.98/g)||[]).length,2);
 const layout=section("local function applyResponsiveLayout()","local function showPage(key)");
 assert.ok(layout.includes("if panelTween then panelTween:Cancel(); panelTween = nil end"));
 assert.ok(layout.includes("local width, height, wide, baseScale = windowMetrics(view)"));
 assert.ok(layout.includes("uiBaseScale = baseScale"));
 assert.ok(layout.includes("panelScale.Scale = uiBaseScale"));
});
test("reference dimensions fit the supplied 574x315 screenshot with margins",()=>{
 const width=574,height=315;
 const scale=Math.min((width-12)/950,(height-12)/520);
 assert.ok(scale>0.57 && scale<0.60);
 assert.ok(950*scale<=width-12+0.00001);
 assert.ok(520*scale<=height-12+0.00001);
 assert.ok(950/520>1.82 && 950/520<1.83);
});
test("top status and search slots do not overlap at min desktop panel width",()=>{
 for(const panelWidth of [738,850,950]){
   const searchLeft=17,searchRight=17+(panelWidth-593);
   const safeLeft=(panelWidth-474)-75,clockLeft=(panelWidth-356)-112;
   const activeLeft=(panelWidth-250)-95,closeLeft=panelWidth-218;
   const sidebarLeft=panelWidth-196;
   assert.ok(searchRight<safeLeft,panelWidth+" search overlaps Safe");
   assert.ok(panelWidth-474<clockLeft,panelWidth+" Safe overlaps clock");
   assert.ok(panelWidth-356<activeLeft,panelWidth+" clock overlaps Active");
   assert.ok(panelWidth-250<closeLeft,panelWidth+" Active overlaps Close");
   assert.ok(closeLeft+17<=sidebarLeft,panelWidth+" Close overlaps sidebar");
 }
});
test("source contains no new additional per-frame or network hooks",()=>{
 assert.equal((source.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 const ui=section("local function buildReferenceMenu()","referenceESP = buildReferenceMenu()");
 assert.ok(!/RenderStepped|:FireServer\(|:InvokeServer\(|game:HttpGet\(/.test(ui));
});
