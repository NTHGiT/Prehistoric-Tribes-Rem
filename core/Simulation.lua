local GameState = require("core.GameState")
local Building = require("core.Building")
local ResourceNode = require("core.ResourceNode")
local Events = require("core.Events")
local Pathfinding = require("core.Pathfinding")
local MapDecoder = require("core.MapDecoder")
local NPCBrain = require("core.NPCBrain")

local Simulation = {}

function Simulation.setPathForEntity(ent, targetX, targetY)
    ent.targetX = targetX
    ent.targetY = targetY
    ent.isPlayerCommanded = true -- Tandai perintah langsung pemain
    ent.path = Pathfinding.findPath(GameState.currentMap, ent.x, ent.y, targetX, targetY)
end

function Simulation.init(map)
    GameState.currentMap = map
    GameState.spawnInitialTribes(map)

    -- Natural resources come from the real level data (core/MapDecoder.lua).
    for _, r in ipairs(map.resources) do
        ResourceNode.spawn(r.type, r.x, r.y, r.amount)
    end

    local store = GameState.buildings[1]
    local kx, ky = MapDecoder.findClearArea(map, store.x + 4, store.y, 3, 2, 12,
        { { x = store.x, y = store.y, w = store.sizeX, h = store.sizeY } })
    if kx then
        table.insert(GameState.buildings, {
                id = 2, type = "kitchen", name = "Restoran Suku",
                x = kx, y = ky, sizeX = 3, sizeY = 2, capacity = 3, occupants = {},
                progress = 100, maxProgress = 100, isConstructed = true,
                maxBuilders = 3, assignedBuilders = {}, assignedStaffId = nil,
                mealsReady = 5, rawFood = 0, maxMeals = 20,
                delivered = { wood = 25, stone = 10, bone = 0 }
        })
    end
end


