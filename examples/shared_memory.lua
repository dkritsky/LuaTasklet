--[[ This examples illustrates Shared Memory or a Blocking Resource

For shared memory, only 1 task may be granted access to the shared state at a
particular time. The rest of the tasks are blocked from starting until it is 
their turn.

]]

local Task = require "Task"

local Shared = {
    state       = {}, 
    lineup      = {},
    blocking    = false, 
    get = function(self, cb)    
        local tasklet
        tasklet = Task{function(...)
            local result = {cb(...)}
            Task(self.when_done, self)
            
            return unpack(result)        
        end}
    
        if self.blocking == false then
            self:start_task(tasklet)           
        else
            table.insert(self.lineup, tasklet)
        end
        
        return tasklet
    end,
    when_done = function(self)
        self.blocking = false
        
        if #self.lineup > 0 then
            local tasklet = table.remove(self.lineup, 1)            
            self:start_task(tasklet)
        end        
    end,
    start_task = function(self, tasklet)
        self.blocking = true
        Task.resume(tasklet, self.state)
    end,
}

local sleepers = {}
local sleep, wakeup

function sleep()
    table.insert(sleepers, Task.running())
    Task.yield() 
end

function wakeup()
    for i,v in ipairs(sleepers) do
        Task.resume(v, "wakeup")
    end
end

local function init()
    local stateA, stateB
    
    stateA = Shared:get(function(state) 
        print("A MSG:", state.msg or "none")
        
        sleep()     -- Going to sleep
        state.msg = "Hello world!"
        
        return "success"
    end)
    
    stateB = Shared:get(function(state) 
        print("B MSG:", state.msg or "none")
        state.msg = "Goodbye world!"
        
        return "success"
    end)
    
    stateA:add(function() print "State A finished" end)
    
    -- Now let's wake up
    print("Time to wakeup")
    wakeup()
    
    stateB:join()
    print("\nResults")
    print("result of A: ", stateA:get())
    print("result of B: ", stateB:get())
    print("\nFinal state msg is", Shared.state.msg)
    
    print("Init finished")
end

local exit = false
local main = Task(init):add(function() exit = true; end)

while exit == false do
    print "Another ITERATION"
    print "================="
    
    Task.resume(main)
end
