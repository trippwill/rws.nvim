---@mod opts-swap.intro Introduction
---@brief [[
--- Module for swapping and resetting Vim options.
--- Provides functions to set options on windows, buffers, globally, or locally,
--- while returning the previous values for easy restoration.
---@brief ]]

---@mod opts-swap.types Types

---@alias OptValueSet table<string, any> A map of option names to their values.

---@brief [[
---The result of swapping options. A table containing the previous values of the options.
---Will also include the target of the swap.
---Always one of WinResult, BufferResult, GlobalResult, or LocalResult.
---@brief ]]
---@class OptValueResult : table<string, any>

---@class WinResult : OptValueResult The result of swapping options on a window.
---@field winid integer

---@class BufferResult : OptValueResult The result of swapping options on a buffer.
---@field bufnr integer

---@class GlobalResult : OptValueResult The result of swapping options globally.
---@field global true

---@class LocalResult : OptValueResult The result of swapping options locally.
---@field local true

---@mod opts-swap.module Module

local M = {}
local api = vim.api
local set_option = api.nvim_set_option_value
local get_option = api.nvim_get_option_value

---Set options on a target (window, buffer, global, or local) and return the previous values.
---@param opt_set OptValueSet
---@param target vim.api.keyset.option
---@return OptValueResult
local function swap_opts(opt_set, target)
  local result = {}

  for k, v in pairs(opt_set) do
    result[k] = get_option(k, target)
    local next_value = type(v) == 'function' and v(result[k]) or v
    local ok, res = pcall(set_option, k, next_value, target)
    if not ok then
      vim.notify(('Error setting option %s: %s'):format(k, res), vim.log.levels.ERROR, { title = 'RWS' })
    end
  end

  return result
end

---Set options on a window, returning the previous values
---@param winid integer
---@param opt_set OptValueSet
---@return WinResult
function M.win_swap_opts(winid, opt_set)
  local result = swap_opts(opt_set, { win = winid }) --[[@as WinResult]]
  result.winid = winid
  return result
end

---Set options on a buffer, returning the previous values
---@param bufnr integer
---@param opt_set OptValueSet
---@return BufferResult
function M.buf_swap_opts(bufnr, opt_set)
  local result = swap_opts(opt_set, { buf = bufnr }) --[[@as BufferResult]]
  result.bufnr = bufnr
  return result
end

---Set options globally, returning the previous values
---@param opt_set OptValueSet
---@return GlobalResult
function M.global_swap_opts(opt_set)
  local result = swap_opts(opt_set, { scope = 'global' }) --[[@as GlobalResult]]
  result.global = true
  return result
end

---Set options locally, returning the previous values
---@param opt_set OptValueSet
---@return LocalResult
function M.local_swap_opts(opt_set)
  local result = swap_opts(opt_set, { scope = 'local' }) --[[@as LocalResult]]
  result['local'] = true
  return result
end

---Reset the options to their original values
---@param opt_result OptValueResult
---@return boolean, string?
function M.reset_opts(opt_result)
  if not opt_result then
    return false, 'No options to reset'
  end

  local target = nil

  if opt_result['global'] then
    target = { scope = 'global' }
    opt_result['global'] = nil
  elseif opt_result['local'] then
    target = { scope = 'local' }
    opt_result['local'] = nil
  elseif opt_result['bufnr'] then
    target = { buf = opt_result['bufnr'] }
    opt_result['bufnr'] = nil
  elseif opt_result['winid'] then
    target = { win = opt_result['winid'] }
    opt_result['winid'] = nil
  else
    return false, 'Invalid target for reset'
  end

  for k, v in pairs(opt_result) do
    pcall(set_option, k, v, target)
  end

  return true
end

return M
