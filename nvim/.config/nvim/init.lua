-- vim.pack's lockfile lives in stdpath('config') ('packlockfile', nvim 0.13+;
-- hardcoded in 0.12). Every NVIM_APPNAME instance pointing at this config dir
-- therefore shares ONE lockfile, so a nightly (see `nvn`) gets pinned to the
-- revisions stable installed -- including plugin revs that predate nightly
-- compatibility fixes. Give non-default appnames their own lockfile in their own
-- (already isolated) data dir. Must be set before the first vim.pack call.
if vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME ~= 'nvim' and vim.fn.exists('&packlockfile') == 1 then
	vim.o.packlockfile = vim.fs.joinpath(vim.fn.stdpath('data'), 'nvim-pack-lock.json')
end

--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Inspiration https://vieitesss.github.io/posts/Neovim-new-config/
require 'plugins.telescope'
require 'plugins.treesitter'
require 'plugins.common'
require 'debugging'
require 'configs'
require 'keymaps'
require 'autocmds'
require 'lsp'
