local keymap = vim.keymap.set
local s = { silent = true }
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
keymap('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

keymap('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
keymap('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
keymap('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
keymap('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
keymap('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

keymap('n', '<C-w>z', '<cmd>Zen<cr>', { desc = 'Center windows' })
keymap('n', '<leader>fm', '<cmd>Oil<cr>', { desc = 'Open File System' })
keymap('n', '<leader>tu', '<cmd>UndotreeToggle<cr>', { desc = 'Toggle Undotree' })

keymap("n", "<Leader>ff", ":lua vim.lsp.buf.format()<CR>", s)                                  -- Format the current buffer using LSP

keymap("n", "<Leader>w", "<cmd>w!<CR>", s)                                                     -- Save the current file

keymap("n", "grd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true }) -- Go to definition
keymap({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })
keymap('n', '<Leader>;', require 'dropbar.api'.pick, { desc = 'Pick symbols in winbar' })

keymap('n', '<leader>hF', '<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>', { desc = 'Review branch changes' })
keymap('n', '<leader>hf',
	function()
		local main_branch = vim.fn.systemlist({
			"git",
			"symbolic-ref",
			"refs/remotes/origin/HEAD",
		})[1]
		local current_branch = vim.fn.systemlist({
			"git",
			"rev-parse",
			"--abbrev-ref",
			"HEAD"
		})[1]
		local merge_base = vim.fn.systemlist({
			"git",
			"merge-base",
			"--fork-point",
			main_branch
		})[1]
		local merge_base_fallback = vim.fn.systemlist({
			"git",
			"merge-base",
			main_branch,
			current_branch

		})[1]
		-- '<cmd>CodeDiff merge_base COMMIT_HASH<cr>'
		vim.api.nvim_cmd({
			cmd = "CodeDiff",
			args = { merge_base == nil and merge_base_fallback or merge_base },
		}, {})
	end, { desc = 'Review branch changes' })

keymap('n', '<leader>r', '<cmd>restart<cr>', { desc = 'Restart' })
keymap('n',
	'<leader>hv',
	function()
		if next(require('diffview.lib').views) == nil then
			vim.cmd 'DiffviewOpen'
		else
			vim.cmd 'DiffviewClose'
		end
	end,
	{ desc = 'Toggle Diffview window' }
)

keymap('n', '<leader>gt', function()
	require('utils').PytestKogan(false)
end)

keymap('n', '<leader>gd', function()
	require('utils').PytestKogan(true)
end)
keymap('n', '<leader>gf', function()
	require('utils').PathBreadcrumbs()
end)

keymap({ 'n', 'v' }, '<leader>hy', '<cmd>GitLink<cr>', { desc = 'Link to GitHub' }) -- linrongbin16/gitlinker.nvim

-- bookmarks.nvim
-- https://github.com/LintaoAmons/VimEverywhere/blob/main/nvim/lua/plugins/editor-enhance/bookmarks.lua
keymap('n', '<leader>mt', '<cmd>' .. 'BookmarksTree' .. '<cr>', { desc = 'Tree' })
keymap('n', '<leader>mg', '<cmd>' .. 'BookmarksGotoRecent' .. '<cr>', { desc = 'Go To Recent' })
keymap('n', '<leader>mm', '<cmd>' .. 'BookmarksMark' .. '<cr>', { desc = 'Mark' })
keymap('n', '<leader>ma', '<cmd>' .. 'BookmarksCommands' .. '<cr>', { desc = 'Commands' })
keymap('n', '<leader>ms', '<cmd>' .. 'BookmarksInfoCurrentBookmark' .. '<cr>', { desc = 'Info' })
keymap('n', '<leader>mo', '<cmd>' .. 'BookmarksGoto' .. '<cr>', { desc = 'GoTo' })
keymap('n', '<leader>ml', '<cmd>' .. 'BookmarksLists' .. '<cr>', { desc = 'Lists' })
keymap('n', '<leader>mn', '<cmd>' .. 'BookmarksGotoNextInList' .. '<cr>', { desc = 'Next' })
keymap('n', '<leader>mp', '<cmd>' .. 'BookmarksGotoPrevInList' .. '<cr>', { desc = 'Prev' })

require 'hydra' {
	name = 'Windows',
	config = {
		invoke_on_body = true,
		hint = {
			offset = -1,
		},
	},
	mode = 'n',
	body = '<C-w>h',
	heads = {
		{ '=',     '<C-w>=',                       { desc = 'equalize' } },
		{ '-',     '<C-w>-',                       { desc = 'Move window bot up' } },
		{ '+',     '<C-w>+',                       { desc = 'Move window bot up' } },
		{ '<',     '<cmd>vertical resize -10<cr>', { desc = 'Move window left' } },
		{ '>',     '<cmd>vertical resize +10<cr>', { desc = 'Move window right' } },
		{ 'q',     nil,                            { exit = true, nowait = true } },
		{ '<Esc>', nil,                            { exit = true, desc = false } },
	},
}

keymap('n', '<leader>fo', '<cmd>Outline<CR>', { desc = '[F]ile [O]utline' })


keymap("n", "<Leader>gy", function()
	local reg = vim.v.register
	if reg == "" then
		reg = '"' -- fallback if no register prefix
	end

	local unnamed, unnamed_t = vim.fn.getreg('"'), vim.fn.getregtype('"')
	local other, other_t = vim.fn.getreg(reg), vim.fn.getregtype(reg)

	vim.fn.setreg('"', other, other_t)
	vim.fn.setreg('+', other, other_t)
	vim.fn.setreg('x', unnamed, unnamed_t) -- Don't lose previous
	vim.notify(string.format('Yanked register %s = %s', reg, other))
end, { desc = "Swap unnamed register with given register" })

-- Gitsigns
--gitsigns.blame_line
keymap("n", "<Leader>hb", require("gitsigns").blame_line, { desc = "git [b]lame line" })
