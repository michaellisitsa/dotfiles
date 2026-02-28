-- Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
-- Other good tutorial https://tduyng.com/blog/neovim-highlight-syntax/
vim.pack.add {
	{ src = 'https://github.com/nvim-treesitter/nvim-treesitter', versions = 'main' }
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
local textobjects = {
	{ key = 'f', type = 'function' },
	{ key = 'b', type = 'block',   exclude_move = true },
	{ key = 'k', type = 'class', },
}

for _, obj in ipairs(textobjects) do
	vim.keymap.set({ 'x', 'o' }, 'a' .. obj.key, function()
		select.select_textobject('@' .. obj.type .. '.outer', 'textobjects')
	end)
	vim.keymap.set({ 'x', 'o' }, 'i' .. obj.key, function()
		select.select_textobject('@' .. obj.type .. '.inner', 'textobjects')
	end)
end

local move = require 'nvim-treesitter-textobjects.move'
for _, obj in ipairs(textobjects) do
	if not obj.exclude_move then
		vim.keymap.set({ 'n', 'x', 'o' }, ']' .. obj.key, function()
			move.goto_next_start('@' .. obj.type .. '.outer', 'textobjects')
		end)
		vim.keymap.set({ 'n', 'x', 'o' }, '[' .. obj.key, function()
			move.goto_previous_start('@' .. obj.type .. '.outer', 'textobjects')
		end)
	end
end
