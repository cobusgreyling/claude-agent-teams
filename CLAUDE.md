# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A reference/documentation repo for **Claude Code Agent Teams** — a blog post, examples, templates, and utilities. There is no application to build or test suite to run.

## Repo-Specific Tools

**Cost calculator** (`cost-calculator.py`) — estimates token usage before running a team:
```bash
python cost-calculator.py --preset review          # presets: review, debug, build
python cost-calculator.py --teammates 5 --tasks-per-teammate 6 --compare
python cost-calculator.py --preset debug --model opus --json
```

**Launcher scripts** — one-command team setup (require `claude` CLI and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`):
```bash
./scripts/launch-review-team.sh --pr 142
./scripts/launch-debug-team.sh --bug "description"
./scripts/launch-build-team.sh --feature "name"
./scripts/launch-review-team.sh --dry-run   # print prompt without executing
```

**Report generator** (`observability/report-generator.py`) — reads `team-session-log.jsonl` produced by `hooks/capture-output.sh`:
```bash
python observability/report-generator.py --input team-session-log.jsonl
python observability/report-generator.py --format html -o report.html
```

## Architecture

The repo has no application logic — every file is either documentation, a reference template, or a standalone utility. Key relationships:

- `README.md` — the primary blog post; the canonical source for all Agent Teams concepts
- `settings.json` — the only file that actually enables the feature (`CLAUDE_CODE_EXPERIMENTAL_TEAMS: "1"`, `teammateMode`)
- `claude-md-examples/` — CLAUDE.md templates for teams to load as context, not for this repo itself
- `hooks/` — standalone bash scripts wired into `settings.json` via the `hooks` key; `TeammateIdle` and `TaskCompleted` are the two relevant hook events
- `examples/` — full prompts for the three core patterns (parallel review, competing hypotheses, cross-layer build)
- `patterns/` — advanced patterns and anti-patterns, independent of the examples

## Agent Teams Key Concepts

- Teams and tasks stored at `~/.claude/teams/{team-name}/` and `~/.claude/tasks/{team-name}/`
- Teammates do **not** inherit the lead's conversation history — they start fresh with only the spawn prompt plus project CLAUDE.md
- **`TeammateIdle` hook**: exit code 2 blocks idling and sends feedback; exit code 0 allows
- **`TaskCompleted` hook**: exit code 2 blocks completion and sends feedback; exit code 0 allows
- `teammateMode`: `"auto"` (default), `"in-process"` (Shift+Down to cycle), `"tmux"` (split panes)