function Simulation.step()
    GameState.tickCount = GameState.tickCount + 1

    if GameState.tickCount % 50 == 0 then
        GameState.updateSheriffRecruitment()
    end

    -- 1. SMOKEHOUSE
    for _, b in ipairs(GameState.buildings) do
        if b.isConstructed and b.type == "smokehouse" then
            b.smokedFood = b.smokedFood or 0
            b.maxSmoked = b.maxSmoked or 30
            if GameState.tickCount % 30 == 0 and GameState.resources.food > 0 and b.smokedFood < b.maxSmoked then
                GameState.resources.food = GameState.resources.food - 1
                b.smokedFood = b.smokedFood + 1
            end
        end
    end

    -- 2. UPDATE ENTITAS & EVALUASI
    for i = 1, GameState.maxEntities do
        local ent = GameState.entities[i]
        if ent and ent.active then

            local hungerRate = (ent.hungerResistanceBuff and ent.hungerResistanceBuff > 0) and 0.05 or 0.12
            if ent.hungerResistanceBuff and ent.hungerResistanceBuff > 0 then
                ent.hungerResistanceBuff = ent.hungerResistanceBuff - 1
            end

            ent.hunger = math.min(100, ent.hunger + hungerRate)
            ent.thirst = math.min(100, ent.thirst + 0.18)

            local penalty = (ent.hunger * 0.4) + (ent.thirst * 0.4)
            ent.mood = math.max(0, math.floor(100 - penalty))

            if ent.hunger >= 100 or ent.thirst >= 100 then
                ent.hp = math.max(0, ent.hp - 0.4)
            end

            NPCBrain.update(ent)

            if ent.path and #ent.path > 0 then
                ent.state = "moving"
                local nextNode = table.remove(ent.path, 1)
                ent.x = nextNode.x
                ent.y = nextNode.y
            else
                -- LOKASI ARRIVAL
                for _, b in ipairs(GameState.buildings) do
                    if Building.isUnitNear(b, ent) then
                        Building.onUnitArrive(b, ent)

                        if ent.state == "moving_to_drink" and (b.type == "store" or b.type == "well") then
                            ent.thirst = math.max(0, ent.thirst - 50)
                            ent.state = "idle"
                            ent.isPlayerCommanded = false
                        end
                    end
                end

                -- SESI LATIHAN WAJIB MILITER TERSTRUKTUR (50 TICKS LATIHAN INTENSIF)
                if ent.state == "moving_to_train" or ent.state == "training" then
                    local targetFac = nil
                    for _, b in ipairs(GameState.buildings) do
                        if b.id == ent.trainingTargetId and b.isConstructed then targetFac = b break end
                    end

                    if targetFac and Building.isUnitNear(targetFac, ent) then
                        if ent.state ~= "training" then
                            if Building.enter(targetFac, ent) then
                                ent.state = "training"
                                ent.trainingTicksLeft = 50 -- 50 Tick durasi sesi latihan
                                Events.notify("Warga #" .. ent.id .. " memulai sesi latihan di " .. targetFac.name, 3)
                            else
                                ent.state = "idle"
                                ent.trainingTargetId = nil
                            end
                        else
                            -- PROGRES SESI LATIHAN
                            ent.trainingTicksLeft = ent.trainingTicksLeft - 1
                            ent.exp.fighter = (ent.exp.fighter or 0) + 2

                            if targetFac.type == "gym" then
                                ent.maxHp = math.min(160, ent.maxHp + 0.2)
                                ent.hp = math.min(ent.maxHp, ent.hp + 0.2)
                            end

                            if ent.trainingTicksLeft <= 0 then
                                Building.leave(targetFac, ent)
                                ent.state = "idle"
                                ent.trainingTargetId = nil
                                Events.notify("Warga #" .. ent.id .. " menyelesaikan sesi militer! EXP Fighter meningkat.", 3)
                            end
                        end
                    end

                    -- BUILDER LOGISTIK & KONSTRUKSI
                elseif ent.job == "builder" and ent.targetBuildingId then
                    local targetBuilding = nil
                    for _, bg in ipairs(GameState.buildings) do
                        if bg.id == ent.targetBuildingId and not bg.isConstructed then
                            targetBuilding = bg
                            break
                        end
                    end

                    if targetBuilding then
                        if not Building.hasAllMaterials(targetBuilding) then
                            if ent.carryingAmount > 0 then
                                if Building.isUnitNear(targetBuilding, ent) then
                                    targetBuilding.delivered[ent.carryingType] = targetBuilding.delivered[ent.carryingType] + ent.carryingAmount
                                    Events.notify("Setor " .. ent.carryingAmount .. " " .. string.upper(ent.carryingType) .. " ke " .. targetBuilding.name, 2)
                                    ent.carryingType = nil
                                    ent.carryingAmount = 0
                                else
                                    Simulation.setPathForEntity(ent, targetBuilding.x, targetBuilding.y)
                                end
                            else
                                local store = nil
                                for _, bg in ipairs(GameState.buildings) do
                                    if bg.type == "store" and bg.isConstructed then store = bg break end
                                end

                                if store then
                                    if Building.isUnitNear(store, ent) then
                                        local resType, neededAmt = Building.getNextNeededResource(targetBuilding)
                                        if resType and GameState.resources[resType] > 0 then
                                            local takeAmt = math.min(ent.maxCarry, neededAmt, GameState.resources[resType])
                                            GameState.resources[resType] = GameState.resources[resType] - takeAmt
                                            ent.carryingType = resType
                                            ent.carryingAmount = takeAmt
                                            Simulation.setPathForEntity(ent, targetBuilding.x, targetBuilding.y)
                                        else
                                            ent.state = "idle"
                                        end
                                    else
                                        Simulation.setPathForEntity(ent, store.x, store.y)
                                    end
                                end
                            end
                        else
                            if Building.isUnitNear(targetBuilding, ent) then
                                ent.state = "building"
                                ent.exp.builder = (ent.exp.builder or 0) + 1
                            else
                                Simulation.setPathForEntity(ent, targetBuilding.x, targetBuilding.y)
                            end
                        end
                    else
                        ent.state = "idle"
                        ent.targetBuildingId = nil
                        ent.isPlayerCommanded = false
                    end

                    -- COOK
                elseif ent.job == "cook" then
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

                        for _, bg in ipairs(GameState.buildings) do
                            if bg.type == "store" and bg.isConstructed and Building.isUnitNear(bg, ent) then
                                if ent.carryingAmount == 0 and GameState.resources.food > 0 then
                                    local needed = kitchen.maxMeals - (kitchen.mealsReady + kitchen.rawFood)
                                    if needed > 0 then
                                        local takeAmt = math.min(ent.maxCarry, needed, GameState.resources.food)
                                        GameState.resources.food = GameState.resources.food - takeAmt
                                        ent.carryingType = "food"
                                        ent.carryingAmount = takeAmt
                                        Simulation.setPathForEntity(ent, kitchen.x, kitchen.y)
                                    end
                                end
                            end
                        end

                        if Building.isUnitNear(kitchen, ent) then
                            if ent.carryingAmount > 0 and ent.carryingType == "food" then
                                kitchen.rawFood = kitchen.rawFood + ent.carryingAmount
                                ent.carryingType = nil
                                ent.carryingAmount = 0
                            end

                            if kitchen.rawFood > 0 and kitchen.mealsReady < kitchen.maxMeals then
                                ent.state = "cooking"
                                if GameState.tickCount % 20 == 0 then
                                    kitchen.rawFood = kitchen.rawFood - 1
                                    kitchen.mealsReady = kitchen.mealsReady + 1
                                    ent.exp.cook = (ent.exp.cook or 0) + 2
                                end
                            else
                                ent.state = "idle"
                            end
                        end
                    end

                    -- GATHERER
                elseif ent.targetNodeId then
                    local node = GameState.resourceNodes[ent.targetNodeId]

                    if node and node.amount > 0 and ent.carryingAmount < ent.maxCarry then
                        if node.requiredTool == "spear" and not ent.hasSpear then
                            Events.notify("Warga #" .. ent.id .. " butuh tombak untuk menangkap ikan!", 4)
                            ent.targetNodeId = nil
                            ent.state = "idle"
                            ent.isPlayerCommanded = false
                        else
                            ent.state = "gathering"
                            ent.job = "gatherer"
                            node.amount = node.amount - 1
                            if node.amount <= 0 then MapDecoder.depleteNode(GameState.currentMap, node) end
                            ent.carryingType = node.resourceType
                            ent.lastGatherType = node.resourceType
                            ent.carryingAmount = ent.carryingAmount + 1
                            ent.exp.gatherer = (ent.exp.gatherer or 0) + 1

                            if ent.carryingAmount >= ent.maxCarry or node.amount <= 0 then
                                local store = nil
                                for _, bg in ipairs(GameState.buildings) do
                                    if bg.type == "store" then store = bg break end
                                end
                                if store then
                                    Simulation.setPathForEntity(ent, store.x, store.y)
                                end
                            end
                        end
                    elseif ent.carryingAmount > 0 then
                        GameState.resources[ent.carryingType] = GameState.resources[ent.carryingType] + ent.carryingAmount
                        ent.carryingAmount = 0

                        if node and node.amount > 0 then
                            Simulation.setPathForEntity(ent, node.x, node.y)
                        else
                            ent.targetNodeId = nil
                            ent.state = "idle"
                            ent.isPlayerCommanded = false
                        end
                    end
                else
                    if ent.state ~= "moving_to_eat" and ent.state ~= "moving_to_drink" and ent.state ~= "resting" and ent.state ~= "training" and ent.state ~= "patrolling" then
                        ent.state = "idle"
                    end
                end
            end

            ent.realX = (ent.x - 1) * 22
            ent.realY = (ent.y - 1) * 16
        end
    end

    Building.updateProgress()
end

return Simulation
