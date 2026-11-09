-- Runs INSIDE your Neovim. cli.lua sends this file's source over RPC on every call,
-- so nothing needs adding to your nvim config. Each function takes one opts table and
-- returns { text = string, err = bool }.
local api, fn = vim.api, vim.fn
local uv = vim.uv or vim.loop
local M = {}

local MAX_LINE = 240 -- truncate very long lines in context output
local MAX_OUTPUT = 6000 -- cap Ex command output
local SEV = { 'E', 'W', 'I', 'H' }

local function clean_err(e)
  e = tostring(e)
  return e:match('(E%d+:.*)$') or e
end

local function rel(name)
  if name == '' then return '[No Name]' end
  return fn.fnamemodify(name, ':~:.')
end

local function is_file_buf(b)
  return api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == '' and api.nvim_buf_get_name(b) ~= ''
end

local function is_editor_win(w)
  return api.nvim_win_is_valid(w)
    and api.nvim_win_get_config(w).relative == ''
    and vim.bo[api.nvim_win_get_buf(w)].buftype ~= 'terminal'
end

-- The window the user means. Normally the current one; if Claude runs in a :terminal
-- inside this Neovim, the current window is that terminal, so use the previous window.
local function target_win()
  local cur = api.nvim_get_current_win()
  if vim.bo[api.nvim_win_get_buf(cur)].buftype ~= 'terminal' then return cur end
  local prev = fn.win_getid(fn.winnr('#'))
  if prev ~= 0 and is_editor_win(prev) then return prev end
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if is_editor_win(w) then return w end
  end
  return cur
end

local function same_file(a, b)
  if a == b then return true end
  local ra, rb = uv.fs_realpath(a), uv.fs_realpath(b)
  return ra ~= nil and ra == rb
end

local function find_buf(path)
  if not path or path == '' then return nil end
  for _, b in ipairs(api.nvim_list_bufs()) do
    if is_file_buf(b) and same_file(api.nvim_buf_get_name(b), path) then return b end
  end
end

