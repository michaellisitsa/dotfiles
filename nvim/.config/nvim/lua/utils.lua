local M = {}

function M.PytestKogan(debug)
	local buf = vim.api.nvim_get_current_buf()

	-- 0-indexed row/col
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local col = cursor[2]

	-- Get active parser & tree
	local parser = vim.treesitter.get_parser(buf)
	local tree = parser:parse()[1]
	local root = tree:root()

	-- Small helper provided by Neovim
	local node = root:named_descendant_for_range(row, col, row, col)

	local rel_filepath = vim.fn.expand('%:.')
	if rel_filepath:find('kogan3/') ~= nil then
		rel_filepath = string.sub(rel_filepath, 8)
	end

	local symbol = ''
	if node then
		symbol = vim.treesitter.get_node_text(node, buf):gsub('\n', ' ')
	end

	local str = string.format(
		'./shortcuts.sh %s "%s" -k "%s"',
		debug and 'vscode_tests' or 'test',
		rel_filepath,
		symbol
	)

	vim.fn.setreg('"', str)
	vim.fn.setreg('+', str)
	print('Pytest: ' .. str)
end

function M.PathBreadcrumbs()
	local ok_sources, sources = pcall(require, 'dropbar.sources')
	local ok_utils, utils = pcall(require, 'dropbar.utils')

	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()
	local row, col = unpack(vim.api.nvim_win_get_cursor(win))
	local cursor = { row, col }

	-- Dropbar.nvim has a get_symbols function that concatenates all the document symbols up the treesitter tree. Use if available
	-- https://github.com/Bekaboo/dropbar.nvim/blob/418897fe7828b2749ca78056ec8d8ad43136b695/lua/dropbar/utils/source.lua#L7
	local breadcrumb = ''
	if ok_sources and ok_utils then
		-- Fallback chain: LSP → Treesitter
		local src = utils.source.fallback {
			sources.lsp,
			sources.treesitter,
		}
		local symbols = src.get_symbols(buf, win, cursor)

		local names = {}
		for _, sym in ipairs(symbols or {}) do
			table.insert(names, sym.name)
		end
		breadcrumb = table.concat(names, ' > ')
	end

	local str = string.format(
		'%s|%d | %s',
		vim.fn.expand('%:p'),
		row,
		breadcrumb
	)

	vim.fn.setreg('"', str)
	vim.fn.setreg('+', str)
	print('Yanked location: ' .. str)
end

return M
