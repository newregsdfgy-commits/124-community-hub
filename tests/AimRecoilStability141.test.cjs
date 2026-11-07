"use strict";
const fs=require("node:fs"),test=require("node:test"),assert=require("node:assert/strict");
const source=fs.readFileSync("Visuals.lua","utf8");
const hub=fs.readFileSync("Hub.lua","utf8");
const start=fs.readFileSync("Start.lua","utf8");
function block(a,b){const i=source.indexOf(a),j=source.indexOf(b,i+a.length);assert.ok(i>=0&&j>i,"missing "+a);return source.slice(i,j)}
test("v1.1.41 source aliases and exact hotfix loader agree",()=>{
 assert.equal(source,hub);
 assert.ok(source.includes('Version = "1.1.41"'));
 assert.ok(start.includes("v1.1.41-aim-recoil-stability-test/Visuals.lua"));
 assert.ok(start.includes('Version = "1.1.41"'));
});
test("AIM candidates are actual BaseParts with safe R6/R15 fallbacks",()=>{
 const s=block("local function aimPart(character, name)","local function sameTeam(");
 assert.ok(s.includes('candidate:IsA("BasePart")'));
 for(const key of ["Head","UpperTorso","Torso","HumanoidRootPart","Left Leg","RightLowerLeg"])
 assert.ok(s.includes('"'+key+'"'));
});
test("AIM locks transient occlusion without aiming through walls",()=>{
 const scan=block("local function findAimTarget(camera)","local function isRobloxMenuOpen()");
 const frame=block("local function aimFrame(dt)","local recoil = (function()");
 assert.ok(scan.includes("aimPro.blockedSince = now"));
 assert.ok(scan.includes("kept.blocked = true"));
 assert.ok(scan.includes("CONFIG.AimOcclusionGraceSeconds"));
 assert.ok(frame.includes("if current.blocked then return end"));
 assert.ok(frame.includes("current.blocked = true"));
 assert.ok(frame.includes("aimPro.blockedSince = 0"));
});
test("AIM LOS checks are bounded for dense servers",()=>{
 const scan=block("local function findAimTarget(camera)","local function isRobloxMenuOpen()");
 assert.ok(source.includes("AimLosCandidatesPerScan = 8"));
 assert.ok(scan.includes("if tested >= CONFIG.AimLosCandidatesPerScan then break end"));
 assert.ok(scan.includes("tested = tested + 1"));
});
test("AIM prediction and smooth angle steps cannot overshoot on a stalled frame",()=>{
 const p=block("local function predictedPoint(part)","local function signedAngle(");
 const frame=block("local function aimFrame(dt)","local recoil = (function()");
 assert.ok(p.includes("distance > CONFIG.AimPredictionMaxStuds"));
 assert.ok(p.includes("offset * (CONFIG.AimPredictionMaxStuds / distance)"));
 assert.ok(frame.includes("math.clamp(dt, 0, 0.05)"));
 assert.ok(frame.includes("local maxStep = math.rad(CONFIG.AimMaxTurnDegreesPerSecond) * dtSafe"));
 assert.ok(frame.includes("pitchStep = math.clamp"));
 assert.ok(frame.includes("yawStep = math.clamp"));
 assert.ok(frame.includes("if state.aimSmoothness == 0 then"));
});
test("Recoil renews a legitimate Tool.Activated firing pulse",()=>{
 const a=block("local function markRecoilShot()","local function equipRecoilTool(tool)");
 assert.ok(a.includes("recoilHoldStarted = now"));
 assert.ok(a.includes("recoilHolding = true"));
 assert.ok(!a.includes("if not recoilHolding then"));
 assert.ok(source.includes("RecoilMaxHoldSeconds = 6.0"));
});
test("Recoil and active AIM never write the camera in the same render pass",()=>{
 const r=block("local function recoilFrame(dt)","-- END RECOIL CONTROL");
 assert.ok(r.includes("if state.aimbot and (aimHeldMouse or aimHeldTouch or aimHeldKey) then return end"));
 assert.ok(!r.includes("and aimTarget then return end"));
 assert.ok(r.includes("if not firing or dt <= 0 or dt > CONFIG.RecoilMaxFrameSeconds then return end"));
});
test("Recoil angular correction is time-based, capped and Tool-gated",()=>{
 const r=block("local function recoilFrame(dt)","-- END RECOIL CONTROL");
 assert.ok(r.includes("recoilTool == nil or recoilTool.Parent ~= LocalPlayer.Character"));
 assert.ok(r.includes("math.rad(CONFIG.RecoilMaxCorrectionPerSecond) * math.clamp(dt, 0, 0.05)"));
 assert.ok(r.includes("math.rad(CONFIG.RecoilMaxCorrectionDegrees)"));
 assert.ok(r.includes("camera.CFrame = camera.CFrame * CFrame.Angles(-correction, 0, 0)"));
 assert.ok(source.includes("RecoilMaxCorrectionPerSecond = 120"));
});
test("aim/recoil adds no new render subscriptions, network or background loops",()=>{
 assert.equal((source.match(/RunService:BindToRenderStep\(/g)||[]).length,4);
 assert.ok(!/:FireServer\s*\(/.test(source));
 assert.ok(!/:InvokeServer\s*\(/.test(source));
});
