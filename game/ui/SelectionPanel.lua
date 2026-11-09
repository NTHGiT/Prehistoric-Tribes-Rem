local GameState = require("core.GameState")
local TextBank = require("core.TextBank")

local SelectionPanel = {
    dialogText = "",          -- Teks subtitle/dialog cerita
    dialogTimer = 0,
    actionButtons = {
        { id = "move",  label = "Pindah" },
        { id = "work",  label = "Kerja" },
        { id = "build", label = "Bangun" },
        { id = "stop",  label = "Batal" }
    }
}

function SelectionPanel.setDialog(text, duration)
    SelectionPanel.dialogText = text or ""
    SelectionPanel.dialogTimer = duration or 5
end

function SelectionPanel.update(dt)
    if SelectionPanel.dialogTimer > 0 then
        SelectionPanel.dialogTimer = SelectionPanel.dialogTimer - dt
        if SelectionPanel.dialogTimer <= 0 then
            SelectionPanel.dialogText = ""
        end
    end
end

function SelectionPanel.draw(selectedEntityId)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- =========================================================================
    -- 1. KIRI ATAS: AVATAR & BAR STATUS UNIT / BANGUNAN
    -- =========================================================================
    if selectedEntityId then
        local ent = GameState.entities[selectedEntityId]
        if ent and ent.active then
            -- Background Card Kiri Atas
            love.graphics.setColor(0, 0, 0, 0.75)
            love.graphics.rectangle("fill", 15, 15, 260, 95, 10, 10)
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.rectangle("line", 15, 15, 260, 95, 10, 10)

            -- Frame Avatar
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", 25, 25, 60, 60, 6, 6)
            
            -- Avatar Visual
            love.graphics.setColor(1, 0.8, 0.2, 1)
            love.graphics.circle("fill", 55, 55, 20)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(tostring(ent.id), 50, 47)

            -- Info Teks Unit
            love.graphics.print("Unit #" .. ent.id .. " [" .. string.upper(ent.type) .. "]", 95, 25)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.print("Status: " .. ent.state, 95, 43)

            -- Bar HP (Hijau)
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", 95, 62, 160, 12, 4, 4)
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            local hpRatio = math.max(0, ent.hp / ent.maxHp)
            love.graphics.rectangle("fill", 95, 62, 160 * hpRatio, 12, 4, 4)
            
            -- Bar Mood / Energi (Kuning)
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", 95, 80, 160, 10, 4, 4)
            love.graphics.setColor(0.9, 0.7, 0.1, 1)
            love.graphics.rectangle("fill", 95, 80, 160 * 0.85, 10, 4, 4)
        end
    end

    -- =========================================================================
    -- 2. TENGAH BAWAH: SUBTITLE / DIALOG TEKS
    -- =========================================================================
    if SelectionPanel.dialogText ~= "" then
        local boxW = math.min(600, screenW - 40)
        local boxH = 50
        local boxX = (screenW - boxW) / 2
        local boxY = screenH - 150

        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8, 8)
        love.graphics.setColor(1, 0.85, 0.3, 1)
        love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 8, 8)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(SelectionPanel.dialogText, boxX + 15, boxY + 15, boxW - 30, "center")
    end

    -- =========================================================================
    -- 3. BAWAH: PANEL TOMBOL AKSI (ACTION BUTTONS)
    -- =========================================================================
    if selectedEntityId then
        local panelH = 80
        local panelY = screenH - panelH
        
        -- Background Panel Bawah
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, panelY, screenW, panelH)
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.line(0, panelY, screenW, panelY)

        -- Render Tombol Aksi
        local btnW = 100
        local btnH = 50
        local spacing = 15
        local startX = (screenW - (#SelectionPanel.actionButtons * (btnW + spacing) - spacing)) / 2
        local btnY = panelY + (panelH - btnH) / 2

        for i, btn in ipairs(SelectionPanel.actionButtons) do
            local x = startX + (i - 1) * (btnW + spacing)

            love.graphics.setColor(0.25, 0.25, 0.3, 1)
            love.graphics.rectangle("fill", x, btnY, btnW, btnH, 8, 8)
            love.graphics.setColor(0.6, 0.6, 0.7, 1)
            love.graphics.rectangle("line", x, btnY, btnW, btnH, 8, 8)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(btn.label, x, btnY + 18, btnW, "center")
        end
    end
end

-- Deteksi Klik pada Tombol Aksi Bawah & Card Kiri Atas
function SelectionPanel.touchpressed(x, y)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local panelH = 80
    local panelY = screenH - panelH

    if y >= panelY then
        local btnW = 100
        local btnH = 50
        local spacing = 15
        local startX = (screenW - (#SelectionPanel.actionButtons * (btnW + spacing) - spacing)) / 2
        local btnY = panelY + (panelH - btnH) / 2

        for i, btn in ipairs(SelectionPanel.actionButtons) do
            local btnX = startX + (i - 1) * (btnW + spacing)
            if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
                return btn.id
            end
        end
        return "panel_clicked"
    end

    if x >= 15 and x <= 275 and y >= 15 and y <= 110 then
        return "card_clicked"
    end

    return nil
end

return SelectionPanel
