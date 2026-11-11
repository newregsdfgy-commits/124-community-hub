#!/usr/bin/env python3
"""124 Visuals release integrity / viewport smoke tests.

Uses Python standard library only. This validates release invariants and
source structure; it DOES NOT compile Luau or exercise Roblox engine APIs.
"""
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSION = "1.3.1"
BRANCH = "v1.3.1-deep-audit-stability-test"
CHECK_COUNT = [0]


def check(label: str, passed: bool, failures: list[str]) -> None:
    CHECK_COUNT[0] += 1
    status = "PASS" if passed else "FAIL"
    print(f"[{status}] {label}")
    if not passed:
        failures.append(label)


def structural_errors(source: str) -> list[str]:
    """Skip Lua string/comment literals and match (), [], {} in code."""
    problems: list[str] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    i, line, size = 0, 1, len(source)
    while i < size:
        ch = source[i]
        if ch.isspace():
            if ch == "\n":
                line += 1
            i += 1
            continue
        if source.startswith("--", i):
            i += 2
            match = re.match(r"\[(=*)\[", source[i:])
            if match:
                end = "]" + match.group(1) + "]"
                i += len(match.group(0))
                at = source.find(end, i)
                if at < 0:
                    problems.append(f"Unclosed block comment near {line}")
                    break
                line += source[i:at].count("\n")
                i = at + len(end)
            else:
                at = source.find("\n", i)
                if at < 0:
                    break
                i = at
            continue
        if ch in ("'", '"'):
            quote, start = ch, line
            i += 1
            closed = False
            while i < size:
                current = source[i]
                if current == "\\":
                    i += 2
                    continue
                if current == "\n":
                    problems.append(f"Raw line break inside short string at {start}")
                    line += 1
                i += 1
                if current == quote:
                    closed = True
                    break
            if not closed:
                problems.append(f"Unclosed short string at {start}")
            continue
        if ch == "[":
            match = re.match(r"\[(=*)\[", source[i:])
            if match:
                end = "]" + match.group(1) + "]"
                i += len(match.group(0))
                at = source.find(end, i)
                if at < 0:
                    problems.append(f"Unclosed long string near {line}")
                    break
                line += source[i:at].count("\n")
                i = at + len(end)
                continue
        if ch in "([{":
            stack.append((ch, line))
        elif ch in ")]}":
            if not stack or stack[-1][0] != pairs[ch]:
                problems.append(f"Unmatched {ch} at {line}")
            else:
                stack.pop()
        i += 1
    for char, line_number in stack:
        problems.append(f"Unclosed {char} at {line_number}")
    return problems


def viewport_ok(x: int, y: int, mobile: bool) -> bool:
    """Smoke-check the same layout dimensions used by the Purple Neon hub."""
    vx, vy = x, max(160, y - (24 if mobile else 0))
    screenshot = mobile and vx >= 960 and vy >= 540 and vx >= vy * 1.35
    wide = screenshot or (not mobile and vx >= 770 and vy >= 560)
    if screenshot:
        width, height = 950, 520
        scale = max(.36, min(1, (vx - 12) / 950, (vy - 12) / 520))
    else:
        preferred_width = 950 if wide else (
            610 if mobile and vx > vy else 460
        )
        width = min(max(160, vx - (22 if mobile else 32)), preferred_width)
        height = min(520 if wide else 610,
                     max(120, vy - (22 if mobile else 38)))
        scale = 1
    sidebar = 196 if wide else (
        68 if width < 340 else 78 if width < 430 else 94
    )
    content = width - sidebar - (11 if wide else 9) - (13 if wide else 9)
    nav_top = 20 if wide else (5 if height < 320 else 11)
    bottom = 90 if wide else (9 if height < 300 else 53)
    nav_height = max(0, height - 76 - nav_top - bottom)
    header_touch = 42 * scale
    nav_button = (55 if wide else 44) * scale
    # Navigation is a ScrollingFrame; short viewports legitimately need it.
    return (width * scale <= vx and height * scale <= vy and
            content >= 160 and nav_height >= 15 and
            header_touch >= 38 and nav_button >= 38 and
            height - 120 >= 20)


