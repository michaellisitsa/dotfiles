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
	{ src = "https://github.com/catppuccin/nvim" },
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
	{ src = "https://github.com/MunifTanjim/nui.nvim" },
	{ src = "https://github.com/esmuellert/codediff.nvim" },
	{ src = 'https://github.com/kiyoon/repeatable-move.nvim' },
}


require('nvim-surround').setup {
	surrounds = {
		['<M-">'] = {
			add = { '"""', '"""' },
			find = '""".-"""',
			delete = "^(...)().-(...)()$",
		},
		["<M-`>"] = {
			add = { "```", "```" },
			find = "```.-```",
			delete = "^(...)().-(...)()$",
		},
	},
}
require('gitsigns').setup({})
require('oil').setup({ keymaps = { ['<Esc>'] = 'actions.close' }, view_options = { show_hidden = true } })
require("mason").setup({})
require("vscode").setup({})
require("flash").setup({
	modes = {
		char = {
			enabled = false,
		},
	}
})
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
local codediff = require("codediff").setup({
	highlights = {
		char_brightness = 1.2,
	},
	-- Keymaps in diff view
	keymaps = {
		view = {
			next_file = "]n", -- Next file[n]ame in explorer/history mode
			prev_file = "[n", -- Previous file[n]ame in explorer/history mode
		},

		explorer = {
			toggle_stage = "s", -- matches diffview
		},
	}
})

local ts_repeat_move = require "nvim-treesitter-textobjects.repeatable_move"
vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)
-- Restore builtin f, F, t, T so repeatable with ; and ,
vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

local repeat_move = require("repeatable_move")
-- Waiting for codediff allow calling actions
-- https://github.com/esmuellert/codediff.nvim/issues/217
local next_hunk_repeat, prev_hunk_repeat = repeat_move.make_repeatable_move_pair(require "codediff".next_hunk,
	require "codediff".prev_hunk)
vim.keymap.set({ "n", "x", "o" }, "]h", next_hunk_repeat)
vim.keymap.set({ "n", "x", "o" }, "[h", prev_hunk_repeat)
