### When The AI Framework Layer Disappears…
# …the Prompt Becomes the Application
#### & The Orchestration Layer Collapses into the Model

> "That's either exciting or terrifying depending on whether you build frameworks for a living."

And most people haven't noticed yet.

---

## Some Observation

When I first used **Anthropic's Agent Teams** I kept waiting for the complexity to show up.

Multi-agent orchestration has always meant frameworks — LangGraph state machines, CrewAI agent definitions, AutoGen conversation patterns…

Hundreds of lines of Python before anything useful happens…or building Agentic Workflows via a node/edge GUI…

**Agent Teams is a prompt.**

You paste natural language into Claude Code, and it spawns teammates, manages tasks, handles messaging, and coordinates work.

- No SDK.
- No YAML.
- No workflow engine.

My first reaction was, this feels too simple. Something must be missing.

**Nothing is missing. The complexity moved. It collapsed into the model.**

---

## What A Multi-Agent Framework Actually Does

Every multi-agent framework — CrewAI, LangGraph, AutoGen, Semantic Kernel — handles the same responsibilities:

```
MULTI-AGENT FRAMEWORK RESPONSIBILITIES
=======================================

  Responsibility              Who handles it now?
  ─────────────────────────── ───────────────────
  1. Define agents             Model (from prompt)
  2. Route messages            Model (native)
  3. Manage task lifecycle     Model (native)
  4. Handle dependencies       Model (native)
  5. Spawn/terminate workers   Model (via tooling)
  ─────────────────────────── ───────────────────
  6. Persistence               Framework
  7. Deterministic replay      Framework
  8. Cost control/limits       Framework
  9. Observability/logging     Framework
  10. Error recovery           Framework
  ─────────────────────────── ───────────────────

  Items 1–5: the model absorbed these.
  Items 6–10: frameworks still own these.
```

Items 1 through 5 represent roughly **80% of what developers use** a multi-agent framework for.

The remaining 20% — persistence, determinism, cost control, observability, error recovery — is where frameworks still win. But that 20% matters primarily in production. For developer workflows, prototyping, and one-off tasks, it doesn't.

---

When I wrote about the [5 Levels of AI Agents](https://cobusgreyling.medium.com/5-levels-of-ai-agents-updated-0ddf8931a1c6), the highest levels described autonomous multi-agent coordination. That coordination used to require hundreds of lines of framework code. Now the model does it natively — you describe the team, and orchestration happens.

This isn't a small shift.

---

## The Collapsing Stack

Each generation of models chips away at another layer:

```
THE COLLAPSING STACK
=====================

Era 1 (2023):  Frameworks handle everything
┌──────────────────────────────────┐
│          Application             │
├──────────────────────────────────┤
│     Framework (CrewAI, etc.)     │
├──────────────────────────────────┤
│   Orchestration (routing, tasks, │
│   agents, state, dependencies)   │
├──────────────────────────────────┤
│          Foundation Model        │
└──────────────────────────────────┘

Era 2 (2025):  Orchestration merges into framework
┌──────────────────────────────────┐
│          Application             │
├──────────────────────────────────┤
│  Framework + Orchestration       │
│  (thinner, model does routing)   │
├──────────────────────────────────┤
│          Foundation Model        │
└──────────────────────────────────┘

Era 3 (now):   Orchestration absorbed by model
┌──────────────────────────────────┐
│   Application (prompt + config)  │
├──────────────────────────────────┤
│          Foundation Model        │
└──────────────────────────────────┘
```

- The framework gets thinner.
- Then it merges with orchestration.
- Then both collapse into the model.
- What remains on top is the application — and the application is a prompt.

---

## The Deeper Implication

**If orchestration collapses into the model, the prompt becomes the application.**

This is exactly what I observed with Agent Teams. The [example prompts](examples/) in the repo aren't documentation. They're the equivalent of `main.py`, written in English. When I wrote the [competing hypotheses debugging](examples/competing-hypotheses.md) example, it defines five agents, their responsibilities, communication patterns, and output format — all in a single markdown block.

**That markdown block is the application.**

`CLAUDE.md` files aren't config. They're code. The language shifted from Python to English, and the runtime shifted from a framework to the model itself.

---

## Framework vs Model-Native: Side by Side

The difference in complexity is stark:

```
FRAMEWORK APPROACH (CrewAI)          MODEL-NATIVE APPROACH (Agent Teams)
═══════════════════════════          ═══════════════════════════════════

from crewai import Agent, Task,      Prompt pasted into Claude Code:
    Crew, Process
                                     "Create an agent team to review
security = Agent(                     PR #142. Spawn three reviewers:
  role="Security Reviewer",
  goal="Find vulnerabilities",        - Security: auth flows, injection
  backstory="Senior security...",       vectors, dependency vulns
  llm="claude-sonnet-4-6"            - Performance: N+1 queries,
)                                       caching, algorithmic complexity
                                      - Tests: coverage, edge cases,
performance = Agent(                    error paths
  role="Performance Reviewer",
  goal="Find bottlenecks",            Have them share findings and
  backstory="Performance...",          debate disagreements before
  llm="claude-sonnet-4-6"             the lead synthesises a summary."
)

tests = Agent(
  role="Test Reviewer",
  goal="Verify coverage",
  backstory="QA engineer...",
  llm="claude-sonnet-4-6"
)

review_tasks = [
  Task(description="Review...",
       agent=security),
  Task(description="Profile...",
       agent=performance),
  Task(description="Verify...",
       agent=tests),
]

crew = Crew(
  agents=[security, performance,
          tests],
  tasks=review_tasks,
  process=Process.sequential
)

result = crew.kickoff()

─────────────────────────────        ─────────────────────────────────
~40 lines of Python                  ~10 lines of English
Agent definitions in code            Agent definitions in the prompt
Orchestration in code                Orchestration in the model
Same outcome.                        Same outcome.
```

Both approaches produce three specialist reviewers working on the same PR. One requires a Python environment, dependency management, and framework knowledge. The other requires a text prompt.

---

## What Frameworks Still Own

The remaining 20% is real and it matters — in the right context:

**Persistence.** Agent Teams teammates are ephemeral. They exist for one session. Production agents need state across runs, checkpointing, and replay.

**Determinism.** The same prompt can produce different team structures. Code-defined agents produce the same structure every time.

**Cost Control.** Frameworks can enforce token budgets, model selection per agent, and circuit breakers. With Agent Teams, each teammate is a full Claude instance and costs scale linearly.

**Observability.** Framework-based agents produce structured logs, traces, and metrics. Agent Teams output is terminal text.

**Error Recovery.** When a framework agent fails, you get retry logic, fallbacks, and compensation patterns. When a teammate fails, the lead decides what to do.

> These are production concerns.

---

## In Closing

Each model generation absorbs another piece of the framework's territory.

- A year ago, defining agent roles required code.
- Six months ago, task routing required code.
- Today, the model handles both natively.

The pattern is consistent: capabilities migrate from application code → framework code → model capability.

The model keeps getting better at orchestration until the framework becomes **optional** for most use cases.

**Not all use cases.** Production systems will need the guardrails that frameworks provide for the foreseeable future.

But for the 80% of multi-agent work that is exploratory, interactive, and disposable, **the framework layer has already disappeared.**

---

*Chief Evangelist @ Kore.ai | Passionate about exploring the intersection of AI and language. Language Models, AI Agents, Agentic Apps, Dev Frameworks & Data-Driven Tools shaping tomorrow. Follow me on [LinkedIn](https://www.linkedin.com/in/cobusgreyling).*
