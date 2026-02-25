#!/bin/bash
# Hook: TaskCompleted
#
# Runs when a task is being marked as complete.
# Exit code 2 = prevent completion and send feedback.
# Exit code 0 = allow the task to be marked complete.
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
#             "command": "/path/to/task-completed.sh"
#           }
#         ]
#       }
#     ]
#   }
# }

# Ensure tests pass before allowing task completion.
# Adjust the test command to match your project.

echo "Running test suite before allowing task completion..."

# Run tests (adjust command for your project)
if command -v npm &> /dev/null && [ -f "package.json" ]; then
    npm test --silent 2>&1
    TEST_EXIT=$?
elif command -v pytest &> /dev/null; then
    pytest --quiet 2>&1
    TEST_EXIT=$?
else
    echo "No test runner detected. Allowing completion."
    exit 0
fi

if [ "$TEST_EXIT" -ne 0 ]; then
    echo "Tests are failing. Fix the failing tests before marking this task complete."
    exit 2  # Block completion
fi

echo "Tests pass. Task completion approved."
exit 0
