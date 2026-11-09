-- Short on-screen messages sent through Events.notify (replaces the old SelectionPanel dialog).
local Events = require("core.Events")

local Toast = { text = "", timer = 0 }

Events.on("notify", function(text, seconds)
        Toast.text = text or ""
        Toast.timer = seconds or 3
end)

function Toast.update(dt)
    if Toast.timer > 0 then
        Toast.timer = Toast.timer - dt
        if Toast.timer <= 0 then Toast.text = "" end
    end
end

function Toast.draw()
    if Toast.timer <= 0 or Toast.text == "" then return end
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local font = love.graphics.getFont()
    local boxW = math.min(screenW - 40, 640)
    local _, lines = font:getWrap(Toast.text, boxW - 24)
    local boxH = #lines * font:getHeight() + 20
    local x, y = (screenW - boxW) / 2, screenH - 120 - boxH
    local alpha = math.min(1, Toast.timer / 0.5)

    love.graphics.setColor(0, 0, 0, 0.75 * alpha)
    love.graphics.rectangle("fill", x, y, boxW, boxH, 8, 8)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(Toast.text, x + 12, y + 10, boxW - 24, "left")
    love.graphics.setColor(1, 1, 1, 1)
end

return Toast
