local json = require("core.json") -- Menggunakan library json (rxi-json atau dkjson)

local PdTables = {
    data = nil,
    isLoaded = false,

    -- Cache internal tabel short & byte
    short0 = {},
    short1 = {},
    short2 = {},
    short4 = {},
    short5 = {},
    short6 = {},
    short7 = {},
    short8 = {},
    short9 = {},
    short10 = {},
    bytes = {}
}

--- Memuat dan menginisialisasi pd0_tables.json
-- @param filePath String path lokasi berkas pd0_tables.json
function PdTables.load(filePath)
filePath = filePath or "assets/data/pd0_tables.json"

local content, err = love.filesystem.read(filePath)
if not content then
    error("Gagal membaca berkas Texture Bank pada: " .. tostring(filePath) .. " | Error: " .. tostring(err))
    end

    PdTables.data = json.decode(content)
    if not PdTables.data then
        error("Format JSON pada pd0_tables.json tidak valid!")
        end

        -- Ekstraksi tabel short
        PdTables.short0  = PdTables.data["short_0"] or {}
        PdTables.short1  = PdTables.data["short_1"] or {}
        PdTables.short2  = PdTables.data["short_2"] or {}
        PdTables.short4  = PdTables.data["short_4"] or {}
        PdTables.short5  = PdTables.data["short_5"] or {}
        PdTables.short6  = PdTables.data["short_6"] or {}
        PdTables.short7  = PdTables.data["short_7"] or {}
        PdTables.short8  = PdTables.data["short_8"] or {}
        PdTables.short9  = PdTables.data["short_9"] or {}
        PdTables.short10 = PdTables.data["short_10"] or {}

        -- Ekstraksi tabel byte
        PdTables.bytes[0] = PdTables.data["byte_0"] or {}
        PdTables.bytes[1] = PdTables.data["byte_1"] or {}
        PdTables.bytes[2] = PdTables.data["byte_2"] or {}
        PdTables.bytes[3] = PdTables.data["byte_3"] or {}
        PdTables.bytes[4] = PdTables.data["byte_4"] or {}

        PdTables.isLoaded = true
        print(string.format("[PdTables] Berhasil memuat %d entry short_0 dan %d entry short_1.", #PdTables.short0, #PdTables.short1))
        return true
        end

        --- Mengambil rentang indeks komponen composite sprite untuk ID sprite tertentu
        -- @param spriteId Index sprite/tile yang dicari
        -- @return startIndex, endIndex (indeks berbasis 1 untuk Lua)
        function PdTables.getComponentRange(spriteId)
        if not PdTables.isLoaded then return 0, 0 end

            local idx = spriteId + 1 -- Konversi indeks 0-based ke 1-based Lua
            if idx < 1 or idx >= #PdTables.short0 then
                return 0, 0
                end

                local startIdx = PdTables.short0[idx] + 1
                local endIdx = PdTables.short0[idx + 1]
                return startIdx, endIdx
                end

                --- Mengambil rincian data komponen visual perakitan sprite
                -- @param compIndex Indeks elemen pada short_1/short_2
                function PdTables.getComponentData(compIndex)
                if not PdTables.isLoaded or compIndex < 1 or compIndex > #PdTables.short1 then
                    return nil
                    end

                    local tileQuadId = PdTables.short1[compIndex] or 0
                    local rawPosData = PdTables.short2[compIndex] or 0

                    -- Unpack bit flags & koordinat offset dari short2
                    local offsetX = bit.band(rawPosData, 0x00FF)
                    if offsetX > 127 then offsetX = offsetX - 256 end -- Handle signed byte

                        local offsetY = bit.rshift(bit.band(rawPosData, 0xFF00), 8)
                        if offsetY > 127 then offsetY = offsetY - 256 end

                            local flipX = bit.band(rawPosData, 0x10000) ~= 0
                            local flipY = bit.band(rawPosData, 0x20000) ~= 0

                            return {
                                quadId = tileQuadId,
                                offsetX = offsetX,
                                offsetY = offsetY,
                                flipX = flipX,
                                flipY = flipY
                            }
                            end

                            --- Memeriksa sifat keterlintasan (walkability) tile berdasarkan ID
                            -- @param tileId Indeks ID ubin
                            function PdTables.isWalkable(tileId)
                            if not PdTables.isLoaded then return true end
                                local byte0 = PdTables.bytes[0]
                                if byte0 and byte0[tileId + 1] then
                                    return byte0[tileId + 1] == 0
                                    end
                                    return true
                                    end

                                    return PdTables
