#!/usr/bin/env python3
"""Test real v1.4.5 Terrain grass callbacks with a setter that mutates then throws."""
from pathlib import Path
from tempfile import gettempdir
source=(Path(__file__).resolve().parents[1]/"src/04_lighting_and_booster.lua").read_text(encoding="utf-8")
a=source.index("local function terrainAccessor(kind)")
b=source.index("-- Белая карта:",a)
segment=source[a:b]
preamble=r'''
local savedTerrainDecoration=nil
local boosterPro={restoreFailures=0}
local terrain={Parent={},decoration=true}
local Workspace={FindFirstChildOfClass=function(_,name)
    if name=="Terrain" then return terrain end
end}
local gethiddenproperty=function(obj,key) return obj.decoration end
local failSetter=true
local sethiddenproperty=function(obj,key,value)
    obj.decoration=value
    if failSetter then failSetter=false;error("set failed after mutation") end
end
local function warn(_) end
'''
checks=r'''
assert(terrain.decoration==true)
assert(hideTerrainGrass()==false,"the first setter should report error")
assert(terrain.decoration==false,"setter did mutate Terrain")
assert(savedTerrainDecoration~=nil,"original must survive the thrown setter")
assert(restoreTerrainGrass()==true,"restoration must succeed")
assert(terrain.decoration==true and savedTerrainDecoration==nil)
print("PASS: injected Terrain grass setter failure retained baseline and restored correctly")
'''
out=Path(gettempdir())/"Army124-Deep145.luau"
out.write_text(preamble+"\n"+segment+"\n"+checks,encoding="utf-8")
print("Created v1.4.5 Terrain recovery harness:",out)
