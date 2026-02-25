# Competing Hypotheses Debugging — Adversarial Investigation

## Setup

Enable Agent Teams in your `settings.json`, then paste the prompt below into Claude Code.

## Prompt

```
Users report the app exits after one message instead of staying connected.
This could be a WebSocket issue, a state management bug, a server timeout,
a client-side error handler, or a race condition during initialisation.

Spawn 5 agent teammates to investigate different hypotheses:

1. WebSocket investigator: check connection lifecycle, heartbeat handling,
   and reconnection logic
2. State management investigator: trace state transitions during message
   send/receive and look for premature cleanup
3. Server-side investigator: examine timeout configs, connection pooling,
   and error propagation from backend
4. Client error handling investigator: review error boundaries, catch blocks,
   and graceful degradation paths
5. Race condition investigator: look for async timing issues during startup,
   especially between auth handshake and first message

Have them talk to each other to try to disprove each other's theories,
like a scientific debate. Each investigator should:
- State their hypothesis clearly
- Gather evidence from the codebase
- Challenge at least one other investigator's theory with counter-evidence
- Revise their own theory if disproven

Update a findings doc with whatever consensus emerges. If no consensus,
document the competing theories with evidence strength ratings.
```

## What Happens

1. The lead creates 5 investigation tasks and spawns 5 teammates
2. Each teammate explores their assigned hypothesis
3. As evidence accumulates, teammates message each other with findings
4. Teammates actively challenge each other's theories
5. Weak theories get eliminated through cross-examination
6. The surviving theory (or theories) get documented with evidence

## Why This Works

Sequential investigation suffers from anchoring. Once one theory is explored, everything after is biased toward confirming it. With five independent investigators actively trying to disprove each other, the theory that survives cross-examination is far more likely to be the actual root cause.

This mirrors how scientific peer review works — not just finding evidence for your theory, but actively trying to break it.

## Recommended Settings

- **Teammates**: 5 (one per hypothesis)
- **Display mode**: `in-process` (easier to follow the debate by cycling through)
- **Plan approval**: not needed (investigation is read-only)
- **Expected token usage**: high (5 teammates with cross-communication)
