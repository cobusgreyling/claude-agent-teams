# Agent Teams Anti-Patterns

Common mistakes when using Claude Agent Teams and how to avoid them.

---

## 1. Over-Specialization

**The mistake:** Spawning 8 teammates when 3 would do. A teammate for "read the
config file," another for "parse the JSON," another for "validate the schema."

**Why it fails:** Coordination overhead exceeds the benefit. Each teammate costs
tokens to spawn, context to share, and time to synchronize. With too many agents,
you spend more time orchestrating than executing.

**The rule:** If a task takes less than 5 minutes to do solo, do not parallelize it.
Agent Teams shine when tasks are genuinely independent and each requires substantial
work. Three teammates working for 10 minutes each will outperform eight teammates
that spend 7 minutes coordinating and 3 minutes working.

**Fix:** Before spawning, ask: "Would I assign this to a separate engineer on a
real team?" If the answer is no, keep it in-scope for an existing teammate.

---

## 2. Under-Communication

**The mistake:** Teammates work in complete isolation. Teammate A discovers that
the database schema has an undocumented constraint, but never tells Teammate B
who is writing queries against that table.

**Why it fails:** Duplicated investigation, conflicting assumptions, and wasted
tokens. One teammate's discovery could save another 5 minutes of debugging.

**Fix:** Explicitly instruct teammates to share discoveries with the group:

```
In your prompt, add:
"Whenever you discover something unexpected about the codebase — a constraint,
a convention, a bug — immediately share it with all teammates via the mailbox.
Do not assume others already know."
```

---

## 3. File Ownership Conflicts

**The mistake:** Two teammates edit the same file concurrently. Teammate A adds
a new function to `utils.ts` while Teammate B refactors an existing function in
the same file. One overwrites the other's changes.

**Why it fails:** Agent Teams do not have built-in merge conflict resolution.
The last write wins, and the first teammate's work is silently lost.

**Fix:** Specify file ownership explicitly in the prompt:

```
- Teammate A owns: src/api/**
- Teammate B owns: src/core/**
- Shared files (src/shared/types.ts): only Teammate A may edit. Teammate B
  proposes changes via mailbox; Teammate A applies them.
```

**Conflict recovery example:** If a conflict does happen:
1. Stop both teammates.
2. Read the file to see which version survived.
3. Check git diff or the mailbox for the lost changes.
4. Assign ONE teammate to manually merge both sets of changes.
5. Resume with clearer ownership boundaries.

---

## 4. Token Explosion

**The mistake:** Using Opus for every teammate regardless of task complexity.
A teammate doing simple file reads and lint fixes runs on the same expensive
model as a teammate doing complex architectural reasoning.

**Why it fails:** Cost scales linearly with the number of teammates and the
model tier. An 8-agent Opus session can burn through budget in minutes while
a mixed-model approach achieves the same results for a fraction of the cost.

**Fix:** Match model to task complexity:

| Task Type | Recommended Model |
|---|---|
| File reads, lint fixes, formatting | Haiku |
| Standard implementation, test writing | Sonnet |
| Architecture decisions, complex debugging | Opus |

Reference the model selection guide in your lead prompt:
```
"Spawn teammates with the appropriate model:
- Use haiku for simple, mechanical tasks.
- Use sonnet for standard implementation work.
- Use opus only for tasks requiring deep reasoning or architectural judgment."
```

---

## 5. Premature Consensus

**The mistake:** Teammates agree on a root cause or approach too quickly without
challenging each other. The first plausible theory gets accepted by everyone.

**Why it fails:** The first theory is often wrong or incomplete. Without adversarial
pressure, the team converges on a local optimum and misses the real issue.

**Fix:** Require adversarial structure in the prompt:

```
"Before the team can declare a root cause or finalize an approach, each teammate
must attempt to disprove at least one other teammate's theory. If you cannot
disprove it, explain specifically what evidence would be needed to disprove it.
Only when no teammate can produce a counter-example may the team converge."
```

For debugging sessions, assign at least one teammate the explicit role of
devil's advocate who must argue against the majority position.

---

## 6. Scope Creep

**The mistake:** A teammate assigned to "implement the /users endpoint" also
refactors the authentication middleware, updates the database connection pool
config, and adds a logging utility — because they "noticed it could be better."

**Why it fails:** Unplanned changes create unexpected interactions with other
teammates' work. The refactored middleware might break Teammate B's auth tests.
The logging utility might conflict with Teammate C's observability work.

**Fix:** Add hard constraints to the prompt:

```
"You ONLY touch files in src/api/users/. If you encounter issues in other
directories, report them via the mailbox but do NOT modify those files.
Any change outside your assigned scope will be reverted."
```

For implementation tasks, the lead should review the teammate's plan before
they begin coding to catch scope expansion early.

---

## 7. Missing Plan Gate

**The mistake:** Teammates jump straight into implementation without getting
their plan approved. Teammate A starts writing code based on their own
interpretation of the requirements, which conflicts with the lead's intent.

**Why it fails:** Implementation without alignment leads to rework. A teammate
might build an entire module the wrong way, wasting all the tokens spent on
that work. Catching a wrong approach at the plan stage costs 50 tokens;
catching it after implementation costs 5000.

**Fix:** Always require plan mode for implementation tasks:

```
"Before writing any code, present your implementation plan:
1. Which files you will create or modify.
2. The key functions/types you will define.
3. How your work connects to other teammates' output.
4. What tests you will write.

Wait for my approval before proceeding. If I request changes to the plan,
revise and resubmit. Do NOT start coding until you receive explicit approval."
```

This gate is especially critical for multi-teammate sessions where parallel
implementation without aligned plans leads to integration failures.
