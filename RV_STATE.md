# RV_STATE — 124 Visuals v1.1.65 Purple Neon UI

Date: 2026-11-11. Current test branch: `v1.1.65-purple-neon-ui-test`.

- User selected reference **Purple Neon №1**. Implemented neon palette, unified full-width header, permanent left nav ESP/Aim/Misc/Memory, compact right-hand toggles with click-only tween, responsive narrow sidebar, scrollable nav on very short displays.
- Core gameplay pre-UI and post-UI initialization remain identical to previous v1.1.63 core. Previous v1.1.64 serialized key-loader retained and repointed to v1.1.65.
- `Hub.lua` and `Visuals.lua` identical blob: `8d5de300e14b8cd4ec18fd4d3598346ed5ea838d`.
- `Start.lua` new blob: `3daa4572d7a130a8b9dc9d8d383df580695af8dc`.
- `AUDIT_UI_v1.1.65.md` created: 69/69 static checks, 7/7 viewport scenario calculations, structural lexical scan 8,391 lines / 39,331 tokens without syntax-structure findings.
- **Unverified:** Roblox Luau compile, actual UI rendering, Android touch behavior, performance/FPS, live ESP/AIM functionality. Do not present these as tested.
- Key System `124HUB` unchanged; it is client-local, not server-secured.
- Known earlier lifecycle caveat: directly loading Hub.lua/Visuals.lua concurrently can race on shared boot phase. Loader guard only serializes Start.lua in the same environment. Not changed in UI-only update.

## Previous history

# RV_STATE — 124 Visuals / launcher-only audit fixes (11 Nov 2026)

Current test branch: `v1.1.64-lifecycle-key-race-audit-test`.
- Working core version is **v1.1.63**, NOT v1.1.64. `Hub.lua` / `Visuals.lua` unchanged, same blob: `02c2e68c861f8ed249d5dc7880324402c06d17a8`.
- `Start.lua` was modified and is ready for *unverified* test: mutex `ARMY124_START_RUNNING` avoids overlapping launcher invocations; removes stale error overlay; validates `124HUB` gate is present in fetched source. New blob `7626b1d3da65abae097da798b9276fadcc4d3d99`.
- One attempt to update both full Lua core files in this branch was blocked. No source-code fixes to core were applied.
- Static checks: 18/18 focused launcher/source consistency checks, 99-line Start.lua lexical scan zero issues.
- Detailed findings: `AUDIT_v1.1.64_pending.md`.
- Pending core fix: per-invocation boot token to prevent races for direct loads; bounded candidate rediscovery in No Spread.
- No Roblox, executor, weapon or FPS live tests. Do not claim all bugs fixed or production readiness.
- The key remains `124HUB` and is validated locally only.
- Old `v1.1.63-independent-reaudit-test` branch untouched.

## Older history

# RV_STATE — 124 Visuals v1.1.63

Current branch: `v1.1.63-independent-reaudit-test`  
Base: `v1.1.62-audit-fixes-test`  
User requested repeated audit and bug fixes. Existing functions preserved.

## Changes
- G-04: explicitly use mobile `TextBox.ReturnPressedFromOnScreenKeyboard`; no accidental submit on blur.
- S-04: spread change events coalesced with bounded 0.05-second reactive interval.
- R-02: mouse held state checked when Tool.Activated occurs without InputBegan callback.

## Verification
- Static asserts: **83/83**.
- Lexer/balanced Luau-like structure: 8,365 lines, 39,214 tokens, zero structural issues.
- Sources identical blob `02c2e68c861f8ed249d5dc7880324402c06d17a8`.
- Launcher blob `8199616e431766480dae89823228497c4394939d`.
- Detail: `AUDIT_v1.1.63.md`.
- Actual Luau compile / Roblox runtime / key UI / executor compatibility / FPS tests: NOT performed.
- Plaintext gate key remains `124HUB`, not server-authorized.

## Next
Test key input and weapon compatibility in Roblox. Preserve prior branch and avoid claiming live behavior before logs/screenshots.

## Previous entries

# RV_STATE — v1.1.62

