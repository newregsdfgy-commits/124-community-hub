"use strict";
const fs=require("node:fs"), test=require("node:test"), assert=require("node:assert/strict");
const source=fs.readFileSync("Visuals.lua","utf8");
const launcher=fs.readFileSync("Start.lua","utf8");
function block(first,last){
 const a=source.indexOf(first),b=source.indexOf(last,a+first.length);
 assert.ok(a>=0&&b>a,"Cannot locate: "+first);return source.slice(a,b);
}
const menu=block("local function buildReferenceMenu()","referenceESP = buildReferenceMenu()");
test("1: isolated visual polish is bound to exact 1.1.36 launcher",()=>{
 assert.ok(source.includes('Version = "1.1.36"'));
 assert.ok(launcher.includes("v1.1.36-ui-polish-stability-test/Visuals.lua"));
 assert.equal(source,fs.readFileSync("Hub.lua","utf8"));
});
test("2: hidden scroll lists require all parent GuiObjects to be visible",()=>{
 const b=block("local function uiVisibleThroughParents(obj)","connect(UserInputService.InputBegan, function(input)");
 assert.ok(b.includes('current:IsA("GuiObject") and not current.Visible'));
 assert.ok(b.includes('current:IsA("ScreenGui") then return current.Enabled'));
 assert.ok(b.includes("uiVisibleThroughParents(scroll)"));
 assert.ok(!b.includes("scroll.Parent.Visible and scroll.Visible"));
 assert.ok(source.includes("touchGestures[input] = nil"));
});
test("3: slider does not change on touch-down or vertical scroll",()=>{
 assert.ok(menu.includes("active = not touch"));
 assert.ok(menu.includes("if not touch then setFromX(input.Position.X) end"));
 assert.ok(menu.includes("if math.abs(dy) >= 10 and math.abs(dy) > math.abs(dx) * 1.1 then"));
 assert.ok(menu.includes("cancelPointer() -- Vertical scroll owns the gesture."));
 assert.ok(menu.includes("if math.abs(dx) < 10 or math.abs(dx) < math.abs(dy) * 1.15 then"));
 assert.ok(menu.includes("drag.active = true"));
});
test("4: active slider finishes on pointer release, tab change and layout reset",()=>{
 assert.ok(menu.includes("if drag and drag.finish then drag.finish() end"));
 assert.ok(menu.includes("cancelPointer()\n        end\n    end)"));
 assert.ok(menu.includes("cancelInteraction = cancelPointer"));
 const page=block("local function showPage(key)","for name, button in pairs(tabButtons)");
 assert.ok(page.includes("referenceESP.cancelInteraction()"));
 const layout=block("local function applyResponsiveLayout()","local function showPage(key)");
 assert.ok(layout.includes("referenceESP.cancelInteraction()"));
});
test("5: expensive ESP refreshes are throttled but final slider value is saved",()=>{
 for(const needle of ["local dirty = false","local lastApplyAt = -1e8",
 "if not dirty then return end","if onChanged then ok, err = pcall(onChanged) end",
 "if os.clock() - lastApplyAt >= 0.11 then commitValue() end",
 "finish = commitValue","requestSave()"])
 assert.ok(menu.includes(needle),needle);
 assert.ok(menu.includes("state[key] = committedValue"));
 assert.ok(menu.includes('tell("Ошибка слайдера "'));
});
test("6: ESP switch restores old state on callback exception",()=>{
 const b=block("local controls = {","local function card(name, y, h)");
 for(const needle of ["local previous = state[key]","state[key] = not previous",
 "local ok, err = pcall(function()","if not ok then",
 "state[key] = previous","pcall(syncEspVisuals)","tell(","return",
 "requestSave()"])assert.ok(b.includes(needle),needle);
 assert.ok(b.indexOf("state[key] = previous")<b.lastIndexOf("requestSave()"));
});
test("7: search reports an empty result and skin module is explicit preview",()=>{
 assert.ok(menu.includes('Name = "EmptySearch"'));
 assert.ok(menu.includes("emptySearch.Visible = matches == 0"));
 assert.ok(menu.includes("if found then matches = matches + 1 end"));
 assert.ok(menu.includes('"UnavailableTag", "PREVIEW"'));
 assert.ok(menu.includes('function() return false end, nil'));
});
test("8: premium gradients are static and hover uses events not frame loops",()=>{
 assert.ok(source.includes('Name = "DragBar", BackgroundColor3'));
 assert.ok(menu.includes('mk("UIGradient", {Rotation = 90'));
 assert.ok(menu.includes("connect(row.MouseEnter"));
 assert.ok(menu.includes("connect(row.MouseLeave"));
 assert.ok(menu.includes("BackgroundTransparency = 0.82"));
 assert.ok(menu.includes('"ReferenceVersion", "v" .. CONFIG.Version'));
 assert.ok(menu.includes('Text = "●  Ready"'));
 assert.ok(!/RenderStepped|Heartbeat:Connect|BindToRenderStep/.test(menu));
});
test("9: layout remains right-sided and game ESP range is unchanged",()=>{
 assert.ok(source.includes("tabs.Position = UDim2.new(1, -196, 0, 0)"));
 assert.ok(source.includes("page.Position = UDim2.fromOffset(14, 81)"));
 assert.ok(menu.includes('makeSlider(top, "Max Distance", "espRangeMeters", 10, 200, 5'));
 assert.equal((source.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
});
test("10: code does not introduce network remotes or dynamic script imports",()=>{
 assert.ok(!/game:HttpGet\(|:FireServer\(|:InvokeServer\(|loadstring\s*\(/.test(menu));
 assert.ok(!menu.includes("rbxassetid:"));
});
