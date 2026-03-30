#!/bin/bash
# Launch a cross-layer feature build team
# Usage: ./scripts/launch-build-team.sh [--feature "description"] [--dry-run] [directory]
# chmod +x scripts/launch-build-team.sh

set -euo pipefail

# Defaults
FEATURE_DESC=""
DRY_RUN=false
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --feature)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --feature requires a description" >&2
                exit 1
            fi
            FEATURE_DESC="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--feature \"description\"] [--dry-run] [directory]"
            echo ""
            echo "Launch a cross-layer feature build team using Claude Agent Teams."
            echo ""
            echo "Options:"
            echo "  --feature \"desc\"  Description of the feature to build"
            echo "  --dry-run         Print the prompt without executing"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Arguments:"
            echo "  directory         Target directory (default: current dir)"
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

# Build the feature context
if [[ -n "$FEATURE_DESC" ]]; then
    FEATURE_CONTEXT="The feature to build is: ${FEATURE_DESC}"
else
    FEATURE_CONTEXT="Analyze the codebase and implement the next planned feature based on TODOs, issues, or roadmap files."
fi

# Build the prompt
PROMPT="You are the lead of a cross-layer feature build team. ${FEATURE_CONTEXT}

Launch 3 sub-agents in parallel to build this feature across the full stack in '${TARGET_DIR}':

1. **Backend Engineer** - Implement the server-side logic:
   - Database schema changes and migrations
   - API endpoints (REST or GraphQL)
   - Business logic and validation
   - Service layer integration
   - Write unit tests for all new backend code

2. **Frontend Engineer** - Implement the client-side UI:
   - UI components and pages
   - State management integration
   - API client calls to new endpoints
   - Form validation and error handling
   - Write component tests for new UI elements

3. **Integration & DevOps Engineer** - Wire everything together:
   - API contracts and type definitions shared between frontend/backend
   - Environment configuration and feature flags
   - CI/CD pipeline updates if needed
   - Integration tests that verify end-to-end flow
   - Documentation updates

Each sub-agent should:
- Read existing code to understand patterns and conventions
- Follow the project's existing style and architecture
- Create well-structured, production-ready code
- Include appropriate error handling
- Write tests alongside implementation

After all sub-agents complete, perform integration:
- Verify no conflicts between the three layers
- Run any available test suites
- Produce a summary of all files created/modified
- List any manual steps needed (migrations, env vars, etc.)"

if $DRY_RUN; then
    echo "=== DRY RUN - Prompt that would be sent ==="
    echo ""
    echo "$PROMPT"
    echo ""
    echo "=== End of prompt ==="
    echo "Directory: $TARGET_DIR"
    exit 0
fi

# Launch the build team
echo "Launching cross-layer feature build team..."
[[ -n "$FEATURE_DESC" ]] && echo "Feature: $FEATURE_DESC"
echo "Target directory: $TARGET_DIR"
echo ""

echo "$PROMPT" | claude -p --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" --directory "$TARGET_DIR"
