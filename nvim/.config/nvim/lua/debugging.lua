-- https://github.com/cgimenes/dotfiles/blob/4ad8cadf1c9ede5ee46f4f4a9be01b7cd0f9d562/nvim/.config/nvim/lua/plugins/debug.lua
vim.pack.add {
	'https://github.com/mfussenegger/nvim-dap-python',
	'https://github.com/mfussenegger/nvim-dap',
}
local dap = require 'dap'

require('dap-python').setup 'uv'

-- DAP UI
vim.pack.add { 'https://github.com/igorlfs/nvim-dap-view' }
require('dap-view').setup {
	auto_toggle = true,
	windows = {
		terminal = {
			position = 'right',
		},
	},
}
vim.keymap.set('n', '<leader>du', '<cmd>DapViewToggle!<cr>', { desc = 'Dap UI' })
-- Use nvim-dap builtin UI widgets for scopes
-- https://github.com/igorlfs/dotfiles/blob/76781206733c96dfef3cc5334e0b2aa3de9fa2db/nvim/.config/nvim/lua/plugins/bare/nvim-dap.lua#L8-L15
vim.keymap.set('n',
	"<leader>ds",
	function()
		local widgets = require("dap.ui.widgets")
		widgets.centered_float(widgets.scopes, { border = "rounded" })
	end,
	{
		desc = "DAP Scopes",
	}
)
vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, { desc = 'Toggle Breakpoint' })
vim.keymap.set('n', '<leader>dc', function() dap.continue() end, { desc = 'Run/Continue' })
vim.keymap.set('n', '<leader>di', function() dap.step_into() end, { desc = 'Step Into' })
vim.keymap.set('n', '<leader>do', function() dap.step_out() end, { desc = 'Step Out' })
vim.keymap.set('n', '<leader>dn', function() dap.step_over() end, { desc = 'Step Over' })
vim.keymap.set('n', '<leader>dm', function() dap.run_to_cursor() end, { desc = 'Run to cursor' })
vim.keymap.set('n', '<leader>dk', function() dap.up() end, { desc = 'Up Scope' })
vim.keymap.set('n', '<leader>dj', function() dap.down() end, { desc = 'Down Scope' })
vim.keymap.set('n', '<leader>dt', function() dap.terminate() end, { desc = 'Terminate' })
vim.keymap.set('n', '<leader>dp', function() dap.disconnect({ terminateDebuggee = false }) end, { desc = 'Disconnect' })

-- https://github.com/r0nsha/dotfiles/blob/master/nvim/lua/plugins/dap/hydra.lua#L82
--
local dv = require "dap-view"
---@param view dapview.Section
local function jump_to_view(view)
	return function()
		dv.open()
		dv.jump_to_view(view)
	end
end
-- Debugging
-- https://github.com/anuvyklack/hydra.nvim/issues/3#issuecomment-1162988750
require "hydra" {
	config = {
		color = 'pink',
		invoke_on_body = true,
		hint = {
			position = 'bottom',
		},
	},
	name = 'dap',
	mode = { 'n', 'x' },
	body = '<leader>dh',
	heads = {
		{ 'b',     dap.toggle_breakpoint,                                             { silent = true } },
		{ 'c',     dap.continue,                                                      { silent = true } },
		{ 'i',     dap.step_into,                                                     { silent = true } },
		{ 'o',     dap.step_out,                                                      { silent = true } },
		{ 'n',     dap.step_over,                                                     { silent = true } },
		{ 'm',     dap.run_to_cursor,                                                 { silent = true } },
		-- Do not remap j and k to move scopes
		{ 't',     dap.terminate,                                                     { silent = true } },
		{ 'p',     ":lua require'dap'.disconnect({ terminateDebuggee = false })<CR>", { exit = true, silent = true } },
		{ 'q',     nil,                                                               { exit = true, nowait = true } },
		{ '<Esc>', nil,                                                               { exit = true, desc = false } },
		{ "gw",    jump_to_view "watches",                                            { desc = "Jump to Watches", private = true } },
		{ "gs",    jump_to_view "scopes",                                             { desc = "Jump to Scopes", private = true } },
		{ "gx",    jump_to_view "exceptions",                                         { desc = "Jump to Exceptions", private = true } },
		{ "gb",    jump_to_view "breakpoints",                                        { desc = "Jump to Breakpoints", private = true } },
		{ "gT",    jump_to_view "threads",                                            { desc = "Jump to Threads", private = true } },
		{ "gR",    jump_to_view "repl",                                               { desc = "Jump to REPL", private = true } },
		{ "gC",    jump_to_view "console",                                            { desc = "Jump to Console", private = true } },
	},
}
