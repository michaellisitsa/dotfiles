-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Virtual lines take up too much space with the LSP diagnostics
-- Showing at current line only is also distracting
-- Instead just have a toggle.
-- When lines are on, text is off.
vim.keymap.set("", "<leader>bl", function()
  vim.diagnostic.config({
    virtual_lines = not vim.diagnostic.config().virtual_lines,
    virtual_text = not vim.diagnostic.config().virtual_text,
  })
end, { desc = "Toggle diagnostic [l]ines" })
