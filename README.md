# RWS.nvim

Remote Window System for Neovim — control and send commands to unfocused windows.

## Features

- Route keypresses and commands to any window, even when it's not focused
- Scroll, move, or execute custom actions in target windows
- Visual highlight for the active target window
- Easily reset or change the target at any time
- Extensible key routing and configuration

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'trippwill/rws.nvim'
}
```

The plugin repo contains a [lazy.lua](./lazy.lua) with a default configuration. With [lazy.nvim](https://github.com/folke/lazy.nvim)
the file is automatically loaded when the plugin is installed. You can use it as a reference for your own configuration.

**lazy.lua**:
```lua
{
  'trippwill/rws.nvim',
  cmd = { 'RemWinSelect', 'RemWinReset', 'RemWinRoute' },
  opts = {},
  keys = {
    { '<M-Up>',    '<cmd>RemWinSelect k<cr>', desc = 'Target window above', mode = { 'n', 'i' } },
    { '<M-Down>',  '<cmd>RemWinSelect j<cr>', desc = 'Target window below', mode = { 'n', 'i' } },
    { '<M-Right>', '<cmd>RemWinSelect l<cr>', desc = 'Target window to the right', mode = { 'n', 'i' } },
    { '<M-Left>',  '<cmd>RemWinSelect h<cr>', desc = 'Target window to the left', mode = { 'n', 'i' } },
    { '<M-Esc>',   '<cmd>RemWinReset<cr>',    desc = 'Reset target window', mode = { 'n', 'i' } },
    { '<Up>',      '<cmd>RemWinRoute <Up><cr>', desc = 'Scroll target window up a line', mode = { 'n', 'i' } },
    { '<Down>',    '<cmd>RemWinRoute <Down><cr>', desc = 'Scroll target window down a line', mode = { 'n', 'i' } },
    { '<S-Up>',    '<cmd>RemWinRoute <S-Up><cr>', desc = 'Scroll target window up a half-page' },
    { '<S-Down>',  '<cmd>RemWinRoute <S-Down><cr>', desc = 'Scroll target window down a half-page' },
  },
}
```

## Usage (with Default Key Bindings)

- Use `<M-Up>`, `<M-Down>`, `<M-Left>`, `<M-Right>` to select a target window in that direction.
- Use `<Up>`, `<Down>`, `<S-Up>`, `<S-Down>` to scroll the target window.
- `<M-Esc>` resets the target window.

### Commands

- `:RemWinSelect {direction|winnr}` — Select a target window (by direction or number)
- `:RemWinReset` — Reset the target window to its original state
- `:RemWinRoute {key}` — Route a key to the target window

## Configuration

You can customize RWS via the `opts` table:

| Option              | Type                | Description                                 | Default                |
|---------------------|---------------------|---------------------------------------------|------------------------|
| `debug`             | boolean/"verbose"   | Enable debug mode                           | `false`                |
| `allow_current_win` | boolean             | Allow targeting the current window          | `false`                |
| `target_options`    | table               | Options to apply to the target window       | See below              |
| `target_hl`         | table               | Highlight group for the target window       | See below              |
| `keys`              | table               | Routed key definitions                      | See below              |

**Default `target_options`:**

```lua
{
  winhighlight = 'NormalNC:VisualNOS',
  cursorline = false,
  statuscolumn = '%#RWSTargetWindow#',
  signcolumn = 'no',
  number = false,
  relativenumber = true,
  foldlevel = 999,
  foldcolumn = '0',
}
```

**Default `target_hl`:**

```lua
{ 'RWSTargetWindow', fg = '#556745', bg = 'NONE' }
```

**Default `keys`:**

```lua
{
  { '<S-Up>',   cmd = 'normal! <C-u>' },
  { '<S-Down>', cmd = 'normal! <C-d>' },
  { '<Up>',     cmd = 'normal! <C-y>' },
  { '<Down>',   cmd = 'normal! <C-e>' },
}
```

## How It Works

RWS temporarily applies custom options and highlights to a target window. Keypresses are routed to the target using user commands, allowing you to scroll or execute actions in any window without changing focus. The target is automatically reset if you focus it or close it.

## License

Apache License 2.0 — see [LICENSE](./LICENSE) for details.

---

For advanced usage, custom key routing, or troubleshooting, see the help file: `:help rws.nvim`


