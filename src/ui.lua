local Widgets = require("src.widgets")
local Emitter = require("src.emitter")
local Patterns = require("src.patterns")

local UI = {}

local PANEL_X = 880
local PANEL_W = 400
local PANEL_PAD = 16
local AREA_W = 880
local AREA_H = 800

function UI.draw(state)
    -- panel background
    love.graphics.setColor(0.08, 0.10, 0.14)
    love.graphics.rectangle("fill", PANEL_X, 0, PANEL_W, 800)
    love.graphics.setColor(0.20, 0.25, 0.32)
    love.graphics.rectangle("fill", PANEL_X - 2, 0, 2, 800)

    local x = PANEL_X + PANEL_PAD
    local w = PANEL_W - PANEL_PAD * 2
    local y = PANEL_PAD

    -- title
    love.graphics.setColor(0.95, 0.95, 1)
    love.graphics.print("Bullets — pattern editor", x, y)
    y = y + 26

    -------------------------------------------- AJOUTER UN PATTERN
    Widgets.label(x, y, "PATTERNS", { 0.55, 0.65, 0.78 })
    y = y + 18
    for i, bp in ipairs(Patterns.blueprints) do
        if Widgets.button(state.ui, "addBp_" .. i, x, y, w, 24, "+ " .. bp.name) then
            local em = Emitter.new(bp, AREA_W / 2, 200)
            table.insert(state.emitters, em)
            state.selectedEmitter = #state.emitters
        end
        y = y + 28
    end

    y = y + 8

    -------------------------------------------- LISTE EMITTERS
    Widgets.label(x, y, "EMITTERS  (clic = select, drag dans la zone)", { 0.55, 0.65, 0.78 })
    y = y + 18

    if #state.emitters == 0 then
        love.graphics.setColor(0.55, 0.55, 0.65)
        love.graphics.print("(aucun emitter)", x, y)
        y = y + 22
    else
        local maxList = 6
        local n = #state.emitters
        local shown = math.min(n, maxList)
        for i = 1, shown do
            local em = state.emitters[i]
            local label = string.format("#%d  %s  (%d, %d)",
                i, em.blueprint.name, math.floor(em.x), math.floor(em.y))
            local isSel = (state.selectedEmitter == i)
            if Widgets.button(state.ui, "selEm_" .. em.id, x, y, w - 30, 22, label,
                                { selected = isSel }) then
                state.selectedEmitter = i
            end
            if Widgets.button(state.ui, "delEm_" .. em.id, x + w - 26, y, 26, 22, "x",
                                { danger = true }) then
                table.remove(state.emitters, i)
                if state.selectedEmitter == i then
                    state.selectedEmitter = nil
                elseif state.selectedEmitter and state.selectedEmitter > i then
                    state.selectedEmitter = state.selectedEmitter - 1
                end
                break
            end
            y = y + 26
        end
        if n > maxList then
            love.graphics.setColor(0.55, 0.55, 0.65)
            love.graphics.print(string.format("... et %d autre(s)", n - maxList), x, y)
            y = y + 18
        end
        y = y + 4
        if Widgets.button(state.ui, "clearAll", x, y, w, 22, "Tout supprimer",
                            { danger = true }) then
            state.emitters = {}
            state.selectedEmitter = nil
        end
        y = y + 28
    end

    y = y + 6

    -------------------------------------------- PARAMETRES
    Widgets.label(x, y, "PARAMETRES", { 0.55, 0.65, 0.78 })
    y = y + 18

    if state.selectedEmitter and state.emitters[state.selectedEmitter] then
        local em = state.emitters[state.selectedEmitter]
        love.graphics.setColor(0.85, 0.88, 0.95)
        love.graphics.print(em.blueprint.name, x, y)
        y = y + 22

        for _, spec in ipairs(em.blueprint.paramSpecs) do
            local current = em.params[spec.name]
            local newVal = Widgets.slider(state.ui, "p_" .. em.id .. "_" .. spec.name,
                x, y + 16, w, spec.label, current, spec.min, spec.max, spec.step)
            em.params[spec.name] = newVal
            y = y + 36
        end

        if Widgets.button(state.ui, "resetParams_" .. em.id, x, y + 4, w, 22,
                            "Reinitialiser les parametres") then
            for k, v in pairs(em.blueprint.defaultParams) do
                em.params[k] = v
            end
        end
    else
        love.graphics.setColor(0.55, 0.55, 0.65)
        love.graphics.print("(selectionne un emitter dans la liste)", x, y)
    end

    -------------------------------------------- BAS : CONTROLES + STATS
    local by = 800 - 96
    love.graphics.setColor(0.20, 0.25, 0.32)
    love.graphics.rectangle("fill", PANEL_X + 8, by - 12, PANEL_W - 16, 1)

    local pauseLabel = state.paused and "Reprendre" or "Pause"
    if Widgets.button(state.ui, "pauseBtn", x, by, (w - 8) / 2, 26, pauseLabel) then
        state.paused = not state.paused
    end
    if Widgets.button(state.ui, "resetBtn", x + (w + 8) / 2, by, (w - 8) / 2, 26, "Reset stats") then
        state.requestReset = true
    end

    by = by + 36
    love.graphics.setColor(0.7, 0.78, 0.90)
    love.graphics.print(string.format("Bullets : %d", #state.bullets), x, by)
    love.graphics.setColor(1, 0.55, 0.55)
    love.graphics.print(string.format("Hits : %d", state.hitCount), x + 130, by)
    love.graphics.setColor(0.85, 0.95, 1)
    love.graphics.print(string.format("Grazes : %d", state.grazeCount), x + 230, by)

    by = by + 18
    love.graphics.setColor(0.50, 0.55, 0.65)
    love.graphics.print("Move: arrows/WASD  Focus: Shift", x, by)
    by = by + 14
    love.graphics.print("R: reset  Space: pause  Suppr: delete emitter", x, by)
end

return UI
