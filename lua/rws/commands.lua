return {
  {
    'RemWinSelect',
    function(_opts)
      local arg = _opts.args
      vim.validate('0', arg, { 'string', 'number' }, 'Usage: RemWinSelect <target>')

      require('rws').select_target(arg)
    end,
    {
      nargs = 1,
      desc = 'Select a target window',
    },
  },
  {
    'RemWinReset',
    function()
      require('rws').reset_target()
    end,
    {
      desc = 'Reset the target window',
    },
  },
  {
    'RemWinRoute',
    function(opts)
      local arg = opts.args
      vim.validate('0', arg, { 'string' }, 'Usage: RemWinRoute <key>')

      require('rws').route(arg)
    end,
    {
      nargs = 1,
      desc = 'Route a key to the target window',
    },
  },
}
