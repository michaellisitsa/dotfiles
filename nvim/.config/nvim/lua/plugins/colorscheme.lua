return {
  -- add vscode theme
  --https://github.com/Mofiqul/vscode.nvim
  { "Mofiqul/vscode.nvim" },

  -- Configure LazyVim to load vscode theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },
}
