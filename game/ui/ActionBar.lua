local GameState = require("core.GameState")

local ActionBar = {
    currentCategory = "BUILD",
    isCollapsed = false, -- Status Toggle Panel Bawah
    buttons = {
        { id = "select", label = "OK" },
        { id = "move",   label = "Move" },
        { id = "army",   label = "Army" },
        { id = "cta",    label = "CTA" },
        { id = "social", label = "Tribes" },
        { id = "cancel", label = "Cancel" },
        { id = "exit",   label = "X" }
    }
}

function ActionBar.draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- 1. HUD RESOURCES ATAS
    love.graphics.setColor(0.15, 0.1, 0.05, 0.9)
    love.graphics.rectangle("fill", 0, 0, screenW, 45)
    love.graphics.setColor(0.6, 0.45, 0.2, 1)
    love.graphics.rectangle("line", 0, 0, screenW, 45)

    love.graphics.setColor(1, 1, 1, 1)
    local popStr = "Pop: " .. GameState.population .. "/" .. GameState.maxPopulation
    local foodStr = "Meat: " .. GameState.resources.food
    local woodStr = "Wood: " .. GameState.resources.wood
    local stoneStr = "Stone: " .. GameState.resources.stone
    local boneStr = "Bone: " .. GameState.resources.bone

    love.graphics.print(popStr .. "   " .. foodStr .. "   " .. woodStr .. "   " .. stoneStr .. "   " .. boneStr, 15, 14)

    -- 2. TAB TOGGLE PANEL BAWAH
    local toggleW = 110
    local toggleH = 22
    local toggleX = (screenW - toggleW) / 2
    local barY = screenH - (ActionBar.isCollapsed and 0 or 90)

    love.graphics.setColor(0.4, 0.3, 0.15, 0.95)
    love.graphics.rectangle("fill", toggleX, barY - toggleH, toggleW, toggleH, 6, 6)
    love.graphics.setColor(0.7, 0.55, 0.3, 1)
    love.graphics.rectangle("line", toggleX, barY - toggleH, toggleW, toggleH, 6, 6)

    love.graphics.setColor(1, 1, 1, 1)
    local toggleLabel = ActionBar.isCollapsed and "▲ PANEL" or "▼ SEMBUNYI"
    love.graphics.printf(toggleLabel, toggleX, barY - toggleH + 4, toggleW, "center")

    -- 3. ACTION BAR (Render Jika Tidak Disembunyikan)
    if not ActionBar.isCollapsed then
        love.graphics.setColor(0.8, 0.7, 0.45, 0.95)
        love.graphics.rectangle("fill", 0, barY, screenW, 90)
        love.graphics.setColor(0.4, 0.3, 0.15, 1)
        love.graphics.rectangle("line", 0, barY, screenW, 90)

        love.graphics.setColor(0.3, 0.2, 0.05, 1)
        love.graphics.printf(ActionBar.currentCategory, 0, barY + 6, screenW, "center")

        local btnW = 55
        local btnH = 50
        local spacing = 12
        local totalW = #ActionBar.buttons * (btnW + spacing) - spacing
        local startX = (screenW - totalW) / 2
        local btnY = barY + 30

        for i, btn in ipairs(ActionBar.buttons) do
            local x = startX + (i - 1) * (btnW + spacing)

            if btn.id == "exit" then
                love.graphics.setColor(0.8, 0.2, 0.2, 1)
            else
                love.graphics.setColor(0.65, 0.55, 0.35, 1)
            end
            love.graphics.rectangle("fill", x, btnY, btnW, btnH, 6, 6)
            love.graphics.setColor(0.3, 0.2, 0.1, 1)
            love.graphics.rectangle("line", x, btnY, btnW, btnH, 6, 6)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(btn.label, x, btnY + 16, btnW, "center")
        end
    end
end

function ActionBar.touchpressed(x, y)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local barY = screenH - (ActionBar.isCollapsed and 0 or 90)

    -- Cek Klik Tab Toggle
    local toggleW = 110
    local toggleH = 22
    local toggleX = (screenW - toggleW) / 2
    local toggleY = barY - toggleH

    if x >= toggleX and x <= toggleX + toggleW and y >= toggleY and y <= barY then
        ActionBar.isCollapsed = not ActionBar.isCollapsed
        return "toggle_panel"
    end

    -- Cek Klik Tombol Aksi
    if not ActionBar.isCollapsed and y >= barY then
        local btnW = 55
        local btnH = 50
        local spacing = 12
        local totalW = #ActionBar.buttons * (btnW + spacing) - spacing
        local startX = (screenW - totalW) / 2
        local btnY = barY + 30

        for i, btn in ipairs(ActionBar.buttons) do
            local btnX = startX + (i - 1) * (btnW + spacing)
            if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
                if btn.id == "exit" then
                    love.event.quit()
                end
                return btn.id
            end
        end
        return "bar_clicked"
    end

    return nil
end

return ActionBar
