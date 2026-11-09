-- A* on the 8-connected tile grid with a binary heap and no corner cutting.
local Pathfinding = {}

local KEY = 1024                       -- key = y * KEY + x (maps are at most 96 wide)
local SQRT2 = 1.41421356
local DX = { 1, -1, 0, 0, 1, -1, 1, -1 }
local DY = { 0, 0, 1, -1, 1, 1, -1, -1 }
local MAX_EXPANSIONS = 8000

function Pathfinding.isWalkable(map, x, y)
    if not map or not map.walkable then return false end
    local row = map.walkable[y]
    return row ~= nil and row[x] == true
end

local function heuristic(x1, y1, x2, y2)
    local dx, dy = math.abs(x1 - x2), math.abs(y1 - y2)
    return math.max(dx, dy) + (SQRT2 - 1) * math.min(dx, dy)
end

local function heapPush(heap, key, f)
    local n = heap.n + 1
    heap.n = n
    heap.keys[n], heap.fs[n] = key, f
    while n > 1 do
        local p = math.floor(n / 2)
        if heap.fs[p] <= heap.fs[n] then break end
        heap.keys[p], heap.keys[n] = heap.keys[n], heap.keys[p]
        heap.fs[p], heap.fs[n] = heap.fs[n], heap.fs[p]
        n = p
    end
end

local function heapPop(heap)
    local n = heap.n
    if n == 0 then return nil end
    local top = heap.keys[1]
    heap.keys[1], heap.fs[1] = heap.keys[n], heap.fs[n]
    heap.keys[n], heap.fs[n] = nil, nil
    n = n - 1
    heap.n = n
    local i = 1
    while true do
        local l, r, s = i * 2, i * 2 + 1, i
        if l <= n and heap.fs[l] < heap.fs[s] then s = l end
        if r <= n and heap.fs[r] < heap.fs[s] then s = r end
        if s == i then break end
        heap.keys[i], heap.keys[s] = heap.keys[s], heap.keys[i]
        heap.fs[i], heap.fs[s] = heap.fs[s], heap.fs[i]
        i = s
    end
    return top
end

-- Closest walkable cell around a blocked target (e.g. a tree or a building wall).
function Pathfinding.nearestWalkable(map, tx, ty, fromX, fromY)
    for r = 1, 4 do
        local bestX, bestY, bestD
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r and Pathfinding.isWalkable(map, tx + dx, ty + dy) then
                    local d = heuristic(tx + dx, ty + dy, fromX or tx, fromY or ty)
                    if not bestD or d < bestD then bestX, bestY, bestD = tx + dx, ty + dy, d end
                end
            end
        end
        if bestX then return bestX, bestY end
    end
    return nil
end

-- Returns the steps after the start cell as { {x=, y=}, ... }, or {} if there is no route.
function Pathfinding.findPath(map, sx, sy, tx, ty)
    if not map or not map.walkable then return {} end
    if sx == tx and sy == ty then return {} end

    if not Pathfinding.isWalkable(map, tx, ty) then
        tx, ty = Pathfinding.nearestWalkable(map, tx, ty, sx, sy)
        if not tx or (sx == tx and sy == ty) then return {} end
    end

    local startKey, targetKey = sy * KEY + sx, ty * KEY + tx
    local gScore, cameFrom, closed = { [startKey] = 0 }, {}, {}
    local heap = { n = 0, keys = {}, fs = {} }
    heapPush(heap, startKey, heuristic(sx, sy, tx, ty))

    local expansions = 0
    while heap.n > 0 do
        local current = heapPop(heap)
        if current == targetKey then
            local path, k = {}, current
            while k ~= startKey do
                path[#path + 1] = { x = k % KEY, y = math.floor(k / KEY) }
                k = cameFrom[k]
            end
            local n = #path
            for i = 1, math.floor(n / 2) do path[i], path[n - i + 1] = path[n - i + 1], path[i] end
            return path
        end

        if not closed[current] then
            closed[current] = true
            expansions = expansions + 1
            if expansions > MAX_EXPANSIONS then return {} end

            local cx, cy = current % KEY, math.floor(current / KEY)
            for d = 1, 8 do
                local nx, ny = cx + DX[d], cy + DY[d]
                local nKey = ny * KEY + nx
                if not closed[nKey] and Pathfinding.isWalkable(map, nx, ny) then
                    local diagonal = DX[d] ~= 0 and DY[d] ~= 0
                    local canStep = true
                    if diagonal then       -- both side cells must be free, otherwise we would cut a corner
                        canStep = Pathfinding.isWalkable(map, cx + DX[d], cy) and Pathfinding.isWalkable(map, cx, cy + DY[d])
                    end
                    if canStep then
                        local g = gScore[current] + (diagonal and SQRT2 or 1)
                        if not gScore[nKey] or g < gScore[nKey] then
                            gScore[nKey] = g
                            cameFrom[nKey] = current
                            heapPush(heap, nKey, g + heuristic(nx, ny, tx, ty))
                        end
                    end
                end
            end
        end
    end
    return {}
end

return Pathfinding
