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
