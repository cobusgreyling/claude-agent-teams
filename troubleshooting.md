# Agent Teams Troubleshooting Guide

A practical reference for diagnosing and fixing common Agent Teams issues. Each entry follows the format: **Problem**, **Cause**, **Solution**.

---

## 1. "My teammates keep editing the same file"

**Cause:** No file ownership was specified in the team prompt, so multiple teammates independently decide to modify the same file, causing conflicts and lost work.

**Solution:** Add explicit file ownership to your prompt.

**Before:**
```
Spawn 3 teammates:
1. Frontend developer: build the login page
2. Backend developer: build the auth API
3. Stylist: make everything look good
```

**After:**
```
Spawn 3 teammates:
1. Frontend developer: build the login page. You OWN src/pages/Login.tsx and src/hooks/useAuth.ts. Do not edit any other files.
2. Backend developer: build the auth API. You OWN src/api/auth.ts and src/middleware/auth.ts. Do not edit any other files.
3. Stylist: make everything look good. You OWN src/styles/ and tailwind.config.js. Do not edit any other files.
```

---

## 2. "A teammate got stuck in a loop"

**Cause:** The teammate received an ambiguous task description or has a circular dependency (e.g., teammate A waits for teammate B, who waits for teammate A).

**Solution:** Message the stuck teammate directly using **Shift+Down** to select them, then give explicit, concrete direction to break the cycle.

**Example message to a stuck teammate:**
```
Stop what you are doing. Here is exactly what I need:
1. Read the file src/utils/parser.ts
2. Add a function called parseCSV that accepts a string and returns an array of objects
3. Write a test in src/utils/parser.test.ts
4. Report back when done
Do not wait for any other teammate.
```

---

## 3. "Tests are failing and I can't tell which teammate broke them"

**Cause:** Multiple teammates are editing code without running tests after each change, making it impossible to attribute failures.

**Solution:** Use the `TaskCompleted` hook to automatically run tests whenever a teammate finishes their task. Configure this in your project's `hooks/` directory.

**Example hook (hooks/TaskCompleted.sh):**
```bash
#!/bin/bash
echo "Running tests after teammate completed task..."
npm test 2>&1 | tail -20
if [ $? -ne 0 ]; then
  echo "TESTS FAILED after teammate completed their task."
  echo "Review the above output to identify the breaking change."
fi
```

This ensures every teammate's work is validated immediately, so you know exactly who introduced a failure.

---

## 4. "My team took way longer than expected"

**Cause:** Too many teammates were spawned, or teammates are sending excessive cross-communication messages, creating coordination overhead that outweighs the parallelism benefits.

**Solution:** Reduce your team to 3-5 teammates and limit message instructions. Each additional teammate adds coordination cost.

**Rules of thumb:**
- 2-3 teammates: minimal overhead, nearly linear speedup
- 4-5 teammates: moderate overhead, still net positive
- 6+ teammates: coordination cost often exceeds time saved

**Limit cross-talk by adding this to your prompt:**
```
IMPORTANT: Do not message other teammates unless you are blocked.
When you finish your task, report directly to the lead only.
Keep all status messages under 50 words.
```

---

## 5. "A teammate finished early and went idle"

**Cause:** Uneven task distribution left one teammate with significantly less work than the others.

**Solution:** Use the `TeammateIdle` hook to detect when a teammate finishes early and reassign them. Configure this in your project's `hooks/` directory.

**Example hook (hooks/TeammateIdle.sh):**
```bash
#!/bin/bash
echo "Teammate $TEAMMATE_NAME is idle."
echo "Checking for unfinished tasks to reassign..."
```

**Alternatively, plan for it in your prompt:**
```
If you finish your primary task early, pick up one of these stretch tasks:
- Add JSDoc comments to any exported functions
- Look for TODO comments and address them
- Write additional edge-case tests
```

---

## 6. "Teammates are repeating each other's work"

**Cause:** Overlapping task definitions in the prompt allow multiple teammates to interpret their scope as covering the same work.

**Solution:** Make tasks mutually exclusive. Each teammate's scope should have zero overlap with any other teammate.

**Before (overlapping):**
```
1. Frontend dev: build the user dashboard with API integration
2. API dev: build the API and connect it to the frontend
```
Both teammates think they own the integration layer.

**After (mutually exclusive):**
```
1. Frontend dev: build the user dashboard UI. Use placeholder data from src/mocks/dashboard.json. Do NOT write any API calls.
2. API dev: build the REST endpoints and write the API client in src/api/dashboard.ts. Do NOT modify any React components.
```

Add a boundary statement to each teammate's instructions:
```
Your scope ends at [boundary]. Anything beyond that belongs to another teammate.
```

---

## 7. "The lead's context window is full"

**Cause:** Teammates are sending verbose reports back to the lead, consuming the lead's context window with unnecessary detail.

**Solution:** Instruct teammates to summarize their findings concisely. Add this constraint to your prompt:

```
REPORTING RULES FOR ALL TEAMMATES:
- When reporting back to the lead, summarize your findings in under 100 words.
- Use bullet points, not paragraphs.
- Only include: what you did, what you found, and what needs attention.
- Do NOT paste full file contents or complete code listings.
- If the lead needs details, they will ask.
```

If you are already hitting context limits, consider writing findings to a shared file instead:
```
Write your findings to FINDINGS.md under a section with your role name.
Do not send findings as a message.
```

---

## 8. "I can't resume a team session"

**Cause:** There is no fix for this. Agent Teams sessions are **ephemeral by design**. Once you close the session, the team state is gone. This is an intentional design choice, not a bug.

**Workaround:** Before ending any team session, instruct the lead to save all findings and progress to a file:

```
Before wrapping up:
1. Compile all teammate findings into TEAM_OUTPUT.md
2. Include a "Next Steps" section listing any unfinished work
3. Include a "Decisions Made" section so the next session has context
```

You can then start a new session and point it at the saved file:
```
claude -p "Read TEAM_OUTPUT.md for context from a previous session. Continue from where the team left off."
```

---

## 9. "Split panes aren't showing"

**Cause:** Agent Teams relies on tmux or iTerm2 for split-pane rendering. If neither is detected, panes will not appear.

**Solution:**

1. **Verify tmux is installed:**
   ```bash
   which tmux
   # If not found:
   brew install tmux   # macOS
   sudo apt install tmux  # Ubuntu/Debian
   ```

2. **If you cannot install tmux**, use in-process mode:
   ```bash
   claude --teammate-mode in-process
   ```
   This runs all teammates in the same process without visual pane splitting. You lose the visual separation but retain all functionality.

3. **If using iTerm2**, make sure you are running version 3.5 or later and that the "Allow tmux integration" setting is enabled under Preferences > General > tmux.

---

## 10. "A teammate crashed mid-task"

**Cause:** The teammate hit an API error (rate limit, server error) or exceeded its context window, causing it to terminate unexpectedly.

**Solution:** The lead agent should detect the failure and reassign the task to a new or existing teammate.

**Example message from the lead to reassign:**
```
@remaining-teammate: Teammate "security-reviewer" crashed before completing their task.
Their assignment was: review src/api/ for injection vulnerabilities and auth bypass issues.
They had partially completed: they reviewed src/api/users.ts (see their notes in FINDINGS.md).
Please pick up where they left off. Start with src/api/payments.ts and src/api/admin.ts.
Report findings in the same format.
```

**To reduce crash likelihood:**
- Keep individual teammate tasks scoped to fewer than 10 files
- Avoid giving teammates tasks that require reading very large files
- If a teammate is working with a large codebase, tell them to use targeted searches rather than reading entire directories
