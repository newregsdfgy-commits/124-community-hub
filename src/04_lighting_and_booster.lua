-- Shared Lighting ownership: only properties actually written by this
-- script are restored. Dynamic day/night changes stay with the game.
local lightingProperties = {
    "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation", "GlobalShadows"
}
local lightingOwned = {} -- key -> last value this script imposed (false is valid).

local function captureLighting()
    if savedLighting then return end
    savedLighting = {}
    for _, key in ipairs(lightingProperties) do
        local ok, value = pcall(function() return Lighting[key] end)
        if ok then savedLighting[key] = value end
    end
end

local function wantedLightingValue(key)
    if not savedLighting then return nil end
    if state.fullbright then
        if key == "Brightness" then return CONFIG.FullBrightBrightness end
        if key == "Ambient" then return CONFIG.FullBrightAmbient end
        if key == "OutdoorAmbient" then return CONFIG.FullBrightOutdoorAmbient end
        if key == "ExposureCompensation" then return CONFIG.FullBrightExposure end
    end
    if key == "GlobalShadows" and (state.fullbright or state.booster) then
        return false
    end
    return nil
end

local function restoreOwnedLighting(key)
    local imposed = lightingOwned[key]
    if imposed == nil then return true end
    local original = savedLighting and savedLighting[key]
    local ok = pcall(function()
        local current = Lighting[key]
        -- Another owner/game changed this property: never overwrite it.
        if original ~= nil and current == imposed and current ~= original then
            Lighting[key] = original
            if Lighting[key] ~= original then error("Lighting restore mismatch") end
        end
    end)
    if ok then
        lightingOwned[key] = nil
    else
        boosterPro.restoreFailures = boosterPro.restoreFailures + 1
        if boosterPro.restoreFailures <= 3 then
            warn("[124 Visuals] Lighting: восстановление " .. tostring(key) .. " будет повторено")
        end
    end
    return ok
end

local function enforceLightingProperty(key)
    if not alive or lightingApplying or not savedLighting then return end
    local wanted = wantedLightingValue(key)
    if wanted == nil then return end
    lightingApplying = true
    pcall(function()
        local current = Lighting[key]
        if current ~= wanted then
            -- Preserve the latest dynamic value from the game, not an old
            -- snapshot taken several day/night transitions ago.
            savedLighting[key] = current
            lightingOwned[key] = wanted
            Lighting[key] = wanted
        end
    end)
    lightingApplying = false
end

local function applyLighting()
    if lightingApplying then return end
    if not state.fullbright and not state.booster then
        if savedLighting then
            lightingApplying = true
            local complete = true
            for _, key in ipairs(lightingProperties) do
                if not restoreOwnedLighting(key) then complete = false end
            end
            lightingApplying = false
            if complete then savedLighting = nil end
        end
        return
    end
    captureLighting()
    lightingApplying = true
    for _, key in ipairs(lightingProperties) do
        local wanted = wantedLightingValue(key)
        if wanted ~= nil then
            pcall(function()
                local current = Lighting[key]
                if current ~= wanted then
                    savedLighting[key] = current
                    lightingOwned[key] = wanted
                    Lighting[key] = wanted
                end
            end)
        else
            -- Example: FullBright OFF while Booster is still ON. Restore
            -- FullBright-owned colors, but leave unowned game lighting alone.
            restoreOwnedLighting(key)
        end
    end
    lightingApplying = false
end

-- Отключение декоративной травы Terrain — только при поддержке исполнителя.
-- Terrain.Decoration официально NotScriptable, поэтому используем API
-- исполнителя исключительно если можем прочитать и вернуть исходное значение.
local function terrainAccessor(kind)
    local direct = kind == "read" and gethiddenproperty or sethiddenproperty
    local alternate = kind == "read" and gethiddenprop or sethiddenprop
    if type(direct) == "function" then return direct end
    if type(alternate) == "function" then return alternate end
    return nil
end

local function hideTerrainGrass()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return false end
    local saved = savedTerrainDecoration
    if saved then
        -- If the game changed grass while Booster was active, remember its
        -- newest choice instead of restoring an obsolete pre-Booster value.
        if saved.terrain ~= terrain then return false end
        local ok, current = pcall(saved.getter, terrain, "Decoration")
        if not ok or type(current) ~= "boolean" then return false end
        if current == false then return true end
        saved.original = current
        local wrote = pcall(saved.setter, terrain, "Decoration", false)
        if not wrote then return false end
        local checked, applied = pcall(saved.getter, terrain, "Decoration")
        return checked and applied == false
    end
    local getter, setter = terrainAccessor("read"), terrainAccessor("write")
    if not getter or not setter then return false end
    local read, original = pcall(getter, terrain, "Decoration")
    if not read or type(original) ~= "boolean" then return false end
    if original == false then return true end -- Already optimized by the game.
    local wrote = pcall(setter, terrain, "Decoration", false)
    if not wrote then return false end
    -- Keep original even when the readback fails: a setter may have mutated
    -- the property and rollback must still know what to attempt.
    savedTerrainDecoration = {
        terrain = terrain, original = original, getter = getter, setter = setter,
    }
    local checked, applied = pcall(getter, terrain, "Decoration")
    return checked and applied == false
end

local function restoreTerrainGrass()
    local saved = savedTerrainDecoration
    if not saved then return true end
    if not saved.terrain.Parent then
        savedTerrainDecoration = nil -- Destroyed Terrain cannot be restored.
        return true
    end
    local ok = pcall(function()
        local current = saved.getter(saved.terrain, "Decoration")
        if type(current) ~= "boolean" then error("Terrain grass readback invalid") end
        if current == false and current ~= saved.original then
            saved.setter(saved.terrain, "Decoration", saved.original)
            if saved.getter(saved.terrain, "Decoration") ~= saved.original then
                error("Terrain grass restore mismatch")
            end
        end
        -- External edits are now the game's property; never overwrite them.
    end)
    if ok then
        savedTerrainDecoration = nil
    else
        boosterPro.restoreFailures = boosterPro.restoreFailures + 1
        if boosterPro.restoreFailures <= 3 then
            warn("[124 Visuals] Booster: Terrain grass restore pending")
        end
    end
    return ok
