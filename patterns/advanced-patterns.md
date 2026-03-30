# Advanced Agent Team Patterns

Five advanced coordination patterns for Claude Agent Teams, each with a full
prompt you can adapt for your own projects.

---

## Pattern 1: Hierarchical Delegation

A team lead delegates to sub-team leads, who each coordinate their own workers.
This mimics a real engineering org structure and works well for large features
that span multiple subsystems.

**Structure:**
```
CTO (Lead)
├── Backend Lead
│   ├── API Engineer
│   └── Database Engineer
└── Frontend Lead
    ├── UI Engineer
    └── State Engineer
```

**When to use:** Features requiring 4+ teammates across distinct subsystems.

**Full prompt:**

```
You are the CTO leading a feature build for user notifications. You will delegate
to two sub-team leads. Do NOT implement anything yourself.

## Your responsibilities
1. Define the high-level plan and approve sub-plans before work begins.
2. Spawn two teammates:
   - **Backend Lead**: Owns `src/backend/` and `migrations/`. They should spawn
     their own teammates for API routes and database work.
   - **Frontend Lead**: Owns `src/frontend/`. They should spawn their own teammates
     for UI components and state management.
3. Coordinate the integration point: the shared schema in `src/shared/schemas/notification.ts`.
4. After both leads report completion, verify the integration works end-to-end.

## Constraints
- No teammate may edit files outside their owned directories.
- The shared schema must be agreed upon before any implementation starts.
- All sub-teams must run tests before reporting completion.

## Communication
- Sub-leads report status to you after each milestone.
- You relay cross-team dependencies (e.g., "Frontend needs the webhook endpoint
  before building the real-time panel").
```

---

## Pattern 2: Round-Robin Review

Every teammate reviews the work of exactly one other teammate in a rotation.
This ensures every piece of work gets a fresh pair of eyes and prevents the
bias of self-review.

**Structure:**
```
Teammate A (implements Feature X) → reviewed by Teammate B
Teammate B (implements Feature Y) → reviewed by Teammate C
Teammate C (implements Feature Z) → reviewed by Teammate A
```

**When to use:** After a parallel implementation phase, to catch bugs and
inconsistencies before merging.

**Full prompt:**

```
You are the lead coordinating a round-robin code review.

## Phase 1: Implementation
Spawn three teammates with these assignments:
- **Teammate A**: Implement the user authentication endpoints in `src/api/auth/`.
- **Teammate B**: Implement the session management service in `src/core/session/`.
- **Teammate C**: Implement the auth UI components in `src/ui/auth/`.

Each teammate must complete their implementation and signal readiness.

## Phase 2: Review rotation
Once all three are done, assign reviews:
- **Teammate A** reviews Teammate B's session service.
- **Teammate B** reviews Teammate C's UI components.
- **Teammate C** reviews Teammate A's auth endpoints.

Each reviewer must:
1. Read every changed file in the other's directory.
2. Run the tests for that directory.
3. Report at least one improvement suggestion and one positive observation.
4. Flag any security concerns with [CRITICAL] prefix.

## Phase 3: Resolution
Collect all review feedback. For each suggestion, either:
- Ask the original author to fix it, or
- Dismiss it with a documented reason.

Only declare the task complete when all reviews are resolved.
```

---

## Pattern 3: Progressive Refinement

A three-phase pipeline where different teammates handle drafting, reviewing,
and polishing. Each phase uses fresh agents to avoid anchoring bias.

**Structure:**
```
Phase 1 (Draft):   Teammate A + Teammate B → initial implementation
Phase 2 (Review):  Teammate C + Teammate D → review and improve
Phase 3 (Polish):  Teammate E → final cleanup and verification
```

**When to use:** High-stakes deliverables where quality matters more than speed
(e.g., public APIs, security-critical code, database migrations).

**Full prompt:**

```
You are the lead running a progressive refinement pipeline for a new payment
processing module.

## Phase 1 — Draft
Spawn two teammates:
- **Drafter A**: Implement the Stripe integration service in `src/core/payments/stripe.ts`.
- **Drafter B**: Implement the payment validation logic in `src/core/payments/validation.ts`.

Requirements: working code that passes basic happy-path tests. Do NOT over-optimize.
Signal when drafts are complete.

## Phase 2 — Review and Improve
Once Phase 1 is done, spawn two NEW teammates (do not reuse Phase 1 agents):
- **Reviewer C**: Review Drafter A's Stripe integration. Focus on error handling,
  retry logic, and idempotency. Rewrite any section that does not handle failures
  gracefully.
- **Reviewer D**: Review Drafter B's validation logic. Focus on edge cases: negative
  amounts, currency mismatches, overflow. Add missing test cases.

Reviewers must document every change they make and why.

## Phase 3 — Polish
Once Phase 2 is done, spawn one final teammate:
- **Polisher E**: Read the full module. Ensure consistent naming, remove dead code,
  verify all tests pass, and check that the public API surface is minimal and
  well-documented. Run `npm run lint` and `npm run typecheck` as a final gate.

Declare complete only after Phase 3 passes all checks.
```

