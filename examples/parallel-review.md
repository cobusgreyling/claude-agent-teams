# Parallel Code Review — 3 Specialist Reviewers

## Setup

Enable Agent Teams in your `settings.json`, then paste the prompt below into Claude Code.

## Prompt

```
Create an agent team to review PR #142. Spawn three reviewers:

1. Security reviewer: examine authentication flows, input validation,
   token handling, SQL injection vectors, and dependency vulnerabilities.
   Flag anything with a severity rating (critical/high/medium/low).

2. Performance reviewer: profile database queries, check for N+1 patterns,
   evaluate caching strategy, and flag any O(n²) or worse algorithms.
   Include estimated impact where possible.

3. Test coverage reviewer: verify that new code paths have corresponding
   tests, check edge cases, validate error handling paths, and confirm
   that existing tests still pass with the changes.

Have each reviewer work independently, then share findings with each other
before the lead synthesises a final review summary. If any reviewer
disagrees with another's assessment, they should discuss it directly.
```

## What Happens

1. The lead creates a shared task list with three review tasks
2. Each teammate claims their task and begins reviewing
3. Reviewers work in parallel — each reading the PR through their own lens
4. When finished, they share findings via the mailbox
5. If conflicts arise (e.g., a performance optimisation introduces a security risk), teammates debate directly
6. The lead synthesises all findings into a final summary

## Why This Works

A single reviewer gravitates toward one issue type at a time. With three specialists running simultaneously, security, performance, and test coverage all get thorough attention. The direct communication step catches cross-cutting concerns that isolated reviews would miss.

## Recommended Settings

- **Teammates**: 3 (one per review domain)
- **Display mode**: `tmux` (easier to watch all three in parallel)
- **Plan approval**: not needed (review is read-only)
