# Case Study: Debugging a WebSocket Disconnect With Agent Teams

## The Problem

Users of a real-time chat application started reporting that the app would disconnect after sending exactly one message. The connection would establish fine — the UI showed "Connected" — but the moment a user typed and sent their first message, the socket would close and the app would show "Connection lost."

The bug only appeared in production. Local development worked perfectly. The team's initial investigation by a single developer spent 90 minutes tracing the WebSocket lifecycle before running out of ideas after the first plausible theory (a misconfigured heartbeat interval) didn't pan out.

We decided to try Agent Teams with the competing hypotheses pattern.

---

## The Team

We spawned 5 investigators, each assigned a different theory:

```
Spawn 5 agent teammates to investigate why the chat app disconnects
after one message. Have them talk to each other to disprove each
other's theories.

1. WebSocket investigator: connection lifecycle, heartbeat, reconnection
2. State management investigator: state transitions during send/receive
3. Server investigator: timeout configs, connection pooling, error propagation
4. Error handling investigator: catch blocks, error boundaries, exit paths
5. Race condition investigator: async timing between auth and first message
```

Display mode: in-process. No plan approval needed — this is read-only investigation.

---

## The Investigation

### Round 1: Initial Findings (first 3 minutes)

Each investigator explored their assigned area independently.

**WebSocket investigator:**

> I found the heartbeat configuration in `src/ws/config.ts`. The `pingInterval` is set to `0` in production but `30000` in development. A ping interval of 0 means the server sends no heartbeats. Without heartbeats, the connection might be considered stale by a load balancer or proxy. This could explain the disconnect.

**State management investigator:**

> Traced the state machine in `src/stores/connection.ts`. After the first message is sent, the state transitions from `CONNECTED` to `SENDING`, then back to `CONNECTED`. But I see a `cleanup()` call in the `SENDING` state exit handler that looks suspicious — it calls `socket.removeAllListeners()`. This could strip the message handler before the response arrives.

**Server investigator:**

> The connection pool in `src/server/pool.ts` has `maxConnections: 1` in the production config. But this is per-user, not global. Each user gets one connection. When a second connection attempt happens (e.g., a message triggers a reconnect), the first connection is forcibly closed. This could explain the disconnect.

**Error handling investigator:**

> Found a critical issue in `src/ws/handlers/message.ts`. The message handler has a try/catch block that catches JSON parse errors. But the catch block calls `process.exit(1)` instead of handling the error gracefully. If any incoming message fails to parse — including the auth token wrapper — the entire server process exits.

**Race condition investigator:**

> The auth handshake in `src/auth/handshake.ts` is async. The client sends the first message before waiting for the auth response. The server receives the message, tries to verify the auth token, and the token isn't in the session store yet because the handshake hasn't completed. This causes an auth failure which triggers... something. Need to trace what happens on auth failure.

---

### Round 2: Cross-Examination (minutes 3–6)

This is where it got interesting. Teammates started challenging each other.

**WebSocket investigator to Error handling investigator:**

> Wait — `process.exit(1)` in a message handler? That would kill the entire server, not just one connection. If this were the issue, ALL users would disconnect simultaneously, not just the one who sent a message. Can you check the deployment logs for server restarts?

**Error handling investigator to WebSocket investigator:**

> Good point about multiple users. But I checked the production deployment — it's running in a containerized environment with auto-restart. The container restarts in ~2 seconds, so from the user's perspective, it looks like their individual connection dropped. Other users would also disconnect but might attribute it to a brief "hiccup." Let me check if the error logs show restart events correlated with user message timestamps.

**Race condition investigator to State management investigator:**

> Your `cleanup()` theory doesn't hold. I traced the exact execution order. The `SENDING` state exit handler fires AFTER the message is acknowledged by the server. The disconnect happens BEFORE any acknowledgment. The timing doesn't match.

**State management investigator:**

> You're right. I retraced the flow. The cleanup happens too late to cause the initial disconnect. Withdrawing this hypothesis.

**Server investigator to Error handling investigator:**

