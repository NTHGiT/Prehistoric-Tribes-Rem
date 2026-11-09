local GameState = require("core.GameState")
local BuildingData = require("core.BuildingData")
local Events = require("core.Events")
local Pathfinding = require("core.Pathfinding")

local Building = {}

function Building.canPlace(buildingType, tileX, tileY)
    local data = BuildingData[buildingType]
    if not data then return false end

    local sizeX = data.sizeX or 1
    local sizeY = data.sizeY or 1

    for x = tileX, tileX + sizeX - 1 do
        for y = tileY, tileY + sizeY - 1 do
            if not Pathfinding.isWalkable(GameState.currentMap, x, y) then
                return false
            end
        end
    end

    for _, b in ipairs(GameState.buildings) do
        local bSizeX = b.sizeX or 1
        local bSizeY = b.sizeY or 1

        local bMinX = b.x
        local bMaxX = b.x + bSizeX - 1
        local bMinY = b.y
        local bMaxY = b.y + bSizeY - 1

        local pMinX = tileX
        local pMaxX = tileX + sizeX - 1
        local pMinY = tileY
        local pMaxY = tileY + sizeY - 1

        if not (pMaxX < bMinX or pMinX > bMaxX or pMaxY < bMinY or pMinY > bMaxY) then
            return false
        end
    end

    return true
end

function Building.isUnitNear(b, unit)
    local bSizeX = b.sizeX or 1
    local bSizeY = b.sizeY or 1
    return unit.x >= (b.x - 1) and unit.x <= (b.x + bSizeX) and
    unit.y >= (b.y - 1) and unit.y <= (b.y + bSizeY)
end

-- MANAJEMEN KAPASITAS PENGHUNI BANGUNAN
function Building.getOccupantCount(b)
    b.occupants = b.occupants or {}
    local count = 0
    for _ in pairs(b.occupants) do count = count + 1 end
    return count
end

function Building.isFull(b)
    local data = BuildingData[b.type]
    local cap = (data and data.capacity) or b.capacity or 2
    return Building.getOccupantCount(b) >= cap
end

function Building.enter(b, entity)
    b.occupants = b.occupants or {}
    if not Building.isFull(b) then
        b.occupants[entity.id] = true
        entity.currentBuildingId = b.id
        return true
    end
    return false
end

function Building.leave(b, entity)
    if b and b.occupants then
        b.occupants[entity.id] = nil
    end
    if entity then
        entity.currentBuildingId = nil
    end
end

function Building.hasAllMaterials(b)
    local data = BuildingData[b.type]
    if not data then return true end
    return (b.delivered.wood >= data.cost.wood) and
    (b.delivered.stone >= data.cost.stone) and
    (b.delivered.bone >= data.cost.bone)
end

function Building.getNextNeededResource(b)
    local data = BuildingData[b.type]
    if not data then return nil, 0 end

    if b.delivered.wood < data.cost.wood and GameState.resources.wood > 0 then
        return "wood", data.cost.wood - b.delivered.wood
    elseif b.delivered.stone < data.cost.stone and GameState.resources.stone > 0 then
        return "stone", data.cost.stone - b.delivered.stone
    elseif b.delivered.bone < data.cost.bone and GameState.resources.bone > 0 then
        return "bone", data.cost.bone - b.delivered.bone
    end
    return nil, 0
end

function Building.create(buildingType, tileX, tileY)
    local data = BuildingData[buildingType]
    if not data then return false end

    if not Building.canPlace(buildingType, tileX, tileY) then
        Events.notify("Lokasi tidak valid atau terhalang!", 4)
        return false
    end

    local newBuilding = {
        id = #GameState.buildings + 1,
        type = buildingType,
        name = data.name,
        x = tileX,
        y = tileY,
        sizeX = data.sizeX or 1,
        sizeY = data.sizeY or 1,
        capacity = data.capacity or 2,
        occupants = {},
        progress = 0,
        maxProgress = data.maxProgress,
        isConstructed = false,
        maxBuilders = data.maxBuilders,
        assignedBuilders = {},
        assignedStaffId = nil,

        mealsReady = 0, rawFood = 0, maxMeals = 20,
        smokedFood = 0, maxSmoked = 30,
        water = 50, maxWater = 50,
        delivered = { wood = 0, stone = 0, bone = 0 }
    }

    table.insert(GameState.buildings, newBuilding)
    Events.notify("Situs " .. data.name .. " dibuat!", 3)
    return true
