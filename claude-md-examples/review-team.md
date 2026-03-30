# CLAUDE.md — Code Review Team

## Project Overview

This is a multi-agent code review session. You are part of a review team inspecting
recent changes for correctness, security, and maintainability. Coordinate with your
teammates to ensure full coverage without duplicating effort.

## Codebase Structure

- `src/api/` — REST endpoints and middleware
- `src/core/` — Business logic and domain models
- `src/db/` — Database access layer, migrations, and seeders
- `src/ui/` — React components and hooks
- `tests/unit/` — Unit tests (mirrors `src/` structure)
- `tests/integration/` — Integration and end-to-end tests
- `docs/` — API docs and architecture decision records

## Testing Commands

- Run all tests: `npm test`
- Run unit tests only: `npm run test:unit`
- Run integration tests: `npm run test:integration`
- Type check: `npm run typecheck`
- Lint: `npm run lint`

## Code Review Checklist

### Security
- [ ] No secrets or credentials in code
- [ ] Input validation on all public endpoints
- [ ] SQL queries use parameterized statements
- [ ] Auth checks present on protected routes

### Performance
- [ ] No N+1 query patterns
- [ ] Large collections use pagination
- [ ] Expensive computations are memoized or cached
- [ ] No synchronous blocking in async paths

### Tests
- [ ] New code has corresponding tests
- [ ] Edge cases covered (empty input, null, boundary values)
- [ ] Tests are deterministic (no time-dependent flakiness)

## Communication Guidelines

- Share findings with all teammates via the mailbox — do not keep discoveries private.
- Challenge cross-cutting concerns directly: if you see an issue that spans another
  teammate's domain, raise it immediately rather than assuming they will find it.
- When you identify a pattern of issues (e.g., repeated missing validation), report
  the pattern, not just individual instances.
- Prefix findings with severity: `[CRITICAL]`, `[WARNING]`, or `[INFO]`.

## File Ownership Boundaries

- **Reviewer A**: `src/api/` and `tests/integration/`
- **Reviewer B**: `src/core/` and `src/db/`
- **Reviewer C**: `src/ui/` and `tests/unit/`

Each reviewer is responsible for their assigned directories but must flag any
cross-boundary issues they encounter for the appropriate owner.
