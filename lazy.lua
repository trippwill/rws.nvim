return {
  'trippwill/rws.nvim',
  cmd = {
    'RemWinSelect',
    'RemWinReset',
    'RemWinRoute',
  },
  opts = {},
  config = function(_, opts)
    local rws = require('rws')
    rws.setup(opts)
  end,
  keys = {
    {
      '<M-Up>',
      '<cmd>RemWinSelect k<cr>',
      desc = 'Target window above',
      mode = { 'n', 'i' },
    },
    {
      '<M-Down>',
      '<cmd>RemWinSelect j<cr>',
      desc = 'Target window below',
      mode = { 'n', 'i' },
    },
    {
      '<M-Right>',
      '<cmd>RemWinSelect l<cr>',
      desc = 'Target window to the right',
      mode = { 'n', 'i' },
    },
    {
      '<M-Left>',
      '<cmd>RemWinSelect h<cr>',
      desc = 'Target window to the left',
      mode = { 'n', 'i' },
    },
    {
      '<M-Esc>',
      '<cmd>RemWinReset<cr>',
      desc = 'Reset target window',
      mode = { 'n', 'i' },
    },
    {
      '<Up>',
      '<cmd>RemWinRoute <Up><cr>',
      desc = 'Scroll target window up a line',
      mode = { 'n', 'i' },
    },
    {
      '<Down>',
      '<cmd>RemWinRoute <Down><cr>',
      desc = 'Scroll target window down a line',
      mode = { 'n', 'i' },
    },
    {
      '<S-Up>',
      '<cmd>RemWinRoute <S-Up><cr>',
      desc = 'Scroll target window up a half-page',
    },
    {
      '<S-Down>',
      '<cmd>RemWinRoute <S-Down><cr>',
      desc = 'Scroll target window down a half-page',
    },
  },
}