end

function Building.assignBuilder(building, entity)
    if building.isConstructed then return false end

    if #building.assignedBuilders >= building.maxBuilders then
        Events.notify("Situs konstruksi ini sudah penuh pekerja!", 3)
        return false
    end

    for _, id in ipairs(building.assignedBuilders) do
        if id == entity.id then return false end
    end

    table.insert(building.assignedBuilders, entity.id)
    entity.job = "builder"
    entity.targetBuildingId = building.id
    entity.targetX = building.x
    entity.targetY = building.y
    entity.isPlayerCommanded = true -- Kunci prioritas perintah pemain
    entity.path = {}
    return true
end

function Building.assignCook(building, entity)
    if not building.isConstructed then return false end
    if building.type ~= "kitchen" and building.type ~= "restaurant" then return false end

    if not building.assignedStaffId then
        building.assignedStaffId = entity.id
        entity.job = "cook"
        entity.targetX = building.x
        entity.targetY = building.y
        entity.isPlayerCommanded = true
        entity.path = Pathfinding.findPath(GameState.currentMap, entity.x, entity.y, building.x, building.y)
        Events.notify("Warga #" .. entity.id .. " ditugaskan sebagai Koki!", 3)
        return true
    end

    if building.assignedStaffId == entity.id then
        entity.job = "cook"
        entity.targetX = building.x
        entity.targetY = building.y
        entity.isPlayerCommanded = true
        entity.path = Pathfinding.findPath(GameState.currentMap, entity.x, entity.y, building.x, building.y)
        return true
    end

    return false
end

function Building.updateProgress()
    for _, b in ipairs(GameState.buildings) do
        if not b.isConstructed and #b.assignedBuilders > 0 then
            if Building.hasAllMaterials(b) then
                local activeBuilders = 0
                for _, bId in ipairs(b.assignedBuilders) do
                    local builder = GameState.entities[bId]
                    if builder and builder.active and Building.isUnitNear(b, builder) then
                        activeBuilders = activeBuilders + 1
                    end
                end

                if activeBuilders > 0 then
                    b.progress = b.progress + activeBuilders
                    if b.progress >= b.maxProgress then
                        b.progress = b.maxProgress
                        b.isConstructed = true

                        for _, bId in ipairs(b.assignedBuilders) do
                            local builder = GameState.entities[bId]
                            if builder then
                                builder.state = "idle"
                                builder.path = {}
                                builder.targetBuildingId = nil
                                builder.isPlayerCommanded = false
                            end
                        end
                        b.assignedBuilders = {}

                        GameState.recalculateMaxPopulation()
                        Events.notify(b.name .. " selesai dibangun!", 4)
                    end
                end
            end
        end
    end
end

function Building.onUnitArrive(building, entity)
    if building.isConstructed and (building.type == "kitchen" or building.type == "restaurant") then
        if entity.hunger > 20 and building.mealsReady > 0 and building.assignedStaffId ~= entity.id then
            building.mealsReady = building.mealsReady - 1
            entity.hunger = math.max(0, entity.hunger - 40)
            entity.mood = math.min(100, entity.mood + 15)
            entity.isPlayerCommanded = false
            Events.notify("Warga #" .. entity.id .. " makan di Restoran.", 3)
        end
    elseif building.isConstructed and building.type == "smokehouse" then
        if entity.hunger > 20 and building.smokedFood > 0 then
            building.smokedFood = building.smokedFood - 1
            entity.hunger = math.max(0, entity.hunger - 35)
            entity.hungerResistanceBuff = 100
            entity.isPlayerCommanded = false
            Events.notify("Warga #" .. entity.id .. " makan Daging Asap.", 3)
        end
    elseif building.isConstructed and building.type == "well" then
        if entity.thirst > 20 then
            entity.thirst = math.max(0, entity.thirst - 50)
            entity.isPlayerCommanded = false
            Events.notify("Warga #" .. entity.id .. " minum di Sumur Purba.", 2)
        end
    end
end

return Building
