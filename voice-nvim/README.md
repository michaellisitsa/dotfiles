# voice-nvim

Drive Neovim by talking to Claude Code. Claude runs in a tmux pane next to your editor. It sees what's on your screen at every prompt and acts on the live Neovim over its RPC socket. You don't need any changes to your nvim config or dotfiles. Keep this repo local-only.

## How it works

```
speak ─▶ Claude Code /voice (hold mode) ─▶ transcript in prompt, Enter to send
          │
          ├─ UserPromptSubmit hook: nv hook prompt
          │     appends an <nvim> snapshot: file, mode, cursor, ±20 visible lines,
          │     word under cursor, selection, diagnostics, open buffers
          │
          ▼
   Claude (Opus 5.5, low effort, auto mode)
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

In the tmux window where Neovim is running, run `voice-pane` from a shell. It starts Claude in a split beside the editor and leaves your focus where it is. It also tags that pane and binds **F5** in your running tmux server, with no prefix. Nothing is written to your tmux.conf, and running `voice-pane` again after a tmux restart re-creates the binding.

- **F5** from anywhere in the tmux session: jumps to the Claude pane. **F5** there jumps back to the pane you came from.
- In the Claude pane, **hold F4** (Claude Code's push-to-talk, rebound from Space in `~/.claude/keybindings.json`) and speak; **release** to stop. The transcript is inserted into the prompt without sending (hold mode, no `autoSubmit`), so review it and press Enter to send.
- Things you can say: "go to line forty two", "rename this to camel user record", "delete this function", "add a null check before the fetch", "open the users controller", "fix the type errors in view", "undo that".
- "Undo" reverts Claude's file edits as well. The reload is in Neovim's undo history (`'undoreload'`), so `u` restores the previous version and `:w` puts the disk back in sync. The prompt already tells Claude to do both.

Map F4 and F5 to Glove80 thumb keys. They must reach the terminal as real function keys, not as macOS media keys.

## Tuning

| | |
|---|---|
| `VOICE_MODEL` | default `claude-opus-5-5`. Switch mid-session with `/model` (e.g. Haiku for lower latency), or `/fast` for Opus fast mode, which a Team admin may need to enable. |
| `VOICE_EFFORT` | default `low` |
| `VOICE_PERMISSION_MODE` | default `auto`: Claude runs what it judges safe without a keypress and asks about the rest; git and `u` are the safety net. `acceptEdits` auto-approves only file edits; `manual` prompts for everything. |
| `VOICE_CHROME` | default `1`: starts Claude with `--chrome` (Claude in Chrome), so it can also drive your running Chrome through the extension. `0` leaves it off. |
| `NV_HOOK_RADIUS` | lines either side of the cursor in the per-prompt snapshot. Default 20, and never more than what's visible. |
| `NV_SOCKET` | pin a specific Neovim, e.g. one started with `nvim --listen /tmp/nvim` |
| `VOICE_KEY` | tmux talk key bound by `voice-pane`, default `F5` |
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

## Session Claude (F6)

One Claude per tmux session that can see and act on every pane in that session, not just Neovim. **F6** is bound in `~/.tmux.conf` and runs `bin/ctl-pane`.

- **The first F6 in a session** starts `claude-ctl` in a hidden window called `controller` (set `CTL_WINDOW_NAME` to change it), in the session's start directory, and stores its pane in the session option `@ctl-pane`.
- **F6 in any other window** moves that same pane in beside you with `join-pane` and focuses it. The process and conversation keep going, because pressing F6 never starts a new one. **Hold F4** to talk.
- **F6 in the Claude pane** moves it back to its hidden window with `break-pane` and returns you to the pane you came from.
- Each prompt gets a `<tmux>` block (from `tp hook prompt`). It lists the session's panes, marks the target, which is the pane you were last in, and includes that pane's last 40 lines.
- Claude acts through `tp`, which types into your panes so you see the commands and they go into your shell history. `tp` refuses panes in other sessions, and Claude's settings deny raw `tmux`. That deny is a prefix rule, not a sandbox. `nv` is allowed too, for when the target is Neovim.
- If the tmux server stops, Claude stops with it. The next F6 starts a fresh one. To pick the old conversation up, run `/resume` in it.

The prompt is `claude/ctl-prompt.md` and the settings are `claude/ctl-settings.template.json`. It takes the same `VOICE_*` variables as `claude-voice`, and `CTL_PANE_SIZE` sets the width (default 38%).

```
tp ctx [-n N]                       session panes + target's last N lines
tp show [-t P] [-n N]               a pane's last N lines
tp run [-t P] [-w SECS] CMD         type CMD + Enter at a shell prompt, wait, print output
tp keys [-t P] KEY...               tmux key names (C-c, q, Up Enter)
tp text [-t P] TEXT                 type without Enter
tp window [-n NAME] [-c DIR] [CMD]  new window in the session, focus stays
tp split [-t P] [-v] [-c DIR] [CMD] split beside P
tp focus P                          show P to the user
```

`tp run` is finished when the shell is back in the foreground and the screen stops changing. It doesn't append a marker to your command. If something is still running after `-w` seconds (60 by default), it prints what's on screen and says it is still running.

## Limits

- `keys` uses `:normal` semantics. A command that waits for input (`:s///c`, `input()`) blocks until it times out, and the prompt tells Claude to avoid them. Interactive pickers go through `nv input`.
- Permission prompts for anything other than `nv` and file edits still need a keypress.
- Tested on macOS (Neovim 0.12.5 and 0.13 nightly via `nvn`, both with your config) and Linux (Neovim 0.9.5): the smoke test, discovery across tmux windows, sessions and `:terminal`, and the talk key pressed through a real attached tmux client. Test another build with `NV_TEST_NVIM=/path/to/nvim test/smoke.sh`.
