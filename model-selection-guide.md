# Model Selection Guide for Agent Teams

Choosing the right model per teammate is one of the simplest ways to control cost without sacrificing quality. Not every role needs the most capable model.

---

## Cost Comparison

| Model | Input / 1K tokens | Output / 1K tokens | Typical teammate session |
|-------|-------------------|--------------------|--------------------------|
| **Opus 4.6** | $0.015 | $0.075 | $2.50 – $4.00 |
| **Sonnet 4.6** | $0.003 | $0.015 | $0.50 – $0.80 |
| **Haiku 4.5** | $0.00025 | $0.00125 | $0.04 – $0.08 |

A 3-teammate Opus team costs roughly **$10.50**. The same team on Sonnet costs **$2.40**. On Haiku, **$0.20**.

The difference is 50x between Opus and Haiku. That makes model selection per teammate the highest-leverage cost decision you can make.

---

## Role-Based Recommendations

| Role | Model | Why |
|------|-------|-----|
| Security reviewer | **Opus** | Attack vector analysis requires deep reasoning about multi-step exploits, auth flows, and subtle injection patterns |
| Architecture reviewer | **Opus** | Cross-system reasoning across multiple layers and codebases needs the strongest model |
| Bug investigator | **Opus** | Root cause analysis requires holding multiple hypotheses simultaneously and reasoning about execution paths |
| Performance reviewer | **Sonnet** | Pattern matching for N+1 queries, O(n²) algorithms, and missing caches is reliable at Sonnet level |
| Implementation engineer | **Sonnet** | Best balance of code quality and cost. Handles most feature work competently |
| Test coverage checker | **Sonnet** | Structural analysis of code paths and test coverage doesn't need Opus-level reasoning |
| Test writer | **Sonnet** | Writing tests from existing code is well within Sonnet's capability |
| Code formatter | **Haiku** | Mechanical transformation — consistent style, import ordering, whitespace |
| Documentation writer | **Haiku** | Straightforward generation from existing code. Very cost-effective |
| File organiser | **Haiku** | Moving files, renaming, restructuring directories — no reasoning needed |

---

## Mixing Models In A Team

Specify the model per teammate in your prompt:

```
Create a team with 3 teammates to review PR #142:

1. Security reviewer (use Opus): examine authentication flows,
   input validation, token handling, SQL injection vectors.
   Flag anything with a severity rating.

2. Performance reviewer (use Sonnet): profile database queries,
   check for N+1 patterns, evaluate caching strategy.

3. Style and docs reviewer (use Haiku): verify code follows
   project style guide, check docstrings, validate imports.
```

This team costs roughly:

```
  Opus (security):     $3.00
  Sonnet (performance): $0.60
  Haiku (style/docs):   $0.06
  ─────────────────────────
  Total:               $3.66
```

Compared to all-Opus ($10.50) or all-Sonnet ($2.40). You get Opus-level security review where it matters, and save everywhere else.

---

## When To Use Each Model

### Opus — Deep Reasoning Required

Use Opus when the teammate needs to:
- Reason about multi-step attack vectors
- Hold multiple competing hypotheses simultaneously
- Understand complex architectural implications
- Make judgment calls about tradeoffs

Typical roles: security auditor, architecture reviewer, bug investigator, system designer.

### Sonnet — The Default Choice

Use Sonnet when the teammate needs to:
- Write functional code from specifications
- Identify patterns in code (N+1, missing tests, etc.)
- Follow established patterns and conventions
- Produce competent, working implementations

Typical roles: implementation engineer, test writer, performance reviewer, API developer.

### Haiku — Mechanical Tasks

Use Haiku when the teammate needs to:
- Apply consistent formatting rules
- Generate documentation from existing code
- Move, rename, or reorganise files
- Run simple checks or validations

Typical roles: code formatter, documentation writer, file organiser, linter.

---

## Cost Optimization Tips

**1. Use Opus only for roles that need deep reasoning.** Most teams need at most 1 Opus teammate. The rest can be Sonnet or Haiku.

**2. Use Sonnet as the default.** When in doubt, Sonnet is the right choice. It handles 80% of coding tasks well.

**3. Use Haiku for mechanical/repetitive work.** At $0.04–0.08 per session, Haiku teammates are essentially free. Use them liberally for formatting, documentation, and organisation.

**4. Estimate before running.** Use the cost calculator to preview costs:

```bash
python cost-calculator.py --teammates 3 --model sonnet
python cost-calculator.py --compare   # Shows all three models
```

**5. Reduce teammate count before downgrading models.** Three Sonnet teammates is usually better than five Haiku teammates. Fewer teammates means less coordination overhead and better quality per role.

**6. Keep prompts concise.** Every token in the spawn prompt is input tokens multiplied by the number of teammates. A 500-word prompt across 5 teammates is 2,500 words of input — before any work begins.

---

## Example: Cost Breakdown By Preset

### Parallel Code Review (3 teammates)

| Configuration | Security | Performance | Tests | Total |
|---------------|----------|-------------|-------|-------|
| All Opus | $3.00 | $3.00 | $3.00 | **$9.00** |
| Mixed (recommended) | $3.00 (Opus) | $0.60 (Sonnet) | $0.60 (Sonnet) | **$4.20** |
| All Sonnet | $0.60 | $0.60 | $0.60 | **$1.80** |
| All Haiku | $0.06 | $0.06 | $0.06 | **$0.18** |

### Competing Hypotheses (5 teammates)

| Configuration | Per Teammate | Total |
|---------------|-------------|-------|
| All Opus | $3.00 | **$15.00** |
| All Sonnet (recommended) | $0.60 | **$3.00** |
| All Haiku | $0.06 | **$0.30** |

For debugging, Sonnet is the sweet spot. Bug investigation benefits from cross-communication more than raw model capability.

### Cross-Layer Build (3 teammates)

| Configuration | Backend | Frontend | Tests | Total |
|---------------|---------|----------|-------|-------|
| All Opus | $4.00 | $4.00 | $3.00 | **$11.00** |
| All Sonnet (recommended) | $0.80 | $0.80 | $0.60 | **$2.20** |
| Mixed | $0.80 (Sonnet) | $0.80 (Sonnet) | $0.06 (Haiku) | **$1.66** |

For feature builds, Sonnet handles implementation well. Consider Haiku for the test writer only if you have a comprehensive test template.

---

## The Rule of Thumb

```
  Does the role require judgment?     → Opus
  Does the role require competence?   → Sonnet
  Does the role require consistency?  → Haiku
```

When in doubt, start with Sonnet. Upgrade to Opus only for the role where deep reasoning makes a measurable difference. Downgrade to Haiku for anything mechanical.
