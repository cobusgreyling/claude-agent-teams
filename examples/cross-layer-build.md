# Cross-Layer Feature Build — Frontend, Backend, Tests

## Setup

Enable Agent Teams in your `settings.json`, then paste the prompt below into Claude Code.

## Prompt

```
Create a team with 3 teammates to build the user notification system.
Use Sonnet for each teammate. Require plan approval before they make
any changes.

Teammate 1 — Backend engineer:
- Create API endpoints: POST /notifications, GET /notifications,
  PATCH /notifications/:id/read
- Database migration for notifications table (user_id, type, message,
  read_at, created_at)
- WebSocket event emission on new notification
- Files owned: src/api/notifications/, src/db/migrations/, src/ws/

Teammate 2 — Frontend engineer:
- Notification bell component with unread count badge
- Notification dropdown with mark-as-read
- Real-time updates via WebSocket subscription
- Files owned: src/components/notifications/, src/hooks/, src/stores/

Teammate 3 — Test engineer:
- Integration tests for all API endpoints
- Component tests for notification UI
- WebSocket event tests
- API contract tests ensuring frontend and backend agree on schema
- Files owned: tests/

Each teammate must plan first and share their plan with the others
before implementation begins. The test engineer should review both
plans to ensure testability. Only approve plans that include error
handling for edge cases.

After implementation, the test engineer runs all tests and reports
results to the team.
```

## What Happens

1. The lead spawns 3 teammates, each in plan mode
2. Backend and frontend engineers draft their plans
3. Plans are shared with all teammates via the mailbox
4. The test engineer reviews both plans for testability
5. The lead approves or rejects each plan (with your criteria)
6. Once approved, each teammate implements in their owned files
7. The test engineer writes and runs tests after implementation

## Why This Works

Cross-layer features are where file conflicts hit hardest. By giving each teammate explicit file ownership, you eliminate overwrites. The plan approval step prevents misaligned implementations — if the backend returns a different schema than the frontend expects, the test engineer catches it during plan review, not after hours of wasted implementation.

## Recommended Settings

- **Teammates**: 3 (one per layer)
- **Model**: Sonnet (good balance of speed and capability for implementation)
- **Display mode**: `tmux` (watch all three implement simultaneously)
- **Plan approval**: required (prevents misaligned implementations)
- **File ownership**: strictly enforced via the prompt
