# freeze-panes.nvim

A Neovim plugin that lets you pin specific lines or columns in place using floating windows.

## Features

- **Horizontal Freeze (`:Freeze`)**: Pin a specific range of lines to the top of the window.
- **Vertical Freeze (`:VFreeze`)**: Pin specific columns to the left side of the window.
- **Dynamic Hiding**: Automatically hides the frozen pane when your cursor moves under it.
- **Syncing**: Automatically keeps fold states, window sizes, and scroll offsets in sync.

## Installation

Install using your preferred plugin manager:

```lua
-- lazy.nvim
{ 'tunaflsh/freeze-panes.nvim' }
-- vim.pack
vim.pack.add({ 'https://github.com/tunaflsh/freeze-panes.nvim' })
```

## Configuration

`freeze-panes.nvim` works out of the box without any setup. You can customize border separators using the `setup` function:

```lua
require('freeze-panes').setup({
  sep = {
    [''] = '─',  -- Horizontal border separator
    ['V'] = '│', -- Vertical border separator
  },
})
```

## Usage

- `:Freeze` - Freezes selected lines (or current selection in Visual mode) at the top of the buffer. Calling it again toggles off the existing horizontal freeze.
- `:VFreeze` - Freezes selected columns at the left side of the buffer. Calling it again toggles off the existing vertical freeze.
