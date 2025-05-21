local swaps = require('rws.opts-swap')

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

---@class HighlightDef : vim.api.keyset.highlight
---@field [1] string

---@class RwsOptions
---@field debug? boolean | 'verbose' Enable debug mode
---@field allow_current_win? boolean Allow scrolling the current window
---@field target_options? OptValueSet
---@field target_hl? HighlightDef
---@field keys? RoutedKeyDef[]

---@mod rws.module Module

local M = {}

---@type RwsOptions
M.defaults = {
  debug = false,
  allow_current_win = false,
  target_options = {
    winhighlight = 'NormalNC:VisualNOS',
    cursorline = false,
    statuscolumn = '%#RWSTargetWindow#',
    signcolumn = 'no',
    number = false,
    relativenumber = true,
    foldlevel = 999,
    foldcolumn = '0',
  },
  target_hl = {
    'RWSTargetWindow',
    fg = '#556745',
    bg = 'NONE',
  },
  keys = {
    { '<S-Up>', cmd = 'normal! <C-u>' },
    { '<S-Down>', cmd = 'normal! <C-d>' },
    { '<Up>', cmd = 'normal! <C-y>' },
    { '<Down>', cmd = 'normal! <C-e>' },
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

---@type table<string, string>
---@package
---@private
M.resolved_keys = {}

---Find the target window based on arg
---@private
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
      return nil, 'Curent window is not allowed to be target'
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
    if err and M.config.debug then
      vim.notify(err or ('Invalid window for arg: ' .. target_arg), vim.log.levels.DEBUG, { title = 'RWS' })
    end

    return false, err
  end

  local current = M.current_target
  if current then
    local current_win = current.winid
    M.current_target = nil
    local ok = pcall(swaps.reset_opts, current)
    if not ok and M.config.debug then
      vim.notify(
        ('Failed to reset target window %d: %s'):format(current_win, vim.inspect(current)),
        vim.log.levels.ERROR,
        { title = 'RWS' }
      )
    end

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

---Reset the target window to its original state
function M.reset_target()
  local current = M.current_target
  if current then
    pcall(swaps.reset_opts, current)
    M.current_target = nil
  end
end

---Route a mapped key to the target window.
---When the target window is not set,
---the key is sent to input.
---@param key string Key to route
---@return boolean True if the key was routed, false otherwise
function M.route(key)
  -- If the key contains < then replace termcodes
  if key:find('<') then
    key = vim.api.nvim_replace_termcodes(key, true, false, true)
  end

  if M.config.debug == 'verbose' then
    vim.notify(('Routing key %s'):format(key), vim.log.levels.DEBUG, { title = 'RWS' })
  end

  if M.current_target then
    local target = M.current_target.winid
    if target then
      local keymap = M.resolved_keys[key]
      if keymap then
        vim.api.nvim_win_call(target, function()
          vim.cmd(keymap)
        end)
        return true
      elseif M.config.debug then
        vim.notify(('Key %s not found in RWS keys'):format(key), vim.log.levels.DEBUG, { title = 'RWS' })
      end
    end
  end

  vim.api.nvim_feedkeys(key, 'n', false) -- n is noremap
  return false
end

---Initialize the RWS module
---@param opts RwsOptions
function M.setup(opts)
  local escape = function(cmd)
    return vim.api.nvim_replace_termcodes(cmd, true, false, true)
  end

  local ok, commands = pcall(require, 'rws.commands')
  if not ok then
    vim.notify(
      ('Fatal: Failed to load user command definitions: '):format(commands),
      vim.log.levels.ERROR,
      { title = 'RWS' }
    )
    return
  end

  local config = vim.tbl_deep_extend('force', M.defaults, opts or {})

  if config.debug then
    vim.notify(('RWS setup with opts:\n%s'):format(vim.inspect(config)), vim.log.levels.DEBUG, { title = 'RWS' })
  end

  if #config.keys == 0 then
    vim.notify('No keys provided for RWS', vim.log.levels.WARN, { title = 'RWS' })
  end

  for _, key in ipairs(config.keys) do
    if type(key) == 'table' and key[1] and key.cmd then
      M.resolved_keys[escape(key[1])] = escape(key.cmd)
    end
  end

  if config.debug == 'verbose' then
    vim.notify(('RWS keys resolved:\n%s'):format(vim.inspect(M.resolved_keys)), vim.log.levels.DEBUG, { title = 'RWS' })
  end

  for _, command in ipairs(commands) do
    if config.debug == 'verbose' then
      vim.notify(
        ('Creating command %s with opts: %s'):format(command[1], vim.inspect(command[3])),
        vim.log.levels.DEBUG,
        { title = 'RWS' }
      )
    end
    vim.api.nvim_create_user_command(command[1], command[2], command[3])
  end

  local target_hl = config.target_hl
  if target_hl then
    local hl_def = {}
    for k, v in pairs(target_hl) do
      hl_def[k] = v
    end
    local hl_name = table.remove(hl_def, 1)
    if hl_name then
      vim.api.nvim_set_hl(0, hl_name, hl_def)
    else
      vim.notify('No highlight group name provided for target_hl', vim.log.levels.ERROR, { title = 'RWS' })
    end
  end

  -- Autoreset when target window gets focus
  vim.api.nvim_create_autocmd('WinEnter', {
    callback = function()
      if M.current_target and vim.api.nvim_get_current_win() == M.current_target.winid then
        M.reset_target()
      end
    end,
    desc = 'RWS: Reset target when it gets focus',
  })

  -- Clear the current target when the window is closed
  vim.api.nvim_create_autocmd('WinClosed', {
    callback = function(args)
      if M.current_target and tonumber(args.match) == M.current_target.winid then
        M.current_target = nil
      end
    end,
    desc = 'RWS: Unset target when it gets closed',
  })

  M.config = config
end

return M
