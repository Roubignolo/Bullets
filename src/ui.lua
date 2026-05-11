local Widgets = require("src.widgets")
local Emitter = require("src.emitter")
local Patterns = require("src.patterns")
local Scenes = require("src.scenes")

local UI = {}

local PANEL_X = 880
local PANEL_W = 400
local PANEL_PAD = 16
local AREA_W = 880

local SCROLL_TOP = 0
local SCROLL_BOTTOM = 596    -- bumped up pour faire de la place a SCENES + clavier
UI.paramsScroll = 0

local function clampScroll(content, area)
    local maxS = math.max(0, content - area)
    if UI.paramsScroll < 0 then UI.paramsScroll = 0 end
    if UI.paramsScroll > maxS then UI.paramsScroll = maxS end
    return maxS
end

function UI.wheelmoved(dx, dy)
    local mx, my = love.mouse.getPosition()
    if mx >= PANEL_X and mx <= PANEL_X + PANEL_W
       and my >= SCROLL_TOP and my <= SCROLL_BOTTOM then
        UI.paramsScroll = UI.paramsScroll - dy * 28
    end
end

function UI.draw(state)
    love.graphics.setColor(0.08, 0.10, 0.14)
    love.graphics.rectangle("fill", PANEL_X, 0, PANEL_W, 800)
    love.graphics.setColor(0.20, 0.25, 0.32)
    love.graphics.rectangle("fill", PANEL_X - 2, 0, 2, 800)

    local x = PANEL_X + PANEL_PAD
    local w = PANEL_W - PANEL_PAD * 2
    local y = PANEL_PAD

    love.graphics.setColor(0.95, 0.95, 1)
    love.graphics.print("Bullets — pattern editor", x, y)
    y = y + 24

    -------------------------------------------- AJOUTER UN PATTERN
    Widgets.label(x, y, "PATTERNS  (clic = ajouter)", { 0.55, 0.65, 0.78 })
    y = y + 18
    for i, bp in ipairs(Patterns.blueprints) do
        if Widgets.button(state.ui, "addBp_" .. i, x, y, w, 20, "+ " .. bp.name) then
            local em = Emitter.new(bp, AREA_W / 2, 200)
            table.insert(state.emitters, em)
            state.selectedEmitter = #state.emitters
            UI.paramsScroll = 0
        end
        y = y + 22
    end

    y = y + 4

    -------------------------------------------- LISTE EMITTERS
    Widgets.label(x, y, "EMITTERS", { 0.55, 0.65, 0.78 })
    y = y + 18

    if #state.emitters == 0 then
        love.graphics.setColor(0.55, 0.55, 0.65)
        love.graphics.print("(aucun)", x, y)
        y = y + 22
    else
        local maxList = 3
        local n = #state.emitters
        local shown = math.min(n, maxList)
        for i = 1, shown do
            local em = state.emitters[i]
            local label = string.format("#%d %s (%d,%d)",
                i, em.blueprint.name, math.floor(em.x), math.floor(em.y))
            local isSel = (state.selectedEmitter == i)
            if Widgets.button(state.ui, "selEm_" .. em.id, x, y, w - 28, 22, label,
                                { selected = isSel }) then
                state.selectedEmitter = i
                UI.paramsScroll = 0
            end
            if Widgets.button(state.ui, "delEm_" .. em.id, x + w - 24, y, 24, 22, "x",
                                { danger = true }) then
                table.remove(state.emitters, i)
                if state.selectedEmitter == i then state.selectedEmitter = nil
                elseif state.selectedEmitter and state.selectedEmitter > i then
                    state.selectedEmitter = state.selectedEmitter - 1
                end
                break
            end
            y = y + 25
        end
        if n > maxList then
            love.graphics.setColor(0.55, 0.55, 0.65)
            love.graphics.print(string.format("... +%d (clic dans la zone)", n - maxList), x, y)
            y = y + 16
        end
        if Widgets.button(state.ui, "clearAll", x, y, w, 20, "Tout supprimer",
                            { danger = true }) then
            state.emitters = {}
            state.selectedEmitter = nil
        end
        y = y + 22
    end

    y = y + 4

    -------------------------------------------- PARAMETRES (scroll)
    SCROLL_TOP = y
    local scrollAreaY = y
    local scrollAreaH = SCROLL_BOTTOM - scrollAreaY

    local origMy = state.ui.my
    if state.ui.my < scrollAreaY or state.ui.my > SCROLL_BOTTOM then
        state.ui.my = -10000
    end

    love.graphics.setScissor(PANEL_X, scrollAreaY, PANEL_W, scrollAreaH)

    local sy = scrollAreaY - UI.paramsScroll
    local startY = sy

    Widgets.label(x, sy, "PARAMETRES", { 0.55, 0.65, 0.78 })
    sy = sy + 18

    if state.selectedEmitter and state.emitters[state.selectedEmitter] then
        local em = state.emitters[state.selectedEmitter]
        love.graphics.setColor(0.85, 0.88, 0.95)
        love.graphics.print(em.blueprint.name, x, sy)
        Widgets.colorSwatch(x + w - 60, sy + 2, 60, 14,
            em.params.hue, em.params.rainbow and em.params.rainbow > 0.5,
            em.params.saturation, em.params.brightness)
        sy = sy + 22

        for _, spec in ipairs(em.blueprint.paramSpecs) do
            if spec.kind == "toggle" then
                em.params[spec.name] = Widgets.toggle(state.ui,
                    "p_" .. em.id .. "_" .. spec.name,
                    x, sy + 4, w, 20, spec.label, em.params[spec.name])
                sy = sy + 26
            else
                em.params[spec.name] = Widgets.slider(state.ui,
                    "p_" .. em.id .. "_" .. spec.name,
                    x, sy + 16, w, spec.label,
                    em.params[spec.name], spec.min, spec.max, spec.step)
                sy = sy + 30
            end
        end

        if Widgets.button(state.ui, "resetParams_" .. em.id, x, sy + 4, w, 22,
                            "Reinitialiser") then
            for k, v in pairs(em.blueprint.defaultParams) do
                em.params[k] = v
            end
        end
        sy = sy + 30
    else
        love.graphics.setColor(0.55, 0.55, 0.65)
        love.graphics.print("(selectionne un emitter)", x, sy)
        sy = sy + 18
    end

    local contentHeight = sy - startY
    love.graphics.setScissor()
    state.ui.my = origMy

    local maxS = clampScroll(contentHeight, scrollAreaH)
    if maxS > 0 then
        local trackX = PANEL_X + PANEL_W - 6
        love.graphics.setColor(0.15, 0.18, 0.24)
        love.graphics.rectangle("fill", trackX, scrollAreaY, 4, scrollAreaH)
        local thumbH = math.max(20, scrollAreaH * (scrollAreaH / contentHeight))
        local thumbY = scrollAreaY + UI.paramsScroll * (scrollAreaH - thumbH) / maxS
        love.graphics.setColor(0.45, 0.55, 0.70)
        love.graphics.rectangle("fill", trackX, thumbY, 4, thumbH, 2, 2)
    end

    -------------------------------------------- BAS : SCENES + CONTROLES + STATS
    local by = SCROLL_BOTTOM + 4
    love.graphics.setColor(0.20, 0.25, 0.32)
    love.graphics.rectangle("fill", PANEL_X + 8, by - 2, PANEL_W - 16, 1)

    -- SCENES (3 slots : Save / Load)
    Widgets.label(x, by + 2, "SCENES", { 0.55, 0.65, 0.78 })
    by = by + 18
    local btnW = (w - 8) / 3
    for slot = 1, 3 do
        local sx = x + (slot - 1) * (btnW + 4)
        if Widgets.button(state.ui, "save_" .. slot, sx, by, btnW, 20, "Save " .. slot) then
            Scenes.save(state, slot)
        end
    end
    by = by + 22
    for slot = 1, 3 do
        local sx = x + (slot - 1) * (btnW + 4)
        local exists = Scenes.exists(slot)
        if Widgets.button(state.ui, "load_" .. slot, sx, by, btnW, 20, "Load " .. slot,
                          { disabled = not exists }) then
            if Scenes.load(state, slot) then
                UI.paramsScroll = 0
            end
        end
    end
    by = by + 26

    -- Pause / Reset
    local pauseLabel = state.paused and "Reprendre" or "Pause"
    if Widgets.button(state.ui, "pauseBtn", x, by, (w - 8) / 2, 22, pauseLabel) then
        state.paused = not state.paused
    end
    if Widgets.button(state.ui, "resetBtn", x + (w + 8) / 2, by, (w - 8) / 2, 22, "Reset stats") then
        state.requestReset = true
    end
    by = by + 26

    -- Toggle clavier
    local layoutText = (state.keyboardLayout == "azerty")
        and "Clavier : AZERTY (ZQSD)"
        or  "Clavier : QWERTY (WASD)"
    if Widgets.button(state.ui, "layoutBtn", x, by, w, 20, layoutText, { selected = true }) then
        state.setKeyboardLayout(state.keyboardLayout == "azerty" and "qwerty" or "azerty")
    end
    by = by + 22

    -- Stats
    love.graphics.setColor(0.7, 0.78, 0.90)
    love.graphics.print(string.format("Bullets : %d", #state.bullets), x, by)
    love.graphics.setColor(1, 0.55, 0.55)
    love.graphics.print(string.format("Hits : %d", state.hitCount), x + 130, by)
    love.graphics.setColor(0.85, 0.95, 1)
    love.graphics.print(string.format("Grazes : %d", state.grazeCount), x + 230, by)

    by = by + 14
    love.graphics.setColor(0.50, 0.55, 0.65)
    local moveKeys = (state.keyboardLayout == "azerty") and "ZQSD" or "WASD"
    love.graphics.print("Move fleches/" .. moveKeys .. "  Shift focus  R reset  Space pause", x, by)
end

return UI
