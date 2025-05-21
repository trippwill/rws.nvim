return {
  'trippwill/rws.nvim',
  cmd = {
    'RemWinSelect',
    'RemWinReset',
    'RemWinRoute',
  },
  opts = {},
  dependencies = {
    { 'nvim-lua/plenary.nvim', optional = true },
  },
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
  },
}
