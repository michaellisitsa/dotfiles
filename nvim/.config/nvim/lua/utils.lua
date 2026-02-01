local M = {}

local function truncate(str, max)
	if not str then
		-- Todo make this the full length
		return ''
	end
	str = str:match '^%s*(.*)$'
	if string.len(str) <= max then
		return str
	end
	return str:sub(1, max - 1) .. '…'
end

function M.PytestKogan(debug, autorun)
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

	if autorun and debug then
		-- Run the command in a new integrated terminal.
		vim.cmd('botright split | terminal ' .. str)

		-- Kick off the debugger using the option from
		-- require('dap').configurations.python, with the name "Attach Auto"
		vim.defer_fn(function()
			local dap = require('dap')
			for _, config in ipairs(dap.configurations.python) do
				if config.name == 'Attach Auto' then
					dap.run(config)
					break
				end
			end
		end, 2000)

		print("Ran command: " .. str)
	end
end

-- @return string Breadcrumb path like "Class > method > inner"
function M.GetBreadcrumbs(buf, row, col, win)
	local ok_sources, sources = pcall(require, 'dropbar.sources')
	local ok_utils, utils = pcall(require, 'dropbar.utils')
	if not (ok_sources and ok_utils) then
		return ''
	end

	local cursor = { row, col }

	-- Dropbar.nvim has a get_symbols function that concatenates all the document symbols up the treesitter tree. Use if available
	-- https://github.com/Bekaboo/dropbar.nvim/blob/418897fe7828b2749ca78056ec8d8ad43136b695/lua/dropbar/utils/source.lua#L7
	local src = utils.source.fallback {
		sources.lsp,
		sources.treesitter,
	}
	local symbols = src.get_symbols(buf, win, cursor)

	local names = {}
	for _, sym in ipairs(symbols or {}) do
		table.insert(names, sym.name)
	end
	return table.concat(names, ' > ')
end

function M.PathBreadcrumbs()
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()

	local row, col = unpack(vim.api.nvim_win_get_cursor(win))
	local breadcrumb = M.GetBreadcrumbs(buf, row, col, win)

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

function M.RenderBookmark(node)
	local Location = require 'bookmarks.domain.location'
	local order_prefix = (node.order or 0)

	local name = node.name
	if node.name == '' then
		name = '[Untitled]'
	end

	local abs_path = node.location.path
	if abs_path == '' then
		return '[No Name]'
	end

	local cwd = vim.loop.cwd()
	if not cwd:match '/$' then
		cwd = cwd .. '/'
	end
	local filename = Location.get_file_name(node.location)
	local path = ''
	if abs_path:sub(1, #cwd) == cwd then
		-- Path is inside cwd, use relative
		local rel_path = vim.fn.fnamemodify(abs_path, ':.')
		path = vim.fn.fnamemodify(rel_path, ':h')
	end
	return string.format(
		'%-03s  %-30s|%-04d   [%-30s]   %-20s %s',
		order_prefix,
		truncate(node.content, 30),
		node.location.line,
		truncate(name, 30),
		truncate(filename, 20),
		path
	)
end

function M.BuildAfterUpdate(plugin_name, build)
	-- https://github.com/cgimenes/dotfiles/blob/4ad8cadf1c9ede5ee46f4f4a9be01b7cd0f9d562/nvim/.config/nvim/lua/plugins/init.lua#L1-L19
	vim.api.nvim_create_autocmd('PackChanged', {
		pattern = '*',
		callback = function(ev)
			if ev.data.spec.name == plugin_name and ev.data.spec.kind ~= 'deleted' then
				vim.notify(plugin_name .. ' was updated, running build', vim.log.levels.INFO)

				if type(build) == 'function' then
					build(ev.data)
				elseif build:sub(1, 1) == ':' then
					local cmd = vim.api.nvim_parse_cmd(build:sub(2), {})
					vim.notify(vim.api.nvim_cmd(cmd, { output = true }), vim.log.levels.INFO)
				else
					vim.notify('You will need to go to ' .. ev.data.path .. ' and run: ' .. build,
						vim.log.levels.WARN)
				end
			end
		end,
	})
end

return M
