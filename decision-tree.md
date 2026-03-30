# Should I Use Agent Teams?

A decision tree and comparison matrix to help you pick the right approach for your task.

---

## Decision Tree

```
Should I Use Agent Teams?

Start here:
  |
  v
Is this a one-off task or a recurring pipeline?
  |
  |-- One-off ----------> Continue below
  |
  +-- Recurring --------> Use a code framework (LangGraph, CrewAI)
                           Reason: you need persistence, determinism, versioning

  |
  v
Does the task require parallel work from different perspectives?
  |
  |-- Yes --------------> Continue below
  |
  +-- No ---------------> Use a single Claude Code session
                           Reason: coordination overhead isn't worth it
                           for linear tasks

  |
  v
How many distinct roles are needed?
  |
  |-- 2-5 --------------> Agent Teams is ideal
  |
  +-- 6+ ---------------> Consider splitting into phases
                           Reason: coordination overhead grows
                           quadratically with team size

  |
  v
Do teammates need to edit the same files?
  |
  |-- Yes --------------> Restructure: assign file ownership per teammate
  |                        OR use sequential phases (plan first,
  |                        implement second)
  |
  +-- No ---------------> Agent Teams is a great fit
```

---

## Comparison Matrix

| Criteria | Single Agent | Agent Teams | Code Framework |
|---|---|---|---|
| Setup time | 0 | 30 seconds | Hours to days |
| Parallel work | No | Yes | Yes |
| Cross-communication | N/A | Native | Framework-dependent |
| Persistence | Session only | Session only | Across runs |
| Reproducibility | Prompt-dependent | Prompt-dependent | Deterministic |
| Cost control | Manual | Per-teammate estimate | Built-in budgets |
| Best for | Simple tasks | Complex one-offs | Production pipelines |

---

## When to Use Each

### Single Agent
- Bug fixes in a single file
- Writing a function or script
- Answering questions about a codebase
- Quick refactors with a clear scope

### Agent Teams
- Full-feature implementation spanning frontend, backend, and tests
- Code review from multiple perspectives (security, performance, correctness)
- Migrating a codebase where different areas can be handled independently
- Exploratory analysis where different teammates investigate different hypotheses

### Code Framework (LangGraph, CrewAI, etc.)
- Production CI/CD pipelines that run on every commit
- Customer-facing agent workflows that must be reliable and reproducible
- Multi-step processes that need persistence across sessions
- Systems where you need deterministic control flow and error handling
