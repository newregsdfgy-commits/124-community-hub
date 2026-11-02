# v1.1.23 — Booster stutter control (test)

User observation: FPS stutters occur with Booster enabled, disappear when Booster is off. This is a correlation and not proof of a single mechanism.

Compared with v1.1.22, this test lowers initial work from 2.2 ms/320 objects to 0.55 ms/48 and 0.22 ms under 42 FPS, with 50-100 ms rests. Streaming queue now uses 24 objects / 0.35 ms per burst and 80-150 ms rests, rather than 144 objects / 1.1 ms every 20 ms. The worker still drains pending elements and uses existing protected hierarchy tests and snapshots for restoration.

If FIFO overflows, a costly full rescan is deferred for at least 3 seconds after most recent stream activity, with 45 seconds minimum between repairs, instead of 12 seconds.

The comparison button now reports observed highest CPU durations for initial traversal and streaming queue. These are Lua scheduling measurements only; they do not include delayed Roblox GPU/engine work.

Tradeoff: the map may take substantially longer to optimize, especially in dense scenes. The change targets frame pacing rather than claiming guaranteed higher average FPS.

Validation: GitHub Actions tests and Luau parse/compile. In-game A/B compare v1.1.22 vs v1.1.23 on same PC, same graphic mode, same scene and same streaming activity. If 1% lows are worse and Booster OFF eliminates stutter, prefer OFF until profiling isolates engine recomposition costs.

Rollback: v1.1.22-startup-check-test remains untouched. main untouched.