> The connection pool maxing at 1 is a red herring. I checked — the pool is per-user and is working correctly. No duplicate connections. But your `process.exit` theory is interesting. Can you trace what triggers the JSON parse error? The first message should be valid JSON.

---

### Round 3: Convergence (minutes 6–9)

**Error handling investigator:**

> Found it. The JSON parse error is NOT from the user's chat message. Here's the execution path:
>
> 1. Client connects via WebSocket
> 2. Server sends an auth challenge (a JWT token wrapped in a custom envelope)
> 3. Client sends first chat message
> 4. Server's message handler receives the message
> 5. The handler tries to parse it, but the FIRST thing it does is check for the auth token envelope
> 6. The auth token uses a non-standard wrapper: `{auth: "token...", payload: {message: "hello"}}`
> 7. The parser expects `JSON.parse()` to work on the inner `auth` field — but in production, the auth service returns the token as a raw string, not JSON
> 8. `JSON.parse("eyJhbG...")` throws a SyntaxError
> 9. The catch block calls `process.exit(1)`

**Race condition investigator:**

> This connects to my finding. The auth handshake hasn't completed when the first message arrives. The server tries to extract auth from the message payload instead of the session. The raw JWT string isn't valid JSON. Parse error. Exit.

**WebSocket investigator:**

> My heartbeat theory is dead. The heartbeat interval of 0 is a separate issue (and should be fixed) but it's not the cause of this bug. The disconnect happens within milliseconds of the first message — long before any heartbeat timeout.

---

## The Root Cause

A try/catch in `src/ws/handlers/message.ts` catches a JSON parse error on the auth token (which is a raw JWT string in production, not a JSON object) and calls `process.exit(1)` instead of handling the error gracefully.

The fix:

```javascript
// BEFORE (broken)
try {
    const auth = JSON.parse(envelope.auth);
    // ...
} catch (e) {
    process.exit(1);  // Kills the entire server
}

// AFTER (fixed)
try {
    const auth = typeof envelope.auth === 'string'
        ? { token: envelope.auth }
        : JSON.parse(envelope.auth);
    // ...
} catch (e) {
    socket.send(JSON.stringify({ error: 'auth_failed', message: 'Invalid auth format' }));
    socket.close(4001, 'Authentication error');
}
```

Additionally:
- The heartbeat interval of 0 was fixed to 30000 in production config
- The auth handshake was updated to complete before allowing message sends

---

## What The Team Approach Got Right

1. **No anchoring bias.** A single developer spent 90 minutes chasing the heartbeat theory. Five independent investigators found five different leads simultaneously. The strongest theory survived cross-examination.

2. **The root cause was non-obvious.** The `process.exit(1)` in a message handler was the kind of thing you only find if you're specifically looking for error handling issues. A general investigation would have focused on the WebSocket lifecycle or state management — the more "logical" suspects.

3. **Cross-examination killed weak theories fast.** The state management theory was disproven in under a minute by the race condition investigator. In a single-agent session, that theory might have consumed 15-20 minutes of investigation before being abandoned.

4. **The race condition and error handling investigators converged.** Neither had the full picture alone. The race condition investigator knew the auth handshake was incomplete. The error handling investigator knew the parse error triggered an exit. Together, they traced the complete execution path.

---

## What Would Have Been Different With A Single Agent

A single agent would have investigated sequentially. Based on the keyword "disconnect," it likely would have started with the WebSocket lifecycle — the same path the human developer took. It might have found the heartbeat issue (a real problem, but not the cause), spent time on it, and either fixed it (masking the real bug) or moved on.

The `process.exit(1)` in a catch block is the kind of thing that only surfaces when someone is specifically assigned to "look at error handling paths." In a sequential investigation, error handling is usually the last thing checked, not the first.

The five-investigator approach found the root cause in 9 minutes. The single-agent approach would likely have taken 30-60 minutes, if it found it at all.

---

## Cost

- 5 teammates on Sonnet for ~9 minutes of active investigation
- Estimated: ~150K total tokens across all teammates
- Estimated cost: ~$1.80
- Time saved vs. manual debugging: at least 80 minutes

The $1.80 is cheaper than 80 minutes of developer time by any measure.
