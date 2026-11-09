function love.conf(t)
    t.identity = "prehistoric_tribes_remastered"
    t.version = "11.5"
    t.window.title = "Prehistoric Tribes: Remastered"
    t.window.width = 960          -- desktop only; Android always runs fullscreen
    t.window.height = 540
    t.window.resizable = true
    t.window.fullscreen = false
    t.accelerometerjoystick = false   -- saves battery on phones
    t.modules.audio = true
    t.modules.sound = true
    t.modules.graphics = true
    t.modules.physics = false
    t.modules.video = false
    t.modules.joystick = false
end
