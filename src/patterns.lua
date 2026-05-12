local Patterns = {}

local function hsv2rgb(h, s, v)
    h = (h % 1) * 6
    local i = math.floor(h)
    local f = h - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end

local function computeColor(em, time)
    local pr = em.params
    local h
    if pr.rainbow and pr.rainbow > 0.5 then
        h = (time * (pr.rainbowSpeed or 1)) % 1
    else
        h = ((pr.hue or 30) / 360) % 1
    end
    local s = pr.saturation or 1
    local v = pr.brightness or 1
    local r, g, b = hsv2rgb(h, s, v)
    return { r, g, b, 1 }
end

-- spawn(em, bullets, x, y, angle, speed, time, [opts])
-- opts.swingAmp/Freq/Phase  : ondulation perpendiculaire
-- opts.curveRate            : rotation continue (rad/s) -> trajectoire en arc
-- opts.accel                : acceleration tangentielle (px/s²)
-- opts.homingRate           : steering vers state.player (rad/s, doux)
local function spawn(em, bullets, x, y, angle, speed, time, opts)
    opts = opts or {}
    local b = {
        x = x, y = y,
        x0 = x, y0 = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        angle = angle,
        speed = speed,
        dirX = math.cos(angle),
        dirY = math.sin(angle),
        age = 0,
        radius = 4,
        life = 8,
        color = computeColor(em, time),
    }
    if opts.swingAmp and opts.swingFreq and opts.swingAmp > 0 and opts.swingFreq > 0 then
        b.swing = {
            amp = opts.swingAmp,
            freq = opts.swingFreq,
            phase = opts.swingPhase or 0,
            perpX = -math.sin(angle),
            perpY = math.cos(angle),
        }
    end
    if opts.curveRate and opts.curveRate ~= 0 then
        b.curve = { rate = opts.curveRate }
    end
    if opts.accel and opts.accel ~= 0 then
        b.accel = opts.accel
    end
    if opts.homingRate and opts.homingRate > 0 then
        b.homing = { rate = opts.homingRate }
    end
    bullets[#bullets + 1] = b
end

local function withColorDefaults(t, hue)
    t.hue = hue or 30
    t.saturation = 1
    t.brightness = 1
    t.rainbow = 0
    t.rainbowSpeed = 1
    return t
end

local function withColorSpecs(specs)
    specs[#specs + 1] = { name = "hue",         min = 0,    max = 360, step = 1,    label = "Hue (couleur)" }
    specs[#specs + 1] = { name = "saturation",  min = 0,    max = 1,   step = 0.05, label = "Saturation" }
    specs[#specs + 1] = { name = "brightness",  min = 0,    max = 1,   step = 0.05, label = "Brightness" }
    specs[#specs + 1] = { name = "rainbow",     min = 0,    max = 1,   step = 1,    label = "Rainbow",       kind = "toggle" }
    specs[#specs + 1] = { name = "rainbowSpeed",min = 0.1,  max = 5,   step = 0.1,  label = "Rainbow speed" }
    return specs
end

Patterns.blueprints = {

    --------------------------------------------- 1. Spiral
    {
        name = "Spiral",
        defaultParams = withColorDefaults(
            { rate = 30, speed = 180, arms = 3, rotSpeed = 1.5 }, 195),
        paramSpecs = withColorSpecs({
            { name = "rate",     min = 1,  max = 200, step = 1,   label = "Rate (b/s)" },
            { name = "speed",    min = 20, max = 800, step = 5,   label = "Speed" },
            { name = "arms",     min = 1,  max = 16,  step = 1,   label = "Arms" },
            { name = "rotSpeed", min = -5, max = 5,   step = 0.1, label = "Rotation (rad/s)" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                for k = 0, pr.arms - 1 do
                    local a = time * pr.rotSpeed + (k * math.pi * 2 / pr.arms)
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time)
                end
            end
        end,
    },

    --------------------------------------------- 2. Ring
    {
        name = "Ring",
        defaultParams = withColorDefaults(
            { interval = 1.0, count = 24, speed = 200, baseAngle = 0 }, 45),
        paramSpecs = withColorSpecs({
            { name = "interval",  min = 0.1, max = 5,         step = 0.1,  label = "Intervalle (s)" },
            { name = "count",     min = 2,   max = 64,        step = 1,    label = "Count" },
            { name = "speed",     min = 20,  max = 800,       step = 5,    label = "Speed" },
            { name = "baseAngle", min = 0,   max = math.pi*2, step = 0.05, label = "Phase (rad)" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            if em.accum >= pr.interval then
                em.accum = em.accum - pr.interval
                for k = 0, pr.count - 1 do
                    local a = pr.baseAngle + (k / pr.count) * math.pi * 2
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time)
                end
            end
        end,
    },

    --------------------------------------------- 3. Fan oscillant
    {
        name = "Fan oscillant",
        defaultParams = withColorDefaults(
            { rate = 25, speed = 220, count = 5, spread = 1.0, sway = 0.6, swaySpeed = 1.5, baseAngle = math.pi/2 }, 120),
        paramSpecs = withColorSpecs({
            { name = "rate",      min = 1,    max = 200,        step = 1,    label = "Rate (b/s)" },
            { name = "speed",     min = 20,   max = 800,        step = 5,    label = "Speed" },
            { name = "count",     min = 1,    max = 16,         step = 1,    label = "Count" },
            { name = "spread",    min = 0.05, max = math.pi,    step = 0.05, label = "Spread (rad)" },
            { name = "sway",      min = 0,    max = 2,          step = 0.05, label = "Sway amp" },
            { name = "swaySpeed", min = 0,    max = 5,          step = 0.1,  label = "Sway speed" },
            { name = "baseAngle", min = 0,    max = math.pi*2,  step = 0.05, label = "Angle base (rad)" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local center = pr.baseAngle + math.sin(time * pr.swaySpeed) * pr.sway
                local n = pr.count
                for k = 0, n - 1 do
                    local t = (n == 1) and 0.5 or (k / (n - 1))
                    local a = center + (t - 0.5) * pr.spread
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time)
                end
            end
        end,
    },

    --------------------------------------------- 4. Aimed
    {
        name = "Aimed",
        defaultParams = withColorDefaults(
            { rate = 8, speed = 240, count = 3, spread = 0.3 }, 0),
        paramSpecs = withColorSpecs({
            { name = "rate",   min = 1,   max = 60,         step = 1,    label = "Rate (b/s)" },
            { name = "speed",  min = 20,  max = 800,        step = 5,    label = "Speed" },
            { name = "count",  min = 1,   max = 8,          step = 1,    label = "Count" },
            { name = "spread", min = 0,   max = math.pi/2,  step = 0.05, label = "Spread (rad)" },
        }),
        update = function(em, dt, time, bullets, target)
            if not target then return end
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local center = math.atan2(target.y - em.y, target.x - em.x)
                local n = pr.count
                for k = 0, n - 1 do
                    local t = (n == 1) and 0.5 or (k / (n - 1))
                    local a = center + (t - 0.5) * pr.spread
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time)
                end
            end
        end,
    },

    --------------------------------------------- 5. Wave
    {
        name = "Wave",
        defaultParams = withColorDefaults(
            { rate = 30, speed = 220, count = 3, spread = 0.6, swingAmp = 60, swingFreq = 6, baseAngle = math.pi/2 }, 260),
        paramSpecs = withColorSpecs({
            { name = "rate",      min = 1,   max = 100,       step = 1,    label = "Rate (b/s)" },
            { name = "speed",     min = 20,  max = 600,       step = 5,    label = "Speed" },
            { name = "count",     min = 1,   max = 8,         step = 1,    label = "Count" },
            { name = "spread",    min = 0,   max = math.pi,   step = 0.05, label = "Spread (rad)" },
            { name = "swingAmp",  min = 0,   max = 200,       step = 5,    label = "Wave amplitude" },
            { name = "swingFreq", min = 0.5, max = 20,        step = 0.2,  label = "Wave frequence" },
            { name = "baseAngle", min = 0,   max = math.pi*2, step = 0.05, label = "Angle base" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local n = pr.count
                for k = 0, n - 1 do
                    local t = (n == 1) and 0.5 or (k / (n - 1))
                    local a = pr.baseAngle + (t - 0.5) * pr.spread
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time, {
                        swingAmp = pr.swingAmp,
                        swingFreq = pr.swingFreq,
                        swingPhase = (k * math.pi) / math.max(1, n),
                    })
                end
            end
        end,
    },

    --------------------------------------------- 6. Twin Spiral
    {
        name = "Twin Spiral",
        defaultParams = withColorDefaults(
            { rate = 30, speed = 180, arms = 3, rotSpeed = 1.5 }, 300),
        paramSpecs = withColorSpecs({
            { name = "rate",     min = 1,  max = 200, step = 1,   label = "Rate (b/s)" },
            { name = "speed",    min = 20, max = 800, step = 5,   label = "Speed" },
            { name = "arms",     min = 1,  max = 12,  step = 1,   label = "Arms / sens" },
            { name = "rotSpeed", min = 0,  max = 5,   step = 0.1, label = "Rotation speed" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                for k = 0, pr.arms - 1 do
                    local base = (k * math.pi * 2 / pr.arms)
                    spawn(em, bullets, em.x, em.y,  time * pr.rotSpeed + base, pr.speed, time)
                    spawn(em, bullets, em.x, em.y, -time * pr.rotSpeed + base, pr.speed, time)
                end
            end
        end,
    },

    --------------------------------------------- 7. Shotgun
    {
        name = "Shotgun",
        defaultParams = withColorDefaults(
            { rate = 3, speed = 280, count = 8, spread = 0.7, aimed = 1 }, 330),
        paramSpecs = withColorSpecs({
            { name = "rate",   min = 0.5, max = 20,        step = 0.1,  label = "Bursts / s" },
            { name = "speed",  min = 20,  max = 800,       step = 5,    label = "Speed" },
            { name = "count",  min = 2,   max = 32,        step = 1,    label = "Bullets / burst" },
            { name = "spread", min = 0.1, max = math.pi,   step = 0.05, label = "Spread (rad)" },
            { name = "aimed",  min = 0,   max = 1,         step = 1,    label = "Vise le joueur",  kind = "toggle" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local center = math.pi / 2
                if pr.aimed > 0.5 and target then
                    center = math.atan2(target.y - em.y, target.x - em.x)
                end
                for _ = 1, pr.count do
                    local a = center + (math.random() - 0.5) * pr.spread
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time)
                end
            end
        end,
    },

    --------------------------------------------- 8. Petal
    {
        name = "Petal",
        defaultParams = withColorDefaults(
            { rate = 24, speed = 180, petals = 5, fanCount = 3, fanSpread = 0.4, rotSpeed = 0.8 }, 150),
        paramSpecs = withColorSpecs({
            { name = "rate",      min = 1,   max = 100, step = 1,    label = "Rate (b/s)" },
            { name = "speed",     min = 20,  max = 600, step = 5,    label = "Speed" },
            { name = "petals",    min = 2,   max = 12,  step = 1,    label = "Petales" },
            { name = "fanCount",  min = 1,   max = 8,   step = 1,    label = "Bullets / petale" },
            { name = "fanSpread", min = 0,   max = 1,   step = 0.02, label = "Spread petale" },
            { name = "rotSpeed",  min = -3,  max = 3,   step = 0.05, label = "Rotation" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local rot = time * pr.rotSpeed
                for petal = 0, pr.petals - 1 do
                    local center = rot + petal * math.pi * 2 / pr.petals
                    local n = pr.fanCount
                    for k = 0, n - 1 do
                        local t = (n == 1) and 0.5 or (k / (n - 1))
                        local a = center + (t - 0.5) * pr.fanSpread
                        spawn(em, bullets, em.x, em.y, a, pr.speed, time)
                    end
                end
            end
        end,
    },

    --------------------------------------------- 9. Curve (bullets en arc)
    {
        name = "Curve",
        defaultParams = withColorDefaults(
            { rate = 25, speed = 200, count = 8, baseAngle = 0, curveRate = 1.5 }, 220),
        paramSpecs = withColorSpecs({
            { name = "rate",      min = 1,  max = 200,       step = 1,    label = "Rate (b/s)" },
            { name = "speed",     min = 20, max = 600,       step = 5,    label = "Speed" },
            { name = "count",     min = 1,  max = 16,        step = 1,    label = "Count" },
            { name = "baseAngle", min = 0,  max = math.pi*2, step = 0.05, label = "Angle base" },
            { name = "curveRate", min = -3, max = 3,         step = 0.05, label = "Curve rate (rad/s)" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local n = pr.count
                for k = 0, n - 1 do
                    local a = pr.baseAngle + (k / n) * math.pi * 2
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time, { curveRate = pr.curveRate })
                end
            end
        end,
    },

    --------------------------------------------- 10. Accel (Cave-style)
    {
        name = "Accel",
        defaultParams = withColorDefaults(
            { rate = 8, speed = 50, accel = 200, count = 5, spread = 0.6, baseAngle = math.pi/2 }, 30),
        paramSpecs = withColorSpecs({
            { name = "rate",      min = 1,    max = 50,         step = 1,    label = "Rate (b/s)" },
            { name = "speed",     min = 0,    max = 400,        step = 5,    label = "Vitesse initiale" },
            { name = "accel",     min = -200, max = 600,        step = 5,    label = "Acceleration" },
            { name = "count",     min = 1,    max = 12,         step = 1,    label = "Count" },
            { name = "spread",    min = 0,    max = math.pi,    step = 0.05, label = "Spread (rad)" },
            { name = "baseAngle", min = 0,    max = math.pi*2,  step = 0.05, label = "Angle base" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local n = pr.count
                for k = 0, n - 1 do
                    local t = (n == 1) and 0.5 or (k / (n - 1))
                    local a = pr.baseAngle + (t - 0.5) * pr.spread
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time, { accel = pr.accel })
                end
            end
        end,
    },

    --------------------------------------------- 11. Homing (vise mais doux)
    {
        name = "Homing",
        defaultParams = withColorDefaults(
            { rate = 4, speed = 180, count = 3, spread = 1.5, homingRate = 1.0, baseAngle = math.pi/2 }, 90),
        paramSpecs = withColorSpecs({
            { name = "rate",       min = 0.5, max = 20,         step = 0.1,  label = "Rate (b/s)" },
            { name = "speed",      min = 20,  max = 400,        step = 5,    label = "Speed" },
            { name = "count",      min = 1,   max = 8,          step = 1,    label = "Count" },
            { name = "spread",     min = 0,   max = math.pi*2,  step = 0.05, label = "Spread initial" },
            { name = "homingRate", min = 0,   max = 5,          step = 0.05, label = "Homing rate (rad/s)" },
            { name = "baseAngle",  min = 0,   max = math.pi*2,  step = 0.05, label = "Angle base" },
        }),
        update = function(em, dt, time, bullets, target)
            em.accum = em.accum + dt
            local pr = em.params
            local interval = 1 / pr.rate
            while em.accum >= interval do
                em.accum = em.accum - interval
                local n = pr.count
                for k = 0, n - 1 do
                    local t = (n == 1) and 0.5 or (k / (n - 1))
                    local a = pr.baseAngle + (t - 0.5) * pr.spread
                    spawn(em, bullets, em.x, em.y, a, pr.speed, time, { homingRate = pr.homingRate })
                end
            end
        end,
    },

    --------------------------------------------- 12. Evaccaneer Doom (Ketsui — boss + satellites)
    -- Boss central qui tire des rings + N satellites qui orbitent et tirent en aimed.
    -- Les satellites sont visibles (petits cercles oranges relies au boss).
    {
        name = "Evaccaneer",
        defaultParams = withColorDefaults({
            ringInterval = 1.5,    -- s entre deux rings du boss
            ringCount = 20,        -- bullets par ring
            ringSpeed = 130,
            satCount = 4,          -- nombre de satellites
            orbitRadius = 90,
            orbitSpeed = 0.6,      -- rad/s
            satRate = 4,           -- tirs/s par satellite
            satSpeed = 240,
            satFanCount = 1,       -- bullets par tir de satellite
            satFanSpread = 0.2,
            satAimed = 1,          -- 0 = tangentiel a l'orbite, 1 = vise le joueur
        }, 195),                   -- cyan signature Ketsui
        paramSpecs = withColorSpecs({
            { name = "ringInterval", min = 0.2, max = 5,         step = 0.1,  label = "Ring interval (s)" },
            { name = "ringCount",    min = 4,   max = 48,        step = 1,    label = "Ring bullets" },
            { name = "ringSpeed",    min = 20,  max = 500,       step = 5,    label = "Ring speed" },
            { name = "satCount",     min = 0,   max = 8,         step = 1,    label = "Satellites" },
            { name = "orbitRadius",  min = 30,  max = 200,       step = 5,    label = "Orbit radius" },
            { name = "orbitSpeed",   min = -3,  max = 3,         step = 0.1,  label = "Orbit speed (rad/s)" },
            { name = "satRate",      min = 0.5, max = 20,        step = 0.1,  label = "Satellite rate" },
            { name = "satSpeed",     min = 20,  max = 600,       step = 5,    label = "Satellite speed" },
            { name = "satFanCount",  min = 1,   max = 8,         step = 1,    label = "Sat. fan count" },
            { name = "satFanSpread", min = 0,   max = 1,         step = 0.05, label = "Sat. fan spread" },
            { name = "satAimed",     min = 0,   max = 1,         step = 1,    label = "Sat. vise joueur",  kind = "toggle" },
        }),
        update = function(em, dt, time, bullets, target)
            local pr = em.params

            -- positions des satellites recalculees a chaque frame
            em.satellites = {}
            local n = pr.satCount
            for k = 0, n - 1 do
                local a = time * pr.orbitSpeed + (k * math.pi * 2 / n)
                em.satellites[k + 1] = {
                    x = em.x + math.cos(a) * pr.orbitRadius,
                    y = em.y + math.sin(a) * pr.orbitRadius,
                    angle = a,
                }
            end

            -- ring central du boss
            em.accum = em.accum + dt
            if em.accum >= pr.ringInterval then
                em.accum = em.accum - pr.ringInterval
                for k = 0, pr.ringCount - 1 do
                    local a = (k / pr.ringCount) * math.pi * 2
                    spawn(em, bullets, em.x, em.y, a, pr.ringSpeed, time)
                end
            end

            -- tir des satellites (chacun fait son intervalle)
            em.satAccum = (em.satAccum or 0) + dt
            local satInterval = 1 / pr.satRate
            while em.satAccum >= satInterval do
                em.satAccum = em.satAccum - satInterval
                for _, sat in ipairs(em.satellites) do
                    local center
                    if pr.satAimed > 0.5 and target then
                        center = math.atan2(target.y - sat.y, target.x - sat.x)
                    else
                        -- tangentiel a l'orbite (perpendiculaire au rayon)
                        center = sat.angle + math.pi / 2
                    end
                    local nf = pr.satFanCount
                    for j = 0, nf - 1 do
                        local t = (nf == 1) and 0.5 or (j / (nf - 1))
                        local a = center + (t - 0.5) * pr.satFanSpread
                        spawn(em, bullets, sat.x, sat.y, a, pr.satSpeed, time)
                    end
                end
            end
        end,

        -- rendu des satellites (appele par main.lua si la fonction existe)
        draw = function(em)
            if not em.satellites or #em.satellites == 0 then return end
            for _, sat in ipairs(em.satellites) do
                love.graphics.setColor(1, 0.55, 0.15, 0.18)
                love.graphics.line(em.x, em.y, sat.x, sat.y)
                love.graphics.setColor(1, 0.65, 0.20, 0.30)
                love.graphics.circle("fill", sat.x, sat.y, 9)
                love.graphics.setColor(1, 0.75, 0.30, 1.0)
                love.graphics.circle("fill", sat.x, sat.y, 5)
                love.graphics.setColor(1, 0.85, 0.50, 0.85)
                love.graphics.circle("line", sat.x, sat.y, 9)
            end
        end,
    },
}

return Patterns
