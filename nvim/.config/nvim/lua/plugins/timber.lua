return {
  {
    "Goose97/timber.nvim",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("timber").setup({
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
        log_marker = "Log →",
      })
    end,
    keys = {
      {
        "gld",
        "<cmd>lua require('timber.actions').clear_log_statements({ global = false })<cr>",
        mode = "n",
        desc = "Clear Log Statements Current File",
      },
    },
  },
}
