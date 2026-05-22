-- Register command automatically when Neovim starts
vim.api.nvim_create_user_command("Emojit", function()
  require("emojit").open()
end, {})
