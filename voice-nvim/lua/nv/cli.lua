-- nv: command-line client, run by bin/nv as `nvim --clean -l cli.lua ARGS`.
-- Finds the Neovim in this tmux window, sends remote.lua over RPC, prints the result.
local USAGE = [[
nv - drive the Neovim in this tmux window over RPC

  nv ctx [-r N]       editor snapshot: file, cursor, code around it (+-N lines, default 20)
  nv keys KEYS        normal-mode keys in <> notation, e.g. nv keys '42Gciwfoo<Esc>'
  nv cmd EX           Ex command and its output, e.g. nv cmd 'edit src/app.ts'
  nv input KEYS       type KEYS asynchronously, as if typed (pickers, prompts)
  nv lua CODE         run Lua inside Neovim and print the result
  nv reload [FILE]    re-read buffers changed on disk (never touches unsaved ones)
  nv sync FILE        write FILE's buffer if it has unsaved changes
  nv where            show which Neovim nv would talk to
  nv hook EVENT       Claude Code hook entry (prompt | pre | post), reads JSON on stdin

keys/cmd/input/lua print the new snapshot afterwards (radius 8; -r N to change, -q to skip).
Target: $NV_SOCKET, else $NVIM (when run inside :terminal), else the Neovim in this
tmux window (or the same tmux session).
]]

local uv = vim.uv or vim.loop
local here = vim.fs.dirname(vim.fn.fnamemodify(arg[0], ':p'))
local REMOTE = table.concat(vim.fn.readfile(here .. '/remote.lua'), '\n')

-- Exit through :cquit so Neovim removes this process's own server socket.
local function exit(code)
  io.stdout:flush()
  io.stderr:flush()
  vim.cmd('cquit ' .. (code or 0))
end

local function emit(s)
  if s and s ~= '' then io.stdout:write(s, s:sub(-1) == '\n' and '' or '\n') end
end

local function die(msg)
  io.stderr:write('nv: ', msg, '\n')
  exit(1)
end

local function run(cmd)
  local ok, lines = pcall(vim.fn.systemlist, cmd)
  if not ok or vim.v.shell_error ~= 0 then return {} end
  return lines
end

local function connect(addr)
  local mode = addr:match('^[^/]+:%d+$') and 'tcp' or 'pipe'
  local ok, chan = pcall(vim.fn.sockconnect, mode, addr, { rpc = true })
  if ok and type(chan) == 'number' and chan > 0 then return chan end
end

local function call(chan, fname, opts)
  local ok, res = pcall(vim.rpcrequest, chan, 'nvim_exec_lua',
    'local src, f, o = ...; return assert(loadstring(src, "=nv-remote"))()[f](o)',
    { REMOTE, fname, opts or {} })
  if not ok then return { text = 'error: ' .. tostring(res), err = true } end
  return res
end

---------------------------------------------------------------------------
-- Discovery: every Neovim (>= 0.9) listens on stdpath('run')/nvim.<pid>.0 by default.
-- Keep the ones with a UI attached, map each to its tmux pane by walking up the
-- process tree, and prefer the one in the same tmux window as this process.

local function processes()
  local procs = {}
  for _, l in ipairs(run({ 'ps', '-A', '-o', 'pid=', '-o', 'ppid=', '-o', 'args=' })) do
    local pid, ppid, args = l:match('^%s*(%d+)%s+(%d+)%s+(.*)$')
    if pid then procs[tonumber(pid)] = { ppid = tonumber(ppid), args = args } end
  end
  return procs
end

