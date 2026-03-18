# Incident Report (Post-Mortem) Template

## How to Use

Fill in each section after an incident is resolved. The goal is to learn and
prevent recurrence, not to assign blame. Complete within 48 hours of resolution.

---

## Incident Report: [TITLE]

**Date**: YYYY-MM-DD
**Severity**: SEV-1 / SEV-2 / SEV-3 / SEV-4
**Duration**: HH:MM (from detection to resolution)
**Author**: [Name]
**Status**: Draft / Final

---

## Incident Summary

One paragraph describing what happened, what was impacted, and how it was resolved.

> Example: On 2025-03-15 at 14:00 UTC, the orders API began returning 503 errors
> for all users. The root cause was a database connection pool exhaustion caused
> by a connection leak in the new bulk-export feature deployed at 13:45 UTC.
> The incident was resolved by rolling back to the previous release at 14:20 UTC.
> Approximately 1,200 orders failed during the 35-minute window.

---

## Severity Definitions

| Level | Definition |
|-------|-----------|
| SEV-1 | Complete outage, all users affected, data loss possible |
| SEV-2 | Major feature unavailable, significant user impact |
| SEV-3 | Partial degradation, some users affected |
| SEV-4 | Minor issue, minimal user impact |

---

## Timeline

All times in UTC.

```
13:45  [deploy]   v2.5.0 deployed to production (includes bulk-export feature)
14:00  [monitor]  5xx error rate crosses 5% threshold
14:02  [alert]    PagerDuty alert: "High error rate on orders-api"
14:05  [human]    On-call engineer acknowledges alert
14:08  [human]    Identifies "connection pool exhausted" in error logs
14:10  [human]    Checks recent deployments — v2.5.0 deployed 25 min ago
14:12  [human]    Decides to rollback
14:15  [deploy]   Rollback to v2.4.9 initiated
14:20  [monitor]  Error rate returns to normal
14:25  [human]    Confirms all health checks passing, declares resolved
```

---

## Root Cause

Explain the technical root cause. Be specific about what code, config, or
infrastructure caused the failure.

> The bulk-export endpoint opened a new database connection for each row being
> exported but never closed it. Under normal load, the connection pool (max 100)
> was exhausted within 15 minutes of the first bulk export request. Once
> exhausted, all other API endpoints that needed a database connection received
> "connection pool exhausted" errors.

---

## Impact

| Metric | Value |
|--------|-------|
| Duration | 35 minutes |
| Users affected | All users (~5,000 active) |
| Failed requests | ~1,200 order submissions |
| Revenue impact | ~$18,000 in delayed orders (all recovered) |
| Data loss | None |

---

## Detection

How was the incident detected? How long from start to detection?

> Detected by automated monitoring 15 minutes after deployment. The 5xx rate
> alert fired at 5% threshold. Detection could have been faster with a
> connection pool utilization alert (would have fired at 80% capacity,
> approximately 5 minutes earlier).

---

## Response

What actions were taken and in what order?

1. On-call acknowledged alert (3 min after alert)
2. Checked error logs — identified connection pool errors
3. Correlated with recent deployment
4. Decided to rollback (faster than debugging in production)
5. Executed rollback via deployment pipeline
6. Monitored recovery for 5 minutes
7. Declared incident resolved

---

## Remediation

### Immediate (completed)
- [x] Rolled back to v2.4.9
- [x] Notified affected users about delayed order processing

### Short-term (this week)
- [ ] Fix connection leak in bulk-export code
- [ ] Add unit test for connection cleanup
- [ ] Add connection pool utilization alert (warn at 80%, critical at 90%)

### Long-term (this quarter)
- [ ] Add connection pool metrics to standard dashboard
- [ ] Implement connection leak detection in integration tests
- [ ] Review all database connection patterns for similar issues

---

## Prevention

What would prevent this class of incident from happening again?

| Prevention Measure | Effort | Impact |
|-------------------|--------|--------|
| Linter rule for unclosed connections | Small | Catches at code review |
| Integration test with connection tracking | Medium | Catches in CI |
| Connection pool alerts | Small | Catches in staging/production |
| Load test before deploy | Large | Catches under realistic conditions |

---

## Lessons Learned

### What went well
- Alert fired within 15 minutes
- Rollback was fast (5 minutes from decision to recovery)
- On-call had clear runbook for rollback procedure

### What could be improved
- No alert on connection pool utilization (only on 5xx rate)
- Bulk-export feature was not load-tested before deploy
- No canary deployment — went straight to 100% traffic

### Surprising or unexpected
- A single bulk-export request (100k rows) was enough to exhaust the pool
- The connection leak only manifests under bulk operations, not single-row queries

---

## Action Items

| # | Action | Owner | Due Date | Status |
|---|--------|-------|----------|--------|
| 1 | Fix connection leak in bulk-export | @alice | 2025-03-17 | Done |
| 2 | Add connection pool alert | @bob | 2025-03-18 | In Progress |
| 3 | Add integration test | @alice | 2025-03-20 | TODO |
| 4 | Load test bulk-export | @carol | 2025-03-25 | TODO |
