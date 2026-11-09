-- Tiny publish/subscribe hub. Lets core/ talk to the UI without depending on game/.
local Events = { handlers = {} }

function Events.on(name, fn)
    local list = Events.handlers[name]
    if not list then
        list = {}
        Events.handlers[name] = list
    end
    list[#list + 1] = fn
end

function Events.emit(name, ...)
    local list = Events.handlers[name]
    if not list then return end
    for i = 1, #list do list[i](...) end
end

-- Convenience for on-screen messages (shown by game/ui/Toast.lua).
function Events.notify(text, seconds)
    Events.emit("notify", text, seconds)
end

return Events
