local utils = require('utils')
-- stdpath('data') is rewritten by NVIM_APPNAME, so anything stored under it is
-- invisible to other instances sharing this config (see `nvn`). This is the
-- appname-independent data dir, for state that should be shared rather than
-- reinstalled/reduplicated per instance (mason binaries, bookmarks DB).
local stable_data_dir = vim.fs.joinpath(vim.env.XDG_DATA_HOME or vim.fn.expand('~/.local/share'), 'nvim')
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
	{ src = 'https://github.com/OXY2DEV/markview.nvim' },
	{ src = 'https://github.com/3rd/image.nvim' },
	{ src = 'https://github.com/HakonHarnes/img-clip.nvim' },
	{ src = 'https://github.com/MagicDuck/grug-far.nvim' },
	-- { src = 'https://github.com/nemanjamalesija/smart-paste.nvim' },
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
-- Default install_root_dir is stdpath("data").."/mason", so a nightly gets an
-- empty mason and prepends its empty bin dir to PATH -> vim.lsp.enable'd servers
-- find no executable and nothing attaches. Server binaries are nvim-agnostic.
require("mason").setup({ install_root_dir = vim.fs.joinpath(stable_data_dir, 'mason') })
require("vscode").setup({})
utils.Patch_flash_searchstate()
require("flash").setup({
	modes = {
		char = {
			enabled = false,
		},
	}
})
-- nvim 0.13 removed BufModifiedSet ("use OptionSet with pattern 'modified'"),
-- but dropbar still lists it in its default `bar.update_events.buf`, so
-- setup() throws E5113 on nightly. Guarded on the event existing, so this is a
-- no-op on 0.12: drop the dead event and re-add the same behaviour via OptionSet.
local dropbar_opts = {}
if vim.fn.exists('##BufModifiedSet') == 0 then
	dropbar_opts.bar = {
		update_events = {
			buf = { 'FileChangedShellPost', 'TextChanged', 'ModeChanged' },
		},
	}
	vim.api.nvim_create_autocmd('OptionSet', {
		pattern = 'modified',
		callback = function(args)
			require('dropbar.utils').bar.exec('update', { buf = args.buf })
		end,
		desc = 'dropbar: BufModifiedSet replacement for nvim >= 0.13',
	})
end
require("dropbar").setup(dropbar_opts)
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
	-- Pin the bookmarks DB to the stable data dir instead of stdpath("data"), so
	-- an NVIM_APPNAME instance (e.g. the nightly, see `nvn`) shares one
	-- bookmarks.sqlite.db rather than starting an empty one of its own.
	-- Backups stay per-app under stdpath("data").."/bookmarks.backup".
	db_dir = stable_data_dir,
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
require("markview").setup({
	preview = { map_gx = false }
});
require("image").setup({
	backend = "kitty",
	processor = "magick_cli",
	integrations = {
		markdown = {
			resolve_image_path = function(document_path, image_path, fallback)
				-- document_path is the path to the file that contains the image
				-- image_path is the potentially relative path to the image. for
				-- markdown it's `![](this text)`

				-- you can call the fallback function to get the default behavior
				return fallback(document_path, image_path)
			end,
		}
	},
	window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
	editor_only_render_when_focused = true, -- auto show/hide images when the editor gains/looses focus
	tmux_show_only_in_active_window = true, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
})
require("img-clip").setup({
	default = {
		-- Resizes images larger than equiv 1000x800 pixels.
		process_cmd = "magick - -resize  '800000@>' -",
	}
})
vim.keymap.set({ "n", "v" }, "<leader>p", "<cmd>PasteImage<cr>", { desc = "Paste image from clipboard" })
require("codediff").setup({
	highlights = {
		char_brightness = 1.2,
	},
	-- Keymaps in diff view
	keymaps = {
		view = {
			next_file = "]n", -- Next file[n]ame in explorer/history mode
			prev_file = "[n", -- Previous file[n]ame in explorer/history mode
		},
	}
})
-- Show dropbar breadcrumbs in codediff diff panes, without layout jitter.
--
-- codediff force-clears `winbar` on BOTH diff panes on every focus event
-- (session.lua sync_window_ui) and exposes no option to disable it. We re-assert
-- dropbar's winbar on every codediff pane in the tab (windows marked with the
-- `codediff_restore` var), only when it is empty -> both panes keep an equal-height
-- winbar (no alignment shift) and conflict/merge mode's "Ours/Theirs/Result" labels
-- (non-empty) are left untouched.
--
-- The re-set must run in the SAME event *after* codediff's clear: autocmds for one
-- event run back-to-back with a single redraw at the end, so trailing codediff means
-- the winbar is never observed empty -> no flicker. (vim.schedule would defer to the
-- next tick, letting a redraw show the cleared state = the jitter.) codediff creates
-- its per-tab handler at diff-open, newer than a startup autocmd, so we re-register
-- ours *after* open completes (deferred bootstrap) to guarantee it runs last.
local cd_dropbar = vim.api.nvim_create_augroup("DropbarInCodeDiff", { clear = true })
local cd_dropbar_boot = vim.api.nvim_create_augroup("DropbarInCodeDiffBoot", { clear = true })

local function apply_codediff_dropbar()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_is_valid(win)
		    and vim.w[win].codediff_restore
		    and vim.wo[win].winbar == "" then
			vim.wo[win].winbar = "%{%v:lua.dropbar()%}"
		end
	end
end

local function register_codediff_dropbar_handler()
	vim.api.nvim_clear_autocmds({ group = cd_dropbar })
	vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter", "WinEnter", "FileType" }, {
		group = cd_dropbar,
		callback = function()
			-- Runs after codediff's clear (same event) -> synchronous set, no jitter.
			if vim.w[vim.api.nvim_get_current_win()].codediff_restore then
				apply_codediff_dropbar()
			end
		end,
	})
end

-- Re-register the handler after each diff opens so it always trails codediff's
-- freshly-created per-tab autocmds. Deferred so it lands after the open call stack
-- (and thus after codediff's augroup) completes.
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = cd_dropbar_boot,
	pattern = "codediff:///*",
	callback = function()
		vim.schedule(function()
			register_codediff_dropbar_handler()
			apply_codediff_dropbar()
		end)
	end,
})
register_codediff_dropbar_handler()
require('grug-far').setup({})
-- require('smart-paste').setup()
local ts_repeat_move = require "nvim-treesitter-textobjects.repeatable_move"
vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)
-- Restore builtin f, F, t, T so repeatable with ; and ,
vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

-- Navigate git hunks repeatable using ; and ,
local repeat_move = require("repeatable_move")
local next_hunk_repeat, prev_hunk_repeat = repeat_move.make_repeatable_move_pair(require "codediff".next_hunk,
	require "codediff".prev_hunk)
vim.keymap.set({ "n", "x", "o" }, "]h", next_hunk_repeat)
vim.keymap.set({ "n", "x", "o" }, "[h", prev_hunk_repeat)
