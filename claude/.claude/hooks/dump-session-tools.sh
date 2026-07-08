#!/bin/bash
# Stop hook: extract every tool call of the session from the transcript
# into one per-session JSONL file.
input=$(cat)
session_id=$(echo "$input" | jq -r .session_id)
transcript=$(echo "$input" | jq -r .transcript_path)
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/logs"
[ -f "$transcript" ] || exit 0
jq -c --arg sid "$session_id" '
  select(.type == "assistant")
  | .message.content[]?
  | select(.type == "tool_use")
  | {session_id: $sid, tool_use_id: .id, tool_name: .name, tool_input: .input}
' "$transcript" > "$CLAUDE_PROJECT_DIR/.claude/logs/session-$session_id-tools.jsonl"
exit 0
