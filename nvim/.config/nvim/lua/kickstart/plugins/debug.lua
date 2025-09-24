-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  {
    'richardhapb/pytest.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {}, -- Define the options here
    config = function(_, opts)
      require('nvim-treesitter.configs').setup {
        ensure_installed = { 'python', 'xml' },
      }

      require('pytest').setup(opts)
    end,
  },
  {
    -- NOTE: Yes, you can install new plugins here!
    'mfussenegger/nvim-dap',
    cond = function()
      return not vim.g.vscode
    end,
    -- NOTE: And you can specify dependencies as well
    dependencies = {
      -- Creates a beautiful debugger UI
      'rcarriga/nvim-dap-ui',

      -- Required dependency for nvim-dap-ui
      'nvim-neotest/nvim-nio',

      -- Installs the debug adapters for you
      'mason-org/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',

      -- Add your own debuggers here
      'mfussenegger/nvim-dap-python',
    },
    -- Coordinated with LazyVim keymaps
    -- https://www.lazyvim.org/extras/dap/core#nvim-dap
    keys = {
      {
        '<leader>dB',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Breakpoint Condition',
      },
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Toggle Breakpoint',
      },
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = 'Run/Continue',
      },
      {
        '<leader>da',
        function()
          require('dap').continue { before = get_args }
        end,
        desc = 'Run with Args',
      },
      {
        '<leader>dC',
        function()
          require('dap').run_to_cursor()
        end,
        desc = 'Run to Cursor',
      },
      {
        '<leader>dg',
        function()
          require('dap').goto_()
        end,
        desc = 'Go to Line (No Execute)',
      },
      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = 'Step Into',
      },
      {
        '<leader>dj',
        function()
          require('dap').down()
        end,
        desc = 'Down',
      },
      {
        '<leader>dk',
        function()
          require('dap').up()
        end,
        desc = 'Up',
      },
      {
        '<leader>dl',
        function()
          require('dap').run_last()
        end,
        desc = 'Run Last',
      },
      {
        '<leader>do',
        function()
          require('dap').step_out()
        end,
        desc = 'Step Out',
      },
      {
        '<leader>dO',
        function()
          require('dap').step_over()
        end,
        desc = 'Step Over',
      },
      {
        '<leader>dP',
        function()
          require('dap').pause()
        end,
        desc = 'Pause',
      },
      {
        '<leader>dr',
        function()
          require('dap').repl.toggle()
        end,
        desc = 'Toggle REPL',
      },
      {
        '<leader>ds',
        function()
          require('dap').session()
        end,
        desc = 'Session',
      },
      {
        '<leader>dt',
        function()
          require('dap').terminate()
        end,
        desc = 'Terminate',
      },
      {
        '<leader>dw',
        function()
          require('dap.ui.widgets').hover()
        end,
        desc = 'Widgets',
      },
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      {
        '<leader>dh',
        function()
          require('dapui').toggle()
        end,
        desc = 'Debug: See last session result.',
      },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      require('mason-nvim-dap').setup {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_installation = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {
          -- NOTE: Only config provided to 'dap' i.e. `require("dap").configurations.python` work,
          -- although it seems you should be able to also pass them in here as well
          -- From https://github.com/SamPosh/PyDevbox/blob/aaf3fd5b45166d304166d68320c4f3a3f2220ee1/lua/kickstart/plugins/dap/handler/python.lua
          -- LazyVim just has an empty function 'python = function() end,'
          python = function() end,
        },

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
          'python',
          'debugpy',
          'js',
        },
      }

      -- Dap UI setup
      -- For more information, see |:help nvim-dap-ui|
      dapui.setup {
        -- Set icons to characters that are more likely to work in every terminal.
        --    Feel free to remove or use ones that you like more! :)
        --    Don't feel like these are good choices.
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          icons = {
            pause = '⏸',
            play = '▶',
            step_into = '⏎',
            step_over = '⏭',
            step_out = '⏮',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
        element_mappings = {
          stacks = {
            open = '<CR>',
            expand = 'o',
          },
        },
      }

      -- Change breakpoint icons
      -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
      -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
      -- local breakpoint_icons = vim.g.have_nerd_font
      --     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      --   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
      -- for type, icon in pairs(breakpoint_icons) do
      --   local tp = 'Dap' .. type
      --   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      --   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
      -- end

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      -- Configure specific adapters
      -- Install python specific config
      require('dap-python').setup 'uv'
      -- Javascript adapter can be configured manually.
      -- We use the one installed by Mason.
      -- FYI the nvim-dap-vscode-js package is unnecessary, see nvim-dap maintainer post:
      -- https://github.com/mfussenegger/nvim-dap/issues/1411#issuecomment-2566396879
      local js_debugger_path = vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter' -- Path to vscode-js-debug installation
      -- We can set additional custom config by below mechanism as well
      require('dap').adapters['pwa-node'] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = {
          command = 'node',
          -- 💀 Make sure to update this path to point to your installation
          args = { js_debugger_path .. '/js-debug/src/dapDebugServer.js', '${port}' },
        },
      }
      for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
        -- Configurations from comment, go there to find some more. Tested with Javascript only
        -- see https://www.reddit.com/r/neovim/comments/y7dvva/comment/iswqdz7/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
        require('dap').configurations[language] = {
          {
            name = 'Launch',
            type = 'pwa-node',
            request = 'launch',
            program = '${file}',
            rootPath = '${workspaceFolder}',
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            skipFiles = { '<node_internals>/**' },
            protocol = 'inspector',
            console = 'integratedTerminal',
          },
          {
            name = 'Attach to node process',
            type = 'pwa-node',
            sourceMaps = true,
            skipFiles = { '<node_internals>/**' },
            request = 'attach',
            rootPath = '${workspaceFolder}',
            -- Interactive visualisation of processes to attach to
            processId = require('dap.utils').pick_process,
          },
        }
      end
      table.insert(require('dap').configurations.python, {
        name = 'Pytest: Current File',
        type = 'python',
        request = 'launch',
        module = 'pytest',
        args = {
          '${file}',
          '-sv',
          '--log-cli-level=INFO',
          '--log-file=pytest_logfile.log',
        },
        console = 'integratedTerminal',
      })
      -- This is currently broken with uv run python.
      table.insert(require('dap').configurations.python, {
        justMyCode = false,
        name = 'Python: Remote attach',
        type = 'debugpy',
        request = 'attach',
        -- mode = 'remote',
        -- program = "${file}", -- This configuration will launch the current file if used.
        connect = {
          host = 'localhost',
          port = 9292,
        },
        cwd = vim.fn.getcwd(),
        -- pathMappings = {
        --   {
        --     localRoot = function()
        --       return vim.fn.input('Local code folder > ', vim.fn.getcwd(), 'file')
        --     end,
        --     remoteRoot = function()
        --       return vim.fn.input('Container code folder > ', '/code', 'file')
        --     end,
        --   },
        -- },
      })
    end,
  },
}
