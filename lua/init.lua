local os_clock_start = os.clock()
local os_clock = os.clock
function os.clock()
    return os_clock() - os_clock_start
end

function table.address(t)
    assert(type(t) == "table", "table.address can only retrieve address from a table")
    local metatable = getmetatable(t)
    setmetatable(t, nil)
    local s = tostring(t)
    setmetatable(t, metatable)

    return s:sub(8)
end


printtable = require("printtable")


starscade.class = starscade.class or {}

starscade.class.Object = require("middleclass")("starscade.Object")
function starscade.class.Object:__tostring()
    return self.class.name .. "[" .. table.address(self) .. "]"
end

starscade.class.Event = require("event")

starscade.event = starscade.event or {}
starscade.event.start = starscade.class.Event()
starscade.event.update = starscade.class.Event()
starscade.event.fixed_update = starscade.class.Event()
starscade.event.net = starscade.class.Event()

starscade.class.Timer = require("timer")


local listen_events_cache = {}
setmetatable(listen_events_cache, {__mode = "v"})

function starscade.net.listen(listen_channel, func)
    local cache_result = listen_events_cache[listen_channel]
    if cache_result then
        cache_result:add(func)
        return cache_result
    end
    
    local event = starscade.class.Event()
    starscade.event.net:add(function(channel, stream, sender)
        if listen_channel ~= channel then return end
        return event:invoke(stream, sender)
    end)
    listen_events_cache[listen_channel] = event
    event:add(func)
    return event
end