end

-- Белая карта: Terrain окрашиваем только при доступном чтении исходного цвета.
-- Цвет каждого материала восстанавливается при отключении Booster и Unload.
local terrainMaterialNames = {
    "Grass", "LeafyGrass", "Ground", "Sand", "Sandstone", "Rock", "Slate",
    "Mud", "Snow", "Ice", "Glacier", "Concrete", "Brick", "Cobblestone",
    "Asphalt", "Basalt", "Pavement", "Limestone", "Salt", "CrackedLava",
}
local terrainWhite = Color3.new(1, 1, 1)
-- Terrain snapshots record the last value actually written by Booster.
-- A game-owned color update must never be overwritten during OFF or Unload.
local function whitenTerrain()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    local previous = savedTerrainColors
    if previous and previous.terrain ~= terrain then
        -- Never discard pending restore entries for a detached old Terrain.
        -- An older Terrain still has pending snapshots; leave it untouched.
        return
    end
    local items = previous and previous.items or {}
    local known = {}
    for _, item in ipairs(items) do known[item[1]] = item end
    for _, name in ipairs(terrainMaterialNames) do
        local material = Enum.Material[name]
        if material then
            local okRead, current = pcall(function() return terrain:GetMaterialColor(material) end)
            if okRead and current and current ~= terrainWhite then
                local item = known[material]
                if item and current ~= item[3] then
                    -- External changes since our last write are the new original.
                    item[2] = current
                end
                local wrote = pcall(function()
                    terrain:SetMaterialColor(material, terrainWhite)
                end)
                if wrote then
                    local checked, applied = pcall(function()
                        return terrain:GetMaterialColor(material)
                    end)
                    if not item then
                        item = {material, current, terrainWhite}
                        items[#items + 1] = item
                        known[material] = item
                    end
                    -- An API may clamp the requested color; preserve what it
                    -- actually wrote so restoration can recognize ownership.
                    if checked then item[3] = applied end
                end
            end
        end
    end
    if #items > 0 then savedTerrainColors = {terrain = terrain, items = items} end
end
local function restoreTerrainColors()
    local data = savedTerrainColors
    if not data then return true end
    if not data.terrain.Parent then
        savedTerrainColors = nil -- Destroyed Terrain is no longer visible.
        return true
    end
    local pending = {}
    for _, item in ipairs(data.items) do
        local material, original, imposed = item[1], item[2], item[3]
        local ok = pcall(function()
            local current = data.terrain:GetMaterialColor(material)
            if current == imposed and current ~= original then
                data.terrain:SetMaterialColor(material, original)
                if data.terrain:GetMaterialColor(material) ~= original then
                    error("Terrain material restore mismatch")
                end
            end
            -- If changed externally, leave the game's newer color untouched.
        end)
        if not ok then
            pending[#pending + 1] = item
            boosterPro.restoreFailures = boosterPro.restoreFailures + 1
            if boosterPro.restoreFailures <= 3 then
                warn("[124 Visuals] Booster Terrain: restore pending for " .. tostring(material))
            end
        end
    end
    if #pending > 0 then
        data.items = pending
        return false
    end
    savedTerrainColors = nil
    return true
end

-- FPS Booster Pro: три ступени, снимки ТОЛЬКО изменённых свойств.
-- Иерархии GUI (включая SurfaceGui/BillboardGui), камеры и персонажей исключены.
-- Профили можно менять в реальном времени, оригинальные значения не теряются.
-- Кэшируем модели игроков: на больших картах нельзя вызывать GetPlayers() на каждой детали.
boosterPro.protectedCharacters = setmetatable({}, {__mode = "k"})
boosterPro.protectedNames = {}
-- CharacterAdded is owned by the player lifetime, not by the hub lifetime.
-- Keep one connection per active Player; disconnect immediately on leaving.
boosterPro.playerConnections = {}
function boosterPro.watchPlayer(person)
    if not alive or boosterPro.playerConnections[person] then return end
    boosterPro.protectedNames[person.Name] = true
    if person.Character then boosterPro.protectedCharacters[person.Character] = true end
    boosterPro.playerConnections[person] = person.CharacterAdded:Connect(function(character)
        if not alive then return end
        boosterPro.protectedCharacters[character] = true
        -- Keep late avatars out of graphic simplification.
        if boosterPro.restoreProtectedTree then
            boosterPro.restoreProtectedTree(character)
        end
    end)
end
function boosterPro.unwatchPlayer(person)
    local connection = boosterPro.playerConnections[person]
    if connection then
        pcall(function() connection:Disconnect() end)
        boosterPro.playerConnections[person] = nil
    end
    boosterPro.protectedNames[person.Name] = nil
end
function boosterPro.stopWatchingPlayers()
    for person, connection in pairs(boosterPro.playerConnections) do
        pcall(function() connection:Disconnect() end)
        boosterPro.playerConnections[person] = nil
    end
    table.clear(boosterPro.protectedNames)
end
for _, person in ipairs(perfCounters.roster) do boosterPro.watchPlayer(person) end
connect(Players.PlayerAdded, boosterPro.watchPlayer)
connect(Players.PlayerRemoving, boosterPro.unwatchPlayer)

-- Проверять каждую родительскую модель для каждой детали дорого.
-- При обходе дерева достаточно проверить границу ветки ОДИН раз.
function boosterPro.isProtectedBranch(obj)
    -- Exact instance ownership: no unrelated game effects are exempted based
    -- on a matching Name, and an unowned Atmosphere remains optimizable.
    if boosterPro.playerFxOwned[obj] == true then return true end
    local cam = Workspace.CurrentCamera
    if obj == cam then return true end
    if obj:IsA("LayerCollector") or obj:IsA("GuiBase2d") then return true end
    if obj:IsA("Model") then
        if boosterPro.protectedCharacters[obj] or boosterPro.protectedNames[obj.Name] then
            return true
        end
        if obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChild("HumanoidRootPart") then
            return true
        end
        if obj:FindFirstChild("Head") and
            (obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("Torso")
                or obj:FindFirstChild("LowerTorso")) then
            return true
        end
    end
    return false
end
function boosterPro.isProtected(obj)
    local parent = obj
    while parent and parent ~= Workspace and parent ~= Lighting do
        if boosterPro.isProtectedBranch(parent) then return true end
        parent = parent.Parent
    end
    return false
end

-- Таблицы целевых свойств общие для всех деталей, без десятков тысяч
-- временных таблиц и Color3.fromRGB на каждом объекте.
local graphicsWhite = Color3.new(1, 1, 1)
local graphicsPlain = {CastShadow = false}
local graphicsNoProperties = {} -- Shared immutable map avoids downgrade allocations.
local graphicsWhitePart = {CastShadow = false, Material = Enum.Material.SmoothPlastic,
    MaterialVariant = "", Color = graphicsWhite}
local graphicsUltraPart = {CastShadow = false, Material = Enum.Material.SmoothPlastic,
    MaterialVariant = "", Color = graphicsWhite, Reflectance = 0}
local graphicsWhiteMesh = {CastShadow = false, Material = Enum.Material.SmoothPlastic,
    MaterialVariant = "", TextureID = "", Color = graphicsWhite}
local graphicsUltraMesh = {CastShadow = false, Material = Enum.Material.SmoothPlastic,
    MaterialVariant = "", TextureID = "", Color = graphicsWhite, Reflectance = 0}
if Enum.RenderFidelity then graphicsUltraMesh.RenderFidelity = Enum.RenderFidelity.Performance end
local graphicsTransparent = {Transparency = 1}
local graphicsDisabled = {Enabled = false}
local graphicsSpecialMesh = {TextureId = ""}
local graphicsSurface = {ColorMap = "", NormalMap = "", RoughnessMap = "", MetalnessMap = ""}
local graphicsWater = {WaterWaveSize = 0, WaterWaveSpeed = 0, WaterReflectance = 0}
local graphicsAtmosphere = {Density = 0, Haze = 0, Glare = 0, Offset = 0}
local graphicsClouds = {Cover = 0, Density = 0}

local function graphicsProperty(obj)
    local level = state.boosterMode
    -- BALANCED не должен менять десятки тысяч BasePart ради одного тумблера.
    -- Глобальные тени отключает applyLighting; здесь только постэффекты.
    if level == "BALANCED" then
        return obj:IsA("PostEffect") and graphicsDisabled or nil
    end
    local white = level == "WHITE" or level == "ULTRA"
    local ultra = level == "ULTRA"
    if obj:IsA("Terrain") then
        return ultra and graphicsWater or nil
    elseif obj:IsA("MeshPart") then
        return ultra and graphicsUltraMesh or white and graphicsWhiteMesh or graphicsPlain
    elseif obj:IsA("BasePart") then
        return ultra and graphicsUltraPart or white and graphicsWhitePart or graphicsPlain
    elseif white and obj:IsA("SpecialMesh") then
        return graphicsSpecialMesh
    elseif white and obj:IsA("SurfaceAppearance") then
        return graphicsSurface
    elseif white and (obj:IsA("Decal") or obj:IsA("Texture")) then
        return graphicsTransparent
    elseif white and (obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight")) then
        return graphicsDisabled
    elseif obj:IsA("PostEffect") or obj:IsA("ParticleEmitter") or
        obj:IsA("Trail") or obj:IsA("Beam") then
        return graphicsDisabled
    elseif white and (obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles")) then
        return graphicsDisabled
    elseif ultra and obj:IsA("Atmosphere") then
        return graphicsAtmosphere
    elseif ultra and obj:IsA("Clouds") then
        return graphicsClouds
    end
    return nil
end

-- Restore only a Booster-owned value. If the game or another script
-- changed this property after we wrote it, keep that new value intact.
function boosterPro.restoreBoosterProperty(obj, snapshot, key, original)
    local written = boosterPro.graphicsWritten[obj]
    local lastWritten = written and written[key] or nil
    local ok = pcall(function()
        if not obj.Parent then return end
        local current = obj[key]
        if current == original then return end
        if lastWritten ~= nil and current == lastWritten then
            obj[key] = original
            if obj[key] ~= original then error("Booster property restore mismatch") end
        end
        -- If current differs from lastWritten, the game owns the newer value.
    end)
    if ok or not obj.Parent then
        snapshot[key] = nil
        if written then
            written[key] = nil
            if not next(written) then boosterPro.graphicsWritten[obj] = nil end
        end
        return true
    end
    return false
end

-- Original snapshots survive BALANCED -> WHITE -> ULTRA changes.
local function optimizeObject(obj, alreadyScreened)
    if not alive or not state.booster then return end
    local desired = graphicsProperty(obj)
    local snap = savedGraphics[obj]
    if not desired and not snap then return end
    if not alreadyScreened and boosterPro.isProtected(obj) then return end
    desired = desired or graphicsNoProperties
    if snap then
        for key, original in pairs(snap) do
            if desired[key] == nil then
                if not boosterPro.restoreBoosterProperty(obj, snap, key, original) then
                    boosterPro.restoreFailures = boosterPro.restoreFailures + 1
                    if boosterPro.restoreFailures <= 3 then
                        warn("[124 Visuals] Booster mode downgrade failed for " .. tostring(key))
                    end
                end
            end
        end
    end
    for key, target in pairs(desired) do
        local read, current = pcall(function() return obj[key] end)
        if read and current ~= target then
            local wrote = pcall(function() obj[key] = target end)
            local checked, applied = pcall(function() return obj[key] end)
            -- A successful setter may be ignored or clamp the target. Never
            -- pretend the property changed and then lose its real baseline.
            if checked and applied ~= current then
                if not snap then snap = {}; savedGraphics[obj] = snap end
                local written = boosterPro.graphicsWritten[obj]
                if not written then written = {}; boosterPro.graphicsWritten[obj] = written end
                if snap[key] == nil or (written[key] ~= nil
                    and current ~= written[key]) then
                    -- The game may update a property while Booster is ON.
                    snap[key] = current
                end
                written[key] = applied
                boosterPro.changedProperties = boosterPro.changedProperties + 1
            elseif wrote and not checked then
                -- We cannot confirm whether the setter mutated the object.
                -- Keep a rollback attempt rather than dropping the original.
                if not snap then snap = {}; savedGraphics[obj] = snap end
                if snap[key] == nil then snap[key] = current end
                local written = boosterPro.graphicsWritten[obj]
                if not written then written = {}; boosterPro.graphicsWritten[obj] = written end
                written[key] = target
                boosterPro.unverifiedWrites = boosterPro.unverifiedWrites + 1
            elseif not wrote then
                boosterPro.deniedWrites = boosterPro.deniedWrites + 1
            end
        end
    end
    if snap and not next(snap) then
        savedGraphics[obj] = nil
        boosterPro.graphicsWritten[obj] = nil
    end
end

-- Проходим дерево без GetDescendants(): контролируем число объектов и CPU-миллисекунды.
-- Новые детали, добавленные во время обхода, дочитает FIFO после завершения.
local function optimizeHierarchy(root, revision)
    local stack = {{items = root:GetChildren(), index = 1}}
    local sliceStarted = os.clock()
    local count = 0
    while #stack > 0 do
        if not alive or not state.booster or revision ~= boosterRevision then return false end
        local level = stack[#stack]
        local obj = level.items[level.index]
        if not obj then
            stack[#stack] = nil
        else
            level.index = level.index + 1
            if not boosterPro.isProtectedBranch(obj) then
                if boosterPro.queuedSeen[obj] then boosterPro.queuedProcessed[obj] = true end
                optimizeObject(obj, true)
                local children = obj:GetChildren()
                if #children > 0 then
                    stack[#stack + 1] = {items = children, index = 1}
                end
            end
            boosterPro.scanned = boosterPro.scanned + 1
            count = count + 1
            if count >= CONFIG.BoosterBatch or (count % 4 == 0 and
                (os.clock() - sliceStarted) * 1000 >=
                    (measuredFps < 35 and CONFIG.BoosterLowFpsSliceMs or CONFIG.BoosterSliceMs)) then
                boosterPro.slicePeakMs = math.max(boosterPro.slicePeakMs,
                    (os.clock() - sliceStarted) * 1000)
                count = 0
                task.wait(measuredFps < 42 and CONFIG.BoosterLowFpsDelay
                    or CONFIG.BoosterInitialDelay)
                sliceStarted = os.clock()
            end
        end
    end
    return true
end

function boosterPro.average(values)
    if #values < 2 then return nil end
    local total = 0
    for _, value in ipairs(values) do total = total + value end
    return math.floor(total / #values + 0.5)
end
function boosterPro.measure(value)
    if not alive or value <= 0 then return end
    local target = nil
    if state.booster then
        -- Измеряем и во время долгой перекраски: ранний FPS Guard иначе бесполезен.
        if boosterPro.startedAt and os.clock() >= boosterPro.startedAt + 4 then
            target = boosterPro.afterFPS
        end
    else
        target = boosterPro.originalFPS
    end
    if target then
        target[#target + 1] = value
        if #target > 6 then table.remove(target, 1) end
    end
    if state.booster then
        boosterPro.after = boosterPro.average(boosterPro.afterFPS)
        -- After the warmup, detect a sustained drop against pre-Booster FPS.
        -- The rollback function is installed after the UI and config handlers exist.
        if boosterPro.autoRollback then boosterPro.autoRollback() end
    end
end
-- Централизованный учёт ресурсов: вызывается по кнопке, не в RenderStepped.
-- Лимит исключает долгий диагностический обход на очень большой карте.
function boosterPro.snapshotStatus(limit)
    local maxObjects = math.max(1, math.floor(tonumber(limit) or 2048))
    local objects, properties, capped = 0, 0, false
    for _, snap in pairs(savedGraphics) do
        objects = objects + 1
        for _ in pairs(snap) do properties = properties + 1 end
        if objects >= maxObjects then capped = true; break end
    end
    return {
        objects = objects, properties = properties, capped = capped,
        terrain = savedTerrainDecoration ~= nil or savedTerrainColors ~= nil,
        lighting = savedLighting ~= nil and not state.fullbright,
        work = boosterPro.workers,
    }
end
function boosterPro.selfCheck()
    -- Только чтение. Не запускает Booster и не меняет мир.
    local checks = {
        {"живой экземпляр", alive == true},
        {"токен запуска", env.ARMY124_BOOT_TOKEN == CONFIG.BootToken},
        {"функция выгрузки", type(env.ARMY124_CLEANUP) == "function"},
        {"границы очереди", boosterPro.queueCount >= 0
            and boosterPro.queueCount <= boosterPro.queueCap},
        {"состояние рабочих задач", boosterPro.workers.scan >= 0
            and boosterPro.workers.restore >= 0 and boosterPro.workers.repair >= 0
            and boosterPro.workers.avatar >= 0},
        {"основная GUI", PlayerGui:FindFirstChild("Army124CommunityVisualsGUI") ~= nil},
        {"ревизия Booster", boosterPro.revision == boosterRevision},
    }
    local failures, passed = {}, 0
    for _, entry in ipairs(checks) do
        if entry[2] then passed = passed + 1
        else failures[#failures + 1] = entry[1] end
    end
    return passed, #checks, failures
end
function boosterPro.diagnosticStatus()
    local snap = boosterPro.snapshotStatus()
    local work = snap.work
    return string.format(
        "v%s | FPS %d | %s/%s | GPU snapshots %d%s (%d props) | Terrain %s | Lighting %s | Queue %d/%d (drop %d) | Workers scan:%d restore:%d repair:%d avatar:%d | errors:%d | hooks:%d",
        CONFIG.Version, measuredFps, tostring(boosterPro.phase),
        tostring(state.boosterMode), snap.objects, snap.capped and "+" or "",
        snap.properties, snap.terrain and "pending" or "ok",
        snap.lighting and "pending" or "ok",
        boosterPro.queueCount, boosterPro.queueCap, boosterPro.queueDropped,
        work.scan, work.restore, work.repair, work.avatar,
        boosterPro.restoreFailures, #connections
    )
end
function boosterPro.readout()
    local before = boosterPro.baseline and tostring(boosterPro.baseline) or "н/д"
    local after = boosterPro.after and tostring(boosterPro.after) or "замер..."
    local delta = ""
    if boosterPro.after and boosterPro.baseline and boosterPro.baseline > 0 then
        local change = boosterPro.after - boosterPro.baseline
        local rawPercent = change * 100 / boosterPro.baseline
        -- Симметричное округление: Lua math.floor(-40 - 0.5) давал -41.
        local percent = (rawPercent >= 0) and math.floor(rawPercent + 0.5)
            or -math.floor(-rawPercent + 0.5)
        delta = string.format(" | %+d FPS (%+d%%)", change, percent)
    elseif not state.booster and not boosterPro.after then
        after = "н/д"
    end
    local phase = state.booster and not boosterPro.complete
        and (" | Деталей: " .. tostring(boosterPro.scanned)) or ""
    return "До: " .. before .. " FPS  |  После: " .. after .. delta .. phase
        .. " | Записано свойств: " .. tostring(boosterPro.changedProperties)
        .. " | " .. tostring(boosterPro.phase)
end

function boosterPro.restoreObject(obj, snapshot)
    local left = false
    for key, original in pairs(snapshot) do
        if not boosterPro.restoreBoosterProperty(obj, snapshot, key, original) then
            left = true
            boosterPro.restoreFailures = boosterPro.restoreFailures + 1
            if boosterPro.restoreFailures <= 3 then
                warn("[124 Visuals] Booster: failed to restore " .. tostring(key)
                    .. " for " .. tostring(obj.Name))
            end
        end
    end
    if not left then
        savedGraphics[obj] = nil
        boosterPro.graphicsWritten[obj] = nil
    end
end

-- Hand an Atmosphere back from Booster to Player weather only after restoring
-- Booster's own saved values; otherwise Player captures Booster's Density=0
-- as its "game original" and leaves permanently flattened fog on disable.
function boosterPro.releaseAtmosphereToPlayer(obj)
    local saved = savedGraphics[obj]
    if saved then boosterPro.restoreObject(obj, saved) end
    return savedGraphics[obj] == nil
end
function boosterPro.reapplyAtmosphereAfterPlayer(obj)
    if alive and state.booster and obj and obj.Parent then
        optimizeObject(obj, false)
    end
end

-- Снимки могли появиться раньше, чем Roblox объявил Model персонажем.
-- Инициируется CharacterAdded или поступлением Humanoid/частей тела.
function boosterPro.restoreGraphicsEmergency()
    local count, sliceStarted = 0, os.clock()
    for obj, snapshot in pairs(savedGraphics) do
        boosterPro.restoreObject(obj, snapshot)
        count = count + 1
        if count % 4 == 0 and ((os.clock() - sliceStarted) * 1000 >=
            CONFIG.BoosterSliceMs or count % CONFIG.BoosterBatch == 0) then
            task.wait()
            sliceStarted = os.clock()
        end
    end
    return next(savedGraphics) == nil
end

-- Late characters are NOT scanned when there are no graphics snapshots.
-- A single owner drains all character restorations in small, nonblocking slices.
-- This matters on accessory-heavy respawns/StreamingEnabled bursts.
boosterPro.protectedRestoreQueue = {}
boosterPro.protectedRestoreSeen = setmetatable({}, {__mode = "k"})
boosterPro.protectedRestoreRunning = false
function boosterPro.restoreProtectedTree(character)
    if not alive or not character or next(savedGraphics) == nil then return end
    if boosterPro.protectedRestoreSeen[character] then return end
    boosterPro.protectedRestoreSeen[character] = true
    local queue = boosterPro.protectedRestoreQueue
    queue[#queue + 1] = character
    if boosterPro.protectedRestoreRunning then return end
    boosterPro.protectedRestoreRunning = true
    task.spawn(function()
        boosterPro.workers.avatar = boosterPro.workers.avatar + 1
        local ok, err = pcall(function()
            while alive and #queue > 0 do
                local current = table.remove(queue, 1)
                if current then
                    local stack = {current}
                    local count, sliceStart = 0, os.clock()
                    while alive and #stack > 0 and next(savedGraphics) ~= nil do
                        local obj = stack[#stack]
                        stack[#stack] = nil
                        local snapshot = savedGraphics[obj]
                        if snapshot then boosterPro.restoreObject(obj, snapshot) end
                        local children = obj:GetChildren()
                        for i = 1, #children do
                            stack[#stack + 1] = children[i]
                        end
                        count = count + 1
                        if count >= 16 or (count % 4 == 0 and
                            (os.clock() - sliceStart) * 1000 >= CONFIG.BoosterLowFpsSliceMs) then
                            task.wait()
                            count, sliceStart = 0, os.clock()
                        end
                    end
                    boosterPro.protectedRestoreSeen[current] = nil
                end
            end
        end)
        -- Unexpected failures cannot leave the queue permanently latched.
        -- Unrestored snapshots remain in savedGraphics for normal retry.
        table.clear(queue)
        table.clear(boosterPro.protectedRestoreSeen)
        boosterPro.protectedRestoreRunning = false
        boosterPro.workers.avatar = math.max(0, boosterPro.workers.avatar - 1)
        if not ok and alive then
            warn("[124 Community Visuals] Protected restore: " .. tostring(err))
        end
    end)
end

local function setBooster(enabled, keepBaseline)
    boosterRevision = boosterRevision + 1
    local revision = boosterRevision
    boosterPro.revision = revision
    -- Любая новая ревизия отменяет ожидающий фоновый откат старой.
    boosterPro.restoreRetryAt = 0
    boosterPro.restoreRetryRunning = false
    boosterPro.terrainRestoreRetryAt = 0
    boosterPro.complete = false
    boosterPro.readyAt = nil
    boosterPro.restoreFailures = 0
    boosterPro.failed = nil
    boosterPro.guardLowSince = nil
    boosterPro.guardLastCheck = 0
    -- Discard old queued descendants. New events belong to the new revision.
    boosterPro.queued = {}
    boosterPro.queuedSeen = setmetatable({}, {__mode = "k"})
    boosterPro.queuedProcessed = setmetatable({}, {__mode = "k"})
    boosterPro.queueHead, boosterPro.queueTail, boosterPro.queueCount = 1, 0, 0
    boosterPro.queueDropped, boosterPro.scanned = 0, 0
    boosterPro.queueLastAt = 0
    boosterPro.slicePeakMs, boosterPro.queuePeakMs = 0, 0
    boosterPro.changedProperties = 0
    boosterPro.deniedWrites, boosterPro.unverifiedWrites = 0, 0
    boosterPro.phase = enabled and "SCANNING" or "RESTORING"
    boosterPro.repairing = false
    boosterPro.repairCoveredDrops, boosterPro.repairRetryAt, boosterPro.repairErrors = 0, 0, 0
    if enabled then
        boosterPro.lastError = nil
        boosterPro.after = nil
        boosterPro.afterFPS = {}
        boosterPro.guardWarned = false
        if not keepBaseline then boosterPro.baseline = boosterPro.average(boosterPro.originalFPS) end
        boosterPro.mode = state.boosterMode
        boosterPro.startedAt = os.clock()
        -- Кнопка возвращает управление сразу. Тяжёлые операции Terrain/карты
        -- начинаются вне обработчика UI; каждая ревизия проверяет актуальность.
        task.spawn(function()
            boosterPro.workers.scan = boosterPro.workers.scan + 1
            local ok, err = pcall(function()
            if not alive or revision ~= boosterRevision or not state.booster then return end
            applyLighting()
            if state.boosterMode == "BALANCED" then
                restoreTerrainGrass()
                restoreTerrainColors()
            else
                hideTerrainGrass()
                whitenTerrain()
            end
            if not alive or revision ~= boosterRevision or not state.booster then return end
            -- Сначала синхронизируем старые снимки: это важно при ULTRA -> BALANCED.
            local n, phaseStarted = 0, os.clock()
            for obj in pairs(savedGraphics) do
                if not alive or revision ~= boosterRevision or not state.booster then return end
                optimizeObject(obj)
                n = n + 1
                if n % 4 == 0 and ((os.clock() - phaseStarted) * 1000 >=
                    (measuredFps < 42 and CONFIG.BoosterLowFpsSliceMs
                        or CONFIG.BoosterSliceMs)
                    or n % CONFIG.BoosterBatch == 0) then
                    task.wait(measuredFps < 42 and CONFIG.BoosterLowFpsDelay
                        or CONFIG.BoosterInitialDelay)
                    phaseStarted = os.clock()
                end
            end
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then optimizeObject(terrain) end
            -- Apply Lighting post effects first; a huge streamed Workspace
            -- must not delay the first visible benefit of the Booster.
            if not optimizeHierarchy(Lighting, revision) then return end
            -- BALANCED intentionally skips the expensive Workspace traversal.
            if state.boosterMode ~= "BALANCED"
                and not optimizeHierarchy(Workspace, revision) then return end
            if revision ~= boosterRevision or not state.booster then return end
            boosterPro.complete = true
            boosterPro.phase = state.boosterMode == "BALANCED" and "READY FAST" or "READY"
            boosterPro.readyAt = os.clock() + 1.5
            -- Compare FPS only after optimization actually finishes; earlier
            -- samples include initial workload and would trigger a false auto-rollback.
            boosterPro.afterFPS = {}
            boosterPro.after = nil
            boosterPro.guardLowSince = nil
            tell("FPS Booster Pro: " .. state.boosterMode .. " применён; просмотрено "
                .. tostring(boosterPro.scanned)
                .. (state.boosterMode == "BALANCED" and " объектов; карта без изменений; измеряем FPS"
                    or " объектов; измеряем FPS"))
            end)
            boosterPro.workers.scan = math.max(0, boosterPro.workers.scan - 1)
            if not ok and alive and revision == boosterRevision and state.booster then
                boosterPro.complete = false
                boosterPro.phase = "FAILED"
                boosterPro.failed = tostring(err)
                boosterPro.lastError = boosterPro.failed
                warn("[124 Community Visuals] Booster: ошибка полного обхода: " .. boosterPro.failed)
                tell("FPS Booster остановлен: ошибка обработки карты; восстановление графики")
                state.booster = false
                local restored, restoreErr = pcall(setBooster, false)
                if not restored then
                    warn("[124 Community Visuals] Ошибка запуска отката Booster: " .. tostring(restoreErr))
                end
                if refreshToggles.booster then pcall(refreshToggles.booster) end
                requestSave()
            end
        end)
    else
        -- Отключение тоже не должно выполнять Terrain/Lighting-перезаписи
        -- внутри обработчика кнопки: всё выполняет контролируемый worker.
        task.spawn(function()
            boosterPro.workers.restore = boosterPro.workers.restore + 1
            local ok, err = pcall(function()
            if revision ~= boosterRevision or state.booster then return end
            restoreTerrainGrass()
            restoreTerrainColors()
            applyLighting()
            if revision ~= boosterRevision or state.booster then return end
            local count, sliceStarted = 0, os.clock()
            for obj, snapshot in pairs(savedGraphics) do
                if revision ~= boosterRevision or state.booster then return end
                boosterPro.restoreObject(obj, snapshot)
                count = count + 1
                if count % 4 == 0 and ((os.clock() - sliceStarted) * 1000 >=
                    (measuredFps < 42 and CONFIG.BoosterLowFpsSliceMs
                        or CONFIG.BoosterSliceMs)
                    or count % CONFIG.BoosterBatch == 0) then
                    task.wait(measuredFps < 42 and CONFIG.BoosterLowFpsDelay
                        or CONFIG.BoosterInitialDelay)
                    sliceStarted = os.clock()
                end
            end
            if alive and revision == boosterRevision then
                local remaining = 0
                for obj, snapshot in pairs(savedGraphics) do
                    if obj.Parent and next(snapshot) ~= nil then remaining = remaining + 1 end
                end
                local terrainPending = savedTerrainDecoration ~= nil
                    or savedTerrainColors ~= nil
                -- Lighting kept intentionally by FullBright is not a pending
                -- Booster rollback: only unowned Lighting needs restoring.
                local restorePending = remaining > 0 or terrainPending
                    or (savedLighting ~= nil and not state.fullbright)
                boosterPro.phase = restorePending and "RESTORE PENDING"
                    or (boosterPro.lastError and "FAILED" or "OFF")
                if restorePending or boosterPro.restoreFailures > 0 then
                    tell("FPS Booster Pro: частичный откат, ошибок "
                        .. tostring(boosterPro.restoreFailures) .. ", объектов с остатком "
                        .. tostring(remaining))
                else
                    tell("FPS Booster Pro: исходные свойства восстановлены")
                end
            end
            end)
            boosterPro.workers.restore = math.max(0, boosterPro.workers.restore - 1)
            if not ok and alive and revision == boosterRevision and not state.booster then
                boosterPro.phase = "RESTORE PENDING"
                boosterPro.lastError = "restore worker: " .. tostring(err)
                boosterPro.restoreRetryAt = 0
                warn("[124 Visuals] Booster rollback worker: " .. tostring(err))
            end
        end)
    end
end

-- AIM: поиск объекта в FOV, сохранение цели, необязательная проверка видимости.
-- ВАЖНО: отключение Visible Check пропускает Raycast, но объект должен быть перед камерой.
-- ПК: удерживание ПКМ. Android: кнопка AIM.
-- A streamed or malformed rig may contain a non-part named Head/Torso.
-- Filter candidates *before* accepting the first match.
local function aimPart(character, name)
    local candidate = character:FindFirstChild(name)
    return candidate and candidate:IsA("BasePart") and candidate or nil
end
local function targetPart(character)
    if state.aimMode == "head" then
        return aimPart(character, "Head")
    elseif state.aimMode == "body" then
        return aimPart(character, "UpperTorso")
            or aimPart(character, "Torso")
            or aimPart(character, "HumanoidRootPart")
    end
    return aimPart(character, "LeftLowerLeg")
        or aimPart(character, "RightLowerLeg")
        or aimPart(character, "Left Leg")
        or aimPart(character, "Right Leg")
        or aimPart(character, "LeftUpperLeg")
        or aimPart(character, "RightUpperLeg")
end

local function sameTeam(player)
    return state.teamCheck and player.Team ~= nil
        and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
end

-- Raycast не должен ошибочно считать полностью прозрачные служебные детали стеной.
local function canSee(camera, point, targetCharacter)
    local origin = camera.CFrame.Position
    local direction = point - origin
    if direction.Magnitude < 0.05 then return false end
    -- Один RaycastParams и один массив вместо создания на каждый кадр.
    local exclusions = aimPro.rayIgnore
    table.clear(exclusions)
    local myCharacter = LocalPlayer.Character
    if myCharacter then exclusions[1] = myCharacter end
    local params = aimPro.rayParams
    for _ = 1, CONFIG.AimVisibleRaycastChecks do
        params.FilterDescendantsInstances = exclusions
        local result = Workspace:Raycast(origin, direction, params)
        if not result then return true end
        if result.Instance:IsDescendantOf(targetCharacter) then return true end
        if result.Instance:IsA("BasePart") and result.Instance.Transparency >= 0.98 then
            exclusions[#exclusions + 1] = result.Instance
        else
            return false
        end
    end
    return false
end

-- Согласованная проверка: используется и при поиске, и при сопровождении цели.
local function predictedPoint(part)
    local point = part.Position
    if not state.prediction then return point end
    local ok, velocity = pcall(function() return part.AssemblyLinearVelocity end)
    if ok and typeof(velocity) == "Vector3" then
        local offset = velocity * state.predictionSeconds
        local distance = offset.Magnitude
        if distance > CONFIG.AimPredictionMaxStuds then
            offset = offset * (CONFIG.AimPredictionMaxStuds / distance)
        end
        point = point + offset
    end
    return point
end

local function signedAngle(a, b)
    return (b - a + math.pi) % (math.pi * 2) - math.pi
end

-- Квадрат дистанции вместо квадратного корня на всех проверяемых целях.
local function examineTarget(camera, player, part, myRoot, center, fovLimit, withLos)
    local character = player and player.Character
    if not character or not part or not part:IsA("BasePart")
        or not part:IsDescendantOf(character) or sameTeam(player) then return nil end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local point = part.Position
    local offset = point - myRoot.Position
    local maxStuds = state.aimRangeMeters / CONFIG.StudMeters
    if offset:Dot(offset) > maxStuds * maxStuds then return nil end
    local projected, onScreen = camera:WorldToViewportPoint(point)
    if not onScreen or projected.Z <= 0 then return nil end
    local dx, dy = projected.X - center.X, projected.Y - center.Y
    local pixelSquared = dx * dx + dy * dy
    if pixelSquared > fovLimit * fovLimit then return nil end
    if withLos and not canSee(camera, point, character) then return nil end
    return {player = player, part = part, character = character,
        humanoid = hum, pixelsSquared = pixelSquared}
end

local function findAimTarget(camera)
    local scanStarted = os.clock()
    local function done(result)
        perfCounters.aimScanMs = math.floor((os.clock() - scanStarted) * 10000 + 0.5) / 10
        return result
    end
    local me = LocalPlayer.Character
    local myRoot = me and me:FindFirstChild("HumanoidRootPart")
    if not myRoot then return done(nil) end
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local fov = state.aimFovPixels

    if state.targetLock and aimTarget and aimTarget.player.Parent == Players then
        local chosen = targetPart(aimTarget.character)
        if chosen then
            local kept = examineTarget(camera, aimTarget.player, chosen, myRoot,
                center, fov * CONFIG.AimLockTolerance, false)
            if kept then
                if not state.visibleCheck or canSee(camera, chosen.Position, kept.character) then
                    aimPro.blockedSince = 0
                    return done(kept)
                end
                -- Keep the same target briefly without moving the camera
                -- through a wall. A single streaming/LOS miss won't retarget.
                local now = os.clock()
                if aimPro.blockedSince == 0 then aimPro.blockedSince = now end
                if now - aimPro.blockedSince < CONFIG.AimOcclusionGraceSeconds then
                    kept.blocked = true
                    return done(kept)
                end
            end
        end
    end

    -- Без Visible Check не создаём сортированный список: ищем один минимум.
    local candidates = aimPro.candidates
    table.clear(candidates)
    local best = nil
    for _, player in ipairs(perfCounters.roster) do
        if player ~= LocalPlayer and player.Character and not sameTeam(player) then
            local part = targetPart(player.Character)
            if part then
                local found = examineTarget(camera, player, part, myRoot,
                    center, fov, false)
                if found then
                    if state.visibleCheck then
                        candidates[#candidates + 1] = found
                    elseif not best or found.pixelsSquared < best.pixelsSquared then
                        best = found
                    end
                end
            end
        end
    end
    if not state.visibleCheck then return done(best) end
    table.sort(candidates, function(a, b) return a.pixelsSquared < b.pixelsSquared end)
    local tested = 0
    for _, candidate in ipairs(candidates) do
        if tested >= CONFIG.AimLosCandidatesPerScan then break end
        tested = tested + 1
        if canSee(camera, candidate.part.Position, candidate.character) then
            aimPro.blockedSince = 0
            return done(candidate)
        end
    end
    aimPro.blockedSince = 0
    return done(nil)
end

-- Один и тот же безопасный источник статуса системного меню для AIM и горячих клавиш.
-- pcall необходим: некоторые исполнители могут ограничивать чтение GuiService.
local function isRobloxMenuOpen()
    local ok, open = pcall(function() return GuiService.MenuIsOpen end)
    return ok and open == true
end

local function aimFrame(dt)
    -- Отсутствие Tool — абсолютный запрет движения камеры, даже при F6/ПКМ/touch.
    if not alive or not state.aimbot or not (aimHeldMouse or aimHeldTouch or aimHeldKey)
        or not aimPro.equippedTool() then
        aimTarget = nil
        return
    end
    if isRobloxMenuOpen() then
        aimPro.reset()
        return
    end
    if UserInputService:GetFocusedTextBox() ~= nil then return end
    local camera = Workspace.CurrentCamera
    if not camera then aimTarget = nil; return end
    local now = os.clock()
    local tier = perfTier()
    local scanEvery = tier == "ECO" and 0.24
        or tier == "QUALITY" and 0.08 or CONFIG.AimScanInterval
    local losInterval = tier == "ECO" and CONFIG.AimLosEcoSeconds
        or tier == "QUALITY" and CONFIG.AimLosQualitySeconds
        or CONFIG.AimLosBalancedSeconds
    local scannedThisFrame = false
    if now >= aimNextScan then
        aimNextScan = now + scanEvery
        local previous = aimTarget
        aimTarget = findAimTarget(camera)
        if not aimTarget or (previous and previous.player ~= aimTarget.player) then
            aimPro.blockedSince = 0
        end
        scannedThisFrame = true
        if aimTarget then
            -- Новый поиск уже сделал LOS при включённом Visible Check.
            aimPro.nextLos = now + losInterval
        end
    end
    local current = aimTarget
    -- Отсутствие цели НЕ обнуляет таймер поиска (было до 60 сканов/с).
    if not current then return end
    -- Occluded lock is retained for stability but NEVER drives the camera.
    if current.blocked then return end
    local part = current.part
    if not part or not part.Parent or not current.player
        or current.player.Character ~= current.character or sameTeam(current.player)
        or not current.humanoid or current.humanoid.Health <= 0 then
        aimTarget = nil
        aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
        return
    end
    local origin = camera.CFrame.Position
    local point = part.Position
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot or (point - origin).Magnitude <= 0.05
        or (point - myRoot.Position).Magnitude * CONFIG.StudMeters > state.aimRangeMeters then
        aimTarget = nil
        aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
        return
    end
    -- Проверка видимости прицеливания остаётся активной, но Raycast реже.
    if state.visibleCheck and not scannedThisFrame and now >= aimPro.nextLos then
        if not canSee(camera, point, current.character) then
            if state.targetLock then
                if aimPro.blockedSince == 0 then aimPro.blockedSince = now end
                if now - aimPro.blockedSince < CONFIG.AimOcclusionGraceSeconds then
                    current.blocked = true
                    aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
                    return
                end
            end
            aimPro.blockedSince = 0
            aimTarget = nil
            aimNextScan = math.min(aimNextScan, now + CONFIG.AimLostRescanSeconds)
            return
        end
        aimPro.blockedSince = 0
        aimPro.nextLos = now + losInterval
    end
    local goal = CFrame.lookAt(origin, predictedPoint(part))
    if state.aimSmoothness == 0 then
        camera.CFrame = goal
    else
        -- Frame-rate independent smoothing with a bounded angular step.
        -- Avoid a sudden jump on a late frame without altering Smooth=0.
        local cx, cy, cz = camera.CFrame:ToOrientation()
        local gx, gy = goal:ToOrientation()
        local speed = CONFIG.AimSmoothnessBaseline / state.aimSmoothness
        local dtSafe = math.clamp(dt, 0, 0.05)
        local alphaX = math.clamp(1 - math.exp(-speed * state.aimSmoothX / 5 * dtSafe), 0, 1)
        local alphaY = math.clamp(1 - math.exp(-speed * state.aimSmoothY / 5 * dtSafe), 0, 1)
        local maxStep = math.rad(CONFIG.AimMaxTurnDegreesPerSecond) * dtSafe
        local pitchStep = math.clamp(signedAngle(cx, gx) * alphaY, -maxStep, maxStep)
        local yawStep = math.clamp(signedAngle(cy, gy) * alphaX, -maxStep, maxStep)
        camera.CFrame = CFrame.new(origin) * CFrame.fromOrientation(
            cx + pitchStep, cy + yawStep, cz)
    end
end

