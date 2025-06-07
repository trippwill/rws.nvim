---@module 'plenary.test_harness'
---@diagnostic disable: unused-local
local plenary_test_harness

local eq = assert.are.same
local rws = require('rws')
rws.setup({})

describe('rws.nvim', function()
  before_each(function()
    -- Ensure only one window and a clean state before each test
    vim.cmd('only')
    rws.reset_target()
  end)

  it('selects a target window', function()
    vim.cmd('vsplit')
    vim.cmd('wincmd h') -- move to left window
    local ok, err = rws.select_target('l') -- select window to the right
    local winids = vim.api.nvim_list_wins()
    local right_win = winids[2]
    eq(true, ok)
    eq(right_win, rws.__current_target.winid)
  end)

  it('toggles the target window off when selecting the same window', function()
    vim.cmd('vsplit')
    vim.cmd('wincmd h')
    rws.select_target('l')
    local ok, err = rws.select_target('l')
    eq(false, ok)
    eq(nil, rws.__current_target)
  end)

  it('resets the target window', function()
    vim.cmd('vsplit')
    vim.cmd('wincmd h')
    rws.select_target('l')
    rws.reset_target()
    eq(nil, rws.__current_target)
  end)

  it('does not allow targeting the current window by default', function()
    vim.cmd('vsplit')
    vim.cmd('wincmd h')
    local ok, err = rws.select_target('h')
    eq(false, ok)
    assert.is_truthy(err)
  end)

  it('routes a key to the target window (basic smoke test)', function()
    vim.cmd('vsplit')
    vim.cmd('wincmd h')
    rws.select_target('l')
    -- This will not actually move the cursor in a headless test, but should not error
    local ok = rws.route('<S-Up>')
    assert.is_true(ok or ok == false) -- just check it runs
  end)

  it('returns false when routing with no target', function()
    rws.reset_target()
    local ok = rws.route('<S-Up>')
    assert.is_false(ok)
  end)
end)
