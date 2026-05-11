local Player = {}
Player.__index = Player

function Player.new(x, y)
    return setmetatable({
        x = x, y = y,
        radius = 4,
        grazeRadius = 14,
        speed = 280,
        hitFlash = 0,
        grazing = false,
    }, Player)
end

function Player:update(dt, areaW, areaH)
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

    self.x = math.max(8, math.min(areaW - 8, self.x))
    self.y = math.max(8, math.min(areaH - 8, self.y))

    self.hitFlash = math.max(0, self.hitFlash - dt)
end

function Player:onHit()
    self.hitFlash = 0.18
end

function Player:draw()
    local flashing = self.hitFlash > 0

    -- ship body (triangle)
    if flashing then
        love.graphics.setColor(1, 0.35, 0.35)
    else
        love.graphics.setColor(0.6, 0.9, 1.0)
    end
    love.graphics.polygon("fill",
        self.x, self.y - 12,
        self.x - 10, self.y + 8,
        self.x + 10, self.y + 8)
    love.graphics.setColor(0.2, 0.3, 0.4)
    love.graphics.polygon("line",
        self.x, self.y - 12,
        self.x - 10, self.y + 8,
        self.x + 10, self.y + 8)

    -- graze ring (visible only when a bullet is near)
    if self.grazing then
        love.graphics.setColor(1, 1, 1, 0.18)
        love.graphics.circle("fill", self.x, self.y, self.grazeRadius)
        love.graphics.setColor(1, 1, 1, 0.55)
        love.graphics.circle("line", self.x, self.y, self.grazeRadius)
    else
        love.graphics.setColor(1, 1, 1, 0.10)
        love.graphics.circle("line", self.x, self.y, self.grazeRadius)
    end

    -- hitbox: big red glow when hit, otherwise small white core
    if flashing then
        love.graphics.setColor(1, 0.2, 0.2, 0.55)
        love.graphics.circle("fill", self.x, self.y, self.radius + 6)
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.circle("fill", self.x, self.y, self.radius + 1)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
end

return Player
