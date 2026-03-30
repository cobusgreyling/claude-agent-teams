# CLAUDE.md — Adversarial Debugging Team

## Project Overview

This is an adversarial debugging session. You are part of a team investigating a
production issue. Each teammate proposes and tests competing hypotheses. The goal
is to find the root cause, not just the symptoms. Challenge each other's theories
aggressively — premature agreement leads to missed bugs.

## Known Issue Areas

- **Authentication service**: Token refresh logic has race conditions under load.
- **Order pipeline**: Decimal precision errors in currency calculations.
- **Event bus**: Messages occasionally delivered out of order during failover.
- **Cache layer**: TTL inconsistencies between Redis and in-memory cache.
- **Search index**: Stale data after bulk writes (replication lag).

## How to Reproduce Common Bugs

- Auth race condition: Run `scripts/load-test-auth.sh --concurrency=50`
- Currency errors: Execute `npm run test:currency -- --seed=42`
- Event ordering: Use `docker compose up --scale worker=3` then trigger `scripts/event-storm.sh`
- Cache staleness: Clear Redis (`redis-cli FLUSHDB`) then hit `/api/products` twice rapidly

## Investigation Methodology

Follow this cycle rigorously:

1. **State hypothesis** — Write a clear, falsifiable statement about the root cause.
2. **Gather evidence** — Run targeted commands, read logs, inspect state. Cite specifics.
3. **Challenge others** — Attempt to disprove at least one other teammate's hypothesis.
4. **Revise** — Update or abandon your hypothesis based on new evidence.
5. **Converge** — Only declare a root cause when no teammate can produce a counter-example.

Do not skip step 3. If everyone agrees too quickly, assign one teammate as devil's
advocate for that round.

## Output Format for Findings

```
## Finding: [Short Title]
**Hypothesis**: [What you believe is happening]
**Evidence**: [Commands run, logs observed, line numbers cited]
**Confidence**: [Low / Medium / High]
**Disproved by**: [Which teammate's evidence contradicts this, if any]
**Status**: [Active / Revised / Disproved / Confirmed]
```

## Coordination Rules

- Share all log snippets and stack traces with the full team — do not summarize them.
- If your investigation touches files outside your assigned area, notify the owner.
- Time-box each hypothesis cycle to 5 minutes. Escalate if no progress.
- The lead agent makes the final root-cause determination after all evidence is in.
