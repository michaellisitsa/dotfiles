vim.cmd.packadd('nvim.difftool')
-- Similar to mbill version but auto updates as you scroll
vim.cmd.packadd('nvim.undotree')

vim.pack.add {
	{ src = 'https://github.com/kylechui/nvim-surround' },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/mbbill/undotree" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/Mofiqul/vscode.nvim" },
	{ src = "https://github.com/folke/flash.nvim" },
	{ src = "https://github.com/Bekaboo/dropbar.nvim" },
	{ src = "https://github.com/sindrets/diffview.nvim" },
	{ src = "https://github.com/nmac427/guess-indent.nvim" },
	{ src = "https://github.com/linrongbin16/gitlinker.nvim" },
	{ src = "https://github.com/Goose97/timber.nvim" },
	-- Note issue with using function call type string
	-- in upstream sqlite https://github.com/kkharji/sqlite.lua/issues/182
	{ src = "https://github.com/kkharji/sqlite.lua" }, -- Dependency of bookmarks.nvim
	{ src = "https://github.com/LintaoAmons/bookmarks.nvim", version = 'v4.0.0' },
	{ src = "https://github.com/nvimtools/hydra.nvim" }, -- Config in debugging and keymaps files
	{ src = "https://github.com/hedyhli/outline.nvim" },
}


require('nvim-surround').setup {}
require('gitsigns').setup({})
require('oil').setup({ keymaps = { ['<Esc>'] = 'actions.close' }, view_options = { show_hidden = true } })
require("mason").setup({})
require("vscode").setup({})
require("flash").setup({})
require("dropbar").setup({})
require("diffview").setup({})
require("guess-indent").setup({})
require("gitlinker").setup({})
require('timber').setup({
	log_templates = {
		default = {
			javascript = [[console.log("%log_marker %line_number: %log_target", %log_target)]],
			typescript = [[console.log("%log_marker %filename %line_number: %log_target", %log_target)]],
			tsx = [[console.log("%log_marker %filename %line_number: %log_target", %log_target)]],
			python = [[print(f"%log_marker %filename %line_number: {%log_target=}")]],
		},
		plain = {
			javascript = [[console.log("%log_marker %filename %line_number: %insert_cursor")]],
			typescript = [[console.log("%log_marker %filename %line_number: %insert_cursor")]],
			tsx = [[console.log("%log_marker %filename %line_number: %insert_cursor")]],
			python = [[print(f"%log_marker %filename %line_number: %insert_cursor")]],
		},
	},
	log_marker = 'Log:',
})
local opts = {
	backup = {
		-- Default backup dir: vim.fn.stdpath("data").."/bookmarks.backup"
		enabled = true,
	},
	treeview = {
		keymap = {
			['<Enter>'] = {
				action = 'goto',
				desc = 'Go to bookmark location in previous window',
			},
		},
		render_bookmark = require("utils").RenderBookmark,
		window_split_dimension = 140,
	},
}
-- plugins/*.lua will be called only after the user config is loaded.
-- bookmarks.nvim resets vim.g.bookmarks_config to nil, and setup() sets it, so we folow that order
-- https://github.com/LintaoAmons/bookmarks.nvim/issues/100
vim.cmd.runtime('plugin/bookmarks.lua')
require('bookmarks').setup(opts)
require('outline').setup {
	symbols = {
		filter = { 'String', 'Constant', exclude = true },
	},
}
