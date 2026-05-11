local Patterns = {}

local function spawn(bullets, x, y, angle, speed)
    table.insert(bullets, {
        x = x, y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        radius = 4,
        life = 8,
    })
end

Patterns.blueprints = {

    {
        name = "Spiral",
        defaultParams = { rate = 30, speed = 180, arms = 3, rotSpeed = 1.5 },
        paramSpecs = {
            { name = "rate",     min = 1,   max = 200, step = 1,   label = "Rate (b/s)" },
            { name = "speed",    min = 20,  max = 800, step = 5,   label = "Speed (px/s)" },
            { name = "arms",     min = 1,   max = 16,  step = 1,   label = "Arms" },
            { name = "rotSpeed", min = -5,  max = 5,   step = 0.1, label = "Rotation (rad/s)" },
        },
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local p = em.params
            local interval = 1 / p.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                for k = 0, p.arms - 1 do
                    local a = time * p.rotSpeed + (k * math.pi * 2 / p.arms)
                    spawn(bullets, em.x, em.y, a, p.speed)
                end
            end
        end,
    },

    {
        name = "Ring",
        defaultParams = { interval = 1.0, count = 24, speed = 200, baseAngle = 0 },
        paramSpecs = {
            { name = "interval",  min = 0.1, max = 5,         step = 0.1,  label = "Interval (s)" },
            { name = "count",     min = 2,   max = 64,        step = 1,    label = "Count" },
            { name = "speed",     min = 20,  max = 800,       step = 5,    label = "Speed (px/s)" },
            { name = "baseAngle", min = 0,   max = math.pi*2, step = 0.05, label = "Phase (rad)" },
        },
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local p = em.params
            if em.accum >= p.interval then
                em.accum = em.accum - p.interval
                for k = 0, p.count - 1 do
                    local a = p.baseAngle + (k / p.count) * math.pi * 2
                    spawn(bullets, em.x, em.y, a, p.speed)
                end
            end
        end,
    },

    {
        name = "Fan oscillant",
        defaultParams = { rate = 25, speed = 220, count = 5, spread = 1.0, sway = 0.6, swaySpeed = 1.5, baseAngle = math.pi / 2 },
        paramSpecs = {
            { name = "rate",      min = 1,    max = 200,        step = 1,    label = "Rate (b/s)" },
            { name = "speed",     min = 20,   max = 800,        step = 5,    label = "Speed (px/s)" },
            { name = "count",     min = 1,    max = 16,         step = 1,    label = "Count" },
            { name = "spread",    min = 0.05, max = math.pi,    step = 0.05, label = "Spread (rad)" },
            { name = "sway",      min = 0,    max = 2,          step = 0.05, label = "Sway amplitude" },
            { name = "swaySpeed", min = 0,    max = 5,          step = 0.1,  label = "Sway speed" },
            { name = "baseAngle", min = 0,    max = math.pi*2,  step = 0.05, label = "Base angle (rad)" },
        },
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local p = em.params
            local interval = 1 / p.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local center = p.baseAngle + math.sin(time * p.swaySpeed) * p.sway
                local n = p.count
                for k = 0, n - 1 do
                    local t = (n == 1) and 0.5 or (k / (n - 1))
                    local a = center + (t - 0.5) * p.spread
                    spawn(bullets, em.x, em.y, a, p.speed)
                end
            end
        end,
    },

    {
        name = "Aimed",
        defaultParams = { rate = 8, speed = 240, count = 3, spread = 0.3 },
        paramSpecs = {
            { name = "rate",   min = 1,   max = 60,         step = 1,    label = "Rate (b/s)" },
            { name = "speed",  min = 20,  max = 800,        step = 5,    label = "Speed (px/s)" },
            { name = "count",  min = 1,   max = 8,          step = 1,    label = "Count" },
            { name = "spread", min = 0,   max = math.pi/2,  step = 0.05, label = "Spread (rad)" },
        },
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local p = em.params
            local interval = 1 / p.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                if not target then return end
                local center = math.atan2(target.y - em.y, target.x - em.x)
                local n = p.count
                for k = 0, n - 1 do
                    local t = (n == 1) and 0.5 or (k / (n - 1))
                    local a = center + (t - 0.5) * p.spread
                    spawn(bullets, em.x, em.y, a, p.speed)
                end
            end
        end,
    },
}

return Patterns
