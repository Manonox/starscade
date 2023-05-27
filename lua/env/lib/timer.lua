local Event = require("event")

local Timer = starscade.class.Object:subclass("starscade.Timer")
Timer.static.default_update_event = starscade.event.update


function Timer:initialize(time)
    self.time = time
    self.start_time = nil
    self.repetition_index = 0
    self.timeout = Event()
    
    self._update_event = nil
    self.callback = function()
        if not self.start_time then return end
        local time_passed = os.clock() - self.start_time
        local time_left = self.time - time_passed
        if time_left > 0 then return end

        self.repetition_index += 1
        self.timeout:invoke(self.repetition_index)

        local is_single = self.repetition_max == nil
        if is_single then
            self:remove()
            return
        end

        local is_infinite = self.repetition_max == 0
        if is_infinite or self.repetition_max > self.repetition_index then
            self.start_time += self.time
            return
        end
        
        self:remove()
    end

    self:set_update_event(self.class.static.default_update_event)
end


function Timer:start(repetitions)
    assert(self.start_time == nil, "timer already started")
    self.start_time = os.clock()
    self.repetition_max = repetitions
    return self
end


function Timer:remove()
    if self._update_event then
        self._update_event:remove(self.callback)
    end
end


function Timer:on_timeout(func)
    self.timeout:add(func)
    return self
end


function Timer:once(func)
    self:start()
    self.timeout:add(func)
    return self
end


function Timer:multi(times, func)
    self:start(times)
    self.timeout:add(func)
    return self
end
Timer.times = Timer.multi
Timer.multiple = Timer.multi

function Timer:infinite(func)
    self:start(0)
    self.timeout:add(func)
    return self
end
Timer.inf = Timer.infinite
Timer.infinitely = Timer.infinite


function Timer:set_update_event(event)
    if self._update_event then
        self._update_event:remove(self.callback)
    end

    self._update_event = event
    self._update_event:add(self.callback)
    return self
end


return Timer
