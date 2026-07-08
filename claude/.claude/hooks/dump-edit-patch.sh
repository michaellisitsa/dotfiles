#!/bin/bash
# PostToolUse hook (matcher: Edit|Write): save each file change Claude makes
# as a git-apply-able .patch file, plus one index.jsonl line recording the
# commit_id/branch it was made against so you know how to apply it.
#
# Patches:  $CLAUDE_PROJECT_DIR/.claude/patches/<UTC-timestamp>-<tool_use_id>.patch
# Index:    $CLAUDE_PROJECT_DIR/.claude/patches/index.jsonl
input=$(cat)

tool_name=$(jq -r '.tool_name // empty' <<<"$input")
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$file" ] || exit 0

patch_dir="${CLAUDE_PROJECT_DIR:-$HOME/.claude}/.claude/patches"
mkdir -p "$patch_dir"

ts=$(date -u +%Y%m%dT%H%M%SZ)
tool_use_id=$(jq -r '.tool_use_id // "unknown"' <<<"$input")
session_id=$(jq -r '.session_id // "unknown"' <<<"$input")
patch_file="$patch_dir/${ts}-${tool_use_id}.patch"

# Git context of the edited file (all empty if not in a repo)
dir=$(dirname "$file")
repo_root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
commit_id=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$repo_root" ]; then
  rel=${file#"$repo_root"/}
else
  rel=$file
fi

# Build a unified diff for JUST this edit from the hook's structuredPatch
# (git diff would mix in unrelated uncommitted changes to the same file).
patch=$(jq -r --arg rel "$rel" '
  (.tool_response.structuredPatch // []) as $p
  | select(($p | length) > 0)
  | "diff --git a/\($rel) b/\($rel)\n--- a/\($rel)\n+++ b/\($rel)\n"
    + ($p | map(
        "@@ -\(.oldStart),\(.oldLines) +\(.newStart),\(.newLines) @@\n"
        + (.lines | join("\n"))
      ) | join("\n"))
' <<<"$input")

# Write with no structuredPatch = new file: emit a creation patch from content
if [ -z "$patch" ] && [ "$tool_name" = "Write" ]; then
  patch=$(jq -r --arg rel "$rel" '
    (.tool_input.content // "") as $c
    | select($c != "")
    | ($c | rtrimstr("\n") | split("\n")) as $l
    | "diff --git a/\($rel) b/\($rel)\nnew file mode 100644\n--- /dev/null\n+++ b/\($rel)\n@@ -0,0 +1,\($l | length) @@\n"
      + ($l | map("+" + .) | join("\n"))
  ' <<<"$input")
fi

[ -n "$patch" ] || exit 0
printf '%s\n' "$patch" > "$patch_file"

jq -nc \
  --arg ts "$ts" --arg sid "$session_id" --arg tid "$tool_use_id" \
  --arg tool "$tool_name" --arg file "$file" --arg rel "$rel" \
  --arg root "$repo_root" --arg commit "$commit_id" --arg branch "$branch" \
  --arg patch "$patch_file" '{
    ts: $ts,
    session_id: $sid,
    tool_use_id: $tid,
    tool_name: $tool,
    file: $file,
    repo_root: (if $root == "" then null else $root end),
    commit_id: (if $commit == "" then null else $commit end),
    branch: (if $branch == "" then null else $branch end),
    patch_file: $patch,
    apply_with: (if $root == "" then null else "git -C \($root) apply \($patch)" end)
  }' >> "$patch_dir/index.jsonl"
exit 0
