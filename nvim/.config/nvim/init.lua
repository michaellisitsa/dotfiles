--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Inspiration https://vieitesss.github.io/posts/Neovim-new-config/
require 'plugins'
require 'telescope-plugins'
require 'configs'
require 'keymaps'
require 'autocmds'
require 'lsp'
