-- Terrain art. The atlas is baked by tools/bake_tiles.py from the original composite tiles,
-- so drawing a map cell is a single quad. See docs/ASSET_PIPELINE.md.
local TextureBank = {
    image = nil,
    ground = {},                 -- tileId -> { quad, ox, oy }
    overhang = { 0, 0, 0, 0 },   -- how far art reaches outside its cell: left, up, right, down (px)
    tileW = 22,
    tileH = 16,
    ready = false,
}

local ATLAS_IMAGE = "assets/atlas/terrain.png"
local ATLAS_DATA = "assets/data/terrain_atlas.lua"

function TextureBank.init()
    local chunk, err = love.filesystem.load(ATLAS_DATA)
    if not chunk then
        print("[TextureBank] " .. ATLAS_DATA .. " tidak ada: " .. tostring(err) .. " (jalankan tools/bake_tiles.py)")
        return false
    end
    local atlas = chunk()

    local ok, image = pcall(love.graphics.newImage, ATLAS_IMAGE)
    if not ok then
        print("[TextureBank] gagal memuat " .. ATLAS_IMAGE .. ": " .. tostring(image))
        return false
    end
    image:setFilter("nearest", "nearest")

    TextureBank.image = image
    TextureBank.tileW, TextureBank.tileH = atlas.tileW, atlas.tileH
    TextureBank.overhang = atlas.overhang
    for id, e in pairs(atlas.ground) do
        TextureBank.ground[id] = {
            quad = love.graphics.newQuad(e[1], e[2], e[3], e[4], atlas.width, atlas.height),
            ox = e[5], oy = e[6],
        }
    end
    TextureBank.ready = true
    return true
end

-- Draw the art of one map cell. (x, y) is the cell's top-left corner in world pixels.
function TextureBank.drawGround(tileId, x, y)
    local entry = TextureBank.ground[tileId]
    if entry then
        love.graphics.draw(TextureBank.image, entry.quad, x + entry.ox, y + entry.oy)
    else
        love.graphics.setColor(0.35, 0.35, 0.35, 1)       -- unknown tile id or atlas missing
        love.graphics.rectangle("fill", x, y, TextureBank.tileW, TextureBank.tileH)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return TextureBank
