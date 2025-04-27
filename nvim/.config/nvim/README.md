# Config based on kickstart.nvim

### Install External Dependencies

External Requirements:
- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`)
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation)
- Clipboard tool (xclip/xsel/win32yank or other depending on the platform)
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  - if you have it set `vim.g.have_nerd_font` in `init.lua` to true

### Other likely dependendencies

- `fzf` for telescope's-fzf-native plugin, and snacks picker search
- `fd` has previously shown up as necessary for snacks picker search
- `rg` for live_grep in telescope
