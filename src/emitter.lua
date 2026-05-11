local Emitter = {}

local nextId = 1

local function copyParams(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

function Emitter.new(blueprint, x, y)
    local id = nextId
    nextId = nextId + 1
    return {
        id = id,
        blueprint = blueprint,
        x = x, y = y,
        params = copyParams(blueprint.defaultParams),
        accum = 0,
    }
end

return Emitter
