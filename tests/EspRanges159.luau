local CONFIG={EspRangeMinMeters=10,EspRangeMaxMeters=1000,StudMeters=0.28,
 EspCompactNameMaxMeters=155,EspCompactDetailsMaxMeters=90}
local state={espRangeMeters=200,espNameMaxMeters=155,espHealthMaxMeters=90,
 espDistanceMaxMeters=90,espBoxMaxMeters=1000,espTracerMaxMeters=1000}
--@@ESP_FLAGS@@
local function check(meters,n,h,d,en,eh,ed)
 local nn,hh,dd=compactEspFlags(meters,n,h,d)
 assert(nn==en and hh==eh and dd==ed,"wrong visibility at "..tostring(meters))
end
check(90,true,true,true,true,true,true)
check(91,true,true,true,true,false,false)
check(155,true,true,true,true,false,false)
check(156,true,true,true,false,false,false)
state.espHealthMaxMeters=325
check(180,true,true,true,false,true,false)
check(325,false,true,false,false,true,false)
check(326,true,true,true,false,false,false)
state.espNameMaxMeters=800
state.espDistanceMaxMeters=500
check(470,true,true,true,true,false,true)
check(600,true,true,true,true,false,false)
check(801,true,true,true,false,false,false)
check(61,false,false,true,false,false,true)
check(61,false,false,false,false,false,false)
local storedKeys={"espNameMaxMeters","espHealthMaxMeters","espDistanceMaxMeters",
 "espBoxMaxMeters","espTracerMaxMeters"}
local defaultSettings={espNameMaxMeters=155,espHealthMaxMeters=90,
 espDistanceMaxMeters=90,espBoxMaxMeters=1000,espTracerMaxMeters=1000}
local numericRules={}
for _,key in ipairs(storedKeys) do
 numericRules[key]={CONFIG.EspRangeMinMeters,CONFIG.EspRangeMaxMeters}
end
local textRules={}
local function validAimKeyName() return true end
--@@PROFILE_VALIDATOR@@
local saved=validatedSettings({
 espNameMaxMeters=400,espHealthMaxMeters=350,
 espDistanceMaxMeters=200,espBoxMaxMeters=1400,espTracerMaxMeters=-25})
assert(saved.espNameMaxMeters==400 and saved.espHealthMaxMeters==350)
assert(saved.espBoxMaxMeters==1000 and saved.espTracerMaxMeters==10)
local invalid=validatedSettings({
 espNameMaxMeters="300",espHealthMaxMeters=0/0,espDistanceMaxMeters=false})
assert(next(invalid)==nil,"invalid profile values must not override ranges")
local function effectiveTracer()
 local radiusStuds = --@@TRACER_RADIUS@@ / CONFIG.StudMeters
 return radiusStuds * CONFIG.StudMeters
end
local function effectiveBox()
 local radiusStuds = --@@BOX_RADIUS@@ / CONFIG.StudMeters
 return radiusStuds * CONFIG.StudMeters
end
assert(math.abs(effectiveTracer()-200)<0.0001 and math.abs(effectiveBox()-200)<0.0001)
state.espTracerMaxMeters=80
state.espBoxMaxMeters=120
assert(math.abs(effectiveTracer()-80)<0.0001 and math.abs(effectiveBox()-120)<0.0001)
state.espRangeMeters=65
assert(math.abs(effectiveTracer()-65)<0.0001 and math.abs(effectiveBox()-65)<0.0001)
print("PASS: production ESP independent ranges, safe profile validation, Box/Tracer caps")
