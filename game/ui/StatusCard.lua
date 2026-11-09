local GameState = require("core.GameState")
local Input = require("game.Input")

local StatusCard = {}

local function drawBar(x, y, w, h, percent, fillColor, labelText)
    -- Background Bar
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)

    -- Fill Progress Bar
    love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3], 1)
    love.graphics.rectangle("fill", x, y, w * math.max(0, math.min(1, percent)), h, 3, 3)

    -- Border Bar
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("line", x, y, w, h, 3, 3)

    -- Label Teks Bar
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(labelText, x, y + 1, w, "center")
end

function StatusCard.draw()
    if not Input.selectedEntityId then return end

    local ent = GameState.entities[Input.selectedEntityId]
    if not ent or not ent.active then return end

    local screenW = love.graphics.getWidth()
    local cardW = 210
    local cardH = 195
    local cardX = screenW - cardW - 12
    local cardY = 55

    -- Background Card Utama
    love.graphics.setColor(0.12, 0.09, 0.06, 0.92)
    love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 8, 8)
    love.graphics.setColor(0.7, 0.55, 0.3, 1)
    love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 8, 8)

    -- Header Info Warga (Nama/ID, Gender, Profesi)
    love.graphics.setColor(1, 0.9, 0.5, 1)
    local genderIcon = (ent.gender == "male") and " (Pria)" or " (Wanita)"
    local titleStr = (ent.type == "chief" and "KEPALA SUKU" or ("Warga #" .. ent.id)) .. genderIcon
    love.graphics.print(titleStr, cardX + 10, cardY + 8)

    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Profesi: " .. string.upper(ent.job), cardX + 10, cardY + 24)

    -- Separator Line
    love.graphics.setColor(0.4, 0.3, 0.2, 1)
    love.graphics.line(cardX + 10, cardY + 40, cardX + cardW - 10, cardY + 40)

    -- Indikator Vitalitas (Hunger, Thirst, Mood)
    local barW = 120
    local barH = 14
    local barX = cardX + 75
    local currY = cardY + 46

    -- Hunger Bar
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Hunger:", cardX + 10, currY)
    local hungerPct = ent.hunger / 100
    drawBar(barX, currY + 1, barW, barH, hungerPct, {0.8, 0.3, 0.2}, math.floor(ent.hunger) .. "%")

    -- Thirst Bar
    currY = currY + 18
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Thirst:", cardX + 10, currY)
    local thirstPct = ent.thirst / 100
    drawBar(barX, currY + 1, barW, barH, thirstPct, {0.2, 0.5, 0.8}, math.floor(ent.thirst) .. "%")

    -- Mood Bar
    currY = currY + 18
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Mood:", cardX + 10, currY)
    local moodPct = ent.mood / 100
    drawBar(barX, currY + 1, barW, barH, moodPct, {0.2, 0.8, 0.3}, math.floor(ent.mood) .. "%")

    -- Inventory (Barang Bawaan Ransel)
    currY = currY + 22
    love.graphics.setColor(1, 1, 1, 1)
    local invStr = "Ransel: " .. (ent.carryingType and (string.upper(ent.carryingType) .. " (" .. ent.carryingAmount .. "/" .. ent.maxCarry .. ")") or "Kosong")
    love.graphics.print(invStr, cardX + 10, currY)

    -- Separator Line
    love.graphics.setColor(0.4, 0.3, 0.2, 1)
    love.graphics.line(cardX + 10, currY + 16, cardX + cardW - 10, currY + 16)

    -- Masteries & Skills (Skill 1 & Skill 2)
    currY = currY + 20
    local s1, s2 = GameState.getTopSkills(ent)

    local lvl1, exp1, max1 = GameState.getSkillLevel(s1.exp)
    love.graphics.setColor(0.9, 0.8, 0.3, 1)
    love.graphics.print("Skill 1: " .. s1.name .. " Lv." .. lvl1, cardX + 10, currY)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print("(" .. exp1 .. "/" .. max1 .. " EXP)", cardX + 130, currY)

    currY = currY + 16
    local lvl2, exp2, max2 = GameState.getSkillLevel(s2.exp)
    love.graphics.setColor(0.8, 0.7, 0.4, 1)
    love.graphics.print("Skill 2: " .. s2.name .. " Lv." .. lvl2, cardX + 10, currY)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print("(" .. exp2 .. "/" .. max2 .. " EXP)", cardX + 130, currY)
end

return StatusCard
