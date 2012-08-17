Lua Tasklet v0.1
================

An implementation of *Green Threads* for Lua by adding callbacks to Lua's builtin coroutines.

Reference
---------

 * Task{foo, ...}   - create a Task but don't start it, see below.
 * Task(foo, ...)   - Starts a task 'foo' asynchronously, giving it the rest of inputs as arguments
                      
 * Task.new(foo, ...)           - same as previous
 * Task.running()               - returns the current running task, or nil if none
 
 * Task.yield(...)              - Yields the task. Similar to coroutine.yield.
 * Task.resume(tasklet, ...)    - Wakes a task up for further processing. Similar to coroutine.resume.
 
 * <instance>.done()    - return true if task is finished
 * <instance>.success() - return true if task is finished without an error
 * <instance>.cancel()  - cancel's the task from further running
 
 * <instance>.get()     - returns the result if done, or error on an error (see: special error messages below)
 * <instance>.join()    - like 'get', but blocks the current task until the instance is finished 
 
 * <instance>.add(...)      - adds possibly many callbacks (these will be called when the task finished, and only if successful (without error))
 * <instance>.remove(...)   - removes previously added callbacks

 Special: placing nil for 'foo' in Task creation will simply forward the arguments to the callbacks

Two special error messages can occur for a task:
 * "Task cancelled"     - the task was cancelled; corresponds to Task.cancelled
 * "Task in progress"   - the task did not finish yet; corresponds to Task.inprogress

 * Task.error_handler   - default error handler called when not a special error

Error Handling
--------------
To facilitate error handling of detached tasklets (similar to anonymous functions) a public error handler 'Task.error_handler' is provided.
The error handler runs just before the error handling for all the join()'s, and only for non-special error messages.

You can set it to 'nil' to remove it, or change the function to custom handle errors.

Examples
--------
All examples are inside the 'examples' directory

 * scheduler_*      - a scheduler with sleep (for 'n' number of **steps**) functionality 
 * event_notify     - a typical implementation of an event notifier
 * multi_callbacks  - adds multiple callbacks to resume the same task, only the first will get called
 * shared_memory    - an implementation of a blocking resource. eg. shared memory

Other Resources
---------------
 * [Green Vs Native Threads](http://c2.com/cgi/wiki?GreenVsNativeThreads)
 * [Cooperative Threading](http://c2.com/cgi/wiki?CooperativeThreading) - this library's method of implementing *Green Threads*

TODO
----
 * write a an introductory example to show off the additions to coroutines (see below)
 * create examples to show 'done', 'success', 'get', and 'join'
 * better way of handling the two 'special' error messages?
 * calling a Tasklet like a function resumes it, is that right? or should it do a join()?
