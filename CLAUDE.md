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
# Existing (bash)
./scripts/launch-review-team.sh --pr 142
./scripts/launch-debug-team.sh --bug "description"
./scripts/launch-build-team.sh --feature "name"
./scripts/launch-review-team.sh --dry-run   # print prompt without executing

# SDLC extension (Python executables, no extension)
./scripts/launch-requirements-team --feature "user notifications"
./scripts/launch-design-team --spec docs/specs/notifications-requirements.md
./scripts/launch-closure-team --feature "user notifications" --branch feat/notifications
./scripts/launch-closure-team --feature "user notifications" --jira-project MYAPP  # optional Jira drafts
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

- Released with **Opus 4.6** (February 2026); requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in env or `settings.json`
- Teams and tasks stored at `~/.claude/teams/{team-name}/` and `~/.claude/tasks/{team-name}/`
- Teammates do **not** inherit the lead's conversation history — they start fresh with only the spawn prompt plus project CLAUDE.md
- **Mailbox** — teammates message each other directly; findings don't route through the lead
- **`TeammateIdle` hook**: exit code 2 blocks idling and sends feedback; exit code 0 allows
- **`TaskCompleted` hook**: exit code 2 blocks completion and sends feedback; exit code 0 allows
- `teammateMode`: `"auto"` (default), `"in-process"` (Shift+Down to cycle), `"tmux"` (split panes)
- **Keyboard shortcuts**: `Shift+Up/Down` cycle teammates · `Ctrl+T` open task list · `Shift+Enter` split-pane dashboard (tmux/iTerm2)
- **Model matching**: Haiku for reads/lint · Sonnet for standard implementation · Opus for architecture decisions
- **`--append-system-prompt-file path/to/team.md`** — portable interactive pattern; appends team composition to every turn in a session (vs. `-p` one-shot in launcher scripts)

## Kickoff Guide

Decision tree, all SDLC archetypes, CLI invocation recipes, and alias setup:

@docs/team-kickoff-guide.md
