local Events = require("core.Events")
local MapDecoder = require("core.MapDecoder")

local GameState = {
    tickCount = 0,
    resources = {
        food = 0,
        wood = 50,
        stone = 20,
        bone = 5
    },
    population = 9,
    baseMaxPopulation = 10,
    maxPopulation = 10,
    entities = {},
    buildings = {},
    resourceNodes = {},
    maxEntities = 100,
    currentMap = nil
}

function GameState.reset()
    GameState.tickCount = 0
    GameState.resources = { food = 0, wood = 50, stone = 20, bone = 5 }
    GameState.entities = {}
    GameState.buildings = {}
    GameState.resourceNodes = {}
    GameState.population = 9
    GameState.baseMaxPopulation = 10
    GameState.maxPopulation = 10

    for i = 1, GameState.maxEntities do
        GameState.entities[i] = { active = false }
    end
end

function GameState.recalculateMaxPopulation()
    local bonusPop = 0
    for _, b in ipairs(GameState.buildings) do
        if b.isConstructed and b.type == "hut" then
            bonusPop = bonusPop + 2
        end
    end
    GameState.maxPopulation = GameState.baseMaxPopulation + bonusPop
end

function GameState.getSkillLevel(exp)
    if exp >= 1000 then return 5, 1000, 1000
    elseif exp >= 601 then return 4, exp, 1000
    elseif exp >= 301 then return 3, exp, 600
    elseif exp >= 101 then return 2, exp, 300
    else return 1, exp, 100
    end
end

function GameState.getTopSkills(entity)
    local list = {
        { name = "Gatherer", exp = (entity.exp and entity.exp.gatherer) or 0 },
        { name = "Builder",  exp = (entity.exp and entity.exp.builder) or 0 },
        { name = "Cook",     exp = (entity.exp and entity.exp.cook) or 0 },
        { name = "Fighter",  exp = (entity.exp and entity.exp.fighter) or 0 }
    }

    table.sort(list, function(a, b) return a.exp > b.exp end)
    return list[1], list[2]
end

-- Perekrutan Acak Garda Suku / Sheriff Berdasarkan Kuota Populasi
function GameState.updateSheriffRecruitment()
    local hasWarriorCamp = false
    for _, b in ipairs(GameState.buildings) do
        if b.isConstructed and b.type == "warrior_camp" then
            hasWarriorCamp = true
            break
        end
    end
    if not hasWarriorCamp then return end

    -- Kuota Sheriff: 10% dari total populasi (minimal 1 slot)
    local maxSheriffs = math.max(1, math.floor(GameState.population * 0.10))
    local currentSheriffs = 0

    for i = 1, GameState.maxEntities do
        local ent = GameState.entities[i]
        if ent and ent.active and ent.job == "sheriff" then
            currentSheriffs = currentSheriffs + 1
        end
    end

    -- Jika kuota belum penuh, undi dari kandidat pria pengangguran ber-EXP Fighter >= 101 (Level 2+)
    if currentSheriffs < maxSheriffs then
        local candidates = {}
        for i = 1, GameState.maxEntities do
            local ent = GameState.entities[i]
            if ent and ent.active and ent.gender == "male" and ent.job == "unemployed" then
                local fighterExp = (ent.exp and ent.exp.fighter) or 0
                if fighterExp >= 101 then
                    table.insert(candidates, ent)
                end
            end
        end

        if #candidates > 0 then
            local chosen = candidates[math.random(1, #candidates)]
            chosen.job = "sheriff"
            chosen.state = "idle"
            Events.notify("Warga #" .. chosen.id .. " terpilih sebagai Garda Suku (Sheriff)!", 4)
        end
    end
end

function GameState.spawnInitialTribes(map)
    GameState.reset()
    map = map or GameState.currentMap
    math.randomseed(os.time())

    -- Settle at the level's original start position, on the nearest free 3x3 patch of ground.
    local storeX, storeY = MapDecoder.findClearArea(map, map.startX, map.startY, 3, 3, 20)
    if not storeX then storeX, storeY = map.startX, map.startY end

    table.insert(GameState.buildings, {
            id = 1, type = "store", name = "Gudang Utama",
            x = storeX, y = storeY, sizeX = 3, sizeY = 3, capacity = 4, occupants = {},
            progress = 100, maxProgress = 100, isConstructed = true,
            maxBuilders = 2, assignedBuilders = {},
            delivered = { wood = 30, stone = 20, bone = 0 }
    })

    local used = {}
    for dy = 0, 2 do
        for dx = 0, 2 do used[(storeY + dy) * 1024 + storeX + dx] = true end
    end
    local gatherX, gatherY = storeX + 1, storeY + 4     -- just south of the store

    local x, y = MapDecoder.pickWalkable(map, gatherX, gatherY, 4, used)
    GameState.spawnEntity(1, "chief", "male", x, y)
    for i = 2, 9 do
        local gender = (math.random(1, 2) == 1) and "male" or "female"
        x, y = MapDecoder.pickWalkable(map, gatherX, gatherY, 4, used)
        GameState.spawnEntity(i, "villager", gender, x, y)
    end
    GameState.entities[2].hasSpear = true

    GameState.recalculateMaxPopulation()
end


function GameState.spawnEntity(id, entityType, gender, x, y)
    if id < 1 or id > GameState.maxEntities then return nil end

    local entity = {
        id = id,
        active = true,
        type = entityType,
        gender = gender,
        job = "unemployed",
        x = x,
        y = y,
        realX = (x - 1) * 22,
        realY = (y - 1) * 16,
        hp = 100,
        maxHp = 100,

        hunger = 0,
        thirst = 0,
        mood = 100,
        hungerResistanceBuff = 0,

        state = "idle",
        idleTimer = 0,
        isPlayerCommanded = false,
        currentBuildingId = nil,
        trainingTargetId = nil,
        trainingTicksLeft = 0,

        targetX = x,
        targetY = y,
        targetBuildingId = nil,
        path = {},

        hasSpear = false,
        carryingType = nil,
        carryingAmount = 0,
        maxCarry = 10,
        targetNodeId = nil,
        lastGatherType = nil,

        exp = {
            gatherer = 0,
            builder = 0,
            cook = 0,
            fighter = 0
        }
    }

    GameState.entities[id] = entity
    return entity
end

return GameState
