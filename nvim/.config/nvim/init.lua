-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Disable copilot globally.
-- To enable on a per case based use
-- `:Copilot enable`
-- Commented out for now because we've uninstalled the plugin
-- vim.cmd(":Copilot disable")

-- Override Ruby File type plugin to use 4 spaces
-- seen by :verbose set shiftwidth? >> nvim/runtime/ftplugin/ruby.vim
vim.api.nvim_create_autocmd("FileType", {
  pattern = "ruby",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})
