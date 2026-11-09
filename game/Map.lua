local GameState = require("core.GameState")

local Map = {
    level = 0,
    width = 64,
    height = 48,
    tiles = {},
    walkableGrid = {}
}

-- Pustaka JSON Sederhana untuk LÖVE2D
local json = require("lib.json") -- pastikan memiliki module JSON decoder di folder lib/

function Map.load(filepath)
filepath = filepath or "assets/maps/level_00.json"

if not love.filesystem.getInfo(filepath) then
    error("Berkas peta tidak ditemukan: " .. filepath)
    return false
    end

    local contents, _ = love.filesystem.read(filepath)
    local mapData = json.decode(contents)

    Map.level = mapData.level or 0
    Map.width = mapData.width or 64
    Map.height = mapData.height or 48
    Map.tiles = mapData.tiles or {}
    Map.walkableGrid = {}

    -- Bersihkan resource node lama
    GameState.resourceNodes = {}

    -- Parsing Matriks Tile & Penentuan Walkability / Resource Node
    for y = 1, Map.height do
        Map.walkableGrid[y] = {}
        local row = Map.tiles[y]

        if row then
            for x = 1, Map.width do
                local tileId = row[x] or 0
                local isWalkable = true

                -- Ubin Tebing / Pintu Gua / Air Dalam (Unwalkable)
                if (tileId >= 25 and tileId <= 39) or (tileId >= 160 and tileId <= 179) then
                    isWalkable = false
                    end

                    Map.walkableGrid[y][x] = isWalkable

                    -- Ekstraksi Sumber Daya Alam Berdasarkan ID Tile Matriks Asli
                    -- Pohon Kayu (WOOD): Tile vegetasi lebat (contoh: ID 6, 28, 29, 30, 31, 32, 169, 170, 171, 172)
                    if tileId == 6 or tileId == 29 or tileId == 30 or tileId == 31 or tileId == 32 or tileId == 169 or tileId == 170 or tileId == 171 then
                        table.insert(GameState.resourceNodes, {
                            id = #GameState.resourceNodes + 1,
                            x = x,
                            y = y,
                            type = "wood",
                            resourceType = "WOOD",
                            amount = 100,
                            maxAmount = 100
                        })
                        -- Batu Gunung (STONE): Tile tebing bebatuan (contoh: ID 83, 86, 87, 88, 89, 90, 91, 92, 93, 94)
                        elseif tileId >= 86 and tileId <= 94 then
                            table.insert(GameState.resourceNodes, {
                                id = #GameState.resourceNodes + 1,
                                x = x,
                                y = y,
                                type = "stone",
                                resourceType = "STONE",
                                amount = 150,
                                maxAmount = 150
                            })
                            -- Semak Buah (BUSH): Tile semak beri (contoh: ID 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24)
                            elseif (tileId >= 9 and tileId <= 24) and (math.random(1, 4) == 1) then
                                table.insert(GameState.resourceNodes, {
                                    id = #GameState.resourceNodes + 1,
                                    x = x,
                                    y = y,
                                    type = "bush",
                                    resourceType = "BUSH",
                                    amount = 50,
                                    maxAmount = 50
                                })
                                end
                                end
                                end
                                end

                                GameState.currentMap = Map
                                return true
                                end

                                function Map.isWalkable(x, y)
                                if x < 1 or x > Map.width or y < 1 or y > Map.height then
                                    return false
                                    end
                                    return Map.walkableGrid[y] and Map.walkableGrid[y][x] or false
                                    end

                                    return Map
