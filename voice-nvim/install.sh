#!/bin/sh
# One-time setup: check requirements, make this a local-only git repo unless it already sits
# inside one, put the commands on PATH via symlinks in ~/.local/bin (override with
# VOICE_BIN_DIR), then run the smoke test.
set -eu
ROOT=$(cd "$(dirname "$0")" && pwd)
BIN=${VOICE_BIN_DIR:-$HOME/.local/bin}

command -v nvim >/dev/null || { echo "install: nvim not found" >&2; exit 1; }
ver=$(nvim --version | sed -n '1s/^NVIM v\([0-9]*\)\.\([0-9]*\).*/\1 \2/p')
set -- $ver
if [ "${1:-0}" -eq 0 ] && [ "${2:-0}" -lt 9 ]; then echo "install: need Neovim >= 0.9 (have $ver)" >&2; exit 1; fi
command -v claude >/dev/null || echo "install: warning: claude not on PATH"
command -v tmux >/dev/null || echo "install: warning: tmux not on PATH (nv then needs NV_SOCKET or \$NVIM)"

chmod +x "$ROOT"/bin/* "$ROOT"/test/*.sh

if top=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null); then
  # Already inside a repo (e.g. ~/.dotfiles): leave staging and commits to you.
  echo "git: inside $top, not creating a repo or committing"
else
  git -C "$ROOT" init -q
  git -C "$ROOT" add .
  git -C "$ROOT" commit -qm "voice-nvim: initial" || echo "install: git commit skipped (set user.name/email and commit yourself)"
  echo "git: local repo created, no remote"
fi

mkdir -p "$BIN"
for cmd in claude-voice nv voice-pane; do ln -sf "$ROOT/bin/$cmd" "$BIN/$cmd"; done
echo "linked claude-voice, nv, voice-pane into $BIN"
case ":$PATH:" in *":$BIN:"*) ;; *) echo "note: $BIN is not on your PATH" ;; esac

"$ROOT/test/smoke.sh"
