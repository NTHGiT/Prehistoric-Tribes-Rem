local GameState = require("core.GameState")

local ResourceNode = {}

-- Definisi Tipe Resource
ResourceNode.TYPES = {
    WOOD = { id = "wood", name = "Pohon", resourceType = "wood", maxAmount = 100, requiredTool = nil },
    STONE = { id = "stone", name = "Batu", resourceType = "stone", maxAmount = 100, requiredTool = nil },
    BUSH = { id = "bush", name = "Semak Buah", resourceType = "food", maxAmount = 60, requiredTool = nil },
    FISH = { id = "fish", name = "Ikan Danau", resourceType = "food", maxAmount = 80, requiredTool = "spear" },
    BONE = { id = "bone", name = "Tulang Belulang", resourceType = "bone", maxAmount = 40, requiredTool = nil }
}

function ResourceNode.spawn(nodeTypeId, x, y, initialAmount)
    local config = ResourceNode.TYPES[nodeTypeId]
    if not config then return nil end

    local node = {
        id = #GameState.resourceNodes + 1,
        type = config.id,
        name = config.name,
        resourceType = config.resourceType,
        x = x,
        y = y,
        amount = initialAmount or config.maxAmount,
        maxAmount = config.maxAmount,
        requiredTool = config.requiredTool
    }

    table.insert(GameState.resourceNodes, node)
    return node
end

return ResourceNode
