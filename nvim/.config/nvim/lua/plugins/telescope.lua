-- Inspiration from https://antoinepoulin.com/blog/2025/08/08/how-to-setup-neovim-0.12-for-c%23-development-with-vim.pack/
vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })
vim.pack.add({ "https://github.com/nvim-telescope/telescope-fzf-native.nvim" }, {
	build = "make",
	cond = function()
		return vim.fn.executable("make") == 1
	end,
})
vim.pack.add({ "https://github.com/nvim-telescope/telescope-live-grep-args.nvim" })
vim.pack.add({ "https://github.com/debugloop/telescope-undo.nvim" })
vim.pack.add({ "https://github.com/nvim-telescope/telescope.nvim" })

local from_entry = require('telescope.from_entry')
local function breadcrumbs_title(self, entry)
	-- your custom logic
	-- can call original_dyn_title(self, entry) as fallback
	local utils = require('utils')

	-- fallback to existing implementation
	-- https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/lua/telescope/previewers/buffer_previewer.lua#L559-L561
	local result = require "plenary.path":new(from_entry.path(entry, false, false)):normalize(vim.uv.cwd())

	if self.state and self.state.bufnr and vim.api.nvim_buf_is_valid(self.state.bufnr) and self.state.winid then
		-- see https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/lua/telescope/previewers/buffer_previewer.lua#L525
		if entry.lnum and entry.lnum > 0 then
			local col, colend = 0, -1
			-- Both col delimiters should be provided for them to take effect.
			-- This is to ensure that column range highlighting was opted in, as `col`
			-- is already used to determine the buffer jump position elsewhere.
			if entry.col and entry.colend then
				col, colend = entry.col - 1, entry.colend - 1
			end
			local bufnr = self.state.bufnr
			local filepath = from_entry.path(entry, false, false)

			-- Detect and set filetype
			local ft = vim.bo[bufnr].filetype
			if filepath and ft == '' then
				ft = vim.filetype.match({ filename = filepath, buf = bufnr })
				if ft then
					vim.bo[bufnr].filetype = ft
				end
			end

			-- Explicitly get parser and parse
			if ft and ft ~= '' then
				local ok, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
				if ok and parser then
					parser:parse()
				end
			end


			result = utils.GetBreadcrumbs(bufnr, entry.lnum, col, self.state.winid)
			return result ~= '' and result or filepath
		end
	end
	return result
end

require('telescope').setup({
	defaults = {
		dynamic_preview_title = true,
		mappings = {
			i = {
				['<C-space>'] = require('telescope.actions').to_fuzzy_refine,
			},
		},
		path_display = {
			"filename_first",
		},
		grep_previewer = function(...)
			local orig_grep_previewer = require('telescope.previewers').vim_buffer_vimgrep.new(...)
			orig_grep_previewer._dyn_title_fn = breadcrumbs_title
			return orig_grep_previewer
		end,
	},
	extensions = {
		live_grep_args = {
			auto_quoting = true,
			mappings = {
				i = {
					['<C-k>'] = require('telescope-live-grep-args.actions').quote_prompt(),
					['<C-i>'] = require('telescope-live-grep-args.actions').quote_prompt { postfix = ' --iglob ' },
					['<C-space>'] = require('telescope.actions').to_fuzzy_refine,
				},
			},
		},
	},
	pickers = {
		['buffers'] = { sort_mru = true, ignore_current_buffer = true, sort_lastused = true, initial_mode = 'normal' },
		colorscheme = {
			enable_preview = true,
		},
	},
})


-- Enable telescope fzf native, if installed
pcall(require("telescope").load_extension, "fzf")
pcall(require('telescope').load_extension, 'live_grep_args')
pcall(require('telescope').load_extension, 'undo')
local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<header>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sp', builtin.registers, { desc = '[S]earch [P]aste Registers' })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set('n', '<leader>sc', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sj', builtin.jumplist, { desc = '[S]earch [J]umps' })
vim.keymap.set('n', '<leader>sg', function()
	require('telescope').extensions.live_grep_args.live_grep_args()
end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>su', function()
	require('telescope').extensions.undo.undo()
end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
-- Shortcut for searching your Neovim configuration files
vim.keymap.set('n', '<leader>sn', function()
	builtin.find_files { cwd = vim.fn.stdpath 'config' }
end, { desc = '[S]earch [N]eovim files' })

vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })

-- Custom Telescope to search Django model files
vim.keymap.set('n', '<leader>sm', function()
	local cmd = {
		'rg',
		'--glob',
		'**/models.py',
		'--glob',
		'!.venv/**',
		'--no-heading',
		'--line-number',
		'--column',
		'class\\s+\\w+\\(',
	}
	local finders = require 'telescope.finders'
	local conf = require('telescope.config').values
	local make_entry = require 'telescope.make_entry'
	local pickers = require 'telescope.pickers'

	local custom_maker = function(entry)
		local original = make_entry.gen_from_vimgrep {
			-- keep path display minimal (we’ll handle display ourselves)
			path_display = { 'tail' },
		} (entry)
		if not original then
			return nil
		end

		-- extract "class Foo()" from the line
		local match = original.text:match 'class%s+%w+%s*%(' or original.text
		match = string.sub(match, 6, -2)

		-- overwrite display
		original.display = function()
			return string.format('%-30s %s:%d', match, original.filename, original.lnum)
		end

		return original
	end

	pickers
	    .new({}, {
		    prompt_title = 'Django Models',
		    finder = finders.new_oneshot_job(cmd, {
			    entry_maker = custom_maker,
		    }),
		    sorter = conf.generic_sorter {},
		    previewer = conf.grep_previewer {},
	    })
	    :find()
end, { desc = 'Search Django models' })
