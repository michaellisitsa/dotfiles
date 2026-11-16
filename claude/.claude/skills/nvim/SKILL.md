---
name: nvim
description: Drive the user's Neovim (in the same tmux session) with the `nv` CLI. Use whenever the user refers to their editor, Neovim, Vim, a tab, "this file/line/function", asks to open, show, jump to, select or edit something "in vim", or a message carries an <nvim …> block.
---

# Driving the user's Neovim

`nv` (on PATH, from `~/.dotfiles/voice-nvim`) talks to the user's running Neovim over RPC. It picks the Neovim in the same tmux window as Claude, else one elsewhere in the same tmux session; `nv where` says which one and why. Never hunt sockets or call `nvim --server … --remote-expr` yourself. If `nv` reports no Neovim, say so; don't start one.

## What you can see
A prompt hook may attach an <nvim …> block: file, mode, cursor (line:col), code around the cursor with line numbers (">" marks the cursor line), word under cursor, selection, diagnostics and open buffers. "This", "here", "that function" refer to it. Only the latest block is current. Run `nv ctx -r 60` for a wider view when you need it.
With more than one tab page there is a `tabs:` line, e.g. `tabs: 1 src/app.py | *2 [CodeDiff] src/app.py`: tab number, "*" for the current tab, [CodeDiff] for a diff view. "The first tab", "the diff" refer to it.
Opening a file while the current tab is [CodeDiff]: do it in a regular tab, not inside the diff, unless told to stay. Prefer the tab already showing the file, else the first non-CodeDiff tab: `nv cmd 'tabnext 1 | edit PATH'`. If none exists, `nv cmd 'tabnew PATH'`. From a diff hunk to the same spot in the real file: `gf`.

## Acting: one nv call per action
- `nv keys 'KEYS'` normal-mode keys in <> notation, run like :normal (mappings apply, atomic): '57G', '/handleSubmit<CR>', 'ciwnewName<Esc>', 'dap', 'u', '<C-o>'.
- `nv cmd 'EX'` an Ex command, with its output: 'w', 'edit src/app.ts', '%s/foo/bar/g', 'vsplit'. Never the c (confirm) flag or anything else that waits for input.
- `nv input 'KEYS'` asynchronous, as if typed. Only for interactive UIs (pickers, completion menus).
- `nv lua 'CODE'` Lua inside Neovim, result printed, e.g. 'vim.lsp.buf.rename("newName")'.
- keys, cmd, input and lua print the new snapshot, so no separate "look" call is needed.
Quote for the shell: text containing ' goes in double quotes; text with both quote kinds goes in a quoted heredoc: nv keys "$(cat <<'EOF' … EOF)".

## Do it in Neovim
When the user asks for something in the editor (move, open, select, search, edit, rename, format, run a test), do it through nv so they see it and it lands in Neovim's undo history. Reach for their mapping or plugin command first, then stock Vim, then Lua.
- Address lines by the snapshot numbers ('57G') or a search ('/pattern<CR>'); don't count motions.
- A named symbol not in the snapshot: one call with a search, e.g. `nv keys '/def get_was_price<CR>'`. Don't grep for the line number first.
- Go to definition: put the cursor on the symbol, then `nv lua 'vim.lsp.buf.definition()'`.
- Multi-line edits: keys ('Oline one<CR>line two<Esc>', '12G3dd'), cmd ('12,20s/a/b/', '12,20normal A;'), or lua with nvim_buf_set_lines / nvim_buf_set_text.
- Formatting, renames and code actions go through Neovim's LSP, never a formatter or sed in the shell.
- Commands whose output the user should watch: their mapping, else `nv cmd 'split | terminal CMD'`.
Ordinary coding work (multi-file changes, big rewrites) is still fine with the Edit/Write tools: hooks save the buffer before you touch the file and reload it afterwards. Reading code to answer a question is fine with Read/Grep, but if the user asks you to show something, show it in Neovim.

"Undo" → `nv keys 'u'` (follow an undone Edit-tool change with `nv cmd 'w'`). "Save" → `nv cmd 'w'`.
Never quit Neovim or discard unsaved work (:q!, :qa, :e!, :bd!) unless the user says so in those words.

## This user's Neovim (0.12, or 0.13 nightly; leader = Space)
- Traps: `s` is Flash jump (waits for a label), not substitute: use `cl`. `f`/`F`/`t`/`T` and `;`/`,` are treesitter repeatable moves. `<Esc>` in normal mode clears search highlight. Visual `p` pastes without overwriting the register.
- LSP: `grn` rename, `gra` code action, `grr` references (Telescope), `gri` implementation, `grd` definition, `K` hover, `<leader>ff` format, `<leader>q` diagnostics to location list. Prefer `nv lua 'vim.lsp.buf.rename("newName")'` for renames (no prompt).
- Save: `<leader>w`. Windows: `<C-h>`/`<C-j>`/`<C-k>`/`<C-l>`. Surround: `ys{motion}{char}`, `ds{char}`, `cs{old}{new}`.
- Git: `]h`/`[h` hunks, `<leader>hb` blame line, `<leader>hv` CodeDiff, `<leader>hf` review branch vs merge-base, `<leader>hy` GitHub link.
- CodeDiff tab: next/previous hunk = `nv lua 'require("codediff").next_hunk()'` (prev_hunk), next/previous file = next_file / prev_file; each prints false when there's nowhere to go. Inside it: `vih` selects the hunk, `<leader>hs`/`<leader>hu`/`<leader>hr` stage/unstage/discard, `-` stages the file, `do`/`dp`, `gf` opens the file in the previous tab, `q` closes. `]c`/`[c` hunks, `]n`/`[n` files.
- Tests: `<leader>gt` copies the `./shortcuts.sh test` command for the test under the cursor (doesn't run it), `<leader>ga` runs it under the debugger. `<leader>gf` path breadcrumbs.
- Panels: `<leader>fm` Oil, `<leader>fo` Outline, `<leader>tu` Undotree, `<leader>du` DAP view, `<leader>db` breakpoint, `<leader>dc` continue, `<leader>mm` bookmark, `<leader>mt` bookmark tree.
- Bookmarks (bookmarks.nvim v4) without prompts, via `nv lua`: S = `require("bookmarks.domain.service")`. `S.create_list("name")` makes a list and sets it active; `S.set_active_list(id)`; `S.toggle_mark("name")` marks the cursor line (renames an existing mark, removes it when the name is ""). Lists and marks: `require("bookmarks.domain.repo")`, `.ensure_and_get_active_list()`, `.find_node(id)`. Refresh signs with `require("bookmarks.sign").safe_refresh_signs()`. Gotcha: sqlite.lua runs line text shaped like `foo(...)` as SQL; for such lines build `local n = require("bookmarks.domain.node").new_bookmark("name")`, set `n.content = " " .. n.content`, then `Repo.insert_node(n, list_id)`.
- Telescope pickers are interactive, so drive them with `input`, never `keys`: `<leader>sc` files, `<leader>sg` live grep, `<leader><leader>` buffers, `<leader>sd` diagnostics, `<leader>s.` recent, `<leader>sr` resume. To open a file you can name, find the path yourself and use `nv cmd 'edit PATH'`.

After acting in the editor, reply in one short line.
