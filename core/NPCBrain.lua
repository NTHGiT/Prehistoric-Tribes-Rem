local GameState = require("core.GameState")
local Pathfinding = require("core.Pathfinding")
local Building = require("core.Building")

local NPCBrain = {}

function NPCBrain.update(ent)
    if not ent or not ent.active then return end

    -- 0. JIKA SEDANG MENJALANKAN PERINTAH PEMAIN: PRIORITAS 100%
    if ent.isPlayerCommanded then
        -- Kebutuhan darurat kelaparan/kematian di atas 90%
        if ent.hunger < 90 and ent.thirst < 90 then
            return
        end
    end

    if ent.idleTimer and ent.idleTimer > 0 then
        ent.idleTimer = ent.idleTimer - 1
        return
    end

    -- -------------------------------------------------------------
    -- 1. KEBUTUHAN VITAL (SURVIVAL & MOOD) DENGAN CEK KAPASITAS
    -- -------------------------------------------------------------

    -- A. LAPAR (Hunger >= 70%)
    if ent.hunger >= 70 and ent.job ~= "cook" then
        if ent.state ~= "moving_to_eat" then
            local targetB = nil

            if ent.mood >= 60 then
                for _, b in ipairs(GameState.buildings) do
                    if b.isConstructed and b.type == "smokehouse" and b.smokedFood > 0 and not Building.isFull(b) then
                        targetB = b
                        break
                    end
                end
            end

            if not targetB then
                for _, b in ipairs(GameState.buildings) do
                    if b.isConstructed and (b.type == "kitchen" or b.type == "restaurant") and b.mealsReady > 0 and not Building.isFull(b) then
                        targetB = b
                        break
                    end
                end
            end

            if targetB then
                ent.targetX = targetB.x
                ent.targetY = targetB.y
                ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, targetB.x, targetB.y)
                ent.state = "moving_to_eat"
                return
            end
        end
    end

    -- B. HAUS (Thirst >= 70%)
    if ent.thirst >= 70 then
        if ent.state ~= "moving_to_drink" then
            local nearestWaterB = nil
            local minDist = 9999

            for _, b in ipairs(GameState.buildings) do
                if b.isConstructed and (b.type == "well" or b.type == "store") and not Building.isFull(b) then
                    local dist = math.abs(ent.x - b.x) + math.abs(ent.y - b.y)
                    if dist < minDist then
                        minDist = dist
                        nearestWaterB = b
                    end
                end
            end

            if nearestWaterB then
                ent.targetX = nearestWaterB.x
                ent.targetY = nearestWaterB.y
                ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, nearestWaterB.x, nearestWaterB.y)
                ent.state = "moving_to_drink"
                return
            end
        end
    end

    -- C. MOOD BURUK (Mood <= 40%) -> Istirahat di Tenda/Hut
    if ent.mood <= 40 and ent.state == "idle" then
        for _, b in ipairs(GameState.buildings) do
            if b.isConstructed and b.type == "hut" and not Building.isFull(b) then
                ent.targetX = b.x
                ent.targetY = b.y
                ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, b.x, b.y)
                ent.state = "resting"
                return
            end
        end
    end

    -- -------------------------------------------------------------
    -- 2. INISIATIF PERAN & WAJIB MILITER TERSTRUKTUR
    -- -------------------------------------------------------------

    -- A. BUILDER
    if ent.job == "builder" then
        if not ent.targetBuildingId then
            for _, b in ipairs(GameState.buildings) do
                if not b.isConstructed and #b.assignedBuilders < b.maxBuilders then
                    local isAlreadyAssigned = false
                    for _, bId in ipairs(b.assignedBuilders) do
                        if bId == ent.id then isAlreadyAssigned = true break end
                    end

                    if not isAlreadyAssigned then
                        table.insert(b.assignedBuilders, ent.id)
                        ent.targetBuildingId = b.id
                        ent.targetX = b.x
                        ent.targetY = b.y
                        return
                    end
                end
            end
        end
    end

    -- B. COOK
    if ent.job == "cook" then
        local kitchen = nil
        for _, b in ipairs(GameState.buildings) do
            if b.isConstructed and (b.type == "kitchen" or b.type == "restaurant") and b.assignedStaffId == ent.id then
                kitchen = b
                break
            end
        end

        if kitchen then
            kitchen.rawFood = kitchen.rawFood or 0
            kitchen.maxMeals = kitchen.maxMeals or 20
            local totalCapacity = kitchen.mealsReady + kitchen.rawFood

            if totalCapacity < kitchen.maxMeals and (#ent.path == 0) then
                if ent.carryingAmount > 0 and ent.carryingType == "food" then
                    if not Building.isUnitNear(kitchen, ent) then
                        ent.targetX = kitchen.x
                        ent.targetY = kitchen.y
                        ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, kitchen.x, kitchen.y)
                        return
                    end
                else
                    local store = nil
                    for _, bg in ipairs(GameState.buildings) do
                        if bg.type == "store" and bg.isConstructed then store = bg break end
                    end

                    if store and GameState.resources.food > 0 then
                        if not Building.isUnitNear(store, ent) then
                            ent.targetX = store.x
                            ent.targetY = store.y
                            ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, store.x, store.y)
                            return
                        end
                    end
                end
            end
        end
    end

    -- C. SHERIFF / GARDA SUKU
    if ent.job == "sheriff" then
        if ent.state == "idle" and (#ent.path == 0) then
            local camp = nil
            for _, b in ipairs(GameState.buildings) do
                if b.isConstructed and b.type == "warrior_camp" then camp = b break end
            end

            if camp then
                ent.idleTimer = math.random(15, 30)
                local px = camp.x + math.random(-4, 4)
                local py = camp.y + math.random(-4, 4)
                if Pathfinding.isWalkable(GameState.currentMap, px, py) then
                    ent.targetX = px
                    ent.targetY = py
                    ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, px, py)
                    ent.state = "patrolling"
                    return
                end
            end
        end
    end

    -- D. WAJIB MILITER SANGAT EFEKTIF (Pria Fit Mengikuti Sesi Latihan Gym / Archery)
    if ent.job == "unemployed" and ent.gender == "male" and ent.hunger < 60 and ent.thirst < 60 then
        if ent.state == "idle" and (#ent.path == 0) then
            local availableFacilities = {}
            for _, b in ipairs(GameState.buildings) do
                if b.isConstructed and (b.type == "gym" or b.type == "archery") and not Building.isFull(b) then
                    table.insert(availableFacilities, b)
                end
            end

            if #availableFacilities > 0 then
                local facility = availableFacilities[math.random(1, #availableFacilities)]
                ent.targetX = facility.x
                ent.targetY = facility.y
                ent.trainingTargetId = facility.id
                ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, facility.x, facility.y)
                ent.state = "moving_to_train"
                return
            end
        end
    end

    -- -------------------------------------------------------------
    -- 3. SANTAI & WANDERING
    -- -------------------------------------------------------------
    if ent.state == "idle" and (#ent.path == 0) then
        ent.idleTimer = math.random(20, 40)

        if math.random(1, 100) <= 30 then
            local rx = ent.x + math.random(-2, 2)
            local ry = ent.y + math.random(-2, 2)

            if Pathfinding.isWalkable(GameState.currentMap, rx, ry) then
                ent.targetX = rx
                ent.targetY = ry
                ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, rx, ry)
            end
        end
    end
end

return NPCBrain
