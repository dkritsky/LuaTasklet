--[[ This examples illustrates an Event Notifier

All added callbacks are remembered and stored in a 'pool', the callbacks can
then be notified/called multiple times.

]]

local Task = require "Task"

local Event = {
    pool = {},
    add = function(self, cb)
        table.insert(self.pool, cb)
    end,
    call = function(self, ...)
        -- this is a special property of the constructor
        -- the task will finish right away, and return the args as the result
        Task(nil, ...)  
            :add(unpack(self.pool))
    end,
}

Event:add(function(...) print('1', ...) end)

print "========="
Event:call('a')

Event:add(function(...) print('2', ...) end)

print "========="
Event:call('b')

print "========="
Event:call('c')


