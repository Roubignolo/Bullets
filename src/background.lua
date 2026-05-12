local Background = {}

local AREA_W, AREA_H = 880, 800
local stars = {}
local nebulas = {}
local initialized = false

local function rand(min, max) return min + math.random() * (max - min) end

local function generate()
    math.randomseed(424242)
    stars = {}
    for _ = 1, 220 do
        table.insert(stars, {
            x = rand(0, AREA_W),
            y = rand(0, AREA_H),
            r = rand(0.4, 1.6),
            b = rand(0.45, 1.0),
            tint = rand(0, 1),
            twinklePhase = rand(0, math.pi * 2),
            twinkleSpeed = rand(0.6, 2.2),
        })
    end
    for _ = 1, 18 do
        table.insert(stars, {
            x = rand(0, AREA_W),
            y = rand(0, AREA_H),
            r = rand(1.8, 2.6),
            b = rand(0.7, 1.0),
            tint = rand(0, 1),
            twinklePhase = rand(0, math.pi * 2),
            twinkleSpeed = rand(0.4, 1.2),
            bright = true,
        })
    end
    nebulas = {
        { x = AREA_W * 0.25, y = AREA_H * 0.30, r = 280, color = { 0.30, 0.10, 0.45 } },
        { x = AREA_W * 0.78, y = AREA_H * 0.55, r = 320, color = { 0.10, 0.20, 0.50 } },
        { x = AREA_W * 0.45, y = AREA_H * 0.82, r = 240, color = { 0.45, 0.15, 0.35 } },
    }
    initialized = true
end

function Background.draw(time)
    if not initialized then generate() end

    love.graphics.setColor(0.02, 0.02, 0.05)
    love.graphics.rectangle("fill", 0, 0, AREA_W, AREA_H)

    for _, n in ipairs(nebulas) do
        for i = 6, 1, -1 do
            local a = 0.05 * (i / 6)
            love.graphics.setColor(n.color[1], n.color[2], n.color[3], a)
            love.graphics.circle("fill", n.x, n.y, n.r * (i / 6))
        end
    end

    for _, s in ipairs(stars) do
        local tw = 0.75 + 0.25 * math.sin((time or 0) * s.twinkleSpeed + s.twinklePhase)
        local b = s.b * tw
        local r, g, bl
        if s.tint < 0.5 then
            r, g, bl = b, b, b
        elseif s.tint < 0.75 then
            r, g, bl = b * 0.85, b * 0.90, b
        else
            r, g, bl = b, b * 0.85, b * 0.75
        end
        love.graphics.setColor(r, g, bl)
        love.graphics.circle("fill", s.x, s.y, s.r)
        if s.bright then
            love.graphics.setColor(r, g, bl, 0.25)
            love.graphics.circle("fill", s.x, s.y, s.r * 2.5)
        end
    end
end

return Background
