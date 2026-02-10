vim.lsp.enable({
	"lua_ls",
	"clangd",
	"ts_ls",
	"ty",
	"ruff",
	"yamlls",
})

vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('my.lsp', {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

		local map = function(keys, func, desc, mode)
			mode = mode or 'n'
			vim.keymap.set(mode, keys, func, { buffer = args.buf, desc = 'LSP: ' .. desc })
		end


		-- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
		if client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
			vim.keymap.set("i", "<C-space>", vim.lsp.completion.get, { desc = "trigger autocompletion" })
		end

		map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences Word under cursor')
		map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
		--  To jump back, press <C-t>r
		map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
		map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
		map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
		map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')
		map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
		map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
		--  In C this would take you to the header.
		map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

		-- Auto-format ("lint") on save.
		-- Usually not needed if server supports "textDocument/willSaveWaitUntil".
		if not client:supports_method('textDocument/willSaveWaitUntil')
		    and client:supports_method('textDocument/formatting') then
			vim.api.nvim_create_autocmd('BufWritePre', {
				group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
				buffer = args.buf,
				callback = function()
					vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
				end,
			})
		end

		local virtual_text_settings = {
			source = 'if_many',
			spacing = 2,
			format = function(diagnostic)
				local diagnostic_message = {
					[vim.diagnostic.severity.ERROR] = diagnostic.message,
					[vim.diagnostic.severity.WARN] = diagnostic.message,
					[vim.diagnostic.severity.INFO] = diagnostic.message,
					[vim.diagnostic.severity.HINT] = diagnostic.message,
				}
				return diagnostic_message[diagnostic.severity]
			end,
		}

		-- Toggle diagnostics so they are not as distracting
		-- https://samuellawrentz.com/hacks/neovim/disable-annoying-eslint-lsp-server-and-hide-virtual-text/
		local isLspDiagnosticsVisible = false
		vim.keymap.set('n', '<leader>lx', function()
			isLspDiagnosticsVisible = not isLspDiagnosticsVisible
			vim.diagnostic.config {
				virtual_text = isLspDiagnosticsVisible and virtual_text_settings or false,
				underline = isLspDiagnosticsVisible,
			}
		end)
	end,
})
