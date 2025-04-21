return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    config = function()
      require("oil").setup({ keymaps = { ["<Esc>"] = "actions.close" } })
    end,
    keys = {
      { "<leader>fm", "<cmd>Oil<cr>", mode = "n", desc = "Open Filesystem" },
    },
    lazy = false,
  },
}
