# voice-nvim

Drive Neovim by talking to Claude Code. Claude runs in a tmux pane next to your editor. It sees what's on your screen at every prompt and acts on the live Neovim over its RPC socket. You don't need any changes to your nvim config or dotfiles. Keep this repo local-only.

## How it works

```
speak ─▶ Claude Code /voice (tap mode) ─▶ transcript submitted
          │
          ├─ UserPromptSubmit hook: nv hook prompt
          │     appends an <nvim> snapshot: file, mode, cursor, ±20 visible lines,
          │     word under cursor, selection, diagnostics, open buffers
          │
          ▼
   Claude (Haiku 5.5, low effort)
          ├─ default: Bash `nv keys|cmd|lua|input '…'` ─RPC─▶ your nvim
          │     every edit, jump, format, rename happens there (in its undo history);
          │     the call returns the new snapshot, so one round trip per utterance
          └─ fallback (nv error, or a whole-file rewrite): Edit tool
                PreToolUse  → save that buffer if it has unsaved changes
                PostToolUse → reload the buffer, move the cursor to the change
```

**How it finds your Neovim.** Every Neovim 0.9+ listens on a socket named `<NVIM_APPNAME>.<pid>.0` (so `nvim.123.0`, or `nvim-nightly.123.0` for `nvn`) under `stdpath('run')`. `nv` globs those sockets and drops the stale ones and its own. It keeps instances that have a UI attached. It then walks each one's process tree up to a tmux pane and picks the one in the same tmux window as Claude, falling back to the same session. Overrides are checked first: `$NV_SOCKET`, then `$NVIM`, which Neovim sets when Claude runs inside its `:terminal`.

**Why one call per utterance.** Each tool call costs a full model turn, which takes seconds. So `keys`, `cmd`, `input` and `lua` all print the updated snapshot themselves, and the prompt hook pre-loads context so Claude doesn't need a "look first" call.

## Install

```sh
~/.dotfiles/voice-nvim/install.sh         # checks nvim>=0.9, links into ~/.local/bin, runs the smoke test
```

Inside `~/.dotfiles`, the installer doesn't create a repo or commit anything; commit when you're ready. Anywhere else, it runs `git init` with no remote.

You'll need Claude Code signed in with your claude.ai account. Voice doesn't work with API-key auth. The first time you run `/voice`, macOS asks to give your terminal microphone access.

## Use

In the tmux window where Neovim is running, run `voice-pane` from a shell. It starts Claude in a split beside the editor and leaves your focus where it is. It also tags that pane and binds **F4** in your running tmux server, with no prefix. Nothing is written to your tmux.conf, and running `voice-pane` again after a tmux restart re-creates the binding.

- **F4** from anywhere in the tmux session: jumps to the Claude pane and taps Space, which starts recording.
- **F4** again: taps Space, which stops recording and sends the prompt, then jumps back to the pane you came from.
- Claude Code only sends automatically if the transcript is **at least 3 words**. Anything shorter is inserted without sending, so say "save the file" rather than "save", or press Enter. Recording also stops by itself after 15 s of silence; your focus then stays on the Claude pane, and the next F4 starts a new recording.
- Things you can say: "go to line forty two", "rename this to camel user record", "delete this function", "add a null check before the fetch", "open the users controller", "fix the type errors in view", "undo that".
- "Undo" reverts Claude's file edits as well. The reload is in Neovim's undo history (`'undoreload'`), so `u` restores the previous version and `:w` puts the disk back in sync. The prompt already tells Claude to do both.

Map F4 to a Glove80 thumb key. The key must reach the terminal as a real F4, not as a macOS media key.

## Tuning

| | |
|---|---|
| `VOICE_MODEL` | default `claude-haiku-5-5`. Switch mid-session with `/model`, or `/fast` for Opus fast mode, which a Team admin may need to enable. |
| `VOICE_EFFORT` | default `low` |
| `VOICE_PERMISSION_MODE` | default `acceptEdits`. File edits apply without a keypress; git and `u` are the safety net. Set to `default` to get prompts back. |
| `NV_HOOK_RADIUS` | lines either side of the cursor in the per-prompt snapshot. Default 20, and never more than what's visible. |
| `NV_SOCKET` | pin a specific Neovim, e.g. one started with `nvim --listen /tmp/nvim` |
| `VOICE_KEY` | tmux talk key bound by `voice-pane`, default `F4` |
| `VOICE_PANE_SIZE` | width of the Claude pane, default `38%` |

`bin/voice-talk` sends Space because that is Claude Code's default dictation key. If you rebind `voice:pushToTalk` in `~/.claude/keybindings.json`, change the `send-keys` key in `voice-talk` to match.

The prompt Claude gets is `claude/voice-prompt.md`. Hooks and permissions are in `claude/settings.template.json`. The launcher fills the absolute path of `nv` into both each time it starts, so the repo can live anywhere.

## nv

```
nv ctx [-r N]       editor snapshot (±N lines, default 20)
nv keys KEYS        normal-mode keys in <> notation, run like :normal: mappings apply, atomic
nv cmd EX           Ex command and its output
nv input KEYS       async, as if typed (pickers, prompts)
nv lua CODE         Lua inside Neovim, result printed
nv reload [FILE]    re-read buffers changed on disk (never touches unsaved ones)
nv sync FILE        write FILE's buffer if unsaved
nv where            which Neovim it would talk to, and why
```

`nv` is `nvim --clean -l lua/nv/cli.lua`. Each run takes about 10 ms and needs no Python, jq or Node. It sends `lua/nv/remote.lua` over RPC and executes it inside your Neovim, so there's nothing to install on that side.

## Limits

- `keys` uses `:normal` semantics. A command that waits for input (`:s///c`, `input()`) blocks until it times out, and the prompt tells Claude to avoid them. Interactive pickers go through `nv input`.
- Permission prompts for anything other than `nv` and file edits still need a keypress.
- Tested on macOS (Neovim 0.12.5 and 0.13 nightly via `nvn`, both with your config) and Linux (Neovim 0.9.5): the smoke test, discovery across tmux windows, sessions and `:terminal`, and F4 pressed through a real attached tmux client. Test another build with `NV_TEST_NVIM=/path/to/nvim test/smoke.sh`.
