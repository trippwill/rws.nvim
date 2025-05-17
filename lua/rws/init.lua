---@mod rws.intro Introduction
---@brief [[
--- The RWS (Remote Window Scrolling) module provides functionality to scroll
--- windows in view that are not the current window.
---@brief ]]

---@mod rws.types Types

---@alias Win integer
---@alias ScrollDirection 'f' | 'b'
---@alias ScrollAmount 'line' | 'half' | 'full'

---@class RwsOptions
---@field debug? boolean | 'verbose' Enable debug mode
---@field allow_current_win? boolean Allow scrolling the current window

---@mod rws.module Module

local M = {}

---@type RwsOptions
---@private
---@package
M.defaults = {
  debug = false,
  allow_current_win = false,
}

---@type RwsOptions | nil
---@package
---@private
M.config = nil

---Find the target window based on arg
---@param arg string|integer
---@see vim.fn.winnr
---@return Win?, string?
function M.find_target_win(arg)
  local target_winnr = vim.fn.winnr(arg)
  if target_winnr == 0 then
    return nil, 'Argument did not match any window: ' .. (arg or '')
  end

  local target_win = vim.fn.win_getid(target_winnr)
  if target_win == 0 then
    return nil, 'Window id not found for winnr: ' .. (target_winnr or '')
  end

  if not M.config.allow_current_win then
    local cur_win = vim.api.nvim_get_current_win()
    if target_win == cur_win then
      return nil, 'Curent window is not allowed to be scrolled'
    end
  end

  return target_win
end

local function precompute_scroll_cmds()
  local escape = function(cmd)
    return vim.api.nvim_replace_termcodes(cmd, true, true, true)
  end

  return {
    line = { f = escape('<c-e>'), b = escape('<c-y>') },
    half = { f = escape('<c-d>'), b = escape('<c-u>') },
    full = { f = escape('<c-f>'), b = escape('<c-b>') },
  }
end

local scroll_cmds = precompute_scroll_cmds()

--- Scroll a target window by window id
---@param target Win
---@param direction ScrollDirection
---@param amount ScrollAmount
function M.scroll_target_window(target, direction, amount)
  local cmd = scroll_cmds[amount] and scroll_cmds[amount][direction]
  if not cmd then
    vim.notify(
      ('Invalid scroll amount: %s or direction %s'):format(amount or '', direction or ''),
      vim.log.levels.ERROR,
      { title = 'RWS' }
    )
    return
  end

  if M.config.debug == 'verbose' then
    vim.notify(
      ('Scrolling target window %d with command: %s'):format(target, cmd),
      vim.log.levels.TRACE,
      { title = 'RWS' }
    )
  end

  vim.api.nvim_win_call(target, function()
    vim.cmd(('normal! %s'):format(cmd))
  end)
end

---Scroll a target window by winnr arg
---@param target_arg string|integer Target window to scroll
---@param scroll_direction ScrollDirection Direction to scroll
---@param scroll_amount ScrollAmount Amount to scroll
---@see vim.fn.winnr
function M.scroll(target_arg, scroll_direction, scroll_amount)
  local target, err = M.find_target_win(target_arg)
  if not target then
    if err and M.config.debug then
      vim.notify(err or ('Invalid window for arg: ' .. target_arg), vim.log.levels.DEBUG, { title = 'RWS' })
    end

    -- Silently return if no error message
    return
  end

  M.scroll_target_window(target, scroll_direction, scroll_amount)
end

---Initialize the RWS module
---@param opts RwsOptions
function M.setup(opts)
  local config = vim.tbl_deep_extend('force', {}, M.defaults, opts or {})
  M.config = config
end

return M
