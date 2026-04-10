local entries = {}

local M = {}

function M.get(key)
  return entries[key]
end

function M.put(key, value)
  entries[key] = value
end

return M
