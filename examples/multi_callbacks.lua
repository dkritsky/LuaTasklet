--[[ This examples illustrates Multiple Callbacks 

This can be used for example to listen to both a Timer event, and waiting
for an action to occur. Once one goes off, the other should not.

]]

local Task = require "Task"

local x,y,z = Task(Task.yield), Task(Task.yield), Task(Task.yield)

local tasklet = Task(function()
    print "Waiting for either x, y, or z to wake me up"
    
    local result = {Task.yield()}   -- go to sleep
    local args = {select(2, unpack(result))}
    print(result[1] .. " woke me up, with args: ", table.concat(args, ','))
    
    Task.yield()                    -- go to sleep again
    print "Neither x, y, or z should wake me up from this sleep"
end)

local action = Task(function()
    Task.resume(tasklet, Task.yield())
end)

-- Add callbacks
x:add(function(...) action("X", ...) end)
y:add(function(...) action("Y", ...) end)
z:add(function(...) action("Z", ...) end)

-- RESUME here
Task.resume(y, "here")  -- will only happen here
Task.resume(x)
Task.resume(z)

Task.resume(y)
