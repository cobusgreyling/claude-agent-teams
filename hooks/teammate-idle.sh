#!/bin/bash
# Hook: TeammateIdle
#
# Runs when a teammate is about to go idle.
# Exit code 2 = send feedback and keep the teammate working.
# Exit code 0 = allow the teammate to go idle.
#
# Usage:
# Add to your settings.json or .claude/settings.json:
#
# {
#   "hooks": {
#     "TeammateIdle": [
#       {
#         "matcher": "",
#         "hooks": [
#           {
#             "type": "command",
#             "command": "/path/to/teammate-idle.sh"
#           }
#         ]
#       }
#     ]
#   }
# }

# Check if the teammate has unclaimed tasks remaining
TASK_DIR="$HOME/.claude/tasks"

if [ -d "$TASK_DIR" ]; then
    # Count pending tasks across all active teams
    PENDING=$(find "$TASK_DIR" -name "*.json" -exec grep -l '"status":"pending"' {} \; 2>/dev/null | wc -l)

    if [ "$PENDING" -gt 0 ]; then
        echo "There are $PENDING pending tasks remaining. Pick up the next unblocked task."
        exit 2  # Keep the teammate working
    fi
fi

# No pending tasks — allow idle
exit 0
