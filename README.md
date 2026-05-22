# emojit.nvim

A lightweight, standalone emoji picker for Neovim written in Lua.

![Emoji Picker](https://user-images.githubusercontent.com/placeholder.png)

## Features

- 🚀 Fast and lightweight (zero dependencies).
- 🔍 Real-time filtering/search.
- 🎨 Modern floating window UI.
- ⌨️ Insert emojis directly into your buffer.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "ginkohub/emojit.nvim" }
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use "ginkohub/emojit.nvim"
```

*Note: The command `:Emojit` is registered automatically. You only need to call `setup()` if you want to pass configuration (currently optional).*

## Usage

Run the command `:Emojit` to open the picker.

### Default Keymaps (within the picker)

- `i` (Insert Mode):
  - `<CR>`: Select and insert the emoji.
  - `<C-n>`: Move selection down.
  - `<C-p>`: Move selection up.
  - `<Esc>`: Close the picker.
- `n` (Normal Mode):
  - `q` or `<Esc>`: Close the picker.

## Configuration

Currently, `emojit` works out of the box with no configuration required. More options coming soon!

## License

Mozilla Public License 2.0