---

## Pattern 4: Escalation Chain

Teammates attempt sub-problems in sequence of increasing difficulty. If one
teammate cannot resolve an issue within a time or complexity budget, they
escalate to the next teammate along with all of their findings.

**Structure:**
```
Teammate A (first attempt, simple fixes)
  └── escalates to Teammate B (deeper analysis)
       └── escalates to Teammate C (expert-level, uses Opus)
```

**When to use:** Debugging sessions where the difficulty is unknown upfront.
Saves tokens by starting with lighter models and only escalating when needed.

**Full prompt:**

```
You are the lead managing an escalation chain to debug a failing CI pipeline.

## Level 1 — Quick Fix (Haiku)
Spawn a teammate using Haiku:
- Read the CI logs in `ci-output.log`.
- Check for obvious failures: missing dependencies, syntax errors, flaky test retries.
- If you identify and fix the issue, report back with the fix.
- If the issue is not obvious after examining logs and running tests twice, escalate.

**Escalation format:**
Write to the mailbox: "ESCALATE: [summary of what was tried, what was ruled out,
and the remaining hypothesis]".

## Level 2 — Deep Analysis (Sonnet)
If Level 1 escalates, spawn a teammate using Sonnet:
- Read the Level 1 findings from the mailbox.
- Do NOT repeat work already done. Start from where Level 1 left off.
- Investigate deeper: check recent git changes, compare with last green build,
  inspect environment configuration.
- If you resolve it, report. If not, escalate with updated findings.

## Level 3 — Expert Resolution (Opus)
If Level 2 escalates, spawn a teammate using Opus:
- Read all prior findings.
- You have full authority to make architectural changes if needed.
- Consider systemic causes: race conditions, environment drift, dependency conflicts.
- This is the final level — you must produce either a fix or a detailed report
  explaining why the issue cannot be resolved automatically.
```

---

## Pattern 5: Context Injection

The lead injects new information mid-session (a stack trace, a requirements
change, a customer report) to test how teammates adapt. This pattern is
useful for building resilient teams and simulating real-world interruptions.

**Structure:**
```
Lead spawns teammates → teammates begin work → lead injects new context
→ teammates adapt → lead evaluates adaptation quality
```

**When to use:** When you want to stress-test a team's ability to handle
changing requirements, or when new information arrives during an investigation.

**How context injection works:** The lead uses direct messaging to send new
information to specific teammates or broadcasts it to all teammates via the
shared mailbox. Teammates are pre-instructed to check for injected context
periodically and adapt their approach.

**Full prompt:**

```
You are the lead running a context injection exercise for a feature build.

## Initial Task
Spawn three teammates to build a user profile page:
- **Teammate A**: Backend API for user profiles (`src/api/users/`).
- **Teammate B**: Frontend profile component (`src/ui/profile/`).
- **Teammate C**: Test suite for the profile feature (`tests/profile/`).

Give them this initial requirement: "Build a simple user profile page showing
name, email, and avatar."

## Context Injection Plan (execute these in order)

### Injection 1 — New requirement (after teammates start working)
Send to ALL teammates via mailbox:
"UPDATED REQUIREMENT: The profile page must now also display the user's role
and last login timestamp. The role field is an enum: admin, editor, viewer."

Observe: Do teammates update their schemas, components, and tests accordingly?

### Injection 2 — Bug report (after Injection 1 is absorbed)
Send ONLY to Teammate A via direct message:
"URGENT: Production stack trace shows a null pointer exception when users have
no avatar set. The avatar field must be optional with a default fallback."

Observe: Does Teammate A fix the bug AND notify teammates B and C about the
schema change?

### Injection 3 — Scope reduction (near the end)
Send to ALL teammates via mailbox:
"SCOPE CHANGE: Drop the last login timestamp — the product team removed it
from the spec. Remove it from API, UI, and tests."

Observe: Do teammates cleanly remove the feature without leaving dead code?

## Evaluation Criteria
After all injections, review:
1. Did teammates adapt without restarting from scratch?
2. Did they communicate schema changes to each other?
3. Is the final code clean — no remnants of removed features?
4. Do all tests still pass?
```
