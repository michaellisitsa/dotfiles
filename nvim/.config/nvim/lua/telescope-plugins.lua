-- Inspiration from https://antoinepoulin.com/blog/2025/08/08/how-to-setup-neovim-0.12-for-c%23-development-with-vim.pack/
vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })
vim.pack.add({ "https://github.com/nvim-telescope/telescope-fzf-native.nvim" }, {
	build = "make",
	cond = function()
		return vim.fn.executable("make") == 1
	end,
})
vim.pack.add({ "https://github.com/nvim-telescope/telescope.nvim" })


require('telescope').setup({})


-- Enable telescope fzf native, if installed
pcall(require("telescope").load_extension, "fzf")

local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<header>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set('n', '<leader>sc', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sj', builtin.jumplist, { desc = '[S]earch [J]umps' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })
