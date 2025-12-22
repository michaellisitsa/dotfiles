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

keymap('n', '<leader>hf', '<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>', { desc = 'Review branch changes' })
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
