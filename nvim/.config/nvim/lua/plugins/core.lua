return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Telescope <leader>ss document symbol search uses get_kind_filter()
      -- For Python this only shows functions
      -- Override and show all types
      -- https://github.com/LazyVim/LazyVim/issues/2216#issuecomment-2091460516
      kind_filter = {
        default = {
          "Class",
          "Constant",
          "Constructor",
          "Enum",
          "Field",
          "Function",
          "Interface",
          "Method",
          "Module",
          "Namespace",
          "Package",
          "Property",
          "Struct",
          "Trait",
          "Variable",
        },
      },
    },
  },
}
