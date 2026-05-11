local UI = {}

local CONTROLS = {
    "Deplacement : fleches / WASD       Focus (precision) : Shift",
    "Pattern : 1-4    Reset : R    Pause : Espace    Quitter : Echap",
    "Parametres : Q/E (rate)  Z/C (speed)  [/] (count|arms)  ,/. (spread|rot)",
}

function UI.draw(state)
    local pat = state.patterns[state.currentPattern]

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Pattern %d/%d  -  %s",
        state.currentPattern, #state.patterns, pat.name), 12, 10)

    love.graphics.setColor(0.85, 0.85, 0.95)
    love.graphics.print(pat.describe(), 12, 28)

    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.print(string.format("Bullets : %d", #state.bullets), 12, 46)

    if state.paused then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print("[ PAUSE ]", 12, 64)
    end

    love.graphics.setColor(0.55, 0.6, 0.7)
    for i, line in ipairs(CONTROLS) do
        love.graphics.print(line, 12, 700 + (i - 1) * 16)
    end
end

return UI
