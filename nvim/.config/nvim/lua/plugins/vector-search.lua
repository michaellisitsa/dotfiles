-- Vector Search: Semantic code search via Telescope
-- Requires the vector-search service running on localhost:9876
-- Start it with:  docker compose -f ~/dotfiles/vector-search/docker-compose.yml up -d
-- Or without Docker: ~/dotfiles/vector-search/start.sh

local M = {}

local port = vim.g.vector_search_port or 9876
local base_url = string.format("http://localhost:%d", port)

--- Trigger indexing for a directory (async, non-blocking)
local function trigger_index(directory, force)
	local body = vim.json.encode({ directory = directory, force = force or false })
	vim.system(
		{
			"curl", "-s", "--max-time", "30",
			"-X", "POST",
			base_url .. "/index",
			"-H", "Content-Type: application/json",
			"-d", body,
		},
		{},
		function(result)
			vim.schedule(function()
				if result.code ~= 0 then
					return
				end
				local ok, data = pcall(vim.json.decode, result.stdout or "")
				if ok and data and data.status == "indexing_started" then
					vim.notify(
						"Vector Search: indexing " .. vim.fn.fnamemodify(directory, ":t"),
						vim.log.levels.INFO
					)
				end
			end)
		end
	)
end

--- Open the Telescope vector search picker
function M.search()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local make_entry = require("telescope.make_entry")
	local sorters = require("telescope.sorters")
	local conf = require("telescope.config").values

	local cwd = vim.fn.getcwd()

	pickers
		.new({}, {
			prompt_title = "Vector Search (Semantic)",
			finder = finders.new_dynamic({
				fn = function(prompt)
					if not prompt or #prompt < 3 then
						return {}
					end

					local body = vim.json.encode({
						query = prompt,
						directory = cwd,
						n_results = 30,
					})

					local result = vim.fn.system({
						"curl", "-s", "--max-time", "5",
						"-X", "POST",
						base_url .. "/search",
						"-H", "Content-Type: application/json",
						"-d", body,
					})

					local ok, data = pcall(vim.json.decode, result)
					if not ok or not data or not data.results then
						return {}
					end

					-- Convert to vimgrep format: file:line:col:text
					local entries = {}
					for _, r in ipairs(data.results) do
						table.insert(entries, string.format(
							"%s:%d:1:%s",
							r.file, r.line, r.text
						))
					end
					return entries
				end,
				entry_maker = make_entry.gen_from_vimgrep({}),
			}),
			-- Don't re-sort: results are ordered by semantic similarity
			sorter = sorters.empty(),
			previewer = conf.grep_previewer({}),
		})
		:find()
end

-- Keymap
vim.keymap.set("n", "<leader>sv", M.search, { desc = "[S]earch [V]ector (semantic)" })

-- User commands
vim.api.nvim_create_user_command("VectorSearchIndex", function(opts)
	trigger_index(vim.fn.getcwd(), opts.bang)
end, { bang = true, desc = "Index cwd for vector search (! to force re-index)" })

vim.api.nvim_create_user_command("VectorSearchStatus", function()
	local cwd = vim.fn.getcwd()
	local result = vim.fn.system({
		"curl", "-s", "--max-time", "3",
		base_url .. "/status?directory=" .. vim.uri_encode(cwd),
	})
	local ok, data = pcall(vim.json.decode, result)
	if ok and data then
		vim.notify(string.format(
			"Vector Search Status:\n  Directory: %s\n  Indexed: %s\n  Chunks: %s\n  Status: %s",
			data.directory or cwd,
			tostring(data.indexed or false),
			tostring(data.chunks or 0),
			data.indexing_status or "unknown"
		), vim.log.levels.INFO)
	else
		vim.notify("Vector Search: service not reachable", vim.log.levels.WARN)
	end
end, { desc = "Show vector search index status" })

-- Auto-index on directory open
vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
	group = vim.api.nvim_create_augroup("VectorSearchAutoIndex", { clear = true }),
	callback = function()
		-- Check if service is running before triggering index
		vim.system(
			{ "curl", "-s", "--max-time", "1", base_url .. "/health" },
			{},
			function(result)
				if result.code == 0 then
					vim.schedule(function()
						trigger_index(vim.fn.getcwd(), false)
					end)
				end
			end
		)
	end,
})

return M
