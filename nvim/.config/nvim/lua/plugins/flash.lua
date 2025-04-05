return {
  "folke/flash.nvim",
  opts = {
    -- Flash overrides default behaviour of Vim's find in line 'f' 'F' 't' 'T'
    -- to find on any subsequent line. This can be disorientating.
    -- Also the commad and ; are aliases to the above.
    -- https://github.com/folke/flash.nvim/blob/3c942666f115e2811e959eabbdd361a025db8b63/lua/flash/plugins/char.lua#L116C24-L116C56
    -- Disable per https://www.lazyvim.org/configuration/plugins#%EF%B8%8F-adding--disabling-plugin-keymaps
    modes = {
      char = {
        enabled = false,
      },
    },
  },
}
