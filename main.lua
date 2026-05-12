local Player = require("src.player")
local Patterns = require("src.patterns")
local Emitter = require("src.emitter")
local UI = require("src.ui")
local Background = require("src.background")

local AREA_W, AREA_H = 880, 800
local VIRT_W, VIRT_H = 1280, 800

local renderCanvas
local renderScale, renderOX, renderOY = 1, 0, 0

local state = {
    player = nil,
    bullets = {},
    emitters = {},
    selectedEmitter = nil,
    draggingEmitter = nil,
    dragOffset = { 0, 0 },
    time = 0,
    paused = false,
    hitCount = 0,
    grazeCount = 0,
    requestReset = false,
    keyboardLayout = "azerty",
    showBackground = true,
    fullscreen = false,

    ui = {
        activeWidget = nil,
        mx = 0, my = 0,
        mouseDown = false,
        mousePressed = false,
        mouseReleased = false,
    },
}

local function resetSimulation()
    state.bullets = {}
    state.time = 0
    state.player.x, state.player.y = AREA_W / 2, AREA_H - 120
    state.player.hitFlash = 0
    state.hitCount = 0
    state.grazeCount = 0
    for _, em in ipairs(state.emitters) do
        em.accum = 0
        em.satAccum = 0   -- Evaccaneer (et tout pattern multi-accumulateurs)
    end
end

local function inPlayArea(x, y)
    return x >= 0 and x <= AREA_W and y >= 0 and y <= AREA_H
end

local function findEmitterAt(x, y)
    for i = #state.emitters, 1, -1 do
        local em = state.emitters[i]
        local dx, dy = x - em.x, y - em.y
        if dx * dx + dy * dy <= 14 * 14 then return i end
    end
    return nil
end

function state.setKeyboardLayout(layout)
    if layout ~= "azerty" and layout ~= "qwerty" then return end
    state.keyboardLayout = layout
    pcall(love.filesystem.write, "layout.txt", layout)
end

local function updateRenderTransform()
    local ww, wh = love.graphics.getDimensions()
    local sx, sy = ww / VIRT_W, wh / VIRT_H
    renderScale = math.min(sx, sy)
    renderOX = (ww - VIRT_W * renderScale) / 2
    renderOY = (wh - VIRT_H * renderScale) / 2
end

local function toVirt(x, y)
    return (x - renderOX) / renderScale, (y - renderOY) / renderScale
end

function state.toggleFullscreen()
    state.fullscreen = not state.fullscreen
    love.window.setFullscreen(state.fullscreen, "desktop")
    updateRenderTransform()
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    renderCanvas = love.graphics.newCanvas(VIRT_W, VIRT_H)
    updateRenderTransform()
    state.player = Player.new(AREA_W / 2, AREA_H - 120)
    table.insert(state.emitters, Emitter.new(Patterns.blueprints[1], AREA_W / 2, 200))
    state.selectedEmitter = 1

    if love.filesystem.getInfo("layout.txt") then
        local ok, saved = pcall(love.filesystem.read, "layout.txt")
        if ok and (saved == "qwerty" or saved == "azerty") then
            state.keyboardLayout = saved
        end
    end
end

function love.resize()
    updateRenderTransform()
end

local function updateBullet(b, dt, target)
    b.age = b.age + dt
    b.life = b.life - dt

    if b.homing then
        if target then
            local desired = math.atan2(target.y - b.y, target.x - b.x)
            local diff = desired - b.angle
            -- normalise dans [-pi, pi]
            diff = math.atan2(math.sin(diff), math.cos(diff))
            local maxRot = b.homing.rate * dt
            if diff > maxRot then diff = maxRot
            elseif diff < -maxRot then diff = -maxRot end
            b.angle = b.angle + diff
            b.vx = math.cos(b.angle) * b.speed
            b.vy = math.sin(b.angle) * b.speed
        end
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
    elseif b.curve then
        b.angle = b.angle + b.curve.rate * dt
        b.vx = math.cos(b.angle) * b.speed
        b.vy = math.sin(b.angle) * b.speed
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
    elseif b.accel then
        local d = b.speed * b.age + 0.5 * b.accel * b.age * b.age
        b.x = b.x0 + b.dirX * d
        b.y = b.y0 + b.dirY * d
    else
        b.x = b.x0 + b.vx * b.age
        b.y = b.y0 + b.vy * b.age
        if b.swing then
            local osc = b.swing.amp * math.sin(b.age * b.swing.freq + b.swing.phase)
            b.x = b.x + b.swing.perpX * osc
            b.y = b.y + b.swing.perpY * osc
        end
    end
end

