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
}

require('nvim-surround').setup {}
require('gitsigns').setup({})
require('oil').setup({ keymaps = { ['<Esc>'] = 'actions.close' }, view_options = { show_hidden = true } })
require("mason").setup({})
require("vscode").setup({})
require("flash").setup({})
require("dropbar").setup({})
require("diffview").setup({})
