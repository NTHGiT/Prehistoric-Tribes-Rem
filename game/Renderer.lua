local GameState = require("core.GameState")
local Input = require("game.Input")
local TextureBank = require("game.TextureBank")

local Renderer = {}

local TILE_W, TILE_H = 22, 16

function Renderer.init()
    TextureBank.init()
    TILE_W, TILE_H = TextureBank.tileW, TextureBank.tileH
end

-- Cells whose art can reach into the view: tall trees overlap the cells above them,
-- so extra rows below (and a column left/right) are drawn as well.
local function visibleCells(map, camera)
    local viewW = love.graphics.getWidth() / camera.scale
    local viewH = love.graphics.getHeight() / camera.scale
    local left, up, right, down = TextureBank.overhang[1], TextureBank.overhang[2], TextureBank.overhang[3], TextureBank.overhang[4]
    local firstCol = math.max(1, math.floor((camera.x - right) / TILE_W) + 1)
    local lastCol = math.min(map.playWidth, math.ceil((camera.x + viewW + left) / TILE_W))
    local firstRow = math.max(1, math.floor((camera.y - down) / TILE_H) + 1)
    local lastRow = math.min(map.playHeight, math.ceil((camera.y + viewH + up) / TILE_H))
    return firstCol, lastCol, firstRow, lastRow
end

local function drawTerrain(map, camera)
    local firstCol, lastCol, firstRow, lastRow = visibleCells(map, camera)
    love.graphics.setColor(1, 1, 1, 1)
    for y = firstRow, lastRow do
        local row = map.tiles[y]
        for x = firstCol, lastCol do
            TextureBank.drawGround(row[x], (x - 1) * TILE_W, (y - 1) * TILE_H)
        end
    end
end

-- Placeholder art: buildings are still plain boxes until their original sprites are decoded.
local function drawBuildings()
    for _, b in ipairs(GameState.buildings) do
        local bX, bY = (b.x - 1) * TILE_W, (b.y - 1) * TILE_H
        local bW, bH = (b.sizeX or 1) * TILE_W, (b.sizeY or 1) * TILE_H

        if b.isConstructed then
            love.graphics.setColor(0.6, 0.4, 0.2, 0.9)
            love.graphics.rectangle("fill", bX, bY, bW, bH, 4, 4)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", bX, bY, bW, bH, 4, 4)
            love.graphics.print(string.sub(b.name or "Building", 1, 8), bX + 3, bY + 4)
        else
            love.graphics.setColor(0.9, 0.7, 0.2, 0.6)
            love.graphics.rectangle("fill", bX, bY, bW, bH, 4, 4)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("line", bX, bY, bW, bH, 4, 4)

            local ratio = (b.maxProgress and b.maxProgress > 0) and (b.progress / b.maxProgress) or 0
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", bX, bY - 7, bW, 5)
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            love.graphics.rectangle("fill", bX, bY - 7, bW * ratio, 5)
        end
    end
end

-- Placeholder art: villagers are still circles until their original sprites are decoded.
local function drawEntities()
    for i = 1, GameState.maxEntities do
        local ent = GameState.entities[i]
        if ent and ent.active then
            local realX = ent.realX or ((ent.x - 1) * TILE_W)
            local realY = ent.realY or ((ent.y - 1) * TILE_H)
            local cx, cy = realX + TILE_W / 2, realY + TILE_H / 2

            if Input.selectedEntityId == ent.id then
                love.graphics.setColor(0.2, 1, 0.2, 0.8)
                love.graphics.circle("line", cx, cy, 11)
                love.graphics.circle("line", cx, cy, 12)
            end

            love.graphics.setColor(1, 0.8, 0.2, 1)
            love.graphics.circle("fill", cx, cy, 8)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.circle("line", cx, cy, 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(tostring(ent.id), realX + 6, realY + 1)

            if ent.carryingAmount and ent.carryingAmount > 0 then
                love.graphics.setColor(1, 0.9, 0.2, 1)
                love.graphics.rectangle("fill", realX + 3, realY - 10, 16, 8, 2, 2)
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.print(tostring(ent.carryingAmount), realX + 7, realY - 12)
            end
        end
    end
end

function Renderer.drawMap(map, camera)
    if not map then return end
    drawTerrain(map, camera)   -- natural resources are part of the terrain art; depleted ones are swapped out
    drawBuildings()
    drawEntities()
    love.graphics.setColor(1, 1, 1, 1)
end

return Renderer
