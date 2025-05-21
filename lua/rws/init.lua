---@mod rws.intro Introduction
---@brief [[
---The RWS (Remote Window System) module sends commands
---to an unfocused target window.
---@brief ]]

---@mod rws.types Types

---@alias Win integer

---@class RoutedKeyDef
---@field [1] string Key to route
---@field cmd string Command to execute
---@field mode? string | string[]
---@field desc? string

---@class HighlightDef : vim.api.keyset.highlight
---@field [1] string

---@class RwsOptions
---@field debug? boolean | 'verbose' Enable debug mode
---@field allow_current_win? boolean Allow scrolling the current window
---@field target_options? OptValueSet
---@field highlights? HighlightDef[]
---@field keys? RoutedKeyDef[]

---@mod rws.module Module

local M = {}
local profiler = require('rws.profiler').enable(false, true)
local swaps = require('rws.opts-swap')
local utils = require('rws.utils')
local api = vim.api
local fn = vim.fn

---@type RwsOptions
M.defaults = {
  debug = false,
  allow_current_win = false,
  target_options = {
    winhighlight = 'NormalNC:Normal',
    cursorline = false,
    statuscolumn = '%#RWSTargetWindow#',
    signcolumn = 'no',
    number = false,
    relativenumber = true,
    foldlevel = 999,
    foldcolumn = '0',
  },
  highlights = {
    {
      'RWSTargetWindow',
      fg = '#556745',
      bg = 'NONE',
    },
  },
  keys = {
    { '<S-Up>', cmd = 'normal! <C-u>', mode = { 'n', 'i' }, desc = 'Scroll the target window up half a page' },
    { '<S-Down>', cmd = 'normal! <C-d>', mode = { 'n', 'i' }, desc = 'Scroll the target window down half a page' },
    { '<S-Left>', cmd = 'normal! <C-y>', mode = { 'n', 'i' }, desc = 'Scroll the target window up one line' },
    { '<S-Right>', cmd = 'normal! <C-e>', mode = { 'n', 'i' } },
  },
}

---@type RwsOptions?
---@private
M.config = nil

---@type WinResult?
---@private
M.__current_target = nil

---@type integer?
---@private
M.__autocmd_group = nil

---@type table<string, string>
---@private
M.__resolved_keys = {}

---Find the target window based on arg
---@private
---@param arg string|integer
---@return Win?, string?
---@see vim.fn.winnr
function M.find_target_win(arg)
  local target_winnr = fn.winnr(arg)
  if target_winnr == 0 then
    return nil, ('Argument did not match any window: %s'):format(arg)
  end

  local target_win = fn.win_getid(target_winnr)
  if target_win == 0 then
    return nil, ('Window id not found for winnr: %s'):format(target_winnr)
  end

  if not M.config.allow_current_win then
    local cur_win = api.nvim_get_current_win()
    if target_win == cur_win then
      return nil, 'Cannot target current window'
    end
  end

  return target_win
end

---Select a target window by winnr arg
---@param target_arg string|integer Target window to select
---@return boolean, string?
---@see vim.fn.winnr
function M.select_target(target_arg)
  local target, err = M.find_target_win(target_arg)
  if not target then
    if err then
      M.__debug(('Invalid window for arg: %s'):format(target_arg))
    end
    return false, err
  end

  local current = M.__current_target
  if current then
    local current_target_win = current.winid
    M.reset_target()
    -- Toggle if the current target is the same as the next target
    if current_target_win == target then
      return false, nil
    end
  end

  assert(not M.__current_target, 'Expected null current target')
  assert(not M.__autocmd_group, 'Expected null autocmd group')

  M.__current_target = swaps.win_swap_opts(target, M.config.target_options)

  -- Create buffer-local autocommands for the target window
  local winid = target
  local bufnr = api.nvim_win_get_buf(winid)
  local group = api.nvim_create_augroup('RWS_Target', { clear = false })

  -- Reset target when it gets focus
  api.nvim_create_autocmd('WinEnter', {
    group = group,
    buffer = bufnr,
    callback = function()
      if M.__current_target and vim.api.nvim_get_current_win() == winid then
        M.reset_target()
      end
    end,
    desc = 'RWS: Reset target when it gets focus',
  })

  -- Unset target when window is closed
  api.nvim_create_autocmd('WinClosed', {
    group = group,
    buffer = bufnr,
    callback = function(args)
      if M.__current_target and tonumber(args.match) == winid then
        M.reset_target(true)
      end
    end,
    desc = 'RWS: Unset target when it gets closed',
  })

  M.__autocmd_group = group
  M.__trace(('Target window %d selected'):format(target))

  return true, nil
