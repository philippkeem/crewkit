# Babysit-PR Monitoring Protocol

## Overview

Babysit-PR watches a pull request from creation through merge, handling CI
failures, flaky tests, and merge conditions automatically. The goal is
zero-touch PR management after the initial review approval.

## CI Check Polling

### Polling Strategy
```
Interval: 30 seconds for first 5 minutes, then 60 seconds
Timeout: 30 minutes (configurable per repo)
Max polls: 60
```

### Check States
```
pending    → CI hasn't started yet (wait)
queued     → CI is queued (wait)
in_progress → CI is running (wait)
success    → All checks passed (proceed to merge)
failure    → A check failed (diagnose)
cancelled  → CI was cancelled (retry once)
```

### Polling Implementation
```bash
# Poll PR check status
gh pr checks <PR_NUMBER> --watch

# Or manual polling with status check
STATUS=$(gh pr checks <PR_NUMBER> --json state --jq '.[].state' | sort -u)
case "$STATUS" in
  *FAILURE*) echo "FAILED" ;;
  *PENDING*|*QUEUED*) echo "WAITING" ;;
  *) echo "PASSED" ;;
esac
```

## Flaky Test Detection

A test is likely flaky if:
1. It passed on the previous commit but fails on this one (with no relevant changes)
2. It fails intermittently across multiple runs
3. It's a known flaky test in the repo's flaky test list

### Detection Heuristic
```
1. CI fails
2. Check which tests failed
3. Compare failed tests to changed files
   - If failed test has NO relation to changed files → likely flaky
   - If failed test is in the changed files → likely real failure
4. Check CI history for the same test
   - Failed 2+ times in last 10 runs on main → confirmed flaky
```

### Flaky Test Response
```
If confirmed flaky:
  1. Log the flaky test name and failure details
  2. Retry CI (max 2 retries for flaky tests)
  3. If passes on retry → proceed with merge
  4. If fails 3 times → escalate to human

If not flaky (real failure):
  1. Report the failure to the PR author
  2. Do NOT retry
  3. Wait for a fix commit
```

## Retry Strategy

| Failure Type | Max Retries | Backoff | Action After Max |
|-------------|------------|---------|------------------|
| Flaky test | 2 | None (immediate) | Escalate to human |
| CI infra failure | 3 | 60s between retries | Escalate to human |
| Build failure | 0 | — | Report error, wait for fix |
| Lint/format failure | 0 | — | Report error, wait for fix |
| Timeout | 1 | — | Escalate if second timeout |

### Retry Implementation
```bash
# Re-run failed CI checks
gh run rerun <RUN_ID> --failed

# Or re-trigger by pushing an empty commit (last resort)
git commit --allow-empty -m "ci: retry"
git push
```

## Auto-Merge Conditions

ALL conditions must be true before auto-merge:

```
[ ] All required CI checks pass
[ ] At least one approving review
[ ] No "changes requested" reviews pending
[ ] No merge conflicts with base branch
[ ] Branch is up-to-date with base (or repo allows merge behind)
[ ] No "do not merge" label
[ ] PR is not in draft state
```

### Merge Method Selection
```
Repository default  → Use whatever the repo is configured for
Squash preferred    → Multiple small commits → squash into one
Merge commit        → Clean history with meaningful commits
Rebase              → Linear history, each commit stands alone
```

### Auto-Merge Implementation
```bash
# Enable auto-merge (GitHub will merge when conditions are met)
gh pr merge <PR_NUMBER> --auto --squash

# Or merge immediately if all conditions met
gh pr merge <PR_NUMBER> --squash --delete-branch
```

## Timeout Handling

| Phase | Timeout | Action |
|-------|---------|--------|
| CI queued | 10 min | Log warning, continue waiting |
| CI running | 30 min | Cancel and retry once |
| Waiting for review | 24 hours | Send reminder comment |
| Merge conflicts | Immediate | Attempt rebase, notify if fails |
| Total babysit time | 2 hours | Escalate to human |

### Timeout Response
```
1. Log timeout event with context
2. Post comment on PR: "CI timed out after {duration}. Retrying."
3. Retry once
4. If second timeout: "CI timed out twice. Manual intervention needed."
5. Tag the PR author and team lead
```

## Full Babysit Lifecycle

```
1. PR created/approved → Start babysit
2. Poll CI status every 30-60s
3. On CI pass → Check merge conditions → Merge
4. On CI fail → Diagnose (flaky vs real)
   4a. Flaky → Retry (max 2x)
   4b. Real failure → Notify author, pause babysit
   4c. Author pushes fix → Resume from step 2
5. On merge conflict → Attempt auto-rebase
   5a. Rebase succeeds → Resume from step 2
   5b. Rebase fails → Notify author, pause babysit
6. On merge → Delete branch, post summary comment
7. On timeout → Escalate to human
```

## Common Mistakes

- Retrying real failures (wastes CI time and delays the fix)
- Not checking for merge conflicts before attempting merge
- Merging without re-checking review status (review could be dismissed)
- Infinite retry loops (always cap retries)
- Not deleting the branch after merge (causes branch clutter)
