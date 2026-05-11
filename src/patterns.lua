local Patterns = {}

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function spawn(bullets, x, y, angle, speed)
    table.insert(bullets, {
        x = x, y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        radius = 4,
        life = 8,
    })
end

----------------------------------------------------------------- Spiral
local spiral = {
    name = "Spiral",
    params = { rate = 30, speed = 180, arms = 3, rotSpeed = 1.5 },
    accum = 0,
}
function spiral.reset() spiral.accum = 0 end
function spiral.update(dt, time, emitter, bullets)
    spiral.accum = spiral.accum + dt
    local interval = 1 / spiral.params.rate
    while spiral.accum >= interval do
        spiral.accum = spiral.accum - interval
        for k = 0, spiral.params.arms - 1 do
            local a = time * spiral.params.rotSpeed + (k * math.pi * 2 / spiral.params.arms)
            spawn(bullets, emitter.x, emitter.y, a, spiral.params.speed)
        end
    end
end
function spiral.keypressed(key)
    local p = spiral.params
    if key == "q" then p.rate = clamp(p.rate - 5, 1, 200) end
    if key == "e" then p.rate = clamp(p.rate + 5, 1, 200) end
    if key == "z" then p.speed = clamp(p.speed - 20, 20, 800) end
    if key == "c" then p.speed = clamp(p.speed + 20, 20, 800) end
    if key == "[" then p.arms = clamp(p.arms - 1, 1, 16) end
    if key == "]" then p.arms = clamp(p.arms + 1, 1, 16) end
    if key == "," then p.rotSpeed = p.rotSpeed - 0.2 end
    if key == "." then p.rotSpeed = p.rotSpeed + 0.2 end
end
function spiral.describe()
    local p = spiral.params
    return string.format("rate=%d/s  speed=%d  arms=%d  rot=%.1f rad/s", p.rate, p.speed, p.arms, p.rotSpeed)
end

----------------------------------------------------------------- Ring
local ring = {
    name = "Ring",
    params = { interval = 1.0, count = 24, speed = 200 },
    accum = 0,
}
function ring.reset() ring.accum = 0 end
function ring.update(dt, time, emitter, bullets)
    ring.accum = ring.accum + dt
    if ring.accum >= ring.params.interval then
        ring.accum = ring.accum - ring.params.interval
        for k = 0, ring.params.count - 1 do
            local a = (k / ring.params.count) * math.pi * 2
            spawn(bullets, emitter.x, emitter.y, a, ring.params.speed)
        end
    end
end
function ring.keypressed(key)
    local p = ring.params
    if key == "q" then p.interval = clamp(p.interval - 0.1, 0.1, 5) end
    if key == "e" then p.interval = clamp(p.interval + 0.1, 0.1, 5) end
    if key == "z" then p.speed = clamp(p.speed - 20, 20, 800) end
    if key == "c" then p.speed = clamp(p.speed + 20, 20, 800) end
    if key == "[" then p.count = clamp(p.count - 2, 2, 64) end
    if key == "]" then p.count = clamp(p.count + 2, 2, 64) end
end
function ring.describe()
    local p = ring.params
    return string.format("interval=%.1fs  count=%d  speed=%d", p.interval, p.count, p.speed)
end

----------------------------------------------------------------- Fan oscillant
local fan = {
    name = "Fan oscillant",
    params = { rate = 25, speed = 220, spread = 1.0, count = 5, sway = 0.6 },
    accum = 0,
}
function fan.reset() fan.accum = 0 end
function fan.update(dt, time, emitter, bullets)
    fan.accum = fan.accum + dt
    local interval = 1 / fan.params.rate
    while fan.accum >= interval do
        fan.accum = fan.accum - interval
        local center = math.pi / 2 + math.sin(time * 1.5) * fan.params.sway
        local n = fan.params.count
        for k = 0, n - 1 do
            local t = (n == 1) and 0.5 or (k / (n - 1))
            local a = center + (t - 0.5) * fan.params.spread
            spawn(bullets, emitter.x, emitter.y, a, fan.params.speed)
        end
    end
end
function fan.keypressed(key)
    local p = fan.params
    if key == "q" then p.rate = clamp(p.rate - 5, 1, 200) end
    if key == "e" then p.rate = clamp(p.rate + 5, 1, 200) end
    if key == "z" then p.speed = clamp(p.speed - 20, 20, 800) end
    if key == "c" then p.speed = clamp(p.speed + 20, 20, 800) end
    if key == "[" then p.count = clamp(p.count - 1, 1, 16) end
    if key == "]" then p.count = clamp(p.count + 1, 1, 16) end
    if key == "," then p.spread = clamp(p.spread - 0.1, 0.1, math.pi) end
    if key == "." then p.spread = clamp(p.spread + 0.1, 0.1, math.pi) end
end
function fan.describe()
    local p = fan.params
    return string.format("rate=%d/s  speed=%d  count=%d  spread=%.1f rad", p.rate, p.speed, p.count, p.spread)
end

----------------------------------------------------------------- Aimed (vise le joueur)
local aimed = {
    name = "Aimed",
    params = { rate = 8, speed = 240, spread = 0.3, count = 3 },
    accum = 0,
}
function aimed.reset() aimed.accum = 0 end
function aimed.update(dt, time, emitter, bullets)
    aimed.accum = aimed.accum + dt
    local interval = 1 / aimed.params.rate
    while aimed.accum >= interval do
        aimed.accum = aimed.accum - interval
        local target = emitter.target
        if not target then return end
        local center = math.atan2(target.y - emitter.y, target.x - emitter.x)
        local n = aimed.params.count
        for k = 0, n - 1 do
            local t = (n == 1) and 0.5 or (k / (n - 1))
            local a = center + (t - 0.5) * aimed.params.spread
            spawn(bullets, emitter.x, emitter.y, a, aimed.params.speed)
        end
    end
end
function aimed.keypressed(key)
    local p = aimed.params
    if key == "q" then p.rate = clamp(p.rate - 1, 1, 60) end
    if key == "e" then p.rate = clamp(p.rate + 1, 1, 60) end
    if key == "z" then p.speed = clamp(p.speed - 20, 20, 800) end
    if key == "c" then p.speed = clamp(p.speed + 20, 20, 800) end
    if key == "[" then p.count = clamp(p.count - 1, 1, 8) end
    if key == "]" then p.count = clamp(p.count + 1, 1, 8) end
    if key == "," then p.spread = clamp(p.spread - 0.05, 0, math.pi / 2) end
    if key == "." then p.spread = clamp(p.spread + 0.05, 0, math.pi / 2) end
end
function aimed.describe()
    local p = aimed.params
    return string.format("rate=%d/s  speed=%d  count=%d  spread=%.2f rad", p.rate, p.speed, p.count, p.spread)
end

function Patterns.list()
    return { spiral, ring, fan, aimed }
end

return Patterns
