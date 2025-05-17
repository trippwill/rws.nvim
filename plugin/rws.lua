vim.api.nvim_create_user_command('RemWinScroll', function(opts)
  local args = vim.fn.split(opts.args, ' ')
  if #args < 3 then
    vim.notify('Usage: RemWinScroll <target> <scroll_direction> <scroll_amount>', vim.log.levels.ERROR)
    return
  end

  require('rws').scroll(args[1], args[2], args[3])
end, {
  nargs = '+',
  desc = 'Scroll a remote window',
})
