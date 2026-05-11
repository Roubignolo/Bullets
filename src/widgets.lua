local Widgets = {}

local function pointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function setColor(r, g, b, a)
    love.graphics.setColor(r, g, b, a or 1)
end

----------------------------------------------------------------- Button
function Widgets.button(ui, id, x, y, w, h, label, opts)
    opts = opts or {}

    if opts.disabled then
        love.graphics.setColor(0.10, 0.12, 0.16)
        love.graphics.rectangle("fill", x, y, w, h, 4, 4)
        love.graphics.setColor(0.20, 0.22, 0.28)
        love.graphics.rectangle("line", x, y, w, h, 4, 4)
        love.graphics.setColor(0.40, 0.42, 0.48)
        local font = love.graphics.getFont()
        local tw = font:getWidth(label)
        local th = font:getHeight()
        love.graphics.print(label, x + (w - tw) / 2, y + (h - th) / 2)
        return false
    end

    local hovered = pointInRect(ui.mx, ui.my, x, y, w, h)
    local active = ui.activeWidget == id

    if hovered and ui.mousePressed and ui.activeWidget == nil then
        ui.activeWidget = id
        active = true
    end

    local clicked = false
    if active and not ui.mouseDown then
        if hovered then clicked = true end
        ui.activeWidget = nil
    end

    local r, g, b
    if opts.danger then
        if active then r, g, b = 0.55, 0.20, 0.20
        elseif hovered then r, g, b = 0.45, 0.18, 0.18
        else r, g, b = 0.28, 0.12, 0.12 end
    elseif opts.selected then
        r, g, b = 0.20, 0.45, 0.65
    else
        if active then r, g, b = 0.30, 0.40, 0.50
        elseif hovered then r, g, b = 0.22, 0.28, 0.36
        else r, g, b = 0.16, 0.18, 0.24 end
    end
    setColor(r, g, b)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    setColor(0.32, 0.40, 0.50)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)

    setColor(0.95, 0.95, 1.0)
    local font = love.graphics.getFont()
    local tw = font:getWidth(label)
    local th = font:getHeight()
    love.graphics.print(label, x + (w - tw) / 2, y + (h - th) / 2)

    return clicked
end

----------------------------------------------------------------- Toggle
function Widgets.toggle(ui, id, x, y, w, h, label, value)
    local on = value > 0.5
    local btn = label .. " : " .. (on and "ON" or "OFF")
    if Widgets.button(ui, id, x, y, w, h, btn, { selected = on }) then
        return on and 0 or 1
    end
    return value
end

----------------------------------------------------------------- Slider
function Widgets.slider(ui, id, x, y, w, label, value, min, max, step)
    local trackY = y + 6
    local handleR = 7

    local hitX, hitY, hitW, hitH = x - 4, y - 4, w + 8, 24
    local hovered = pointInRect(ui.mx, ui.my, hitX, hitY, hitW, hitH)

    if hovered and ui.mousePressed and ui.activeWidget == nil then
        ui.activeWidget = id
    end

    if ui.activeWidget == id then
        if not ui.mouseDown then
            ui.activeWidget = nil
        else
            local t = (ui.mx - x) / w
            t = math.max(0, math.min(1, t))
            value = min + t * (max - min)
            if step and step > 0 then
                value = math.floor((value - min) / step + 0.5) * step + min
            end
            value = math.max(min, math.min(max, value))
        end
    end

    setColor(0.85, 0.88, 0.95)
    local valStr
    if step and step >= 1 then
        valStr = tostring(math.floor(value + 0.5))
    else
        valStr = string.format("%.2f", value)
    end
    love.graphics.print(label, x, y - 16)
    local font = love.graphics.getFont()
    love.graphics.print(valStr, x + w - font:getWidth(valStr), y - 16)

    setColor(0.16, 0.18, 0.24)
    love.graphics.rectangle("fill", x, trackY, w, 4, 2, 2)

    local span = max - min
    local t = span > 0 and (value - min) / span or 0
    setColor(0.40, 0.62, 0.85)
    love.graphics.rectangle("fill", x, trackY, w * t, 4, 2, 2)

    local hx = x + w * t
    if ui.activeWidget == id then setColor(0.75, 0.88, 1.0)
    elseif hovered then setColor(0.6, 0.78, 0.95)
    else setColor(0.5, 0.68, 0.85) end
    love.graphics.circle("fill", hx, trackY + 2, handleR)
    setColor(0.20, 0.30, 0.45)
    love.graphics.circle("line", hx, trackY + 2, handleR)

    return value
end

----------------------------------------------------------------- Color preview
function Widgets.colorSwatch(x, y, w, h, hue, rainbow, sat, val)
    sat = sat or 1
    val = val or 1
    if rainbow then
        local steps = 28
        local sw = w / steps
        for i = 0, steps - 1 do
            local h_ = i / steps
            local hh = h_ * 6
            local ii = math.floor(hh)
            local f = hh - ii
            local r, g, b
            if     ii == 0 then r, g, b = val, val * f, 0
            elseif ii == 1 then r, g, b = val * (1 - f), val, 0
            elseif ii == 2 then r, g, b = 0, val, val * f
            elseif ii == 3 then r, g, b = 0, val * (1 - f), val
            elseif ii == 4 then r, g, b = val * f, 0, val
            else                r, g, b = val, 0, val * (1 - f) end
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle("fill", x + i * sw, y, sw + 1, h)
        end
    else
        local h_ = ((hue or 0) / 360) % 1 * 6
        local i = math.floor(h_)
        local f = h_ - i
        local p = val * (1 - sat)
        local q = val * (1 - f * sat)
        local t = val * (1 - (1 - f) * sat)
        local r, g, b
        if     i == 0 then r, g, b = val, t, p
        elseif i == 1 then r, g, b = q, val, p
        elseif i == 2 then r, g, b = p, val, t
        elseif i == 3 then r, g, b = p, q, val
        elseif i == 4 then r, g, b = t, p, val
        else               r, g, b = val, p, q end
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", x, y, w, h)
    end
    love.graphics.setColor(0.30, 0.36, 0.46)
    love.graphics.rectangle("line", x, y, w, h)
end

----------------------------------------------------------------- Label
function Widgets.label(x, y, text, color)
    if color then setColor(color[1], color[2], color[3], color[4])
    else setColor(0.95, 0.95, 1.0) end
    love.graphics.print(text, x, y)
end

return Widgets
