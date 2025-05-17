return {
  'trippwill/rws.nvim',
  cmd = 'RemWinScroll',
  opts = {},
  keys = {
    {
      '<M-Up>',
      '<cmd>RemWinScroll k f half<cr>',
      desc = 'Scroll window above forward half a page',
      mode = { 'n', 'i' },
    },
    {
      '<S-Up>',
      '<cmd>RemWinScroll k b half<cr>',
      desc = 'Scroll window above back half a page',
      mode = { 'n', 'i' },
    },
    {
      '<M-Down>',
      '<cmd>RemWinScroll j f half<cr>',
      desc = 'Scroll window below forward half a page',
      mode = { 'n', 'i' },
    },
    {
      '<S-Down>',
      '<cmd>RemWinScroll j b half<cr>',
      desc = 'Scroll window below back half a page',
      mode = { 'n', 'i' },
    },
    {
      '<M-Right>',
      '<cmd>RemWinScroll l f half<cr>',
      desc = 'Scroll window to right forward half a page',
      mode = { 'n', 'i' },
    },
    {
      '<S-Right>',
      '<cmd>RemWinScroll l b half<cr>',
      desc = 'Scroll window to right back half a page',
      mode = { 'n', 'i' },
    },
    {
      '<M-Left>',
      '<cmd>RemWinScroll h f half<cr>',
      desc = 'Scroll window to left forward half a page',
      mode = { 'n', 'i' },
    },
    {
      '<S-Left>',
      '<cmd>RemWinScroll h b half<cr>',
      desc = 'Scroll window to left back half a page',
      mode = { 'n', 'i' },
    },
  },
}
