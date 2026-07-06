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

function M.PathBreadcrumbs(visual)
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()

	local row, col = unpack(vim.api.nvim_win_get_cursor(win))
	local breadcrumb = M.GetBreadcrumbs(buf, row, col, win)
	local path = vim.fn.expand('%:p:~')

	local str
	if visual then
		local start_line = vim.fn.line("'<")
		local end_line = vim.fn.line("'>")
		str = string.format(
			'[%s|#L%d-L%d](%s|%d)',
			breadcrumb,
			start_line,
			end_line,
			path,
			start_line
		)
	else
		str = string.format(
			'[%s-#L%d](%s|%d)',
			breadcrumb,
			row,
			path,
			row
		)
	end

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

local IMPORT_NODES = {
	import_statement = true, -- Python, JS, TS
	import_from_statement = true, -- Python
	future_import_statement = true, -- Python
	use_declaration = true, -- Rust
	preproc_include = true, -- C/C++
	import_declaration = true, -- Go, Java
	import_spec = true, -- Go
}

-- Telescope lsp_references that hides entries inside test_* files or inside
-- import statements (detected via treesitter). Falls back to passing entries
-- through unchanged once filtering exceeds the 1s budget.
function M.FilteredLspReferences()
	local make_entry = require('telescope.make_entry')
	local base = make_entry.gen_from_quickfix({})

	local tree_cache = {}
	local function get_tree(filename)
		if tree_cache[filename] ~= nil then return tree_cache[filename] end
		local bufnr = vim.fn.bufnr(filename)
		if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then
			local ft = vim.bo[bufnr].filetype
			if ft ~= '' then
				local ok, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
				if ok and parser then
					tree_cache[filename] = parser:parse()[1]
					return tree_cache[filename]
				end
			end
		end
		local ft = vim.filetype.match({ filename = filename })
		local f = ft and io.open(filename, 'r')
		if f then
			local content = f:read('*a')
			f:close()
			local ok, parser = pcall(vim.treesitter.get_string_parser, content, ft)
			if ok and parser then
				tree_cache[filename] = parser:parse()[1]
				return tree_cache[filename]
			end
		end
		tree_cache[filename] = false
		return false
	end

	local function is_in_import(filename, lnum, col)
		local tree = get_tree(filename)
		if not tree then return false end
		local node = tree:root():named_descendant_for_range(lnum - 1, col - 1, lnum - 1, col - 1)
		while node do
			if IMPORT_NODES[node:type()] then return true end
			node = node:parent()
		end
		return false
	end

	local TIMEOUT_NS = 1e9
	local start_ns, timed_out

	require('telescope.builtin').lsp_references({
		entry_maker = function(entry)
			if not start_ns then start_ns = vim.uv.hrtime() end
			if not timed_out and (vim.uv.hrtime() - start_ns) > TIMEOUT_NS then
				timed_out = true
				vim.schedule(function()
					vim.notify('FilteredLspReferences: timed out, passing remaining entries through',
						vim.log.levels.WARN)
				end)
			end
			if timed_out then return base(entry) end
			if vim.fn.fnamemodify(entry.filename, ':t'):match('^test_') then
				return nil
			end
			if is_in_import(entry.filename, entry.lnum, entry.col) then
				return nil
			end
			return base(entry)
		end,
	})
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