-- Editor snapshot: file, mode, cursor, visible code around the cursor, diagnostics, buffers.
local function snapshot(radius)
  radius = tonumber(radius) or 20
  return api.nvim_win_call(target_win(), function()
    local buf = api.nvim_get_current_buf()
    local bo = vim.bo[buf]
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local top, bot = fn.line('w0'), fn.line('w$')
    local first, last = math.max(top, row - radius), math.min(bot, row + radius)
    local mode = api.nvim_get_mode().mode

    local out = {
      string.format(
        '<nvim file="%s" ft=%s mode=%s cursor=%d:%d lines=%d view=%d-%d%s>',
        rel(api.nvim_buf_get_name(buf)),
        bo.filetype ~= '' and bo.filetype or '-',
        mode, row, col + 1, api.nvim_buf_line_count(buf), top, bot,
        bo.modified and ' unsaved' or ''
      ),
    }

    local info = { 'cwd: ' .. fn.fnamemodify(fn.getcwd(), ':~') }
    local word = fn.expand('<cword>')
    if word ~= '' then info[#info + 1] = 'word: ' .. word end
    if mode:match('^[vV\22]') then
      local v = fn.getpos('v')
      info[#info + 1] = string.format('selection: %d:%d-%d:%d', v[2], v[3], row, col + 1)
    end
    out[#out + 1] = table.concat(info, '  ')

    for i, line in ipairs(api.nvim_buf_get_lines(buf, first - 1, last, false)) do
      local n = first + i - 1
      if #line > MAX_LINE then line = line:sub(1, MAX_LINE) .. '…' end
      out[#out + 1] = string.format('%s%5d  %s', n == row and '>' or ' ', n, line)
    end

    local ok, diags = pcall(vim.diagnostic.get, buf)
    if ok and #diags > 0 then
      table.sort(diags, function(a, b) return a.lnum < b.lnum end)
      local shown, outside = 0, 0
      for _, d in ipairs(diags) do
        local ln = d.lnum + 1
        if ln >= first and ln <= last and shown < 8 then
          if shown == 0 then out[#out + 1] = 'diagnostics:' end
          out[#out + 1] = string.format('  %d:%d %s %s', ln, d.col + 1, SEV[d.severity] or '?', (d.message:gsub('%s*\n%s*', ' ')))
          shown = shown + 1
        else
          outside = outside + 1
        end
      end
      if outside > 0 then out[#out + 1] = string.format('(%d more diagnostics elsewhere in this file)', outside) end
    end

    local others = {}
    for _, b in ipairs(api.nvim_list_bufs()) do
      if b ~= buf and vim.bo[b].buflisted and is_file_buf(b) and #others < 12 then
        others[#others + 1] = rel(api.nvim_buf_get_name(b)) .. (vim.bo[b].modified and ' (unsaved)' or '')
      end
    end
    if #others > 0 then out[#out + 1] = 'buffers: ' .. table.concat(others, ', ') end

    out[#out + 1] = '</nvim>'
    return table.concat(out, '\n')
  end)
end

-- Compose an action's reply: error (if any), command output, then the new snapshot.
local function finish(opts, err, output)
  local out = {}
  if err then out[#out + 1] = 'error: ' .. clean_err(err) end
  if output and output ~= '' then
    if #output > MAX_OUTPUT then output = output:sub(1, MAX_OUTPUT) .. '\n…(truncated)' end
    out[#out + 1] = output
  end
  if not opts.quiet then out[#out + 1] = snapshot(opts.radius or 8) end
  return { text = table.concat(out, '\n'), err = err ~= nil }
end

function M.ctx(opts)
  return { text = snapshot(opts.radius) }
end

-- Normal-mode keys, run like :normal (mappings apply; an unfinished command is aborted
-- and insert mode is ended, so each call is atomic).
function M.keys(opts)
  local keys = api.nvim_replace_termcodes(opts.keys or '', true, true, true)
  local err
  api.nvim_win_call(target_win(), function()
    local ok, e = pcall(api.nvim_cmd, { cmd = 'normal', args = { keys }, mods = { silent = true } }, {})
    if not ok then err = e end
  end)
  return finish(opts, err)
end

-- Asynchronous input, exactly as if typed. For interactive UIs (pickers, prompts).
function M.input(opts)
  api.nvim_input(opts.keys or '')
  return { text = '' }
end

function M.cmd(opts)
  local output, err
  api.nvim_win_call(target_win(), function()
    local ok, res = pcall(api.nvim_exec2, opts.cmd or '', { output = true })
    if ok then output = res.output else err = res end
  end)
  return finish(opts, err, output)
end

function M.lua(opts)
  local code = opts.code or ''
  local chunk, perr = loadstring('return ' .. code, '=nv lua')
  if not chunk then chunk, perr = loadstring(code, '=nv lua') end
  if not chunk then return finish(opts, perr) end
  local ok, res = pcall(api.nvim_win_call, target_win(), chunk)
  if not ok then return finish(opts, res) end
  return finish(opts, nil, res ~= nil and vim.inspect(res) or nil)
end

-- Write the buffer for `path` if it has unsaved changes (before Claude reads/edits the file).
function M.sync(opts)
  local b = find_buf(opts.path)
  if not b or not vim.bo[b].modified then return { text = '' } end
  local ok, e = pcall(api.nvim_buf_call, b, function() vim.cmd('silent update') end)
  if not ok then return { text = 'error: ' .. clean_err(e), err = true } end
  return { text = 'saved ' .. rel(api.nvim_buf_get_name(b)) }
end

-- Put the cursor on the changed code in whichever window shows buffer b.
local function jump(b, needle)
  if not needle or needle == '' then return end
  local wins = fn.win_findbuf(b)
  if #wins == 0 then return end
  for i, line in ipairs(api.nvim_buf_get_lines(b, 0, -1, false)) do
    local s = line:find(needle, 1, true)
    if s then
      local tw = target_win()
      local w = vim.tbl_contains(wins, tw) and tw or wins[1]
      api.nvim_win_set_cursor(w, { i, s - 1 })
      api.nvim_win_call(w, function() vim.cmd('normal! zv') end)
      return
    end
  end
end

-- Re-read buffers whose files changed on disk. Buffers with unsaved changes are never
-- touched. The reload stays in Neovim's undo history ('undoreload'), so `u` reverts it.
function M.reload(opts)
  if opts.path then
    local b = find_buf(opts.path)
    if not b then return { text = '' } end
    if vim.bo[b].modified then
      return { text = 'not reloaded (unsaved changes in Neovim): ' .. rel(opts.path), err = true }
    end
    api.nvim_buf_call(b, function() vim.cmd('silent edit') end)
    jump(b, opts.needle)
    return { text = 'reloaded ' .. rel(opts.path) }
  end
  local skipped = {}
  for _, b in ipairs(api.nvim_list_bufs()) do
    if is_file_buf(b) then
      if vim.bo[b].modified then
        skipped[#skipped + 1] = rel(api.nvim_buf_get_name(b))
      else
        api.nvim_buf_call(b, function()
          vim.cmd('setlocal autoread')
          vim.cmd('silent! checktime ' .. b)
          vim.cmd('set autoread<')
        end)
      end
    end
  end
  if #skipped > 0 then return { text = 'skipped (unsaved): ' .. table.concat(skipped, ', ') } end
  return { text = '' }
end

function M.info()
  return { pid = fn.getpid(), uis = #api.nvim_list_uis() }
end

return M
