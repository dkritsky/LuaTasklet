local Task = require "Task"
local Main = require "examples/scheduler"

local sleepPool = {}

function Main.sleep(time)
    time = time or 0
    
    if time > 1 then
        sleepPool[Task.running()] = time-1  -- store it
        Task.yield()                        -- then yield it
    elseif time == 1 then
        Main.yield()
    else
        return
    end
end

function Main.checkSleep()
    for routine, time in pairs(sleepPool) do
        if time == 0 then
            sleepPool[routine] = nil
            Task.resume(routine)
        else
            sleepPool[routine] = time - 1
        end
    end
end

Main.checkSleepForever = Task{function()
    while true do
        Main.checkSleep()
        Main.yield()        -- do this to prevent blocking the main scheduler
    end
end}

Main.add(Main.checkSleepForever)
Main.add(function()
    Main.sleep(15)
    
    print "Cancelling Sleep Function"
    Main.checkSleepForever:cancel()
end)

return Main