## Current
- Branch: `v1.1.62-audit-fixes-test`
- Gate code: `124HUB` (client-local, every run).
- Hub / Visuals Git blob: `37e05e9bd9941cd5b688985779060fd3ebf703eb`.
- Start Git blob: `81db382ddf0f14edddfd7e40f110a9db43b62a5e`.
- Audit: `AUDIT_v1.1.62.md`. 114/114 static checks; lexical scanner zero issues in 8,344-line file.
- Runtime / true Luau compilation: **not performed**.
- Key UI: transactional widgets, mobile fallback and cleanup, silent cancel.
- Recoil: orphan watchdog prevents extended ghost compensation.
- Spread: per-instance watcher cleanup, deferred-safe DescendantRemoving and slower fallback verification.
- Existing main branch untouched. Baseline `v1.1.61-shared-key-gate-test` preserved.
- Open work: live device / weapon compatibility, actual mobile keyboard UX, FPS benchmark.

## Previous state

# 124 Visuals — RV_STATE

## v1.1.61 / shared key gate (2026-11-11)

- Base: `v1.1.60-recoil-spread-stability-test`
- Branch: `v1.1.61-shared-key-gate-test`
- Shared local access key: `124HUB`. Case-sensitive; trims leading/trailing whitespace.
- Every run opens a centered purple key entry panel inside PlayerGui, after previous-session cleanup and pending recovery, before creation of `state`, module controllers, GUI and render callbacks.
- `Hub.lua` and `Visuals.lua` contain the same gate; direct loading of either current-branch file also requires the key.
- Mouse/touch button and Enter key submit. Wrong key clears input and retains the gate. Cancel or GUI destruction exits without creating modules.
- No key saving across sessions. Existing function state is not initialized until authorization.
- File blob: Hub.lua / Visuals.lua `dbd62506d52c962ce9386f2a702e9619b6adc565`; Start.lua `ef6ab06623d4590f4e8a4319cd29afb0859b0b3e`.
- Validation: 22 / 22 **static** assertions passed; both source files identical; only Hub.lua / Visuals.lua / Start.lua changed versus v1.1.60.
- **Unverified:** Luau compile in real executor, interactive GUI input, gameplay tests in Roblox, mobile keyboard visibility and screen-size fit.
- **Security model:** local shared-key gate, not remote authentication. The key is visible in client source, and anyone loading previous branches or modifying source can circumvent it; do not claim server-side secure licensing.

## Prior state

# RV_STATE.md

## Состояние
- Релиз-кандидат: **124 Visuals v1.1.60**.
- Базовая ветка: `v1.1.59-recovery-crosshair-graphics-audit`.
- Рабочая ветка: `v1.1.60-recoil-spread-stability-test`.
- `Hub.lua` и `Visuals.lua`: зеркальные, Git blob `23c8c9800945ee0ae696971f190cd6cd9eba5d03`.
- `Start.lua`: обновлён на v1.1.60 и текущую ветку, Git blob `3dc700484de9baf5019abb22bfb1be618af455cb`.

## Изменения
- No Recoil: дополнен распознаванием нажатия MouseButton1, ButtonR2 и касания явно названных GUI-кнопок Fire/Shoot/Attack/Trigger; `Tool.Activated` сохранён.
- Дубликаты одновременных сигналов подсчитываются один раз; сброс удержания по `InputEnded`.
- No Spread: подписка на `Value` и `AttributeChanged`, коалесцирование обновлений и контрольный проход не чаще раза в 0.30 с.
- Добавлены имена числовых параметров, обнаружение конфигурационных атрибутов, отключение наблюдателей перед восстановлением снимков.
- UI, AIM, ESP, FPS Booster, настройки профилей и откат сохранены.

## Проверки
- Сравнение исходников и загрузчика GitHub: **22/22 статических утверждения успешно**.
- `Hub.lua` и `Visuals.lua` идентичны по содержимому и Git blob.
- Компиляция Luau: **не выполнялась** (компилятора нет в доступной среде).
- Реальный Roblox, Delta/Xeno, FPS, оружейные скрипты и мобильные касания: **не проверялись**.
- Статические проверки не доказывают отсутствие ошибок во время выполнения.

## Известные пределы
- Не изменяется разброс, вычисляемый сервером или скрытый внутри модулей, не представленный доступными числовыми свойствами/атрибутами.
- Не вся кастомная мобильная кнопка стрельбы имеет узнаваемое имя.
- Компенсация камеры по-прежнему вертикальная; во время активного AIM приоритет управления камерой сохранён.
- Не заявлять о 100% совместимости с каждым оружием до испытаний в конкретном месте.

## Следующая проверка
Испытать на двух видах оружия: где раньше работало и где раньше не работало. Отдельно проверить нажатие, удержание, сброс при смене Tool, включение/выключение No Spread, сохранение прицела и отсутствие новых ошибок Output.
