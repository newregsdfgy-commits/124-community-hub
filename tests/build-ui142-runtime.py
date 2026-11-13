#!/usr/bin/env python3
"""Run exact 124 Visuals windowMetrics source under real Luau CLI.

UI component rendering still needs a Roblox-client screenshot; this verifies
viewport math and breakpoint selection rather than pretending to render GuiObjects.
"""
from pathlib import Path
from tempfile import gettempdir

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "src/06_gui_runtime.lua").read_text(encoding="utf-8")
begin = source.index("local function isReferenceLandscape(view)")
end = source.index("local winWidth, winHeight, _, initialScale = windowMetrics(viewport)", begin)
assert begin > 0 and end > begin
block = source[begin:end]
assert "local preferredWidth = wide and 930" in block
assert "local marginX = mobile and 16 or 34" in block
assert "local marginY = mobile and 18 or 38" in block

preamble = r'''
local UserInputService = {TouchEnabled = false}
local Vector2 = {new = function(x,y) return {X=x, Y=y} end}
local function uiSafeView(raw) return raw end
local viewport = Vector2.new(1237, 683)
'''
checks = r'''
local function checkScreen(x, y, touch, expectWide, expectSplit)
    UserInputService.TouchEnabled = touch
    local width, height, wide, scale = windowMetrics(Vector2.new(x,y))
    assert(wide == expectWide, "wide mismatch " .. tostring(x) .. "x" .. tostring(y))
    local actualW, actualH = width * scale, height * scale
    assert(actualW <= x and actualH <= y, "panel overflow")
    local gapX, gapY = (x-actualW)/2, (y-actualH)/2
    assert(gapX >= (touch and 8 or 24) and gapY >= (touch and 4 or 18),
        "window lacks margins: " .. tostring(x) .. "x" .. tostring(y))
    local sidebarWidth = wide and (width >= 900 and 184 or 156)
        or (width < 340 and 68 or width < 430 and 78 or 94)
    local contentX = sidebarWidth + (wide and 11 or 9)
    local contentRight = wide and 13 or 9
    local available = width - contentX - contentRight
    assert(available >= 160, "content too narrow")
    local split = wide and available >= 720
    assert(split == expectSplit, "bad column breakpoint: " .. tostring(x))
    if split then assert((available - 10)/2 >= 350) end
    return width, height, scale
end

-- Exact size of supplied screenshot: should retain generous surrounding space.
local w,h,sc = checkScreen(1237,683,false,true,true)
assert(w == 930 and h == 505 and sc == 1)
assert((1237 - w)/2 >= 100 and (683 - h)/2 >= 60)

-- Smaller desktop falls back to a single scrollable column.
checkScreen(950,600,false,true,false)
checkScreen(900,580,false,true,false)
checkScreen(800,600,false,true,false)
checkScreen(490,340,false,false,false)

-- Mobile landscape respects 42px header hit targets after scaling.
local mw,mh,ms = checkScreen(960,540,true,true,true)
assert(ms < 1 and ms * 42 >= 38)
checkScreen(1280,800,true,true,true)
checkScreen(873,393,true,false,false)
checkScreen(640,360,true,false,false)
checkScreen(390,844,true,false,false)
checkScreen(280,500,true,false,false)
print("PASS: production windowMetrics 11 screenshot/desktop/mobile cases, margins and column breakpoints")
'''
out = Path(gettempdir())/"Army124-UI142.luau"
out.write_text(preamble+"\n"+block+"\n"+checks, encoding="utf-8")
print("wrote:",out)
