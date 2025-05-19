local swaps = require('rws.opts-swap')

---@mod rws.intro Introduction
---@brief [[
--- The RWS (Remote Window Scrolling) module provides functionality to scroll
--- windows in view that are not the current window.
---@brief ]]

---@mod rws.types Types

---@alias Win integer
---@alias ScrollDirection 'f' | 'b'
---@alias ScrollAmount 'line' | 'half' | 'full'

---@class HighlightDef : vim.api.keyset.highlight
---@field [1] string

---@class RwsOptions
---@field debug? boolean | 'verbose' Enable debug mode
---@field allow_current_win? boolean Allow scrolling the current window
---@field target_options? OptValueSet
---@field target_hl? HighlightDef

---@mod rws.module Module

local M = {}

---@type RwsOptions
---@private
---@package
M.defaults = {
  debug = false,
  allow_current_win = false,
  target_options = {
    winhighlight = 'NormalNC:RWSTargetWindow',
    cursorline = false,
    statuscolumn = '%#MoreMsg#‖%=%l ',
    signcolumn = 'no',
    number = false,
    relativenumber = true,
    foldlevel = 999,
    foldcolumn = '0',
  },
  target_hl = {
    'RWSTargetWindow',
    bg = '#121225',
  },
}

---@type RwsOptions?
---@package
---@private
M.config = nil

---@type WinResult?
---@package
---@private
M.current_target = nil

---Find the target window based on arg
---@param arg string|integer
---@return Win?, string?
---@see vim.fn.winnr
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

local scroll_cmds = (function()
  local escape = function(cmd)
    return vim.api.nvim_replace_termcodes(cmd, true, true, true)
  end

  return {
    line = { f = escape('<c-e>'), b = escape('<c-y>') },
    half = { f = escape('<c-d>'), b = escape('<c-u>') },
    full = { f = escape('<c-f>'), b = escape('<c-b>') },
  }
end)()

---Scroll a target window by window id
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

---Select a target window by winnr arg
---@param target_arg string|integer Target window to select
---@return boolean, string?
---@see vim.fn.winnr
function M.select_target(target_arg)
  local target, err = M.find_target_win(target_arg)
  if not target then
    if err and M.config.debug then
      vim.notify(err or ('Invalid window for arg: ' .. target_arg), vim.log.levels.DEBUG, { title = 'RWS' })
    end

    return false, err
  end

  local current = M.current_target
  if current then
    local current_win = current.winid
    M.current_target = nil
    swaps.reset_opts(current)

    -- If the target window is currently selected, unselect it and return
    if current_win == target then
      return false, nil
    end
  end

  M.current_target = swaps.win_swap_opts(target, M.config.target_options)

  if M.config.debug == 'verbose' then
    vim.notify(
      ('Target window %d selected with config: %s'):format(target, vim.inspect(M.current_target)),
      vim.log.levels.TRACE,
      { title = 'RWS' }
    )
  end

  return true, nil
end

function M.route(key)
  if M.current_target then
    local target = M.current_target.winid
    if target then
      vim.api.nvim_win_call(target, function()
        vim.cmd(('normal! %s'):format(key))
      end)
    end
  else
    vim.api.nvim_input(key)
  end
end

---Reset the target window to its original state
function M.reset_target()
  local current = M.current_target
  if current then
    swaps.reset_opts(current)
    M.current_target = nil
  end
end

---Initialize the RWS module
---@param opts RwsOptions
function M.setup(opts)
  local config = vim.tbl_deep_extend('force', M.defaults, opts or {})

  if config.debug then
    vim.notify(('RWS setup with opts:\n%s'):format(vim.inspect(config)), vim.log.levels.DEBUG, { title = 'RWS' })
  end

  local target_hl = config.target_hl
  if target_hl then
    local hl = table.remove(target_hl, 1)
    if hl then
      vim.api.nvim_set_hl(0, hl, target_hl)
    else
      vim.notify('No highlight group name provided for target_hl', vim.log.levels.ERROR, { title = 'RWS' })
    end
  end

  vim.api.nvim_create_user_command('RemWinScroll', function(_opts)
    local args = vim.fn.split(_opts.args, ' ')
    if #args < 3 then
      vim.notify('Usage: RemWinScroll <target> <scroll_direction> <scroll_amount>', vim.log.levels.ERROR)
      return
    end

    require('rws').scroll(args[1], args[2], args[3])
  end, {
    nargs = '+',
    desc = 'Scroll the target window',
  })

  vim.api.nvim_create_user_command('RemWinSelect', function(_opts)
    local arg = _opts.args
    vim.validate('0', arg, { 'string', 'number' }, 'Usage: RemWinSelect <target>')

    require('rws').select_target(arg)
  end, {
    nargs = 1,
    desc = 'Select a target window',
  })

  M.config = config
end

return M
