local MapDecoder = require("core.MapDecoder")
local GameState = require("core.GameState")
local Simulation = require("core.Simulation")
local Camera = require("game.Camera")
local Renderer = require("game.Renderer")
local Input = require("game.Input")
local ActionBar = require("game.ui.ActionBar")
local BuildMenu = require("game.ui.BuildMenu")
local StatusCard = require("game.ui.StatusCard")
local Toast = require("game.ui.Toast")

local LEVEL = 0                 -- 0 = tutorial map; see assets/data/levels.lua
local TICK_RATE = 0.120         -- the original simulation ran at about 8 ticks per second
local MAX_TICKS_PER_FRAME = 5   -- avoid a spiral of death after a long hitch

local currentMap = nil
local loadError = nil
local accumulator = 0

-- Pointers (touches or the mouse) currently held down. Needed for pinch zoom, and
-- the only way to tell a mouse drag from a touch drag because both go through here.
local pointers = {}
local pinch = nil               -- { dist = start distance, scale = start zoom }
local multiTouchGesture = false -- true until every pointer is released; stops pinch ending as a tap

local function pointerCount()
    local n = 0
    for _ in pairs(pointers) do n = n + 1 end
    return n
end

local function twoPointers()
    local a, b
    for _, p in pairs(pointers) do
        if not a then a = p else b = p; break end
    end
    return a, b
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    Renderer.init()

    local ok, result = pcall(MapDecoder.load, LEVEL)
    if not ok then
        loadError = tostring(result)
        print("[main] " .. loadError)
        return
    end
    currentMap = result
    Simulation.init(currentMap)

    Camera:setWorld(currentMap.playWidth * 22, currentMap.playHeight * 16)
    local store = GameState.buildings[1]
    local focusX = store and (store.x - 1 + store.sizeX / 2) * 22 or (currentMap.startX - 1) * 22
    local focusY = store and (store.y - 1 + store.sizeY / 2) * 16 or (currentMap.startY - 1) * 16
    Camera:centerOn(focusX, focusY)
end

function love.resize()
    Camera:clamp()
end

function love.update(dt)
    if not currentMap then return end
    accumulator = accumulator + math.min(dt, 0.25)

    local ticks = 0
    while accumulator >= TICK_RATE and ticks < MAX_TICKS_PER_FRAME do
        Simulation.step()
        accumulator = accumulator - TICK_RATE
        ticks = ticks + 1
    end
    if ticks == MAX_TICKS_PER_FRAME then accumulator = 0 end

    Input.update(dt)
    Toast.update(dt)
end

function love.draw()
    love.graphics.clear(0.05, 0.05, 0.05)
    if loadError then
        love.graphics.setColor(1, 0.4, 0.4, 1)
        love.graphics.printf("Gagal memuat peta:\n" .. loadError, 20, 20, love.graphics.getWidth() - 40)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    Camera:apply()
    Renderer.drawMap(currentMap, Camera)
    Camera:clear()

    ActionBar.draw()
    BuildMenu.draw()
    StatusCard.draw()
    Toast.draw()
end

-- ==========================================
-- POINTER HANDLING (touch on phones, mouse on PC)
-- ==========================================
local function pointerPressed(id, x, y)
    pointers[id] = { x = x, y = y }

    if pointerCount() == 2 then
        multiTouchGesture = true
        local a, b = twoPointers()
        pinch = { dist = math.max(1, math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)), scale = Camera.scale }
        return
    end

    if Input.touchpressed(id, x, y) then return end     -- BuildMenu consumed it

    local action = ActionBar.touchpressed(x, y)
    if action == "select" or action == "cta" then
        BuildMenu.isOpen = not BuildMenu.isOpen
        Input.isTap = false
    end
end

local function pointerMoved(id, x, y, dx, dy)
    local p = pointers[id]
    if not p then return end
    p.x, p.y = x, y
    Input.touchmoved(id, x, y, dx, dy)

    if pointerCount() >= 2 and pinch then
        local a, b = twoPointers()
        local dist = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
        Camera:zoomAt(pinch.scale * dist / pinch.dist, (a.x + b.x) / 2, (a.y + b.y) / 2)
    elseif pointerCount() == 1 then
        local barH = ActionBar.isCollapsed and 22 or 90
        if y < love.graphics.getHeight() - barH and not BuildMenu.isOpen and not BuildMenu.isPlacing then
            Camera:pan(dx, dy)
        end
    end
end

local function pointerReleased(id, x, y)
    if not pointers[id] then return end
    local wasMulti = multiTouchGesture
    pointers[id] = nil
    if pointerCount() < 2 then pinch = nil end
    if pointerCount() == 0 then multiTouchGesture = false end
    if not wasMulti then Input.touchreleased(id, x, y) end
end

function love.touchpressed(id, x, y) pointerPressed(id, x, y) end
function love.touchmoved(id, x, y, dx, dy) pointerMoved(id, x, y, dx, dy) end
function love.touchreleased(id, x, y) pointerReleased(id, x, y) end

function love.mousepressed(x, y, button, istouch)
    if not istouch and button == 1 then pointerPressed("mouse", x, y) end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if not istouch and pointers["mouse"] then pointerMoved("mouse", x, y, dx, dy) end
end

function love.mousereleased(x, y, button, istouch)
    if not istouch and button == 1 then pointerReleased("mouse", x, y) end
end

function love.wheelmoved(_, y)
    if BuildMenu.wheelmoved and BuildMenu.wheelmoved(y) then return end
    if y == 0 then return end
    local mx, my = love.mouse.getPosition()
    Camera:zoomAt(Camera.scale + (y > 0 and 0.25 or -0.25), mx, my)
end

function love.keypressed(key)
    if BuildMenu.keypressed and BuildMenu.keypressed(key) then return end
    if key == "escape" then love.event.quit() end
end
