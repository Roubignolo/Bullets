-- Save / load des scenes (emitters + params) via love.filesystem.
-- Stockage : <save-dir>/scene-<slot>.lua (Lua serialise, rechargeable via loadstring).
-- Sur web (love.js) : persiste en IndexedDB, donc survit aux refresh.

local Patterns = require("src.patterns")
local Emitter = require("src.emitter")

local Scenes = {}

local function serialize(t, indent)
    indent = indent or ""
    local nextIndent = indent .. "  "
    local lines = { "{" }
    for i = 1, #t do
        local v = t[i]
        local enc
        if type(v) == "table" then enc = serialize(v, nextIndent)
        elseif type(v) == "string" then enc = string.format("%q", v)
        else enc = tostring(v) end
        lines[#lines + 1] = nextIndent .. enc .. ","
    end
    for k, v in pairs(t) do
        if type(k) == "string" then
            local enc
            if type(v) == "table" then enc = serialize(v, nextIndent)
            elseif type(v) == "string" then enc = string.format("%q", v)
            else enc = tostring(v) end
            lines[#lines + 1] = nextIndent .. string.format("[%q] = ", k) .. enc .. ","
        end
    end
    lines[#lines + 1] = indent .. "}"
    return table.concat(lines, "\n")
end

local function path(slot)
    return "scene-" .. tostring(slot) .. ".lua"
end

function Scenes.save(state, slot)
    local data = { emitters = {} }
    for _, em in ipairs(state.emitters) do
        local params = {}
        for k, v in pairs(em.params) do params[k] = v end
        data.emitters[#data.emitters + 1] = {
            name = em.blueprint.name,
            x = em.x,
            y = em.y,
            params = params,
        }
    end
    local serialized = "return " .. serialize(data)
    local ok, err = pcall(love.filesystem.write, path(slot), serialized)
    return ok, err
end

function Scenes.load(state, slot)
    local p = path(slot)
    if not love.filesystem.getInfo(p) then return false, "no save" end
    local chunk, err = love.filesystem.load(p)
    if not chunk then return false, err end
    local ok, data = pcall(chunk)
    if not ok or not data or not data.emitters then return false, "parse error" end

    state.emitters = {}
    state.selectedEmitter = nil
    for _, edata in ipairs(data.emitters) do
        local bp
        for _, b in ipairs(Patterns.blueprints) do
            if b.name == edata.name then bp = b; break end
        end
        if bp then
            local em = Emitter.new(bp, edata.x or 440, edata.y or 200)
            for k, v in pairs(edata.params) do
                em.params[k] = v
            end
            state.emitters[#state.emitters + 1] = em
        end
    end
    if #state.emitters > 0 then state.selectedEmitter = 1 end
    return true
end

function Scenes.exists(slot)
    return love.filesystem.getInfo(path(slot)) ~= nil
end

return Scenes
