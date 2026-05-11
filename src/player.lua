local Player = {}
Player.__index = Player

function Player.new(x, y)
    return setmetatable({
        x = x,
        y = y,
        radius = 4,
        speed = 280,
    }, Player)
end

function Player:update(dt, w, h)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left", "a") then dx = dx - 1 end
    if love.keyboard.isDown("right", "d") then dx = dx + 1 end
    if love.keyboard.isDown("up", "w") then dy = dy - 1 end
    if love.keyboard.isDown("down", "s") then dy = dy + 1 end

    local mult = (love.keyboard.isDown("lshift", "rshift")) and 0.4 or 1.0
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len
        self.x = self.x + dx * self.speed * mult * dt
        self.y = self.y + dy * self.speed * mult * dt
    end

    self.x = math.max(8, math.min(w - 8, self.x))
    self.y = math.max(8, math.min(h - 8, self.y))
end

function Player:draw(hit)
    if hit then
        love.graphics.setColor(1, 0.25, 0.25)
    else
        love.graphics.setColor(0.6, 0.9, 1.0)
    end
    love.graphics.polygon("fill",
        self.x, self.y - 12,
        self.x - 10, self.y + 8,
        self.x + 10, self.y + 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Player
