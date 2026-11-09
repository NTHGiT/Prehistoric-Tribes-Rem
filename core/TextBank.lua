local json = require("core.json")

local TextBank = {
    currentLang = "en",
    data = {}
}

-- Bahasa yang tersedia di folder assets/text/: en, fr, it, de, es
function TextBank.setLanguage(langCode)
    TextBank.currentLang = langCode or "en"
    TextBank.data = {}

    local files = { "ui", "story", "descriptions" }

    for _, category in ipairs(files) do
        local path = string.format("assets/text/%s/%s.json", TextBank.currentLang, category)

        if love.filesystem.getInfo(path) then
            local contents = love.filesystem.read(path)
            if contents then
                local success, result = pcall(json.decode, contents)
                if success and type(result) == "table" then
                    TextBank.data[category] = result
                end
            end
        end
    end
end

-- Fungsi pencarian string teks (dengan fallback jika kunci tidak ditemukan)
function TextBank.get(category, key, defaultText)
    if TextBank.data[category] then
        local value = TextBank.data[category][key] or TextBank.data[category][tostring(key)]
        if value then
            return value
        end
    end
    return defaultText or (category .. "." .. tostring(key))
end

return TextBank