local function candidates(procs)
  local run_dir = vim.fn.stdpath('run')
  local seen, list = { [vim.v.servername] = true }, {}
  -- Sockets are <NVIM_APPNAME>.<pid>.0 (e.g. nvim-nightly.123.0). On macOS run_dir is
  -- $TMPDIR/nvim.$USER/<random>, unique per process, so also glob its siblings.
  for _, pat in ipairs({ run_dir .. '/*.*.0', vim.fs.dirname(run_dir) .. '/*/*.*.0' }) do
    for _, p in ipairs(vim.fn.glob(pat, true, true)) do
      local pid = tonumber(p:match('%.(%d+)%.0$'))
      local proc = procs[pid]
      -- Skip stale sockets (process gone) and other nv runs (connecting to them could deadlock).
      if not seen[p] and (next(procs) == nil or (proc and not proc.args:find('nv/cli.lua', 1, true))) then
        seen[p] = true
        list[#list + 1] = p
      end
    end
  end
  return list
end

local function tmux_info(procs)
  if not vim.env.TMUX then return nil end
  local target = vim.env.TMUX_PANE and { '-t', vim.env.TMUX_PANE } or {}
  local me = run(vim.list_extend({ 'tmux', 'display-message', '-p' }, vim.list_extend(target, { '#{session_id} #{window_id}' })))[1]
  if not me then return nil end
  local my_session, my_window = me:match('(%S+) (%S+)')
  local panes = {}
  for _, l in ipairs(run({ 'tmux', 'list-panes', '-a', '-F', '#{pane_pid} #{session_id} #{window_id} #{pane_last} #{pane_id}' })) do
    local pid, s, w, last, id = l:match('(%d+) (%S+) (%S+) (%d) (%S+)')
    if pid then panes[tonumber(pid)] = { session = s, window = w, last = last == '1', id = id } end
  end
  return { session = my_session, window = my_window, panes = panes, procs = procs }
end

local function pane_of(pid, t)
  for _ = 1, 32 do
    if not pid or pid <= 1 then return nil end
    if t.panes[pid] then return t.panes[pid] end
    pid = t.procs[pid] and t.procs[pid].ppid
  end
end

local function discover()
  local procs = processes()
  local t = tmux_info(procs)
  local best
  for _, addr in ipairs(candidates(procs)) do
    local chan = connect(addr)
    if chan then
      local ok, info = pcall(vim.rpcrequest, chan, 'nvim_exec_lua',
        'return { vim.fn.getpid(), #vim.api.nvim_list_uis() }', {})
      local score = 0
      if ok and info[2] > 0 then -- skip headless instances (including other nv runs)
        score = 1
        if t then
          local pane = pane_of(info[1], t)
          score = 0 -- inside tmux: only Neovims in this tmux session count
          if pane and pane.session == t.session then
            score = (pane.window == t.window and 100 or 10) + (pane.last and 5 or 0)
          end
        end
      end
      if score > 0 and (not best or score > best.score) then
        if best then vim.fn.chanclose(best.chan) end
        best = { chan = chan, addr = addr, score = score, pid = info[1] }
      else
        vim.fn.chanclose(chan)
      end
    end
  end
  return best
end

local function resolve()
  for _, var in ipairs({ 'NV_SOCKET', 'NVIM' }) do
    local addr = vim.env[var]
    if addr and addr ~= '' then
      local chan = connect(addr)
      if chan then return { chan = chan, addr = addr, via = '$' .. var } end
      if var == 'NV_SOCKET' then return nil end -- explicit target is down: don't guess
    end
  end
  local best = discover()
  if best then best.via = best.score >= 100 and 'this tmux window' or best.score >= 10 and 'this tmux session' or 'only Neovim running' end
  return best
end

local function need()
  local t = resolve()
  if not t then die('no Neovim found in this tmux window (start nvim there, or set NV_SOCKET)') end
  return t.chan
end

local function finish(res)
  emit(res.text)
  exit(res.err and 1 or 0)
end

---------------------------------------------------------------------------
-- Claude Code hooks. Always exit 0: a hook failure must never block the session.

local function read_json()
  local s = io.stdin:read('*a') or ''
  local ok, v = pcall(vim.json.decode, s)
  return ok and type(v) == 'table' and v or {}
end

local function str(v) return type(v) == 'string' and v or nil end

-- The most distinctive (longest) line of the new text, used to find the change after reload.
local function needle_of(ti)
  local s = str(ti.new_string)
  if not s and type(ti.edits) == 'table' and type(ti.edits[1]) == 'table' then s = str(ti.edits[1].new_string) end
  if not s then return nil end
  local best
  for line in (s .. '\n'):gmatch('(.-)\n') do
    local t = vim.trim(line)
    if #t > (best and #best or 0) then best = t end
  end
  return best
end

local function hook(event)
  local input = read_json()
  local t = resolve()
  if event == 'prompt' then
    if not t then
      emit('<nvim>no Neovim found in this tmux window</nvim>')
    else
      emit(call(t.chan, 'ctx', { radius = tonumber(vim.env.NV_HOOK_RADIUS) or 20 }).text)
    end
    return
  end
  if not t then return end
  local ti = type(input.tool_input) == 'table' and input.tool_input or {}
  local path = str(ti.file_path)
  if not path then return end
  local res
  if event == 'pre' then
    res = call(t.chan, 'sync', { path = path })
  elseif event == 'post' then
    res = call(t.chan, 'reload', { path = path, needle = needle_of(ti) })
  end
  if res and res.err then io.stderr:write('nv: ', res.text or '', '\n') end
end

---------------------------------------------------------------------------

local argv = { unpack(arg) }
local sub = table.remove(argv, 1)
local opts, rest, flags = {}, {}, true
local i = 1
while i <= #argv do
  local a = argv[i]
  if flags and a == '--' then
    flags = false
  elseif flags and a == '-q' then
    opts.quiet = true
  elseif flags and a == '-r' and tonumber(argv[i + 1]) then
    opts.radius = tonumber(argv[i + 1])
    i = i + 1
  else
    rest[#rest + 1] = a
  end
  i = i + 1
end
local text = table.concat(rest, ' ')

if sub == 'ctx' then
  opts.radius = opts.radius or 20
  finish(call(need(), 'ctx', opts))
elseif sub == 'keys' then
  opts.keys = text
  finish(call(need(), 'keys', opts))
elseif sub == 'cmd' then
  opts.cmd = text
  finish(call(need(), 'cmd', opts))
elseif sub == 'lua' then
  opts.code = text
  finish(call(need(), 'lua', opts))
elseif sub == 'input' then
  local chan = need()
  call(chan, 'input', { keys = text })
  if opts.quiet then exit(0) end
  vim.wait(150) -- let Neovim process the typed keys before taking the snapshot
  finish(call(chan, 'ctx', { radius = opts.radius or 8 }))
elseif sub == 'reload' then
  finish(call(need(), 'reload', { path = text ~= '' and vim.fn.fnamemodify(text, ':p') or nil }))
elseif sub == 'sync' then
  if text == '' then die('usage: nv sync FILE') end
  finish(call(need(), 'sync', { path = vim.fn.fnamemodify(text, ':p') }))
elseif sub == 'where' then
  local t = resolve()
  if not t then die('no Neovim found in this tmux window') end
  local info = call(t.chan, 'info', {})
  emit(string.format('%s  (via %s, pid %s, %s UI)', t.addr, t.via, tostring(info.pid), tostring(info.uis)))
  exit(0)
elseif sub == 'hook' then
  pcall(hook, rest[1])
  exit(0)
else
  io.stdout:write(USAGE)
  exit((sub == nil or sub == 'help' or sub == '-h' or sub == '--help') and 0 or 2)
end
