local Player = require("src.player")
local Patterns = require("src.patterns")
local UI = require("src.ui")

local W, H = 1024, 768

local state = {
    player = nil,
    bullets = {},
    patterns = {},
    currentPattern = 1,
    emitter = { x = W / 2, y = 200 },
    time = 0,
    paused = false,
    hitFlash = 0,
}

local function resetSimulation()
    state.bullets = {}
    state.time = 0
    state.player.x, state.player.y = W / 2, H - 120
    for _, p in ipairs(state.patterns) do
        if p.reset then p.reset() end
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    state.player = Player.new(W / 2, H - 120)
    state.patterns = Patterns.list()
end

function love.update(dt)
    if state.paused then return end

    state.time = state.time + dt
    state.player:update(dt, W, H)
    state.emitter.target = state.player

    local pat = state.patterns[state.currentPattern]
    pat.update(dt, state.time, state.emitter, state.bullets)

    for i = #state.bullets, 1, -1 do
        local b = state.bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 or b.x < -20 or b.x > W + 20 or b.y < -20 or b.y > H + 20 then
            table.remove(state.bullets, i)
        end
    end

    local px, py, pr = state.player.x, state.player.y, state.player.radius
    for _, b in ipairs(state.bullets) do
        local dx, dy = b.x - px, b.y - py
        if dx * dx + dy * dy < (pr + b.radius) ^ 2 then
            state.hitFlash = 0.18
            break
        end
    end
    state.hitFlash = math.max(0, state.hitFlash - dt)
end

function love.draw()
    love.graphics.clear(0.05, 0.06, 0.09)

    love.graphics.setColor(0.85, 0.75, 0.25)
    love.graphics.circle("line", state.emitter.x, state.emitter.y, 10)
    love.graphics.circle("fill", state.emitter.x, state.emitter.y, 3)

    love.graphics.setColor(1, 0.45, 0.2)
    for _, b in ipairs(state.bullets) do
        love.graphics.circle("fill", b.x, b.y, b.radius)
    end

    state.player:draw(state.hitFlash > 0)
    UI.draw(state)
end

function love.keypressed(key)
    local n = tonumber(key)
    if n and n >= 1 and n <= #state.patterns then
        state.currentPattern = n
        resetSimulation()
        return
    end

    if key == "space" then state.paused = not state.paused; return end
    if key == "r" then resetSimulation(); return end
    if key == "escape" then love.event.quit(); return end

    local pat = state.patterns[state.currentPattern]
    if pat.keypressed then pat.keypressed(key) end
end
