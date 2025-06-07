# RWS.nvim

Remote Window System for Neovim — control and send commands to unfocused windows.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Configuration](#configuration)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- Route keypresses and commands to unfocused target windows
- Scroll, move, or execute custom actions in target windows even when you're in insert mode
- Visual highlight for the active target window
- Easily reset or change the target at any time
- Extensible key routing and configuration

---

## Installation

**Requirements:**
- Neovim 0.11+
- (Optional) [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for profiling and running tests

**With [lazy.nvim](https://github.com/folke/lazy.nvim):**

```lua
{
  'trippwill/rws.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', optional = true },
  opts = {},
}
```

A [lazy.lua](./lazy.lua) file is included with default configuration and keymaps for scrolling the target window.

When using lazy.nvim, it will be loaded automatically.

---

## Quick Start

1. **Install the plugin** using your plugin manager.
2. **Use the default key bindings** (see below) or configure your own.
3. **Try it out:**
   - Open multiple windows (`:vsplit`, `:split`, etc).
   - Use `<M-Up>`, `<M-Down>`, `<M-Left>`, `<M-Right>` to select a target window.
   - Use `<S-Up>`, `<S-Down>`, `<S-Up>`, `<S-Down>` to scroll the target window.
   - Press `<M-Esc>` to reset the target.

---

## Usage

### Default Key Bindings

| Key           | Action                                 | Mode        |
|---------------|----------------------------------------|-------------|
| `<M-Up>`      | Target window above                    | Normal/Insert |
| `<M-Down>`    | Target window below                    | Normal/Insert |
| `<M-Left>`    | Target window to the left              | Normal/Insert |
| `<M-Right>`   | Target window to the right             | Normal/Insert |
| `<M-Esc>`     | Reset target window                    | Normal/Insert |
| `<S-Up>`        | Scroll target window up a line         | Normal/Insert |
| `<S-Down>`      | Scroll target window down a line       | Normal/Insert |
| `<S-Up>`      | Scroll target window up a half-page    | Normal/Insert          |
| `<S-Down>`    | Scroll target window down a half-page  | Normal/Insert          |

### Commands

- `:RemWinSelect {direction|winnr}` — Select a target window (by direction or number)
- `:RemWinReset` — Reset the target window to its original state
- `:RemWinRoute {key}` — Route a key or key sequence to the target window

---

## Configuration

Customize RWS via the `opts` table:

| Option              | Type                | Description                                 | Default                |
|---------------------|---------------------|---------------------------------------------|------------------------|
| `debug`             | boolean/"verbose"   | Enable debug mode                           | `false`                |
| `allow_current_win` | boolean             | Allow targeting the current window          | `false`                |
| `target_options`    | table               | Options to apply to the target window       | See below              |
| `highlights`         | table               | Highlight groups to define when the plugin is loaded       | See below              |
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

**Default `highlights`:**

```lua
{
  { 'RWSTargetWindow', fg = '#556745', bg = 'NONE' }
}
```

**Default `keys`:**

```lua
  {
    { '<S-Up>', cmd = 'normal! <C-u>', mode = { 'n', 'i' }, desc = 'Scroll the target window up half a page' },
    { '<S-Down>', cmd = 'normal! <C-d>', mode = { 'n', 'i' }, desc = 'Scroll the target window down half a page' },
    { '<S-Left>', cmd = 'normal! <C-y>', mode = { 'n', 'i' }, desc = 'Scroll the target window up one line' },
    { '<S-Right>', cmd = 'normal! <C-e>', mode = { 'n', 'i' } },
  }
```

---

## How It Works

RWS temporarily applies custom options and highlights to a target window. Keypresses are routed to the target using user commands, allowing you to scroll or execute actions in any window without changing focus. The target is automatically reset if you focus it or close it.

---

## Troubleshooting

**No effect when routing keys?**
- Make sure you have selected a target window using the key bindings or `:RemWinSelect`.
- Key sequences are not routable if not defined in your `keys` config.
- When using the default lazy.nvim config, only the commands `:RemWinSelect` and `:RemWinReset` will autoload the plugin.

**Cannot target the current window?**
- By default, targeting the current window is disabled. Set `allow_current_win = true` in your config to override. Fair warning, this is a strange experience.

**Plugin not loading or commands missing?**
- Ensure you are using Neovim 0.11 or newer.
- If using lazy-loading, make sure the `cmd` and `keys` options are set in your plugin spec, like they are in the default `lazy.lua` file.

**Profiling errors or missing features?**
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) is optional, and is only required for development. Install it if you want to profile or run tests.

**Still having issues?**
- Enable debug mode: set `debug = true` or `debug = "verbose"` in your config for more logging.
- Open an issue with details and your configuration.

---

## Contributing

Contributions are welcome!

- Fork the repository and create a feature branch.
- Add or update tests in `tests/` as appropriate.
- Run tests with `sh test.sh`. Ensure Neovim 0.11+
  and [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) are installed.
- For documentation, see and update the Lua docstrings and run `sh doc.sh` to regenerate help files. Docstrings are parsed by vimcat.
- Open a pull request with a description of your changes.

For questions or feature requests, open an issue or start a discussion.

---

## License

Apache License 2.0 — see [LICENSE](./LICENSE) for details.

---

For advanced usage, custom key routing, or troubleshooting, see the help file: `:help rws.nvim`
