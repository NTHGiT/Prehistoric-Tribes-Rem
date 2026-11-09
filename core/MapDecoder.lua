-- Loads a level and derives everything the simulation needs from it:
-- tiles, walkability (same rules as the original loader) and natural resources.
-- Data comes from tools/pack_levels.py and tools/bake_tiles.py (see docs/ASSET_PIPELINE.md).
-- All coordinates here are 1-based: tiles[y][x].
local MapDecoder = {}

local LEVELS_FILE = "assets/data/levels.lua"
local INFO_FILE = "assets/data/tile_info.lua"

local levelsMeta, tileInfo

local function loadTable(path)
    local chunk, err = love.filesystem.load(path)
    if not chunk then error("Gagal memuat " .. path .. ": " .. tostring(err)) end
    return chunk()
end

local function toSet(list)
    local set = {}
    for i = 1, #list do set[list[i]] = true end
    return set
end

-- Cells 175..179 hold food/bones. Amounts are the original values (chunk 110).
local SPAWN = {
    [175] = { type = "BUSH", amount = 20 },
    [176] = { type = "BUSH", amount = 20 },
    [177] = { type = "FISH", amount = 20 },
    [178] = { type = "BONE", amount = 15 },
    [179] = { type = "BONE", amount = 25 },
}

-- Wood and stone are NOT original data: the original harvests them differently.
-- This is a prototype rule so the tree / boulder / cliff art on the map is usable.
local WOOD_AMOUNT, STONE_AMOUNT = 100, 150

local function classify(tile)
    local spawn = SPAWN[tile]
    if spawn then return spawn.type, spawn.amount end
    if tile >= 180 and tile <= 229 then return "WOOD", WOOD_AMOUNT end              -- palms and trees
    if tile == 46 then return nil end                                                -- cave entrance
    if (tile >= 41 and tile <= 62) or (tile >= 63 and tile <= 75) or (tile >= 115 and tile <= 127) then
        return "STONE", STONE_AMOUNT                                                 -- cliffs and boulders
    end
    return nil
end

-- Tile shown once a resource is used up.
local function replacementTile(tile)
    if tile == 177 then return 6 end                    -- fishing spot stays water
    if tile >= 115 and tile <= 127 then return 3 end    -- boulder on dirt -> dirt
    if tile >= 225 and tile <= 229 then return 3 end    -- palm on dirt -> dirt
    return 0                                            -- everything else -> grass
end

function MapDecoder.isWalkable(map, x, y)
    local row = map.walkable[y]
    return row ~= nil and row[x] == true
end

local function touchesWalkable(map, x, y)
    for dy = -1, 1 do
        for dx = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and MapDecoder.isWalkable(map, x + dx, y + dy) then return true end
        end
    end
    return false
end

function MapDecoder.load(level)
    level = level or 0
    levelsMeta = levelsMeta or loadTable(LEVELS_FILE)
    tileInfo = tileInfo or loadTable(INFO_FILE)

    local meta = levelsMeta[level]
    if not meta then error("Level tidak dikenal: " .. tostring(level)) end

    local path = string.format("assets/maps/level_%02d.bin", level)
    local data = love.filesystem.read(path)
    local w, h = meta.width, meta.height
    if not data or #data ~= w * h then
        error("Berkas peta hilang atau rusak: " .. path .. " (jalankan tools/pack_levels.py)")
    end

    local blocked = toSet(tileInfo.blocked)
    local playW, playH = meta.playWidth, meta.playHeight
    local map = {
        level = level, width = w, height = h,
        playWidth = playW, playHeight = playH,
        startX = meta.startX + 1, startY = meta.startY + 1,
        tiles = {}, walkable = {}, resources = {},
    }

    for y = 1, h do
        local tiles, walk = {}, {}
        for x = 1, w do
            local tile = data:byte((y - 1) * w + x)
            tiles[x] = tile
            local inside = x <= playW and y <= playH
            local border = (y == 1) or (y == h) or (x == w)     -- original: edge cells are always solid
            walk[x] = inside and not border and not blocked[tile]
        end
        map.tiles[y], map.walkable[y] = tiles, walk
    end

    for y = 1, playH do
        for x = 1, playW do
            local kind, amount = classify(map.tiles[y][x])
            if kind then
                local reachable = SPAWN[map.tiles[y][x]] ~= nil or touchesWalkable(map, x, y)
                if reachable then map.resources[#map.resources + 1] = { type = kind, x = x, y = y, amount = amount } end
            end
        end
    end
    return map
end

-- Called by the simulation when a node runs dry: swap the art and, where sensible, open the cell.
function MapDecoder.depleteNode(map, node)
    local row = map.tiles[node.y]
    if not row then return end
    row[node.x] = replacementTile(row[node.x])
    local border = (node.y == 1) or (node.y == map.height) or (node.x == map.width)
    local inside = node.x <= map.playWidth and node.y <= map.playHeight
    if node.type ~= "fish" and inside and not border then map.walkable[node.y][node.x] = true end
end

local function areaClear(map, x0, y0, w, h, avoid)
    for y = y0, y0 + h - 1 do
        for x = x0, x0 + w - 1 do
            if not MapDecoder.isWalkable(map, x, y) then return false end
        end
    end
    if avoid then
        for i = 1, #avoid do
            local a = avoid[i]
            if x0 < a.x + a.w + 1 and a.x < x0 + w + 1 and y0 < a.y + a.h + 1 and a.y < y0 + h + 1 then return false end
        end
    end
    return true
end

-- Spiral search for the nearest top-left corner where a w*h footprint fits on walkable ground.
function MapDecoder.findClearArea(map, cx, cy, w, h, maxRadius, avoid)
    for r = 0, maxRadius or 12 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r and areaClear(map, cx + dx, cy + dy, w, h, avoid) then
                    return cx + dx, cy + dy
                end
            end
        end
    end
    return nil
end

-- Random walkable cell near (cx, cy). `used` is an optional set that is updated, keys are y*1024+x.
function MapDecoder.pickWalkable(map, cx, cy, radius, used)
    local candidates = {}
    for dy = -radius, radius do
        for dx = -radius, radius do
            local x, y = cx + dx, cy + dy
            if MapDecoder.isWalkable(map, x, y) and not (used and used[y * 1024 + x]) then
                candidates[#candidates + 1] = { x = x, y = y }
            end
        end
    end
    if #candidates == 0 then return cx, cy end
    local c = candidates[math.random(#candidates)]
    if used then used[c.y * 1024 + c.x] = true end
    return c.x, c.y
end

return MapDecoder
