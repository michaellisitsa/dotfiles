-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true
-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- https://www.reddit.com/r/neovim/comments/1myfvla/comment/nad22ts/
if vim.fn.has 'nvim-0.12' == 1 then
  vim.o.diffopt = 'internal,filler,closeoff,inline:word,linematch:40'
elseif vim.fn.has 'nvim-0.11' == 1 then
  vim.o.diffopt = 'internal,filler,closeoff,linematch:40'
end

-- current line show number
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wildmenu = true
-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Use treesitter folding, already built into neovim
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- Folds all start closed if you don't set this
vim.o.foldlevelstart = 99

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.opt.confirm = true

-- Better diff syntax
--
vim.opt.fillchars = {
  fold = ' ',
  diff = '╱',
  wbr = '─',
  msgsep = '─',
  horiz = ' ',
  horizup = '│',
  horizdown = '│',
  vertright = '│',
  vertleft = '│',
  verthoriz = '│',
}

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

local function yank_pytest(debug)
  local ts_utils = require 'nvim-treesitter.ts_utils'
  local node = ts_utils.get_node_at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local rel_filepath = vim.fn.expand '%:.'
  if rel_filepath:find 'kogan3/' ~= nil then
    rel_filepath = string.sub(rel_filepath, 8)
  end

  local symbol = ''
  if node then
    symbol = vim.treesitter.get_node_text(node, buf):gsub('\n', ' ')
  end
  local str = string.format('./shortcuts.sh %s "%s" -k "%s"', debug and 'vscode_tests' or 'test', rel_filepath, symbol)
  vim.fn.setreg('"', str)
  vim.fn.setreg('+', str)
  print('Pytest: ' .. str)
end

vim.keymap.set('n', '<leader>gt', function()
  yank_pytest(false)
end)

vim.keymap.set('n', '<leader>gd', function()
  yank_pytest(true)
end)

