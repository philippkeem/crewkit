# Debug Mode — Detailed Guide

## When to Use Debug Mode

Activate when investigating a bug, unexpected behavior, or system failure. The goal
is to find the root cause, not just make the symptom disappear.

## Investigation Workflow

```
1. Reproduce the problem (or confirm it's reproducible)
2. Gather evidence (logs, errors, stack traces)
3. Form hypotheses (rank by likelihood)
4. Test hypotheses (one at a time, cheapest first)
5. Confirm root cause (explain WHY, not just WHERE)
6. Plan fix (minimal change that addresses the cause)
```

## 5 Whys Template

Start with the observed symptom and ask "why" until you reach a systemic cause:

```
Problem: Users see a blank dashboard after login.

Why 1: The dashboard API returns an empty array.
Why 2: The database query filters by org_id, but org_id is null.
Why 3: The user record has no org_id set.
Why 4: The signup flow skips org assignment for SSO users.
Why 5: The SSO callback handler was added after the org assignment
        logic and nobody updated the flow.

Root cause: SSO signup path bypasses org assignment.
Fix: Add org assignment step to SSO callback handler.
```

Stop when you reach a cause that is:
- Actionable (you can write code to fix it)
- Systemic (it explains all observed symptoms)
- Not a tautology ("it's broken because it doesn't work")

## Hypothesis Ranking

List all plausible explanations and rank them:

| # | Hypothesis | Likelihood | Evidence For | Evidence Against | Test |
|---|-----------|-----------|-------------|-----------------|------|
| 1 | Null org_id for SSO users | High | Only SSO users affected | — | Query DB for SSO users with null org_id |
| 2 | API caching stale data | Medium | Started after deploy | Other endpoints work fine | Clear cache and retry |
| 3 | Frontend rendering bug | Low | — | API confirmed empty response | Check network tab in browser |

### Ranking Rules
- Start with the most likely hypothesis
- Test the cheapest/fastest hypothesis first when likelihoods are close
- Eliminate hypotheses; don't just confirm your favorite
- If top 3 hypotheses are all disproven, step back and re-examine evidence

## Evidence Collection Patterns

### Log Analysis
```bash
# Find errors around the time of the incident
grep -i "error\|exception\|fatal" app.log | tail -50

# Correlate by request ID
grep "req-abc123" app.log

# Look for patterns in timing
grep "2024-01-15T14:3" app.log | grep "dashboard"
```

### Database Investigation
```sql
-- Check for the suspected null org_id
SELECT id, email, org_id, created_at, auth_provider
FROM users
WHERE org_id IS NULL
ORDER BY created_at DESC
LIMIT 20;

-- Compare SSO vs password users
SELECT auth_provider, COUNT(*), COUNT(org_id)
FROM users
GROUP BY auth_provider;
```

### Network/API Investigation
```bash
# Replay the failing request
curl -v -H "Authorization: Bearer $TOKEN" \
  https://api.example.com/dashboard

# Check response headers for caching
curl -I https://api.example.com/dashboard
```

## Common Root Cause Categories

| Category | Examples | Typical Fix |
|----------|----------|-------------|
| **Missing null check** | Undefined property access, null ref | Add guard clause or validation |
| **Race condition** | Intermittent failures, order-dependent | Add locking, retry, or sequencing |
| **State inconsistency** | DB says X, cache says Y | Fix write path, add cache invalidation |
| **Boundary mismatch** | Off-by-one, timezone, encoding | Fix the boundary math, add test |
| **Missing code path** | New feature skips existing logic | Add the missing step to the new path |
| **Config/environment** | Works locally, fails in prod | Diff configs, check env vars |
| **Dependency change** | Broke after upgrade | Check changelog, pin version or adapt |

## Documenting the Investigation

When you find the root cause, record:

```markdown
## Bug: <title>
Symptom: <what the user sees>
Root cause: <why it happens>
Evidence: <what confirmed it>
Fix: <what code change resolves it>
Prevention: <what would catch this earlier next time>
```

## Common Mistakes

- Fixing the symptom without understanding the cause
- Testing multiple hypotheses at once (can't tell which one worked)
- Ignoring intermittent failures ("it works now, ship it")
- Not reproducing the bug before attempting a fix
- Skipping the prevention step (same bug will return in a different form)
