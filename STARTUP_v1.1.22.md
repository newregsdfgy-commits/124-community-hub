# v1.1.22 — Startup diagnostics
Base: v1.1.21 test. main unchanged and was on v1.1.16 when checked.
Start.lua checks the GitHub Raw file, content completeness and version, compiles Luau, executes under xpcall, then verifies GUI initialization.
Visuals.lua and Hub.lua expose ARMY124_BOOT_PHASE and ARMY124_BOOT_ERROR in the executor environment; failures during previous cleanup, graphics recovery and UI initialization also display on screen.
PlayerGui wait increased to 30 seconds.
CI runs Node static regressions and official Luau parser/compiler for Start.lua, Visuals.lua and Hub.lua.
Actual in-game client failure and FPS remain unverified.
