local Camera = {
    x = 0,
    y = 0,
    scale = 2.5,
    minScale = 1.0,
    maxScale = 4.5,
    worldW = 0,      -- size of the playable map in world pixels (0 = no clamping)
    worldH = 0,
}

function Camera:apply()
    love.graphics.push()
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:clear()
    love.graphics.pop()
end

function Camera:setWorld(width, height)
    self.worldW, self.worldH = width, height
    self:clamp()
end

-- Keep the view inside the map; a map smaller than the screen is centred.
function Camera:clamp()
    if self.worldW <= 0 then return end
    local viewW = love.graphics.getWidth() / self.scale
    local viewH = love.graphics.getHeight() / self.scale
    if viewW >= self.worldW then self.x = (self.worldW - viewW) / 2
    else self.x = math.max(0, math.min(self.x, self.worldW - viewW)) end
    if viewH >= self.worldH then self.y = (self.worldH - viewH) / 2
    else self.y = math.max(0, math.min(self.y, self.worldH - viewH)) end
end

function Camera:pan(dx, dy)
    self.x = self.x - dx / self.scale
    self.y = self.y - dy / self.scale
    self:clamp()
end

function Camera:centerOn(worldX, worldY)
    self.x = worldX - love.graphics.getWidth() / (2 * self.scale)
    self.y = worldY - love.graphics.getHeight() / (2 * self.scale)
    self:clamp()
end

-- Zoom while keeping the world point under the screen position (sx, sy) fixed.
function Camera:zoomAt(newScale, sx, sy)
    newScale = math.max(self.minScale, math.min(self.maxScale, newScale))
    local wx, wy = self:toWorldCoords(sx, sy)
    self.scale = newScale
    self.x = wx - sx / newScale
    self.y = wy - sy / newScale
    self:clamp()
end

-- Screen pixels -> world pixels
function Camera:toWorldCoords(screenX, screenY)
    return screenX / self.scale + self.x, screenY / self.scale + self.y
end

return Camera
