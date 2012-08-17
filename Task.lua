-- Lua Tasklet v0.1
-- ================

local lib = {}
local lib_mt

local RUNNING = nil

local Task = {}
local Task_mt

local create, resume, notify, emit, emit_error
local insert, remove, clear, copy

local forwarder

-- Lib
lib.inprogress  = "Task in progress"
lib.cancelled   = "Task canceled"

function lib.new(routine, ...)
    local instance = create(routine)
    
    local is = type(routine)
    local call = (getmetatable(routine) or {}).__call
    
    -- don't start right away if we got a packed constructor:  {func, args...}
    if not (is == 'table' and not call) then
        lib.resume(instance, ...)
    end
    
    return instance
end

function create(routine)
    local new_routine
    
    local is = type(routine)
    local call = (getmetatable(routine) or {}).__call
    
    if is == 'function' then
    elseif is == 'table' and call then
        new_routine = function(...) call(routine, ...) end
    elseif is == 'table' then
        local inner_routine = routine[1]
    
        is = type(inner_routine)
        call = (getmetatable(inner_routine) or {}).__call
        
        if is == 'function' or (is == 'table' and call) or is == 'nil' then
            return create(function() inner_routine(select(2, unpack(routine))) end)
        else
            error("Invalid 1st argument", 3)
        end
    elseif is == 'nil' then
        new_routine = forwarder
    else
        error("Invalid 1st argument", 3)
    end
    
    local instance = {
        _error = false,
        _result = nil,
        _routine = coroutine.create(new_routine or routine),
        _callbacks = {},
        _error_callback = {},
    }
    
    return setmetatable(instance, Task_mt)
end

function lib.running()
    return RUNNING
end

function lib.yield(...)
    return coroutine.yield(...)
end

function lib.resume(self, ...)
    return resume(self, ...)
end

function resume(self, ...)
    if type(self) ~= 'table' then
        error("Only Tasks are valid input", 3)
    end

    if not self:done() then
        local routine = self._routine
        local prev = lib.running()
        
        RUNNING = self
        local co_result = {coroutine.resume(routine, ...)}
        RUNNING = prev
        
        if coroutine.status(routine) == 'dead' then
            local success = co_result[1]
            
            self._error = not success        
            self._result = {select(2, unpack(co_result))}
            
            notify(self)
        end
    end
    
    return self
end

function notify(self)
    if self._error then
        local error_msg = self._result[1]
        if lib._error_handle and error_msg ~= lib.cancelled and error_msg ~= lib.inprogress then
            lib._error_handle(error_msg)
        end
    
        emit_error(self)
    else
        emit(self)
    end
end

-- Task
function Task:done()
    return self._error or self._result
end

function Task:success()
    return not self._error and self._result
end

function Task:get()
    if self._error then
        error(self._result[1], 2)
    elseif self._result then
        return unpack(self._result)
    else
        error(lib.inprogress, 2)
    end 
end

function Task:cancel()
    if not self.error then
        self._error = true
        self._result = {lib.cancelled}
        
        notify(self)
    end
end

function Task:add(...)
    for _, obj in ipairs({...}) do
        if obj == self then
            error("Trying to add 'self' to Task callback. Purposeless.", 2)
        end
    
        insert(self, obj)
    end
    
    if self:success() then
        notify(self)
    end
    
    return self
end

function Task:remove(...)
    for _, obj in ipairs({...}) do
        remove(self._callbacks, obj)
    end
    
    return self
end

function Task:join()
    local myself = lib.running()
    
    if myself == nil then
        error("Trying to 'join' on the Main program", 2)
    elseif myself == self then
        error("Trying to 'join' on self. Will result in a loop.", 2)
    end

    if self:done() then
        -- continue
    else
        if myself == nil then   -- probably not a good idea
            while true do
                lib.yield()     -- ??? how else to block CPU
            end
        else
            insert(self, myself, true)
            lib.yield()         -- block until finished
        end
    end
    
    if self._error then
        error(self._result[1], 2)
    end
    
    return unpack(self._result)
end

-- Misc...
function emit(self)
    local callbacks, error_callback = copy(self)
    clear(self)

    for i,routine in ipairs(callbacks) do    
        lib.new(routine, unpack(self._result))  
    end
end

function emit_error(self)
    local callbacks, error_callback = copy(self)    
    clear(self)

    for i,routine in ipairs(callbacks) do
        if error_callback[i] == true then
            local is = type(routine)
            local call = (getmetatable(routine) or {}).__call
            
            -- Technically only Task's who join()ed should exist here
            if is == 'function' then
                routine()
            elseif is == 'table' and call then
                call(routine)
            end
        end
    end
end

-- Callback data-structures
function insert(self, routine, on_error)
    local pool = self._callbacks

    local is = type(routine)
    local call = (getmetatable(routine) or {}).__call
    local value
    
    if is == 'function' then
        value = routine
    elseif is == 'table' and call then
        value = routine
    else
        error("Can't add " .. is, 2)
    end
    
    table.insert(pool, value)
    table.insert(self._error_callback, on_error or false)
end

function remove(self, routine)
    local pool = self._callbacks

    for k,v in pairs(pool) do
        if v == routine then
            table.remove(pool, k)
            table.remove(self._error_callback, k)
        end
    end
end

function clear(self)
    self._callbacks = {}
    self._error_callback = {}
end

function copy(self)
    return {unpack(self._callbacks)}, {unpack(self._error_callback)}
end

-- Special
function forwarder(...)
    return ...
end

lib_mt      = {__call = function(table, ...) return lib.new(...) end}
Task_mt     = {__index = Task, __call = function(self, ...) return lib.resume(self, ...) end}

lib._error_handle = error
setmetatable(lib, lib_mt)
return lib
