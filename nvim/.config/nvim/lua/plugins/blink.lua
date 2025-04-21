return {
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- Automated signatures
      --https://cmp.saghen.dev/configuration/signature
      signature = { enabled = true },
      -- https://www.reddit.com/r/neovim/comments/1hfotru/comment/m34envg/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
      keymap = {
        preset = "super-tab",
      },
    },
  },
}
