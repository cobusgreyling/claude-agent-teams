# Claude Agent Teams: Kickoff Guide

A practical reference for spinning up the right team for any stage of the software development lifecycle. This is a living document — trim mercilessly as you learn what you actually use.

---

## What Agent Teams Are (and Aren't)

An **Agent Team** is a mesh of independent Claude Code sessions that share a **Task List** and a **Mailbox**. Unlike subagents (which report only to a lead), teammates message each other directly, claim tasks without being delegated to, and can debate findings peer-to-peer.

The tradeoff is cost: each teammate is a full Claude instance with its own context window. Expect 3–5× the token spend of a solo session with the same scope.

**Use a team when:**
- The work naturally splits across distinct domains with clear file ownership (API / UI / tests)
- You want adversarial pressure — multiple agents trying to disprove each other's theories
- Sequential review would anchor reasoning (same model, same framing, finds same blind spots)
- The problem is wide enough that a single context window would thrash between concerns

**Use solo Claude (or subagents) when:**
- The task fits comfortably in one context window
- Work is sequential by nature — step N depends on step N-1
- You need results fast with minimal overhead

---

## How to Invoke a Team

Two distinct patterns. Pick based on whether you want a one-shot pipeline or an ongoing interactive session.

### Pattern A: Launcher script (pipeline / automation)

Launcher scripts pipe a fully-constructed prompt to `claude -p` and exit. Good for CI hooks, pre-merge gates, or any workflow where you want a structured output artifact without staying in the loop.

```bash
# Existing patterns (bash)
./scripts/launch-review-team.sh --pr 142
./scripts/launch-debug-team.sh --bug "intermittent 500 on /checkout"
./scripts/launch-build-team.sh --feature "user notifications"

# SDLC extensions (Python, no extension)
./scripts/launch-requirements-team --feature "user notifications"
./scripts/launch-design-team --spec docs/specs/notifications-requirements.md
./scripts/launch-closure-team --feature "user notifications" --branch feat/notifications
```

Add `--dry-run` to any launcher to print the full prompt without executing — useful for tuning.

### Pattern B: `--append-system-prompt-file` (interactive session)

Appends a team composition file to every turn in your interactive Claude session. You stay in the conversation; teammates are spawned as part of the flow.

```bash
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
  claude --append-system-prompt-file ~/.claude/teams/design-team.md

# Or as a shell function (add to ~/.aliases.zsh or ~/bin/cteam):
cteam() {
  local team="$1"; shift
  local tmpl="$HOME/.claude/teams/${team}.md"
  [[ -f "$tmpl" ]] || { echo "No template: $tmpl"; return 1; }
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
    claude --append-system-prompt-file "$tmpl" "$@"
}

# Usage:
cteam design-team
cteam requirements-team "Gather requirements for the checkout redesign"
```

Team template files live in `~/.claude/teams/` (one per archetype). They describe team composition and coordination rules — the same content as a launcher's embedded prompt, but as a reusable file you can version in your dotfiles.

---

## SDLC Archetypes

### 1. Requirements Discovery

**When:** Starting a feature with ambiguous or under-specified requirements. Simulated user personas surface unstated needs and contradictions before a line of code is written.

**Team (4 members):**
| Role | Responsibility |
|------|---------------|
| **Product Lead** (lead) | Facilitates sessions, synthesizes into PRD |
| **Power User** | Heavy user who wants depth, control, and efficiency |
| **Casual User** | Non-technical user who wants simplicity and clarity |
| **Skeptic** | Challenges assumptions; surfaces edge cases, friction, and unstated constraints |

**Output:** `docs/specs/{feature}-requirements.md` — PRD with user stories and acceptance criteria

**Launcher:**
```bash
./scripts/launch-requirements-team --feature "user notifications"
./scripts/launch-requirements-team --feature "checkout redesign" --stakeholders 4 --dry-run
```

**Sample prompt skeleton:**
```
You are leading a requirements discovery session for: {feature}.

Spawn 3 teammates:
1. Power User — wants depth and control; asks "can it also do X?"
2. Casual User — wants simplicity; asks "why do I need to know that?"
3. Skeptic — challenges every assumption; asks "what happens when Y fails?"

Conduct 2–3 rounds of structured Q&A. Each persona must respond to the others.
Skeptic must challenge at least one assumption per round.
Synthesize findings into docs/specs/{feature}-requirements.md with:
- Problem statement
- User stories (As a ___, I want ___, so that ___)
- Acceptance criteria
- Out of scope (explicit)
- Open questions
```

---

### 2. Technical Design

**When:** You have requirements and need to produce a tech design doc that survives peer review. The team stress-tests the design before implementation starts.

**Team (4 members):**
| Role | Responsibility |
|------|---------------|
| **Tech Lead** (lead) | Proposes initial design, synthesizes final doc |
| **Senior Engineer** | Challenges architecture; surfaces risks, edge cases, operational concerns |
| **Implementer** | Asks "how would I actually build this?" — flags ambiguity, missing contracts |
| **Stakeholder** (simulated PM) | Validates against requirements; spots scope creep and missed user needs |

