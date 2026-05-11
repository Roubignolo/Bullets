function love.conf(t)
    t.identity = "bullets-editor"
    t.window.title = "Bullets — pattern editor"
    t.window.width = 1024
    t.window.height = 768
    t.window.resizable = false
    t.window.vsync = 1
    t.modules.physics = false
end
