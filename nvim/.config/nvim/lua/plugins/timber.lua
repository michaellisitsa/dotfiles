return {
  {
    "Goose97/timber.nvim",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("timber").setup({
        log_templates = {
          default = {
            javascript = [[console.log("%line_number: %log_target", %log_target)]],
            typescript = [[console.log("%line_number: %log_target", %log_target)]],
            tsx = [[console.log("%line_number: %log_target", %log_target)]],
            python = [[print(f"%line_number: {%log_target=}")]],
          },
          plain = {
            javascript = [[console.log("%line_number: %insert_cursor")]],
            typescript = [[console.log("%line_number: %insert_cursor")]],
            tsx = [[console.log("%line_number: %insert_cursor")]],
            python = [[print(f"%line_number: %insert_cursor")]],
          },
        },
        log_marker = "LOG: ", -- Or any other string, e.g: MY_LOG
      })
    end,
  },
}