def main() -> int:
    failures: list[str] = []
    hub = (ROOT / "Hub.lua").read_text(encoding="utf-8")
    visuals = (ROOT / "Visuals.lua").read_text(encoding="utf-8")
    launcher = (ROOT / "Start.lua").read_text(encoding="utf-8")

    check("Hub.lua and Visuals.lua are byte-identical", hub == visuals, failures)
    check("Release version matches", f'Version = "{VERSION}"' in hub, failures)
    check("Launcher verifies release", f'Version = "{VERSION}"' in launcher, failures)
    check("Launcher points at same branch", f"{BRANCH}/Visuals.lua" in launcher, failures)
    check("Key gate retained", 'local ACCESS_KEY = "124HUB"' in hub, failures)
    check("Key gate precedes state", hub.find("local function requireAccessKey()") <
          hub.find("local state = {"), failures)
    check("Per-instance startup token retained",
          "env.ARMY124_BOOT_TOKEN = CONFIG.BootToken" in hub and
          "env.ARMY124_BOOT_TOKEN ~= runError" in launcher, failures)
    check("Launcher prevents concurrent invocation",
          "ARMY124_START_RUNNING = true" in launcher and
          "ARMY124_START_RUNNING = nil" in launcher, failures)
    check("No stale GUI or event connections",
          "stale signal registration" in hub and
          "stale GUI construction" in hub, failures)
    check("Purple Neon UI retained",
          'Text = "124 VISUALS"' in hub and
          'local navSlots = mk("ScrollingFrame"' in hub, failures)
    check("Booster work is bounded",
          "BoosterBatch = 64" in hub and
          "BoosterQueueBatch = 24" in hub and
          "BoosterSliceMs = 0.75" in hub, failures)
    check("Booster rollback snapshots are tracked",
          "function boosterPro.snapshotStatus(" in hub and
          "function boosterPro.restoreGraphicsSliced(" in hub, failures)
    check("Booster worker ownership is tracked",
          all(f"boosterPro.workers.{key}" in hub
              for key in ("scan", "restore", "repair", "avatar")), failures)
    check("On-device read-only self-check exists",
          "function boosterPro.selfCheck()" in hub and
          "Самопроверка стабильности" in hub, failures)
    check("Shutdown still registered",
          "cleanup = function(safeStop)" in hub and
          "env.ARMY124_CLEANUP = cleanup" in hub, failures)
    check("Recoil and Spread restore remain",
          "function controller.restoreSpread()" in hub and
          "pcall(recoil.shutdown)" in hub, failures)
    check("Weapons 2.0 diagnostics and menu",
          "controller.diagnostics = function()" in hub and
          '"Диагностика Weapons 2.0"' in hub, failures)
    check("Safe spread guard and latest external baseline",
          "safeApplySpread = function()" in hub and
          "rememberSpreadBaseline(instance, nil, value)" in hub and
          "rememberSpreadBaseline(instance, name, value)" in hub, failures)
    check("Queued post-shot update is generation guarded",
          "controller.spread.generation == generation" in hub, failures)
    check("No Spread-only shot signals counted",
          hub.find("controller.shots = controller.shots + 1") <
          hub.find("if not (state.controlRecoil or state.noRecoil) then return end"),
          failures)
    check("No Spread diagnostic status avoids runtime claims",
          "влияние на траекторию не подтверждено" in hub, failures)
    check("Render and UI controllers retained",
          all(token in hub for token in (
              "local function aimFrame(dt)",
              "local function refreshESP()",
              "local function applyResponsiveLayout()")), failures)
    check("Purple Neon UI 2.0 label",
          "PURPLE NEON 2.0" in hub, failures)
    check("Mobile wide only near native size",
          "view.X >= 960" in hub and "view.Y >= 540" in hub, failures)
    check("Accessible header targets",
          'Size = UDim2.fromOffset(42, 42)' in hub, failures)
    check("No overlapping toggle tweens",
          'knobTween:Cancel()' in hub, failures)
    check("Active slider gesture cancelled on rotate",
          'local function applyResponsiveLayout()\n    sliderDrag = nil' in hub,
          failures)
    check("Larger slider gesture area",
          'Size = UDim2.new(1, -20, 0, 32)' in hub, failures)
    check("Runtime UI audit is on demand",
          'boosterPro.uiAudit = function()' in hub and
          'Проверка адаптации UI 2.0' in hub, failures)
    check("ESP 2.0 urgent respawn queue",
          "local function queueESPRefresh(urgent)" in hub and
          "queueESPRefresh(true)" in hub and
          "bindLocalEspCharacter" in hub, failures)
    check("ESP 2.0 camera motion",
          "EspCameraMotionVisualHz = 36" in hub and
          "motion.motionUntil" in hub and
          "motion.motionCamera" in hub, failures)
    check("Key System 2.0 counter, local cooldown",
          "KeyMaxWrongAttempts = 5" in hub and
          "wrongCount = wrongCount + 1" in hub and
          "KeyLocalCooldownSeconds" in hub, failures)
    check("Key System 2.0 dedup and confirm to close",
          "lastSubmitAt < CONFIG.KeySubmitDedupSeconds" in hub and
          "cancelArmedAt <= CONFIG.KeyCloseConfirmSeconds" in hub, failures)
    check("Android keyboard location adjustment",
          "input.Focused:Connect(function() moveForKeyboard(true) end)" in hub,
          failures)
    check("Same source bundle as 11 source modules",
          hub == b"".join((ROOT / "src" / name).read_bytes() for name in (
              "00_config.lua", "01_access_gate.lua", "02_state_and_services.lua",
              "03_esp_tracker.lua", "04_lighting_and_booster.lua",
              "05_weapons_and_recoil.lua", "06_gui_runtime.lua",
              "07_esp_overlays.lua", "08_ui_controls.lua",
              "09_misc_and_diagnostics.lua", "10_run_and_cleanup.lua"
          )).decode("utf-8"), failures)
    check("ESP local respawn retains existing overlays",
          "if not myRoot then" in hub and
          "if isLive(item.highlight) then item.highlight.Enabled = false end" in hub and
          "if item.tracer and item.tracer.Parent then item.tracer.Visible = false end" in hub,
          failures)
    check("ESP urgent dedup uses latest event timestamp",
          "espUrgentDirtyAt = os.clock()" in hub and
          "lastScanAt >= espUrgentDirtyAt" in hub and
          "urgentSkipped" in hub, failures)
    check("Key result latched before waiting",
          "if completed then" in hub and "accepted = resolvedValue" in hub and
          "screen.AncestryChanged:Connect" in hub, failures)
    check("Key empty duplicate does not overwrite feedback",
          "if now - lastSubmitAt < CONFIG.KeySubmitDedupSeconds then return end" in hub and
          "if candidate == \"\" then" in hub, failures)
    check("ESP CFrame skipped when no 2D visuals",
          hub.find("if not state.tracers and not state.espBox then") <
          hub.find("local camera = Workspace.CurrentCamera", hub.find("local espVisualElapsed = 0")),
          failures)
    check("Source quote/comment/bracket scan",
          not structural_errors(hub), failures)
    check("Launcher quote/comment/bracket scan",
          not structural_errors(launcher), failures)

    viewports = [
        (873, 393, True), (640, 360, True), (480, 260, True),
        (393, 873, True), (320, 568, True), (280, 500, True),
        (1280, 800, True), (800, 1280, True), (1366, 768, False),
        (700, 500, False), (490, 340, False), (960, 540, True),
        (1024, 600, True), (1000, 580, True), (760, 520, True),
        (360, 720, True), (800, 1280, True), (1920, 1080, False),
    ]
    for x, y, mobile in viewports:
        check(f"Viewport {x}x{y} {'touch' if mobile else 'desktop'}",
              viewport_ok(x, y, mobile), failures)

    print(f"\n{CHECK_COUNT[0] - len(failures)}/{CHECK_COUNT[0]} checks passed")
    if failures:
        print("Failing checks:", ", ".join(failures))
        return 1
    print("Static integrity only; Luau compiler and Roblox runtime are not tested.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
