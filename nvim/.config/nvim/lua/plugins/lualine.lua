-- https://github.com/lkhphuc/dotfiles/blob/e49b9af0f67dee78c177f8f9dbbe291d76007479/nvim/lua/plugins/ui.lua?plain=1#L78

local colors = {
  red = "#ec5f67",
}
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = {
        component_separators = "", -- ┊ |        
        section_separators = "", -- { left = "", right = "" },
      }
      opts.sections.lualine_a = {
        {
          "mode",
          icon = "", --   
          fmt = function(str)
            return str:sub(1, 3)
          end,
          color = { gui = "bold" },
        },
      }

      -- LayVim lualine_b has the branch. Don't usually need to see this.
      -- This shows the current repo you're working in
      opts.sections.lualine_b = {}
      -- Remove directory, file path and diagnostics
      opts.sections.lualine_c = {}
      -- Remove some LazyVim's default
      -- This has some Copilot icons, some cube, and the commands
      opts.sections.lualine_x = {}
      opts.sections.lualine_y = {
        {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          symbols = { error = " " },
          -- Only want error diagnostics
          -- Default has all of them
          -- per https://github.com/nvim-lualine/lualine.nvim/blob/f4f791f67e70d378a754d02da068231d2352e5bc/lua/lualine/components/diagnostics/config.lua#L26
          sections = { "error" },
          diagnostics_color = {
            error = { fg = colors.red },
          },
        },
      }
      -- Default has the time. We have that on our Mac window bar
      opts.sections.lualine_z = {}

      opts.extensions = { "neo-tree", "lazy", "quickfix", "nvim-tree" }
    end,
  },
}
