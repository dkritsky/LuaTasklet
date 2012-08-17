local Task = require "Task"

local Main = {}
Main.pool = {}

function Main.add(tasklet)
    local routine = tasklet
    if type(tasklet) == 'function' then
        -- to prevent the Task from starting right away, use curly braces
        routine = Task{tasklet}
    end
    
    table.insert(Main.pool, routine)
end

function Main.yield()
    table.insert(Main.pool, Task.running())
    Task.yield()
end

function step()
    local copy = {unpack(Main.pool)}
    Main.pool = {}
    
    -- will call all the functions in the pool right away
    Task():add(unpack(copy))
end

function forever()
    while #Main.pool > 0 do
        step()
    end
end

return Main
