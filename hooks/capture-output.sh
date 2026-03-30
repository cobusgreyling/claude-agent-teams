#!/bin/bash
# Hook: TaskCompleted — Capture output for observability
#
# Appends task completion events to team-session-log.jsonl
# Each line is a self-contained JSON object for easy parsing.
#
# Usage:
# Add to your settings.json or .claude/settings.json:
#
# {
#   "hooks": {
#     "TaskCompleted": [
#       {
#         "matcher": "",
#         "hooks": [
#           {
#             "type": "command",
#             "command": "/path/to/capture-output.sh"
#           }
#         ]
#       }
#     ]
#   }
# }

LOG_FILE="${TEAM_SESSION_LOG:-team-session-log.jsonl}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read task info from stdin (hook receives JSON context)
TASK_INFO=$(cat)

# Extract fields from hook input
TEAMMATE=$(echo "$TASK_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('teammate','unknown'))" 2>/dev/null || echo "unknown")
TASK_DESC=$(echo "$TASK_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task',''))" 2>/dev/null || echo "")
STATUS=$(echo "$TASK_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','completed'))" 2>/dev/null || echo "completed")

# Build JSON line
JSON_LINE=$(python3 -c "
import json
print(json.dumps({
    'timestamp': '$TIMESTAMP',
    'teammate': '$TEAMMATE',
    'task': '''$TASK_DESC''',
    'status': '$STATUS',
    'event': 'task_completed'
}))
" 2>/dev/null)

# Fallback if python isn't available
if [ -z "$JSON_LINE" ]; then
    JSON_LINE="{\"timestamp\":\"$TIMESTAMP\",\"teammate\":\"$TEAMMATE\",\"task\":\"$TASK_DESC\",\"status\":\"$STATUS\",\"event\":\"task_completed\"}"
fi

# Append to log
echo "$JSON_LINE" >> "$LOG_FILE"
echo "Logged task completion to $LOG_FILE"

# Allow completion
exit 0
