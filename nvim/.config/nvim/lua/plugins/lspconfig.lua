return {
  {
    -- Override lazyvim default lspconfig with the new virtual_lines features
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = true,
        -- virtual_lines = {
        --   current_line = true,
        -- },
      },
    },
  },
}
