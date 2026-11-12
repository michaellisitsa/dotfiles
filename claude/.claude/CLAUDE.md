# Working preferences

## Output
- **Cite code as `path|line`** (pipe), always the **full path relative to the
  working directory (cwd)** — NEVER a bare filename. Write
  `src/app/models/user.py|283`, not `user.py|283`. This holds
  everywhere, including call-stack / trace listings. Use a **single** line
  number; for a range, repeat the citation per endpoint (`...views.py|551`
  and `...views.py|593`, never `...views.py|551-593`). Use the pipe form,
  not the `file:line` colon form, so I can `:e` straight to the line.
- **Show URLs in full** — print the raw URL, never markdown link text like
  `[label](url)`. My tmux setup only lets me click URLs that display in full.

## Tooling
- **Editor:** nvim. When a task needs an editor, use nvim.
- **Environment:** macOS with Homebrew; assume BSD/macOS tool variants. WM is aerospace.
- **Terminal multiplexer:** tmux — prefer tmux-friendly workflows.
- **CLI tools:** prefer modern replacements when available —
  `rg` over grep, `fd` over find, `bat` over cat, `fzf` for fuzzy-find,
  `ast-grep` for structural search.

## Git & safety
- Never commit or push on my behalf — I commit myself. Write/edit files only.
- No destructive operations in generated scripts (no `rm -rf`); design around deletion.
