# Config

Suitable for neovim 0.12, utilising native package manager for plugins

### Install External Dependencies

External Requirements:
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation)
- `fzf` for telescope's-fzf-native plugin
- Clipboard tool (xclip/xsel/win32yank or other depending on the platform) - Linux only
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  - if you have it set `vim.g.have_nerd_font` in `init.lua` to true
- [tree-sitter-cli](https://formulae.brew.sh/formula/tree-sitter-cli)

# Steps
- Install above dependencies
- Load neovim
- Install all lsps used in `/lsp/` folder using `:Mason`
- Install all debuggers and formatters using `:Mason`

# Useful directories

`~/.local/share/nvim/mason/bin` - LSP, formatter and debugger binaries
`~/.local/share/nvim/bookmarks.sqlite.db` - All bookmarks saved
`~/.local/state/nvim` - shada, frecency etc.
