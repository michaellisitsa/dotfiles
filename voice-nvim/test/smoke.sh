#!/bin/sh
# Smoke test: starts a throwaway headless Neovim and exercises nv and the hooks against it.
# Touches nothing outside a temp dir. Run: test/smoke.sh  (NV_TEST_NVIM=/path/to/nvim to test another build)
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
NV="$ROOT/bin/nv"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/voice-nvim-test.XXXXXX")
SOCK="$TMP/nvim.sock"
FILE="$TMP/app.ts"
fails=0

cat > "$FILE" <<'EOF'
export async function getUser(id: string) {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error("bad");
  return res.json();
}
EOF

"${NV_TEST_NVIM:-nvim}" --clean --headless --listen "$SOCK" "$FILE" >/dev/null 2>&1 &
NVPID=$!
trap 'kill $NVPID 2>/dev/null; rm -rf "$TMP"' EXIT
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -S "$SOCK" ] && break; sleep 0.2; done
export NV_SOCKET="$SOCK"

check() { # name, haystack, needle
  if printf '%s' "$2" | grep -qF -- "$3"; then echo "ok   $1"; else echo "FAIL $1"; echo "     expected: $3"; printf '%s\n' "$2" | sed 's/^/     | /'; fails=$((fails + 1)); fi
}

out=$("$NV" ctx);                         check "ctx shows file and cursor"      "$out" 'cursor=1:1 lines=5'
check "ctx marks cursor line"            "$out" '>    1  export async function getUser'
out=$("$NV" keys '3G');                   check "keys moves cursor"              "$out" 'cursor=3:1'
out=$("$NV" keys '/fetch<CR>');           check "keys search"                    "$out" 'cursor=2:21'
out=$("$NV" keys 'ciwgrab<Esc>');         check "keys edit"                      "$out" 'await grab(`'
check "edit marks buffer unsaved"        "$out" ' unsaved>'
out=$("$NV" keys 'u');                    check "undo"                           "$out" 'await fetch(`'
out=$("$NV" keys '/nomatchanywhere<CR>'); check "keys error reported"            "$out" 'error: E486'
out=$("$NV" cmd 'echo "hello"');          check "cmd output"                     "$out" 'hello'
out=$("$NV" cmd 'nosuchcommand');         check "cmd error reported"             "$out" 'error: E492'
out=$("$NV" lua 'vim.api.nvim_buf_line_count(0)' -q); check "lua result"         "$out" '5'
out=$("$NV" input 'gg0' -r 1);            check "input (async)"                  "$out" 'cursor=1:1'

# Hooks: Claude reads/edits the file while the buffer has unsaved changes.
"$NV" keys 'Gox<Esc>' -q
printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$FILE" | "$NV" hook pre
check "pre hook saves unsaved buffer"    "$(cat "$FILE")" 'x'
out=$("$NV" ctx);                         check "buffer clean after pre hook"    "$out" 'lines=6 view'
sed 's/throw new Error("bad")/throw new HttpError(res.status)/' "$FILE" > "$FILE.new" && mv "$FILE.new" "$FILE"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"throw new Error(\\"bad\\")","new_string":"throw new HttpError(res.status)"}}' "$FILE" | "$NV" hook post
out=$("$NV" ctx);                         check "post hook reloads buffer"       "$out" 'HttpError(res.status)'
check "post hook jumps to change"        "$out" 'cursor=3:'
out=$("$NV" keys 'u');                    check "u reverts the reload"           "$out" 'throw new Error("bad")'
out=$("$NV" cmd 'w' -q; cat "$FILE");     check "w puts disk back"               "$out" 'throw new Error("bad")'
out=$(echo '{}' | "$NV" hook prompt);     check "prompt hook prints snapshot"    "$out" '<nvim file='

if [ "$fails" -eq 0 ]; then echo "all passed"; else echo "$fails failed"; exit 1; fi