**Output:** `docs/plans/{feature}-design.md` + ADR stub at `docs/plans/{feature}-adr.md`

**Launcher:**
```bash
./scripts/launch-design-team --spec docs/specs/notifications-requirements.md
./scripts/launch-design-team --spec docs/specs/checkout-requirements.md --output docs/plans/
```

**Sample prompt skeleton:**
```
You are leading a technical design session. Requirements: {spec_path}

Spawn 3 teammates:
1. Senior Engineer — must attempt to break the design: find failure modes,
   edge cases, operational risks. Must raise at least 2 concrete objections.
2. Implementer — must flag every ambiguity: missing API contracts, undefined
   error states, unclear ownership. Must ask "what does X return when Y?"
3. Stakeholder — must validate each design decision against the requirements.
   Must flag any scope creep or missing requirement coverage.

Conduct 2 rounds of structured review. Each reviewer must respond to
at least one point raised by another.

Tech Lead synthesizes into docs/plans/{feature}-design.md:
- Architecture overview
- Component breakdown with ownership
- API contracts (request/response shapes)
- Data model
- Error handling strategy
- Open decisions (with options and recommendation)
- ADR stub for each major decision
```

---

### 3. Feature Implementation (cross-layer build)

**When:** Building a feature that spans backend, frontend, and tests. File ownership prevents merge conflicts; plan approval prevents misaligned implementations.

**Team (3 members):**
| Role | Owns |
|------|------|
| **Backend Engineer** | `src/api/`, `src/db/`, business logic, unit tests |
| **Frontend Engineer** | `src/ui/`, hooks, state management, component tests |
| **Test Engineer** | `tests/integration/`, API contract tests, e2e |

**Launcher:**
```bash
./scripts/launch-build-team.sh --feature "user notifications"
```

See `examples/cross-layer-build.md` for a full prompt.

**Key constraint:** Backend publishes API contract first via Mailbox. Frontend and Test wait for it before building. Plan approval required before any implementation.

---

### 4. Code Review (parallel, multi-lens)

**When:** Pre-merge review of a complex PR, or any codebase area where you want security, performance, and maintainability reviewed independently without anchoring.

**Team (3 members):** Security · Performance · Maintainability reviewers working in parallel.

**Launcher:**
```bash
./scripts/launch-review-team.sh --pr 142
./scripts/launch-review-team.sh src/payments/   # directory review
```

See `examples/parallel-review.md` for a full prompt.

**Output format:** Each reviewer tags findings `[CRITICAL]`, `[WARNING]`, `[INFO]` with file + line. Lead deduplicates and synthesizes.

---

### 5. Bug Investigation (competing hypotheses)

**When:** A bug that resists sequential investigation — intermittent failures, race conditions, cross-layer corruption. Adversarial structure eliminates weak theories through cross-examination.

**Team (5 investigators):** Each assigned a different root-cause hypothesis. Must attempt to disprove at least one other investigator's theory.

**Launcher:**
```bash
./scripts/launch-debug-team.sh --bug "checkout silently drops items when coupon is applied"
```

See `examples/competing-hypotheses.md` for a full prompt.

**Critical rule:** Require adversarial structure. Without it, teammates agree too quickly (premature consensus is the most common anti-pattern in debugging teams).

---

### 6. Documentation Closure

**When:** Implementation is complete and you need archival artifacts: ADR, PR description, Jira tickets, and a changelog entry — all consistent with each other and with the actual diff.

**Team (3–4 members):**
| Role | Responsibility |
|------|---------------|
| **Docs Lead** (lead) | Coordinates, reads actual diff, commits output |
| **ADR Writer** | Writes Architecture Decision Record: context, decision, consequences |
| **PR Summarizer** | Writes PR description from git diff: summary, motivation, test plan |
| **Jira Scribe** (optional) | Drafts Jira ticket descriptions for completed work items |

**Output:** `docs/plans/{feature}-adr.md` + PR description to stdout + optional Jira drafts

**Launcher:**
```bash
./scripts/launch-closure-team --feature "user notifications" --branch feat/notifications
./scripts/launch-closure-team --feature "payments refactor" --jira-project PAY
```

**Sample prompt skeleton:**
```
You are leading documentation closure for: {feature} (branch: {branch}).

Run `git log main..{branch} --oneline` and `git diff main..{branch} -- .`
to understand what was actually built.

Spawn 3 teammates:
1. ADR Writer — write docs/plans/{feature}-adr.md:
   - Title: "ADR: {short decision name}"
   - Status: Accepted
   - Context: what problem, what constraints
   - Decision: what was chosen and why (not just what)
   - Consequences: trade-offs, future implications
   Read the diff first. Document the actual decisions made, not ideal ones.

2. PR Summarizer — write a PR description (markdown, stdout):
   - Summary: 3–5 bullet points of what changed
   - Motivation: why this change (link to requirements if available)
   - Test plan: what to verify manually + what tests cover it
   - Breaking changes: any API or schema changes consumers need to know about

3. Jira Scribe (if --jira-project provided) — draft one Jira ticket per
   logical work item found in the diff:
   - Summary: imperative verb + object ("Add POST /notifications endpoint")
   - Description: what it does, acceptance criteria, notes for QA
   - Type: Story / Bug / Task based on nature of change

Lead commits ADR to git after review.
```

