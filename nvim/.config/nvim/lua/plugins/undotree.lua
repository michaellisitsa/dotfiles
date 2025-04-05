return {
  {
    "mbbill/undotree",
    lazy = false,
    keys = {
      { "<leader>tu", "<cmd>UndotreeToggle<CR>", desc = "Toggle Undotree" },
    },
    config = function()
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
  },
}
