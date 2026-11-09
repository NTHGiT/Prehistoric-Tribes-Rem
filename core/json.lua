-- core/json.lua (ringkas untuk memuat file JSON data game)
local json = {}

local controls = { ["n"] = "\n", ["r"] = "\r", ["t"] = "\t", ["b"] = "\b", ["f"] = "\f" }

local function parse_string(str, i)
    local res = ""
    i = i + 1
    while i <= #str do
        local c = str:sub(i, i)
        if c == '"' then return res, i + 1 end
        if c == "\\" then
            local next_c = str:sub(i + 1, i + 1)
            res = res .. (controls[next_c] or next_c)
            i = i + 2
        else
            res = res .. c
            i = i + 1
        end
    end
    error("String JSON tidak ditutup")
end

local function parse_number(str, i)
    local val = str:match("^%-?%d+%.?%d*[eE]?%s*%-?%d*", i)
    return tonumber(val), i + #val
end

local parse_value

local function parse_array(str, i)
    local arr = {}
    i = i + 1
    while i <= #str do
        i = str:find("%S", i) or i
        local c = str:sub(i, i)
        if c == "]" then return arr, i + 1 end
        if c == "," then i = i + 1 end
        local val
        val, i = parse_value(str, i)
        table.insert(arr, val)
    end
    error("Array JSON tidak ditutup")
end

local function parse_object(str, i)
    local obj = {}
    i = i + 1
    while i <= #str do
        i = str:find("%S", i) or i
        local c = str:sub(i, i)
        if c == "}" then return obj, i + 1 end
        if c == "," then i = i + 1 end
        if str:sub(i, i) == '"' then
            local key
            key, i = parse_string(str, i)
            i = str:find(":", i) + 1
            local val
            val, i = parse_value(str, i)
            obj[key] = val
        else
            i = i + 1
        end
    end
    error("Object JSON tidak ditutup")
end

parse_value = function(str, i)
    i = str:find("%S", i) or i
    local c = str:sub(i, i)
    if c == "{" then return parse_object(str, i) end
    if c == "[" then return parse_array(str, i) end
    if c == '"' then return parse_string(str, i) end
    if c == "t" then return true, i + 4 end
    if c == "f" then return false, i + 5 end
    if c == "n" then return nil, i + 4 end
    return parse_number(str, i)
end

function json.decode(str)
    local val, _ = parse_value(str, 1)
    return val
end

return json
