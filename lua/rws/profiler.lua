---@class RWSProfiler
local M = {}
local p = require('plenary.profile')

---Enable or disable profiling
---@param arg boolean|nil If false, disable profiling
---@param flame boolean|nil If true, enable flame graph profiling
---@return RWSProfiler
function M.enable(arg, flame)
  if not p then
    error('Plenary is required for profiling')
    return M
  end

  M.__enabled = type(arg) == 'boolean' and arg or false
  M.__flame = flame or false
  return M
end

---Profile a function with the given log name
---@param log_name string Name of the log file
---@param func function Function to profile
---@param ... any Arguments to pass to the function
---@return any Result of the function
function M.profile_func(log_name, func, ...)
  if p and M.__enabled then
    p.start(log_name --[[@as any]], { flame = M.__flame })
    local results = func(...)
    p.stop()
    return results
  end
  return func(...)
end

---Start profiling with the given log name
---@param log_name string Name of the log file
---@return function() end
function M.profile_start(log_name)
  if p and M.__enabled then
    p.start(log_name --[[@as any]], { flame = M.__flame })

    return p.stop
  end
  return function() end
end

return M
