local GameState = require("core.GameState")
local BuildingData = require("core.BuildingData")
local Building = require("core.Building")

local BuildMenu = {
    isOpen = false,
    isPlacing = false,
    selectedBuildingType = nil,
    previewTileX = 15,
    previewTileY = 10,

    scrollOffset = 0,
    maxVisibleItems = 4,

    btnConfirm = { x = 0, y = 0, w = 36, h = 36 },
    btnCancel  = { x = 0, y = 0, w = 36, h = 36 }
}

local buildingList = {
    "store", "well", "hut", "chief_house",
    "kitchen", "smokehouse", "armory", "tannery",
    "beast_pen", "bonfire", "disco", "shaman_shrine",
    "nursery", "gym", "archery", "spy_camp", "warrior_camp"
}

function BuildMenu.draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    if BuildMenu.isOpen then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)

        local menuW, menuH = 440, 310
        local menuX = (screenW - menuW) / 2
        local menuY = (screenH - menuH) / 2

        love.graphics.setColor(0.15, 0.12, 0.1, 0.95)
        love.graphics.rectangle("fill", menuX, menuY, menuW, menuH, 8, 8)
        love.graphics.setColor(0.8, 0.65, 0.3, 1)
        love.graphics.rectangle("line", menuX, menuY, menuW, menuH, 8, 8)

        love.graphics.setColor(1, 0.9, 0.5, 1)
        love.graphics.print("KATALOG BANGUNAN (" .. (BuildMenu.scrollOffset + 1) .. "-" .. math.min(#buildingList, BuildMenu.scrollOffset + BuildMenu.maxVisibleItems) .. "/" .. #buildingList .. ")", menuX + 20, menuY + 15)

        love.graphics.setColor(0.9, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", menuX + menuW - 35, menuY + 10, 25, 25, 4, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("X", menuX + menuW - 27, menuY + 14)

        local startY = menuY + 48
        for i = 1, BuildMenu.maxVisibleItems do
            local idx = BuildMenu.scrollOffset + i
            if idx <= #buildingList then
                local bType = buildingList[idx]
                local data = BuildingData[bType]
                local itemY = startY + (i - 1) * 58

                love.graphics.setColor(0.25, 0.2, 0.15, 0.9)
                love.graphics.rectangle("fill", menuX + 15, itemY, menuW - 30, 52, 6, 6)
                love.graphics.setColor(0.5, 0.4, 0.3, 1)
                love.graphics.rectangle("line", menuX + 15, itemY, menuW - 30, 52, 6, 6)

                love.graphics.setColor(1, 0.9, 0.4, 1)
                love.graphics.print(data.name, menuX + 25, itemY + 6)
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
                love.graphics.print(data.desc, menuX + 25, itemY + 26)

                local costStr = "K:" .. data.cost.wood .. " B:" .. data.cost.stone .. " T:" .. data.cost.bone
                love.graphics.setColor(0.7, 0.9, 0.7, 1)
                love.graphics.print(costStr, menuX + menuW - 145, itemY + 6)
            end
        end
    end

    if BuildMenu.isPlacing and BuildMenu.selectedBuildingType then
        BuildMenu.drawPlacementPreview(screenW, screenH)
    end
end

function BuildMenu.drawPlacementPreview(screenW, screenH)
    local Camera = require("game.Camera")
    local data = BuildingData[BuildMenu.selectedBuildingType]
    if not data then return end

    local sizeX = data.sizeX or 1
    local sizeY = data.sizeY or 1

    local tileW, tileH = 22, 16
    local worldX = (BuildMenu.previewTileX - 1) * tileW
    local worldY = (BuildMenu.previewTileY - 1) * tileH
    local worldW = sizeX * tileW
    local worldH = sizeY * tileH

    local screenTileX = (worldX - Camera.x) * Camera.scale
    local screenTileY = (worldY - Camera.y) * Camera.scale
    local scaledW = worldW * Camera.scale
    local scaledH = worldH * Camera.scale

    local isValid = Building.canPlace(BuildMenu.selectedBuildingType, BuildMenu.previewTileX, BuildMenu.previewTileY)

    Camera:apply()
    if isValid then
        love.graphics.setColor(0.2, 0.9, 0.3, 0.5)
    else
        love.graphics.setColor(0.9, 0.2, 0.2, 0.5)
    end
    love.graphics.rectangle("fill", worldX, worldY, worldW, worldH)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(isValid and {0.2, 1, 0.3, 1} or {1, 0.2, 0.2, 1})
    love.graphics.rectangle("line", worldX, worldY, worldW, worldH)
    love.graphics.setLineWidth(1)
    Camera:clear()

    local btnW, btnH = 36, 36
    local btnY = screenTileY - btnH - 8
    if btnY < 50 then btnY = screenTileY + scaledH + 8 end

    local btnConfirmX = screenTileX + (scaledW / 2) - btnW - 4
    local btnCancelX  = screenTileX + (scaledW / 2) + 4

    BuildMenu.btnConfirm = { x = btnConfirmX, y = btnY, w = btnW, h = btnH }
    BuildMenu.btnCancel  = { x = btnCancelX,  y = btnY, w = btnW, h = btnH }

    if isValid then
        love.graphics.setColor(0.15, 0.7, 0.2, 0.95)
    else
        love.graphics.setColor(0.3, 0.4, 0.3, 0.6)
    end
    love.graphics.rectangle("fill", btnConfirmX, btnY, btnW, btnH, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", btnConfirmX, btnY, btnW, btnH, 6, 6)
    love.graphics.print("V", btnConfirmX + 13, btnY + 10)

    love.graphics.setColor(0.8, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", btnCancelX, btnY, btnW, btnH, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", btnCancelX, btnY, btnW, btnH, 6, 6)
    love.graphics.print("X", btnCancelX + 13, btnY + 10)
end

function BuildMenu.touchpressed(x, y)
    local Camera = require("game.Camera")

    if BuildMenu.isPlacing then
        local c = BuildMenu.btnConfirm
        if x >= c.x and x <= c.x + c.w and y >= c.y and y <= c.y + c.h then
            local isValid = Building.canPlace(BuildMenu.selectedBuildingType, BuildMenu.previewTileX, BuildMenu.previewTileY)
            if isValid then
                Building.create(BuildMenu.selectedBuildingType, BuildMenu.previewTileX, BuildMenu.previewTileY)
                BuildMenu.isPlacing = false
                BuildMenu.selectedBuildingType = nil
            end
            return true
        end

        local r = BuildMenu.btnCancel
        if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            BuildMenu.isPlacing = false
            BuildMenu.selectedBuildingType = nil
            return true
        end

        local worldX, worldY = Camera:toWorldCoords(x, y)
        BuildMenu.previewTileX = math.max(1, math.min(64, math.floor(worldX / 22) + 1))
        BuildMenu.previewTileY = math.max(1, math.min(48, math.floor(worldY / 16) + 1))
        return true
    end

    if not BuildMenu.isOpen then return false end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local menuW, menuH = 440, 310
    local menuX = (screenW - menuW) / 2
    local menuY = (screenH - menuH) / 2

    if x >= menuX + menuW - 35 and x <= menuX + menuW - 10 and y >= menuY + 10 and y <= menuY + 35 then
        BuildMenu.isOpen = false
        return true
    end

    local startY = menuY + 48
    for i = 1, BuildMenu.maxVisibleItems do
        local idx = BuildMenu.scrollOffset + i
        if idx <= #buildingList then
            local itemY = startY + (i - 1) * 58
            if x >= menuX + 15 and x <= menuX + menuW - 15 and y >= itemY and y <= itemY + 52 then
                BuildMenu.selectedBuildingType = buildingList[idx]
                BuildMenu.isOpen = false
                BuildMenu.isPlacing = true

                local worldCenterX, worldCenterY = Camera:toWorldCoords(screenW / 2, screenH / 2)
                BuildMenu.previewTileX = math.max(1, math.min(64, math.floor(worldCenterX / 22) + 1))
                BuildMenu.previewTileY = math.max(1, math.min(48, math.floor(worldCenterY / 16) + 1))
                return true
            end
        end
    end

    return true
end

function BuildMenu.wheelmoved(y)
    if BuildMenu.isOpen then
        if y > 0 then
            BuildMenu.scrollOffset = math.max(0, BuildMenu.scrollOffset - 1)
        elseif y < 0 then
            BuildMenu.scrollOffset = math.min(#buildingList - BuildMenu.maxVisibleItems, BuildMenu.scrollOffset + 1)
        end
        return true
    end
    return false
end

function BuildMenu.keypressed(key)
    if key == "escape" then
        if BuildMenu.isPlacing then
            BuildMenu.isPlacing = false
            BuildMenu.selectedBuildingType = nil
            return true
        elseif BuildMenu.isOpen then
            BuildMenu.isOpen = false
            return true
        end
    end
    return false
end

return BuildMenu
