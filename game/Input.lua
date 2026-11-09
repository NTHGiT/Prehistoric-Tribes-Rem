local Camera = require("game.Camera")
local GameState = require("core.GameState")
local BuildMenu = require("game.ui.BuildMenu")
local Building = require("core.Building")
local ActionBar = require("game.ui.ActionBar")
local Simulation = require("core.Simulation")

local Input = {
    selectedEntityId = nil,
    touchStartX = 0,
    touchStartY = 0,
    isTap = false,

    pendingTap = nil,
    pendingTapTimer = 0,
    doubleTapDelay = 0.28
}

-- The resource node closest to a tapped tile (within one tile), or nil.
local function findNearestNode(tileX, tileY)
    local best, bestDist = nil, 3
    for _, node in ipairs(GameState.resourceNodes) do
        if node.amount > 0 then
            local d = math.abs(node.x - tileX) + math.abs(node.y - tileY)
            if d < bestDist and math.abs(node.x - tileX) <= 1 and math.abs(node.y - tileY) <= 1 then
                best, bestDist = node, d
            end
        end
    end
    return best
end

function Input.update(dt)
    if Input.pendingTap then
        Input.pendingTapTimer = Input.pendingTapTimer - dt
        if Input.pendingTapTimer <= 0 then
            local tap = Input.pendingTap
            Input.pendingTap = nil

            if tap.clickedEntityId then
                Input.selectedEntityId = tap.clickedEntityId
            elseif Input.selectedEntityId then
                Input.selectedEntityId = nil
            end
        end
    end
end

function Input.touchpressed(id, x, y)
    Input.touchStartX = x
    Input.touchStartY = y
    Input.isTap = true

    -- Cek interaksi BuildMenu & Proyeksi Placement
    if BuildMenu.isOpen or BuildMenu.isPlacing then
        local menuRes = BuildMenu.touchpressed(x, y)
        if menuRes then
            Input.isTap = false
            return true
        end
    end

    return false
end

function Input.touchmoved(id, x, y, dx, dy)
    if math.abs(dx) > 3 or math.abs(dy) > 3 then
        Input.isTap = false
    end
end

function Input.touchreleased(id, x, y)
    local screenH = love.graphics.getHeight()
    local barH = ActionBar.isCollapsed and 22 or 90

    if BuildMenu.isPlacing then return end

    if Input.isTap and y < screenH - barH and y > 45 then
        local worldX, worldY = Camera:toWorldCoords(x, y)
        local tileX = math.floor(worldX / 22) + 1
        local tileY = math.floor(worldY / 16) + 1

        local clickedEntityId = nil
        for i = 1, GameState.maxEntities do
            local ent = GameState.entities[i]
            if ent and ent.active then
                if ent.x == tileX and ent.y == tileY then
                    clickedEntityId = ent.id
                    break
                end
            end
        end

        if Input.pendingTap then
            Input.pendingTap = nil

            if Input.selectedEntityId then
                local ent = GameState.entities[Input.selectedEntityId]
                if ent and ent.active then

                    local clickedBuilding = nil
                    for _, b in ipairs(GameState.buildings) do
                        if math.abs(b.x - tileX) <= 1 and math.abs(b.y - tileY) <= 1 then
                            clickedBuilding = b
                            break
                        end
                    end

                    if clickedBuilding then
                        if not clickedBuilding.isConstructed then
                            Building.assignBuilder(clickedBuilding, ent)
                        elseif clickedBuilding.type == "kitchen" or clickedBuilding.type == "restaurant" then
                            if not Building.assignCook(clickedBuilding, ent) then
                                Simulation.setPathForEntity(ent, clickedBuilding.x, clickedBuilding.y)
                                ent.targetNodeId = nil
                            end
                        end
                        return
                    end

                    local clickedNode = findNearestNode(tileX, tileY)

                    if clickedNode then
                        ent.targetNodeId = clickedNode.id
                        Simulation.setPathForEntity(ent, clickedNode.x, clickedNode.y)
                        return
                    end

                    ent.targetNodeId = nil
                    local map = GameState.currentMap
                    Simulation.setPathForEntity(ent, math.max(1, math.min(map.width, tileX)), math.max(1, math.min(map.height, tileY)))
                end
            end
        else
            Input.pendingTap = {
                tileX = tileX,
                tileY = tileY,
                clickedEntityId = clickedEntityId
            }
            Input.pendingTapTimer = Input.doubleTapDelay
        end
    end
end

return Input
