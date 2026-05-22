# emojit.nvim

A lightweight, standalone emoji picker for Neovim written in Lua.

![Emoji Picker](https://user-images.githubusercontent.com/placeholder.png)

## Features

- 🚀 Fast and lightweight (zero dependencies).
- 🔍 Real-time filtering/search (search by name or category).
- 🎨 Modern grid-based floating window UI.
- 💡 Dynamic tooltips showing emoji names on hover.
- ⌨️ Insert emojis directly into your buffer.
- 🛠️ Customizable window dimensions and grid layout.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "ginkohub/emojit.nvim",
  opts = {
    columns = 10, -- Number of emojis per row
    width = 50,   -- Window width
    height = 20,  -- Window height
  }
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "ginkohub/emojit.nvim",
  config = function()
    require("emojit").setup({
      columns = 10,
      width = 50,
      height = 20,
    })
  end,
}
```

## Usage

Run the command `:Emojit` to open the picker.

### Default Keymaps (within the picker)

- `i` (Insert Mode):
  - `<CR>`: Select and insert the emoji.
  - `<C-n>`: Move down.
  - `<C-p>`: Move up.
  - `<C-f>`: Move right.
  - `<C-b>`: Move left.
  - `<Esc>`: Close the picker.
- `n` (Normal Mode):
  - `q` or `<Esc>`: Close the picker.
  - `<CR>`: Select and insert.

## Configuration

Default settings:

```lua
require("emojit").setup({
  columns = 8,
  width = 42,
  height = 15,
})
```

## Configuration

Currently, `emojit` works out of the box with no configuration required. More options coming soon!

## License

Mozilla Public License 2.0
