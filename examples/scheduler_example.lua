local Task = require "Task"
local Main = require "examples/scheduler_sleep"

Main.add(function()
    print "Hello World!"
    Main.yield()
    print "Goodbye World"
end)

local timers = {
    function()
        Main.sleep(10)
        print"10"
    end,
    
    function() 
        Main.sleep(5)
        print"5"
    end,
    
    function()
        Main.sleep(8)
        print"8"
        Main.sleep(3)
        print"11"
    end,
}

for i,v in ipairs(timers) do 
    Main.add(v)
end

Main.add(function()
    for i=0,20 do 
        print("Finished step: "..i)
        Main.yield()
    end
end)

forever()
