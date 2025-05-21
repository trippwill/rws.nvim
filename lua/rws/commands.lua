local trim_quotes = require('rws.utils').trim_surrounding_quotes
return {
  {
    'RemWinSelect',
    function(opts)
      local arg = opts.args
      vim.validate('args', arg, { 'string', 'number' }, 'Usage: RemWinSelect <target>')

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
      local keyseq = trim_quotes(opts.args)
      vim.validate('args', keyseq, { 'string' }, 'Usage: RemWinRoute <key> [<key> ...]')
      require('rws').route(keyseq)
    end,
    {
      nargs = '+',
      desc = 'Route a key or key sequence to the target window',
      complete = nil,
    },
  },
}
