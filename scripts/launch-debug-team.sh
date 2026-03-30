#!/bin/bash
# Launch a competing hypotheses debugging team
# Usage: ./scripts/launch-debug-team.sh [--bug "description"] [--dry-run] [directory]
# chmod +x scripts/launch-debug-team.sh

set -euo pipefail

# Defaults
BUG_DESC=""
DRY_RUN=false
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bug)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --bug requires a description" >&2
                exit 1
            fi
            BUG_DESC="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--bug \"description\"] [--dry-run] [directory]"
            echo ""
            echo "Launch a competing hypotheses debugging team using Claude Agent Teams."
            echo ""
            echo "Options:"
            echo "  --bug \"desc\"    Description of the bug to investigate"
            echo "  --dry-run       Print the prompt without executing"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Arguments:"
            echo "  directory       Target directory to debug (default: current dir)"
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

# Build the bug context
if [[ -n "$BUG_DESC" ]]; then
    BUG_CONTEXT="The reported bug is: ${BUG_DESC}"
else
    BUG_CONTEXT="Investigate any reported issues, recent regressions, or suspicious patterns in the codebase."
fi

# Build the prompt
PROMPT="You are the lead of a competing hypotheses debugging team. ${BUG_CONTEXT}

Launch 5 sub-agents in parallel, each pursuing a different hypothesis about the root cause in '${TARGET_DIR}':

1. **Data Flow Investigator** - Trace the data flow from input to output. Look for data corruption, type mismatches, missing transformations, or incorrect serialization/deserialization.

2. **State & Concurrency Analyst** - Examine shared state, race conditions, deadlocks, stale caches, and session/state management issues. Check for missing locks or atomic operations.

3. **Dependency & Integration Checker** - Investigate external dependencies, API contract violations, version mismatches, configuration drift, and environment-specific issues.

4. **Error Handling Auditor** - Trace error propagation paths. Look for swallowed exceptions, incorrect error codes, missing retry logic, and cascading failure patterns.

5. **Recent Changes Forensic** - Use git log and git diff to examine recent commits. Identify which changes correlate with when the bug was introduced. Check for incomplete migrations or partial rollouts.

Each sub-agent should:
- State their hypothesis clearly
- Gather evidence by reading code, logs, and configs
- Rate their confidence (high/medium/low) with supporting evidence
- Suggest a specific fix if the hypothesis is confirmed

After all sub-agents complete, synthesize their findings:
- Rank hypotheses by confidence and evidence strength
- Identify the most likely root cause
- Propose a fix with specific code changes
- Suggest regression tests to prevent recurrence"

if $DRY_RUN; then
    echo "=== DRY RUN - Prompt that would be sent ==="
    echo ""
    echo "$PROMPT"
    echo ""
    echo "=== End of prompt ==="
    echo "Directory: $TARGET_DIR"
    exit 0
fi

# Launch the debug team
echo "Launching competing hypotheses debugging team..."
[[ -n "$BUG_DESC" ]] && echo "Bug: $BUG_DESC"
echo "Target directory: $TARGET_DIR"
echo ""

echo "$PROMPT" | claude -p --allowedTools "Bash,Read,Glob,Grep,Agent" --directory "$TARGET_DIR"