end

---Reset the target window to its original state
---@param skip_opts_reset? boolean Skip resetting window options. Useful when the window is closing.
function M.reset_target(skip_opts_reset)
  local current = M.__current_target
  local augroup_id = M.__autocmd_group
  if current then
    M.__trace(('Resetting target window %d'):format(current.winid))
    M.__current_target = nil
    M.__autocmd_group = nil

    if not skip_opts_reset then
      pcall(swaps.reset_opts, current)
    end

    -- Clear autocommands if any
    if augroup_id then
      pcall(api.nvim_del_augroup_by_id, augroup_id)
    end
  end
end

---Route a mapped key to the target window.
---When the target window is not set,
---the key is sent to input.
---@param keyseq string Key Sequence to route
---@return boolean True if the key was routed, false otherwise
function M.route(keyseq)
  M.__trace(("Routing key sequence: '%s'"):format(keyseq))

  if not keyseq or keyseq == '' then
    M.__warn('route: Empty key sequence provided')
    return false
  end

  if keyseq:sub(1, 1) == '<' then
    keyseq = utils.escape_keys(keyseq)
    M.__trace(('route: Escaping key sequence'):format(keyseq))
  end

  if M.__current_target then
    local target = M.__current_target.winid
    if target then
      local cmd = M.__resolved_keys[keyseq]
      if cmd then
        api.nvim_win_call(target, function()
          vim.cmd(cmd)
        end)
        return true
      end
    end
  end

  -- No match, feed keys as input
  M.__trace('route: No target window, feeding keys as input')
  api.nvim_feedkeys(keyseq, 'n', false)
  return false
end

--- Load commands from the specified module
---@private
---@param module string Module name to load commands from
---@return boolean, string? Error message if loading fails
local function load_commands(module)
  local ok, commands = pcall(require, module)
  if not ok or type(commands) ~= 'table' then
    return false, commands
  end

  for _, command in ipairs(commands) do
    ok = pcall(api.nvim_create_user_command, command[1], command[2], command[3])
    if not ok then
      return false, ('Failed to create command %s: %s'):format(command[1], command[2])
    end
  end

  return true, nil
end

---@private
local function hook_notify(debug)
  local notify = vim.notify
  ---@private
  M.__warn = function(s)
    notify(s, vim.log.levels.WARN, { title = 'RWS' })
  end
  ---@private
  M.__error = function(s)
    notify(s, vim.log.levels.ERROR, { title = 'RWS' })
  end
  ---@private
  M.__debug = debug and function(s)
    notify(s, vim.log.levels.DEBUG, { title = 'RWS' })
  end or function() end
  ---@private
  M.__trace = debug == 'verbose' and function(s)
    notify(s, vim.log.levels.TRACE, { title = 'RWS' })
  end or function() end
end

---Initialize the RWS module
---@param opts RwsOptions
function M.setup(opts)
  local pstop = profiler.profile_start('rws_profile_setup')
  -- Load and validate the options
  local config = vim.tbl_deep_extend('force', M.defaults, opts or {})
  hook_notify(config.debug)
  M.__debug(('RWS setup with opts:\n%s'):format(vim.inspect(config)))

  local ok, err = load_commands('rws.commands')
  if not ok then
    M.__error(('Unrecoverable: Failed to load commands: %s'):format(err))
    return
  end

  if #config.keys == 0 then
    M.__warn('No keys provided')
  end

  -- Register keymaps and build the table for resolved key sequences
  M.__resolved_keys = {}
  for _, keydef in ipairs(config.keys) do
    if type(keydef) == 'table' then
      local keyseq = keydef[1]
      local cmd = keydef.cmd

      if keyseq and cmd then
        local mode = keydef.mode or { 'n' }
        local resolved = utils.escape_keys(keyseq)
        vim.keymap.set(mode, keyseq, function()
          M.route(resolved)
        end, { noremap = true, silent = true, desc = keydef.desc })
        M.__resolved_keys[resolved] = utils.escape_keys(keydef.cmd)
      else
        M.__error(('Invalid key definition: %s'):format(vim.inspect(keydef)))
      end
    end
  end

  M.__trace(('Resolved keys:\n%s'):format(vim.inspect(M.__resolved_keys)))

  -- Register highlights
  local highlights = config.highlights or {}
  for _, hl_def in ipairs(highlights) do
    if type(hl_def) == 'table' then
      local hl_name = table.remove(hl_def, 1)
      if hl_name then
        api.nvim_set_hl(0, hl_name, hl_def)
      else
        M.__error('No highlight group name provided for highlight')
      end
    end
  end

  pstop()
  M.config = config
end

return M
