-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Fix for https://www.trulyao.dev/posts/no-newline-at-end-of-file-vim

vim.opt.fixeol = false
vim.opt.eol = false

-- LSP's will format on save, but tab and Enter are handled by treesitter which ishould also show the correct
-- e.g. run :set indentexpr? will show nvim_treesitter#indent()
-- Note this was insufficient alone for Ruby which uses the FileType plugin to override the options here
-- An autocmd has been added to init.lua to override those ruby's settings
vim.opt.shiftwidth = 4
