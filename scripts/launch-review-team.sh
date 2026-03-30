#!/bin/bash
# Launch a parallel code review team
# Usage: ./scripts/launch-review-team.sh [--pr 142] [--dry-run] [directory]
# chmod +x scripts/launch-review-team.sh

set -euo pipefail

# Defaults
PR_NUMBER=""
DRY_RUN=false
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pr)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --pr requires a PR number" >&2
                exit 1
            fi
            PR_NUMBER="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--pr <number>] [--dry-run] [directory]"
            echo ""
            echo "Launch a parallel code review team using Claude Agent Teams."
            echo ""
            echo "Options:"
            echo "  --pr <number>   PR number to review (omit for general review)"
            echo "  --dry-run       Print the prompt without executing"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Arguments:"
            echo "  directory       Target directory to review (default: current dir)"
            exit 0
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            echo "Run '$0 --help' for usage information." >&2
            exit 1
            ;;
        *)
            if [[ -n "$TARGET_DIR" ]]; then
                echo "Error: Multiple directories specified" >&2
                exit 1
            fi
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Default target directory to current dir
TARGET_DIR="${TARGET_DIR:-.}"

# Validate target directory
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist" >&2
    exit 1
fi

# Check claude CLI is available
if ! command -v claude &>/dev/null; then
    echo "Error: 'claude' CLI not found. Install it from https://docs.anthropic.com/claude-code" >&2
    exit 1
fi

# Check agent teams env var
if [[ -z "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" ]]; then
    echo "Warning: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is not set." >&2
    echo "  Agent Teams may not work correctly without it." >&2
    echo "  Set it with: export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1" >&2
    echo "" >&2
fi

# Build the PR context line
PR_CONTEXT=""
if [[ -n "$PR_NUMBER" ]]; then
    PR_CONTEXT="Focus on PR #${PR_NUMBER}. Use 'gh pr diff ${PR_NUMBER}' to get the changes."
else
    PR_CONTEXT="Review the recent changes in the working directory."
fi

# Build the prompt
PROMPT="You are the lead of a parallel code review team. ${PR_CONTEXT}

Launch 3 sub-agents in parallel to review the code in '${TARGET_DIR}':

1. **Security Reviewer** - Look for security vulnerabilities, injection risks, auth issues, secret exposure, and unsafe data handling. Check for OWASP top-10 patterns.

2. **Performance Reviewer** - Identify performance bottlenecks, N+1 queries, unnecessary allocations, missing indexes, unoptimized loops, and caching opportunities.

3. **Maintainability Reviewer** - Check code style consistency, naming conventions, function complexity, test coverage gaps, documentation quality, and adherence to SOLID principles.

Each sub-agent should:
- Read the relevant files
- Produce a structured list of findings with severity (critical/warning/info)
- Include file paths and line numbers where applicable

After all sub-agents complete, synthesize their findings into a unified review report:
- Deduplicate overlapping findings
- Prioritize by severity
- Group by file
- Provide a final summary with an overall assessment"

if $DRY_RUN; then
    echo "=== DRY RUN - Prompt that would be sent ==="
    echo ""
    echo "$PROMPT"
    echo ""
    echo "=== End of prompt ==="
    echo "Directory: $TARGET_DIR"
    exit 0
fi

# Launch the review team
echo "Launching parallel code review team..."
[[ -n "$PR_NUMBER" ]] && echo "Reviewing PR #${PR_NUMBER}"
echo "Target directory: $TARGET_DIR"
echo ""

echo "$PROMPT" | claude -p --allowedTools "Bash,Read,Glob,Grep,Agent" --directory "$TARGET_DIR"