function love.update(dt)
    local rmx, rmy = love.mouse.getPosition()
    state.ui.mx, state.ui.my = toVirt(rmx, rmy)
    local nowDown = love.mouse.isDown(1)
    state.ui.mousePressed = nowDown and not state.ui.mouseDown
    state.ui.mouseReleased = (not nowDown) and state.ui.mouseDown
    state.ui.mouseDown = nowDown

    if state.requestReset then
        resetSimulation()
        state.requestReset = false
    end

    if state.paused then return end

    state.time = state.time + dt
    state.player:update(dt, AREA_W, AREA_H, state.keyboardLayout)

    for _, em in ipairs(state.emitters) do
        em.blueprint.update(em, dt, state.time, state.bullets, state.player)
    end

    for i = #state.bullets, 1, -1 do
        local b = state.bullets[i]
        updateBullet(b, dt, state.player)
        if b.life <= 0 or b.x < -20 or b.x > AREA_W + 20 or b.y < -20 or b.y > AREA_H + 20 then
            table.remove(state.bullets, i)
        end
    end

    local px, py = state.player.x, state.player.y
    state.player.grazing = false
    for _, b in ipairs(state.bullets) do
        local dx, dy = b.x - px, b.y - py
        local d2 = dx * dx + dy * dy
        local hitR2 = (state.player.radius + b.radius) ^ 2
        local grazeR2 = (state.player.grazeRadius + b.radius) ^ 2
        if d2 < hitR2 then
            if not b._counted then
                state.hitCount = state.hitCount + 1
                b._counted = true
                state.player:onHit()
            end
        elseif d2 < grazeR2 then
            state.player.grazing = true
            if not b._grazed then
                state.grazeCount = state.grazeCount + 1
                b._grazed = true
            end
        end
    end
end

function love.draw()
    love.graphics.setCanvas(renderCanvas)
    love.graphics.clear(0, 0, 0, 1)

    if state.showBackground then
        Background.draw(state.time)
    else
        love.graphics.setColor(0.05, 0.06, 0.09)
        love.graphics.rectangle("fill", 0, 0, AREA_W, AREA_H)
        love.graphics.setColor(0.10, 0.12, 0.16)
        for gx = 0, AREA_W, 80 do love.graphics.line(gx, 0, gx, AREA_H) end
        for gy = 0, AREA_H, 80 do love.graphics.line(0, gy, AREA_W, gy) end
    end

    love.graphics.setScissor(0, 0, AREA_W, AREA_H)

    for i, em in ipairs(state.emitters) do
        -- rendu specifique au blueprint (ex. satellites Evaccaneer) en couche du fond
        if em.blueprint.draw then em.blueprint.draw(em) end

        local sel = (state.selectedEmitter == i)
        if sel then
            love.graphics.setColor(0.4, 0.7, 1.0, 0.25)
            love.graphics.circle("fill", em.x, em.y, 16)
            love.graphics.setColor(0.4, 0.7, 1.0)
        else
            love.graphics.setColor(0.85, 0.75, 0.25)
        end
        love.graphics.circle("line", em.x, em.y, 12)
        love.graphics.circle("fill", em.x, em.y, 3)
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.print(string.format("#%d", i), em.x + 14, em.y - 7)
    end

    for _, b in ipairs(state.bullets) do
        love.graphics.setColor(b.color)
        love.graphics.circle("fill", b.x, b.y, b.radius)
    end
    for _, b in ipairs(state.bullets) do
        love.graphics.setColor(b.color[1], b.color[2], b.color[3], 0.35)
        love.graphics.circle("line", b.x, b.y, b.radius + 1.5)
    end

    state.player:draw()

    love.graphics.setScissor()

    UI.draw(state)

    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(renderCanvas, renderOX, renderOY, 0, renderScale, renderScale)
end

function love.mousepressed(x, y, button)
    x, y = toVirt(x, y)
    if button == 1 and inPlayArea(x, y) and state.ui.activeWidget == nil then
        local idx = findEmitterAt(x, y)
        if idx then
            state.selectedEmitter = idx
            state.draggingEmitter = idx
            state.dragOffset[1] = state.emitters[idx].x - x
            state.dragOffset[2] = state.emitters[idx].y - y
        end
    end
end

function love.mousemoved(x, y)
    x, y = toVirt(x, y)
    if state.draggingEmitter and love.mouse.isDown(1) then
        local em = state.emitters[state.draggingEmitter]
        if em then
            em.x = math.max(20, math.min(AREA_W - 20, x + state.dragOffset[1]))
            em.y = math.max(20, math.min(AREA_H - 20, y + state.dragOffset[2]))
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then state.draggingEmitter = nil end
end

function love.wheelmoved(dx, dy)
    UI.wheelmoved(state, dx, dy)
end

function love.keypressed(key)
    if key == "space" then state.paused = not state.paused; return end
    if key == "r" then state.requestReset = true; return end
    if key == "f11" then state.toggleFullscreen(); return end
    if key == "delete" or key == "backspace" then
        if state.selectedEmitter then
            table.remove(state.emitters, state.selectedEmitter)
            state.selectedEmitter = nil
        end
        return
    end
    if key == "escape" then
        if state.fullscreen then state.toggleFullscreen(); return end
        love.event.quit(); return
    end
end
