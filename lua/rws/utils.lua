local M = {}
local api = vim.api

---@param s string
---@return string
function M.trim_surrounding_quotes(s)
  if type(s) ~= 'string' then
    return s
  end

  local first, last = s:sub(1, 1), s:sub(-1)
  if (first == last) and (first == '"' or first == "'") then
    return s:sub(2, -2)
  end

  return s
end

function M.escape_keys(cmd)
  return api.nvim_replace_termcodes(cmd, true, false, true)
end

return M