-- Print the full file path of the current file and line number
-- Useful for bookmarking in a separate markdown file
-- gf because that's usually the shortcut used to navigate (or gF) to a file string
-- Also add breadcrumbs
vim.keymap.set('n', '<leader>gf', function()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  local cursor = { row, col }

  -- Dropbar.nvim has a get_symbols function that concatenates all the document symbols up the treesitter tree.
  -- https://github.com/Bekaboo/dropbar.nvim/blob/418897fe7828b2749ca78056ec8d8ad43136b695/lua/dropbar/utils/source.lua#L7
  local sources = require 'dropbar.sources'
  -- Fallback chain: LSP first, then Treesitter
  local src = require('dropbar.utils').source.fallback { sources.lsp, sources.treesitter }
  local symbols = src.get_symbols(buf, win, cursor)

  -- Apply our own to string conversion.
  local names = {}
  for _, sym in ipairs(symbols) do
    table.insert(names, sym.name)
  end
  local breadcrumb = table.concat(names, ' > ')

  local str = string.format('%s|%d | %s', vim.fn.expand '%:p', row, breadcrumb)
  vim.fn.setreg('"', str)
  vim.fn.setreg('+', str)
  print('Yanked location: ' .. str)
end)

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_user_command('Zen', function()
  local padding_width = math.floor((vim.o.columns - vim.o.textwidth) / 4 - 1)
  local padding_bufnr = nil
  local padding_winid = nil

  -- Find if a window with buffer name "_padding_" already exists
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match '_padding_$' then
      padding_bufnr = buf
      padding_winid = win
      break
    end
  end

  if padding_winid then
    -- Just resize the existing padding window
    vim.api.nvim_set_current_win(padding_winid)
    vim.cmd('vertical resize ' .. padding_width)
    -- Go back to previous window
    vim.cmd 'wincmd p'
  else
    -- Create a new left split for padding
    vim.cmd(string.format('topleft %dvsplit _padding_', padding_width))
    local pad_buf = vim.api.nvim_get_current_buf()

    -- Make it unmodifiable and blank
    vim.api.nvim_buf_set_option(pad_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(pad_buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(pad_buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(pad_buf, 'modifiable', false)

    -- Return to previous window
    vim.cmd 'wincmd p'
  end
end, {})

vim.keymap.set('n', '<C-w>z', '<cmd>Zen<cr>', { desc = 'Center windows' })

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--

-- Function to handle both blink.cmp and default <C-n> behavior
function C_n_handler()
  local blink = require 'blink.cmp'
  if blink.is_menu_visible() then
    blink.select_next()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-n>', true, true, true), 'n', true)
  end
end

-- Function to handle both blink.cmp and default <C-p> behavior
function C_p_handler()
  local blink = require 'blink.cmp'
  if blink.is_menu_visible() then
    blink.select_prev()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-p>', true, true, true), 'n', true)
  end
end

require('lazy').setup({
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    -- Gitsigns blame toggled off will be added in
    -- https://github.com/lewis6991/gitsigns.nvim/pull/1397
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    {
      'linrongbin16/gitlinker.nvim',
      cmd = 'GitLink',
      opts = {},
      keys = {
        { '<leader>hy', '<cmd>GitLink<cr>', mode = { 'n', 'v' }, desc = 'Yank git link' },
        { '<leader>hY', '<cmd>GitLink!<cr>', mode = { 'n', 'v' }, desc = 'Open git link' },
      },
    },
  },
  {
    'stevearc/oil.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    -- Optional dependencies
    desc = 'Oil File System',
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    config = function()
      require('oil').setup { keymaps = { ['<Esc>'] = 'actions.close' }, view_options = { show_hidden = true } }
    end,
    keys = {
      { '<leader>fm', '<cmd>Oil<cr>', mode = 'n', desc = 'Open Filesystem' },
    },
    lazy = false,
  },
  {
    'benomahony/uv.nvim',
    -- Optional filetype to lazy load when you open a python file
    -- ft = { python }
    -- Optional dependency, but recommended:
    -- dependencies = {
    --   "folke/snacks.nvim"
    -- or
    --   "nvim-telescope/telescope.nvim"
    -- },
    opts = {},
  },
  {
    'mbbill/undotree',
    cond = function()
      return not vim.g.vscode
    end,
    lazy = false,
    keys = {
      { '<leader>tu', '<cmd>UndotreeToggle<CR>', desc = 'Toggle Undotree' },
    },
    config = function()
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
  },
  {
    'Goose97/timber.nvim',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      require('timber').setup {
        log_templates = {
          default = {
            javascript = [[console.log("%log_marker %line_number: %log_target", %log_target)]],
            typescript = [[console.log("%log_marker %filename %line_number: %log_target", %log_target)]],
            tsx = [[console.log("%log_marker %filename %line_number: %log_target", %log_target)]],
            python = [[print(f"%log_marker %filename %line_number: {%log_target=}")]],
          },
          plain = {
            javascript = [[console.log("%log_marker %filename %line_number: %insert_cursor")]],
            typescript = [[console.log("%log_marker %filename %line_number: %insert_cursor")]],
            tsx = [[console.log("%log_marker %filename %line_number: %insert_cursor")]],
            python = [[print(f"%log_marker %filename %line_number: %insert_cursor")]],
          },
        },
        log_marker = 'Log →',
      }
    end,
    keys = {
      {
        'gld',
        "<cmd>lua require('timber.actions').clear_log_statements({ global = false })<cr>",
        mode = 'n',
        desc = 'Clear Log Statements Current File',
      },
    },
  },
  {
    'sindrets/diffview.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    -- Review diff config https://github.com/calops/nix/blob/9b9d31bf8dc3afb8695db37602d6bd4f972b49c9/modules/home/programs/neovim/config/lua/plugins/git.lua#L5-L25
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
    -- Inspired from https://lyz-code.github.io/blue-book/diffview/
    keys = {
      { '<leader>hf', '<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>', desc = 'Review branch changes' },
      {
        '<leader>hv',
        function()
          if next(require('diffview.lib').views) == nil then
            vim.cmd 'DiffviewOpen'
            -- vim.cmd.colorscheme 'github_dark_default'
          else
            vim.cmd 'DiffviewClose'
            -- vim.cmd.colorscheme 'vscode'
          end
        end,
        desc = 'Toggle Diffview window',
      },
    },
  },

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `opts` key (recommended), the configuration runs
  -- after the plugin has been loaded as `require(MODULE).setup(opts)`.
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.opt.timeoutlen
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      filter = function(mapping)
        -- Exclude mappings without a description
        return mapping.desc and mapping.desc ~= ''
      end,
      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle Options' },
        { '<leader>f', group = '[F]ile managers' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { '<leader>d', group = '[D]ebug', mode = { 'n', 'v' } },
        { '<leader>i', group = '[I]ron Repl', mode = { 'n' } },
        { '<leader>is', group = '[I]ron Repl [S]end', mode = { 'n' } },
        { '<leader>im', group = '[I]ron Repl [M]ark', mode = { 'n' } },
        { '<leader>ir', group = '[I]ron Repl [R]estart', mode = { 'n' } },
      },
    },
  },
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',
        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-live-grep-args.nvim' },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-telescope/telescope-frecency.nvim' },
      { 'jmacadie/telescope-hierarchy.nvim' },
      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      { 'aaronhallaert/advanced-git-search.nvim', cmd = { 'AdvancedGitSearch' } },
    },
    config = function()
      -- Two important keymaps to use to see what keymaps are available depend on which mode you're in:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        defaults = {
          mappings = {
            i = {
              -- These interfere with backspace char code. Think of better keys
              -- ['<C-l>'] = require('telescope.actions').cycle_history_next,
              -- ['<C-h>'] = require('telescope.actions').cycle_history_prev,
              ['<C-space>'] = require('telescope.actions').to_fuzzy_refine,
            },
          },
        },
        extensions = {
          -- By default frecency will not used fuzzy finding
          -- see https://github.com/nvim-telescope/telescope-frecency.nvim/issues/165
          -- config keys see example https://github.com/gaetanfox/kickstart.nvim/blob/beb79337952b592a181b7cb8b886927e80affcf5/lua/custom/plugins/telescope-frecency.lua#L23
          live_grep_args = {
            auto_quoting = true, -- enable/disable auto-quoting
            -- define mappings, e.g.
            mappings = { -- extend mappings
              i = {
                ['<C-k>'] = require('telescope-live-grep-args.actions').quote_prompt(),
                ['<C-i>'] = require('telescope-live-grep-args.actions').quote_prompt { postfix = ' --iglob ' },
                ['<C-space>'] = require('telescope.actions').to_fuzzy_refine,
              },
            },
            -- ... also accepts theme settings, for example:
            -- theme = "dropdown", -- use dropdown theme
            -- theme = { }, -- use own theme spec
            -- layout_config = { mirror=true }, -- mirror preview pane
          },
          frecency = {
            db_version = 'v2', -- Will be default in v2 of plugin
            matcher = 'fuzzy',
            -- show scores is very noisy as also shows fuzzy matcher scores. TMI
            -- show_scores = true, -- Default: false
            -- If `true`, it shows confirmation dialog before any entries are removed from the DB
            -- If you want not to be bothered with such things and to remove stale results silently
            -- set db_safe_mode=false and auto_validate=true
            --
            -- This fixes an issue I had in which I couldn't close the floating
            -- window because I couldn't focus it
            db_safe_mode = false, -- Default: true
            -- If `true`, it removes stale entries count over than db_validate_threshold
            auto_validate = true, -- Default: true
            -- It will remove entries when stale ones exist more than this count
            db_validate_threshold = 10, -- Default: 10
            hide_current_buffer = true,
            default_workspace = 'CWD',
            path_display = { 'filename_first' },
            -- Show the path of the active filter before file paths.
            show_filter_column = false,
          },
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
          hierarchy = {
            -- telescope-hierarchy.nvim config
            initial_multi_expand = true, -- Run a multi-expand on open? If false, will only expand one layer deep by default
            multi_depth = 2, -- How many layers deep should a multi-expand go?
          },
        },
        -- We want to search through all hidden files, vimgrep_arguments
        -- but ignore dependency folders.
        -- Alternatively, we could use Live Grep with Arguments extension to dynamically modify these settings
        pickers = {
          ['buffers'] = { sort_mru = true, ignore_current_buffer = true, sort_lastused = true, initial_mode = 'normal' },
          colorscheme = {
            enable_preview = true,
          },
          lsp_dynamic_workspace_symbols = {
            -- By default Telescope will let the LSP define the order of results
            -- however some LSPs like Pyright don't return in a useful order
            -- Override so that the fuzzy sorting is done based on the native fzf sorter
            -- see https://github.com/nvim-telescope/telescope.nvim/issues/2104
            sorter = require('telescope').extensions.fzf.native_fzf_sorter {
              fuzzy = true, -- false will only do exact matching
              override_generic_sorter = true, -- override the generic sorter
              override_file_sorter = true, -- override the file sorter
              case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
            },
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'live_grep_args')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'frecency')
      pcall(require('telescope').load_extension, 'hierarchy')
      pcall(require('telescope').load_extension, 'advanced_git_search')
      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>si', function()
        require('telescope').extensions.hierarchy.incoming_calls()
      end, { desc = 'LSP: [S]earch [I]ncoming Calls' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>sj', builtin.jumplist, { desc = '[S]earch [J]umps' })
      vim.keymap.set('n', '<leader>sc', function()
        require('telescope').extensions.frecency.frecency()
      end, { desc = '[S]earch [C]ount Recency' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', function()
        require('telescope').extensions.live_grep_args.live_grep_args()
      end, { desc = '[S]earch by [G]rep' })
      -- vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader>sm', function()
        local cmd = {
          'rg',
          '--glob',
          '**/models.py',
          '--glob',
          '!.venv/**',
          '--no-heading',
          '--line-number',
          '--column',
          'class\\s+\\w+\\(',
        }
        local finders = require 'telescope.finders'
        local conf = require('telescope.config').values
        local make_entry = require 'telescope.make_entry'
        local pickers = require 'telescope.pickers'

        local custom_maker = function(entry)
          local original = make_entry.gen_from_vimgrep {
            -- keep path display minimal (we’ll handle display ourselves)
            path_display = { 'tail' },
          }(entry)
          if not original then
            return nil
          end

          -- extract "class Foo()" from the line
          local match = original.text:match 'class%s+%w+%s*%(' or original.text
          match = string.sub(match, 6, -2)

          -- overwrite display
          original.display = function()
            return string.format('%-30s %s:%d', match, original.filename, original.lnum)
          end

          return original
        end

        pickers
          .new({}, {
            prompt_title = 'Django Models',
            finder = finders.new_oneshot_job(cmd, {
              entry_maker = custom_maker,
            }),
            sorter = conf.generic_sorter {},
            previewer = conf.grep_previewer {},
          })
          :find()
      end, { desc = 'Search Django models' })
      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },
  {
    'LintaoAmons/bookmarks.nvim',
    -- pin the plugin at specific version for stability
    -- backup your bookmark sqlite db when there are breaking changes (major version change)
    tag = 'v4.0.0',
    dependencies = {
      -- Note issue with using function call type string
      -- in upstream sqlite https://github.com/kkharji/sqlite.lua/issues/182
      -- -- Note issue with using function call type string
      -- in upstream sqlite https://github.com/kkharji/sqlite.lua/issues/182
      { 'kkharji/sqlite.lua' },
      { 'nvim-telescope/telescope.nvim' }, -- currently has only telescopes supported, but PRs for other pickers are welcome
      { 'stevearc/dressing.nvim' }, -- optional: better UI
    },
    config = function()
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
      local opts = {
        backup = {
          -- Default backup dir: vim.fn.stdpath("data").."/bookmarks.backup"
          enabled = true,
        },
        treeview = {
          keymap = {
            ['<Enter>'] = {
              action = 'goto',
              desc = 'Go to bookmark location in previous window',
            },
          },
          render_bookmark = function(node)
            local Location = require 'bookmarks.domain.location'
            local order_prefix = (node.order or 0)
            local linked_icon = #node.linked_bookmarks > 0 and '🔗' or ''

            local name = node.name
            if node.name == '' then
              name = '[Untitled]'
            end

            local abs_path = node.location.path
            if abs_path == '' then
              return '[No Name]'
            end

            local cwd = vim.loop.cwd()
            -- Normalize both with a trailing slash for proper prefix check
            if not cwd:match '/$' then
              cwd = cwd .. '/'
            end
            filename = Location.get_file_name(node.location)
            if abs_path:sub(1, #cwd) == cwd then
              -- Path is inside cwd → show relative form
              rel_path = vim.fn.fnamemodify(abs_path, ':.')
              path = vim.fn.fnamemodify(rel_path, ':h')
            else
              -- Path is outside cwd → use fallback
              path = ''
            end
            -- return order_prefix .. path .. '|' .. node.location.line .. ': ' .. name .. ' ' .. linked_icon
            return string.format(
              '%-03s  %-30s|%-04d   [%-30s]   %-20s %s',
              order_prefix,
              truncate(node.content, 30),
              node.location.line,
              truncate(name, 30),
              truncate(filename, 20),
              path
            )
          end,
          -- Dimension of the window spawned for Treeview
          window_split_dimension = 140,
          -- stylua: ignore end
        },
      } -- check the "./lua/bookmarks/default-config.lua" file for all the options
      require('bookmarks').setup(opts) -- you must call setup to init sqlite db
      -- Define highlight groups once
      vim.api.nvim_set_hl(0, 'BookmarkDir', { fg = '#2e7515', bold = true })
      vim.api.nvim_set_hl(0, 'BookmarkFile', { fg = '#1196c6', bold = true })
      vim.api.nvim_set_hl(0, 'BookmarkLine', { fg = '#ffaf00' })

      -- Example config https://github.com/LintaoAmons/VimEverywhere/blob/main/nvim/lua/plugins/editor-enhance/bookmarks.lua
      -- where the keymaps were borrowed from
      vim.keymap.set('n', '<leader>mt', '<cmd>' .. 'BookmarksTree' .. '<cr>', { desc = 'Tree' })
      vim.keymap.set('n', '<leader>mg', '<cmd>' .. 'BookmarksGotoRecent' .. '<cr>', { desc = 'Go To Recent' })
      vim.keymap.set('n', '<leader>mm', '<cmd>' .. 'BookmarksMark' .. '<cr>', { desc = 'Mark' })
      vim.keymap.set('n', '<leader>ma', '<cmd>' .. 'BookmarksCommands' .. '<cr>', { desc = 'Commands' })
      vim.keymap.set('n', '<leader>ms', '<cmd>' .. 'BookmarksInfoCurrentBookmark' .. '<cr>', { desc = 'Info' })
      vim.keymap.set('n', '<leader>mo', '<cmd>' .. 'BookmarksGoto' .. '<cr>', { desc = 'GoTo' })
      vim.keymap.set('n', '<leader>ml', '<cmd>' .. 'BookmarksLists' .. '<cr>', { desc = 'Lists' })
      vim.keymap.set('n', '<leader>mn', '<cmd>' .. 'BookmarksGotoNextInList' .. '<cr>', { desc = 'Next' })
      vim.keymap.set('n', '<leader>mp', '<cmd>' .. 'BookmarksGotoPrevInList' .. '<cr>', { desc = 'Prev' })
    end,
  },
  {
    'nvimtools/hydra.nvim',
    config = function()
      local Hydra = require 'hydra'
      local cmd = require('hydra.keymap-util').cmd
      local pcmd = require('hydra.keymap-util').pcmd
      -- Official example window and buffer management
      -- https://github.com/anuvyklack/hydra.nvim/wiki/Windows-and-buffers-management
      -- excludes:
      --   WinShift for re-arranging windows
      --   SmartSplits
      --   Windows
      Hydra {
        name = 'Windows',
        hint = window_hint,
        config = {
          invoke_on_body = true,
          hint = {
            offset = -1,
          },
        },
        mode = 'n',
        -- Typically this is mapped to move to left window
        -- But I remap that to <C-h> anyway
        -- Also this is consistent with the debugging hydra
        body = '<C-w>h',
        heads = {
          { '=', '<C-w>=', { desc = 'equalize' } },

          -- Vertical and horizontal resizing
          --
          { '-', '<C-w>-', { desc = 'Move window bot up' } },
          { '+', '<C-w>+', { desc = 'Move window bot up' } },
          { '<', '<cmd>vertical resize -10<cr>', { desc = 'Move window left' } },
          { '>', '<cmd>vertical resize +10<cr>', { desc = 'Move window right' } },

          { 'q', nil, { exit = true, nowait = true } },
          { '<Esc>', nil, { exit = true, desc = false } },
        },
      }
      local dap = require 'dap'

      local hint = [[
 _n_: step over   _c_: Continue/Start   _b_: Breakpoint     _K_: Eval
 _i_: step into   _t_: Terminate             ^ ^                 ^ ^
 _o_: step out                               ^ ^
 _m_: to cursor   _j_: Down             _k_: Up
 ^
]]
      -- Debugging
      -- https://github.com/anuvyklack/hydra.nvim/issues/3#issuecomment-1162988750
      Hydra {
        -- hint = hint,
        config = {
          color = 'pink',
          invoke_on_body = true,
          hint = {
            position = 'bottom',
          },
        },
        name = 'dap',
        mode = { 'n', 'x' },
        -- body = '<leader>d',
        -- heads = {
        --   { 'n', '<leader>dn', { silent = true } },
        --   { 'i', '<leader>di', { silent = true } },
        --   { 'o', '<leader>do', { silent = true } },
        --   { 'r', '<leader>dr', { silent = true } },
        --   { 'c', '<leader>dc', { silent = true } },
        --   { 't', '<leader>dt', { silent = true } },
        --   { 'b', '<leader>db', { silent = true } },
        --   { 'h', '<leader>dh', { silent = true } },
        --   { 'j', '<leader>dj', { silent = true } },
        --   { 'k', '<leader>dk', { silent = true } },
        -- },
        body = '<leader>dh',
        heads = {
          { 'n', dap.step_over, { silent = true } },
          { 'i', dap.step_into, { silent = true } },
          { 'o', dap.step_out, { silent = true } },
          { 'm', dap.run_to_cursor, { silent = true } },
          { 'c', dap.continue, { silent = true } },
          { 't', ":lua require'dap'.disconnect({ terminateDebuggee = false })<CR>", { exit = true, silent = true } },
          { 'C', ":lua require('dapui').close()<cr>:DapVirtualTextForceRefresh<CR>", { silent = true } },
          { 'b', dap.toggle_breakpoint, { silent = true } },
          { 'K', ":lua require('dap.ui.widgets').hover()<CR>", { silent = true } },
          { 'q', nil, { exit = true, nowait = true } },
          { '<Esc>', nil, { exit = true, desc = false } },
        },
      }
    end,
  },
  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Same as upstream but with new 0.11 syntax
    -- ie. return vim.lsp.completion._lsp_to_complete_items(result, prefix)
    'michaellisitsa/nvim-lspimport',
    cond = function()
      return not vim.g.vscode
    end,
    keys = {
      {
        'grs',
        function()
          require('lspimport').import()
        end,
        mode = '',
        desc = 'Auto import',
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    -- VS code handles all LSPs
    cond = function()
      return not vim.g.vscode
    end,
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
    },
    config = function()
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- When used with Pyright LSP, turn off certain capabilities like textDocument/hover
          -- https://docs.astral.sh/ruff/editors/setup/#neovim
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client == nil then
            return
          end
          if client.name == 'ruff' then
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end

          --  We create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

          -- Find references for the word under your cursor.
          map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          --  In C this would take you to the header.
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
      }
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
      vim.keymap.set('n', '<leader>ct', '<cmd>lua vim.lsp.buf.incoming_calls()<cr>', { desc = 'LiteeCalltree' })
      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        clangd = {},
        -- gopls = {},
        html = {},
        pgformatter = {},
        pyright = {
          --[[
          -- Pyright will preference pyproject.toml so you may need to override
          [tool.pyright]
          -- Reduce unused code
          exclude = ["**/node_modules", "**/__pycache__", "**/migrations", "**/tests/", "**/.venv/"]
          -- LSP recognises dependencies
          venvPath = "."
          venv = ".venv"
          ]]
          settings = {
            python = {
              -- venvPath = '.',
              -- venv = '.venv',
              -- pythonPath = nil,
              analysis = {
                autoSearchPaths = true,
                typeCheckingMode = 'standard',
                useLibraryCodeForTypes = true,
                diagnosticMode = 'openFilesOnly',
                -- as above this may be overridden by pyproject.toml config
                exclude = { '**/node_modules', '**/__pycache__', '**/migrations/', '**/.venv/', '**/tests/' },
              },
            },
          },
        },
        ruff = {},
        rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        ts_ls = {},
        --
        jsonls = {
          settings = {
            json = {
              format = {
                enable = true,
              },
            },
            validate = { enable = true },
          },
        },

        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
        bashls = {},
        terraformls = {},
      }

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      --
      -- `mason` had to be setup earlier: to configure its options see the
      -- `dependencies` table for `nvim-lspconfig` above.
      --
      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        handlers = {
          function(server_name)
            local config = servers[server_name] or {}
            vim.lsp.config(server_name, config)
            vim.lsp.enable(server_name)
          end,
        },
      }
    end,
  },
  { -- Autoformat
    'stevearc/conform.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        -- Typically unnecessary with autoformat, but may be useful
        '<leader>ff',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ile [F]ormat',
      },
    },
    -- https://github.com/stevearc/conform.nvim?tab=readme-ov-file#options
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = {}
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 5000,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters = {
        injected = {
          options = {
            ignore_errors = false,
            lang_to_formatters = {
              sql = { 'pgformatter' },
            },
            lang_to_ext = {
              sql = 'sql',
            },
          },
        },
        pgformatter = {
          command = 'pg_format',
          args = { '--no-extra-line' },
        },
        shfmt = {
          prepend_args = { '-i', '2', '-ci', '-bn' },
        },
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        python = { 'isort', 'black' },
        sql = { 'pgformatter' },
        sh = { 'shfmt' },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        c = { 'clang-format' },
      },
    },
  },
  { -- Autocompletion
    'saghen/blink.cmp',
    cond = function()
      return not vim.g.vscode
    end,
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        preset = 'default',

        ['<C-n>'] = false,
        ['<C-p>'] = false,

        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
        menu = {
          auto_show = false,
        },
        ghost_text = {
          enabled = true,
          show_with_menu = false, -- only show when menu is closed
        },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
    -- Blink overrides default word completions https://neovim.io/doc/user/insert.html#i_CTRL-N
    -- Fix so we can still use this, solution per
    -- https://github.com/Saghen/blink.cmp/discussions/2149
    init = function()
      vim.keymap.set('i', '<C-n>', C_n_handler, { noremap = true, silent = true })
      vim.keymap.set('i', '<C-p>', C_p_handler, { noremap = true, silent = true })
    end,
  },
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Taken from https://github.com/a-barjo/dots/commit/4f620a4b8667baa106942786f42a30ea41947601#diff-2ffb01bb11910b65c47999af310bd3590640e032e74f94e15e2d298d144d665f
    config = function()
      local palette = require('github-theme.palette').load 'github_dark_default'
      require('github-theme').setup {
        options = {
          hide_end_of_buffer = false,
          hide_nc_statusline = false,
          styles = {
            comments = 'italic',
            keywords = 'italic',
          },
        },
        groups = {
          all = {
            DiffAdd = { bg = palette.scale.green[10], fg = 'none' },
            DiffChange = { bg = palette.scale.yellow[10], fg = 'none' },
            DiffText = { bg = palette.scale.yellow[8], fg = 'none' },
            DiffDelete = { bg = palette.scale.red[8], fg = 'none' },
          },
        },
      }
      -- vim.cmd.colorscheme 'github_dark_default'
    end,
  },
  {
    'Mofiqul/dracula.nvim',
    priority = 1000,
    cond = function()
      return not vim.g.vscode
    end,
    opts = {},
  },
  {
    'rebelot/kanagawa.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    name = 'kanagawa',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      -- vim.cmd.colorscheme 'kanagawa'
    end,
  },
  {
    'rose-pine/neovim',
    cond = function()
      return not vim.g.vscode
    end,
    name = 'rose-pine',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      -- vim.cmd.colorscheme 'rose-pine-main'
    end,
  },
  {
    'ellisonleao/gruvbox.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    priority = 1000, -- Make sure to load this before all the other start plugins.
    opts = {},
    config = function() end,
  },
  {
    'navarasu/onedark.nvim',
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('onedark').setup {
        style = 'darker',
      }
      -- -- Enable theme
      -- require('onedark').load()
    end,
  },
  {
    'Mofiqul/vscode.nvim',
    -- Both namespace clash and theme unnecessary in vscode
    cond = function()
      return not vim.g.vscode
    end,
    priority = 1000, -- Make sure to load this before all the other start plugins.
    opts = {},
    config = function()
      vim.cmd.colorscheme 'vscode'
    end,
  },
  {
    'vague2k/vague.nvim',
    -- Both namespace clash and theme unnecessary in vscode
    cond = function()
      return not vim.g.vscode
    end,
    priority = 1000, -- Make sure to load this before all the other start plugins.
    opts = {},
    config = function()
      -- vim.cmd.colorscheme 'vscode'
    end,
  },
  {
    'p00f/alabaster.nvim',
    cond = function()
      return not vim.g.vscode
    end,
  },
  {
    -- Highlight todo, notes, etc in comments
    'folke/todo-comments.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = {
        char = {
          enabled = false,
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    },
  },
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },
  {
    'hedyhli/outline.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    config = function()
      -- Example mapping to toggle outline
      vim.keymap.set('n', '<leader>fo', '<cmd>Outline<CR>', { desc = '[F]ile [O]utline' })

      require('outline').setup {
        -- Filter by kinds (string) for symbols in the outline.
        -- Possible kinds are the Keys in the icons table below.  symbols = {
        symbols = {
          filter = { 'String', 'Constant', exclude = true },
        },
      }
    end,
  },
  {
    'Bekaboo/dropbar.nvim',
    cond = function()
      return not vim.g.vscode
    end,
    -- optional, but required for fuzzy finder support
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
    },
    config = function()
      local dropbar_api = require 'dropbar.api'
      vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
      vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
      vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
    end,
  },
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    -- Currently we only use status line which is not necessary
    cond = function()
      return not vim.g.vscode
    end,
    config = function()
      require('mini.indentscope').setup()
      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }
      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
  {
    'ldelossa/litee.nvim',
    event = 'VeryLazy',
    opts = {
      -- notify = { enabled = false },
      panel = {
        orientation = 'right',
        panel_size = 70,
      },
    },
    config = function(_, opts)
      require('litee.lib').setup(opts)
    end,
  },
  {
    'ldelossa/litee-calltree.nvim',
    dependencies = 'ldelossa/litee.nvim',
    event = 'VeryLazy',
    opts = {
      on_open = 'panel',
      map_resize_keys = false,
      -- Does not work reliably with symbol resolution particular expand.
      -- see https://github.com/LazyVim/LazyVim/discussions/1137#discussioncomment-6457002
      resolve_symbols = false,
    },
    config = function(_, opts)
      require('litee.calltree').setup(opts)
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = 'VeryLazy',
    branch = 'main',
    enabled = true,
    dependencies = { 'nvim-treesitter/nvim-treesitter', branch = 'main' },
    config = function()
      require('nvim-treesitter-textobjects').setup {
        select = {
          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,
          -- You can choose the select mode (default is charwise 'v')
          selection_modes = {
            ['@parameter.outer'] = 'v', -- charwise
            ['@function.outer'] = 'V', -- linewise
            ['@class.outer'] = '<c-v>', -- blockwise
          },
          include_surrounding_whitespace = false,
        },
        move = {
          -- whether to set jumps in the jumplist
          set_jumps = true,
        },
      }
      local select = require 'nvim-treesitter-textobjects.select'
      vim.keymap.set({ 'x', 'o' }, 'af', function()
        select.select_textobject('@function.outer', 'textobjects')
      end)
      vim.keymap.set({ 'x', 'o' }, 'if', function()
        select.select_textobject('@function.inner', 'textobjects')
      end)
      local move = require 'nvim-treesitter-textobjects.move'
      vim.keymap.set({ 'n', 'x', 'o' }, ']f', function()
        move.goto_next_start('@function.outer', 'textobjects')
      end)
      vim.keymap.set({ 'n', 'x', 'o' }, '[f', function()
        move.goto_previous_start('@function.outer', 'textobjects')
      end)
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    branch = 'main',
    lazy = false,
    -- NOTE: If This hangs, you need to install tree-sitter-cli.
    -- see issue https://github.com/nvim-treesitter/nvim-treesitter/issues/8010#issuecomment-3172049340
    config = function()
      local ts = require 'nvim-treesitter'
      ts.install {
        'bash',
        'c',
        'diff',
        'lua',
        'query',
        'vim',
        'vimdoc',
        'luadoc',
        -- Markdown
        'markdown',
        'markdown_inline',
        -- JSON
        'json',
        'jsonc',
        -- Python
        'python',
        'toml',
        -- Javascript
        'javascript',
        'typescript',
        'tsx',
        'jsdoc',
        -- FE
        'html',
      }

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match) or args.match
          local installed = require('nvim-treesitter').get_installed 'parsers'
          if vim.tbl_contains(installed, lang) then
            vim.treesitter.start(args.buf)
          end
        end,
      })
    end,
  },

  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  -- require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