---

### 7. Security Audit

**When:** Pre-launch security review, or any time a new authentication / payment / data-handling surface is added.

**Team (4 members):**
| Role | Focus area |
|------|-----------|
| **Security Lead** (lead) | Synthesizes findings into remediation plan |
| **Auth Auditor** | Authentication, authorization, session management, JWT/token handling |
| **Input Validator** | Injection (SQL, XSS, command), deserialization, file upload, path traversal |
| **Dependency Scanner** | Known CVEs in dependencies, outdated packages, supply chain risks |

*(No dedicated launcher yet — use Pattern B with `~/.claude/teams/security-audit.md`)*

**Sample `~/.claude/teams/security-audit.md`:**
```
You are leading a security audit of this codebase.

Spawn 3 teammates with strict file ownership:
1. Auth Auditor — read all auth middleware, token handling, session management.
   Check: Is every endpoint that should be authenticated actually protected?
   Is token expiry enforced? Are permissions checked at the right layer?

2. Input Validator — read all request handlers, form parsers, file uploads.
   Check: Is every user-supplied value validated before use?
   Parameterized queries everywhere? No eval/exec on user input?

3. Dependency Scanner — run `npm audit` or `pip-audit` or equivalent.
   Check: Any HIGH or CRITICAL CVEs? Packages >2 major versions behind?
   Any packages with known supply chain incidents?

All findings: tag [CRITICAL], [HIGH], [MEDIUM], [LOW] with file + line.
Critical findings block completion until remediation is proposed.
Synthesize into SECURITY_AUDIT.md with: findings table, remediation priority, pass/fail verdict.
```

---

## Team Composition Principles

**Size:** 3–5 teammates. Below 3, parallelism doesn't justify overhead. Above 5, coordination cost dominates.

**Tasks per teammate:** 5–6 tasks. Enough to stay busy across the session without scope bloat.

**File ownership is mandatory for implementation teams.** Two teammates writing the same file → last write wins → silent data loss. Assign directories, not files. Shared config files: only one teammate may edit; others propose changes via Mailbox.

**Model matching:**
```
Haiku    → file reads, grep, lint, formatting passes
Sonnet   → standard implementation, test writing, documentation
Opus     → architecture decisions, complex debugging, adversarial review
```
Mix models per task. Don't default every teammate to Opus — it's 5–15× the cost of Sonnet for tasks that don't need it.

**Plan approval gate:** Always require plan approval before implementation tasks. Catching the wrong approach at plan stage costs ~50 tokens; after implementation costs ~5,000.

**Adversarial structure for review/debug:** Require each reviewer to challenge at least one other's finding. Without this, teammates converge too fast and miss the same blind spots.

---

## Hooks Quick Reference

Configure in `settings.json`:

```json
{
  "hooks": {
    "TeammateIdle": [{"type": "command", "command": "./hooks/teammate-idle.sh"}],
    "TaskCompleted": [{"type": "command", "command": "./hooks/task-completed.sh"}]
  }
}
```

| Hook | Fires when | Exit 0 | Exit 2 |
|------|-----------|--------|--------|
| `TeammateIdle` | Teammate has no active task | Allow idle | Send feedback, keep working |
| `TaskCompleted` | Teammate marks task done | Allow completion | Block; send feedback |

Typical `TaskCompleted` implementation: run tests, block on failure. See `hooks/task-completed.sh`.

---

## Alias Recipes

### `cteam` — interactive team launcher

Add to `~/.aliases.zsh`:

```zsh
cteam() {
  local team="$1"; shift
  local tmpl="$HOME/.claude/teams/${team}.md"
  if [[ ! -f "$tmpl" ]]; then
    echo "No template found: $tmpl"
    echo "Available: $(ls ~/.claude/teams/*.md 2>/dev/null | xargs -n1 basename -s .md | tr '\n' ' ')"
    return 1
  fi
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
    claude --append-system-prompt-file "$tmpl" "$@"
}
```

Usage:
```bash
cteam design-team
cteam requirements-team "Gather requirements for the search redesign"
cteam security-audit
```

Templates live at `~/.claude/teams/{name}.md`. Version them in your dotfiles repo.

### `ctdry` — dry-run any launcher

```zsh
ctdry() { "$@" --dry-run; }
# Usage: ctdry ./scripts/launch-design-team --spec docs/specs/auth.md
```

### Cost check before firing

```zsh
# Estimate cost before any team
alias ctcost='python /path/to/claude-agent-teams/cost-calculator.py'
ctcost --preset review
ctcost --teammates 4 --tasks-per-teammate 5 --model sonnet --compare
```

---

## Common Anti-Patterns

See `patterns/anti-patterns.md` for the full list. The three that hurt most in practice:

1. **Over-specialization** — 8 teammates when 3 would do. If a task takes <5 min solo, don't parallelize it.
2. **Missing file ownership** — two teammates editing the same file. Always assign directories explicitly.
3. **Premature consensus** — teammates agreeing without challenging each other. Require adversarial structure in review and debug teams.
