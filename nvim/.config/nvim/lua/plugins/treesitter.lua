-- Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
-- Other good tutorial https://tduyng.com/blog/neovim-highlight-syntax/
vim.pack.add {
	'https://github.com/nvim-treesitter/nvim-treesitter',
}
vim.pack.add {
	{ src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
}
require('nvim-treesitter').setup {
	-- Testing separate directory due to issue with installed parsers
	install_dir = vim.fn.stdpath('data') .. '/site_treesitter'
}
require('nvim-treesitter-textobjects').setup {
	select = {
		-- Automatically jump forward to textobj, similar to targets.vim
		lookahead = true,
		-- You can choose the select mode (default is charwise 'v')
		selection_modes = {
			['@parameter.outer'] = 'v', -- charwise
			['@function.outer'] = 'V', -- linewise
			['@class.outer'] = '<c-v>', -- blockwise
		},
		include_surrounding_whitespace = false,
	},
	move = {
		-- whether to set jumps in the jumplist
		set_jumps = true,
	},
}
-- This should build both treesitter and text-objects
require('utils').BuildAfterUpdate('nvim-treesitter', ':TSUpdate')
require('utils').BuildAfterUpdate('nvim-treesitter-textobjects', ':TSUpdate')
require('nvim-treesitter').install {
	'bash',
	'zsh',
	'c',
	'diff',
	'lua',
	'query',
	'vim',
	'vimdoc',
	'luadoc',
	-- Data
	'markdown',
	'markdown_inline',
	'json',
	'jsonc',
	-- Python
	'python',
	'toml',
	-- Javascript
	'javascript',
	'typescript',
	'tsx',
	'jsdoc',
	-- FE
	'html',
	-- Configuration
	'terraform',
	'yaml',
}

vim.api.nvim_create_autocmd('FileType', {
	-- Treesitter isn't enabled by default in 'main' branch
	-- https://github.com/nvim-treesitter/nvim-treesitter/issues/8053
	-- Also treesitter specific highlight groups have been removed.
	-- https://github.com/nvim-treesitter/nvim-treesitter/issues/4106
	pattern = '*',
	-- Currently the treesitter parsing for certain javascript isn't highlight most elements
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(args.match) or args.match
		local installed = require('nvim-treesitter').get_installed 'parsers'
		if vim.tbl_contains(installed, lang) then
			vim.treesitter.start(args.buf)

			-- Use treesitter folding, already built into neovim
			vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
			vim.wo[0][0].foldmethod = 'expr'

			-- Treesitter-based indentation is provided by this plugin but considered experimental
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})

local select = require 'nvim-treesitter-textobjects.select'
vim.keymap.set({ 'x', 'o' }, 'af', function()
	select.select_textobject('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'if', function()
	select.select_textobject('@function.inner', 'textobjects')
end)
local move = require 'nvim-treesitter-textobjects.move'
vim.keymap.set({ 'n', 'x', 'o' }, ']f', function()
	move.goto_next_start('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[f', function()
	move.goto_previous_start('@function.outer', 'textobjects')
end)
