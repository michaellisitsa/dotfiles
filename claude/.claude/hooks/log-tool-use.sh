#!/bin/bash
# PostToolUse hook: append one JSONL line per tool call.
# tool_response is omitted — it can be huge; add it back if you need outputs.
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/logs"
jq -c '{
  ts: (now | todate),
  session_id,
  tool_use_id,
  tool_name,
  tool_input
}' >> "$CLAUDE_PROJECT_DIR/.claude/logs/tool-calls.jsonl"
exit 0
