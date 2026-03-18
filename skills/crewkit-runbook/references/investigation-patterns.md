# Investigation Patterns

## 5 Whys

A structured method to trace a symptom to its root cause.

### Process
1. State the problem clearly
2. Ask "Why did this happen?"
3. Take the answer and ask "Why?" again
4. Repeat until you reach a systemic, actionable cause
5. Stop at 5 (or fewer if you reach the root)

### Template
```
Problem: [Observable symptom]

Why 1: [First-level cause]
  Evidence: [How do we know this?]

Why 2: [Deeper cause]
  Evidence: [How do we know this?]

Why 3: [Deeper cause]
  Evidence: [How do we know this?]

Why 4: [Deeper cause]
  Evidence: [How do we know this?]

Why 5: [Root cause]
  Evidence: [How do we know this?]

Root Cause: [Summary]
Action: [What to fix]
```

### Example
```
Problem: API response times spiked to 10s at 2pm.

Why 1: The database queries were slow.
  Evidence: Slow query log shows queries taking 8-9s.

Why 2: The database was doing full table scans.
  Evidence: EXPLAIN shows seq scan on orders table.

Why 3: The index on orders.created_at was missing.
  Evidence: \di in psql shows no index on that column.

Why 4: The migration that creates the index failed silently.
  Evidence: Migration log shows error but exit code 0.

Why 5: Migration runner doesn't propagate DDL errors.
  Evidence: Code review confirms error is caught and logged but not thrown.

Root Cause: Migration runner swallows DDL errors.
Action: Fix error handling in migration runner; add the missing index.
```

## Fault Tree Analysis

Work backward from a failure to identify all possible contributing causes.

### Structure
```
                    [Top Event: Service Down]
                           /        \
                    [AND/OR]        [AND/OR]
                   /       \       /        \
            [Cause A]  [Cause B] [Cause C]  [Cause D]
               |           |
          [Sub-cause]  [Sub-cause]
```

- **OR gate**: Any one child cause is sufficient
- **AND gate**: All child causes must occur together

### Example
```
Service returns 503
├── OR: Application crashed
│   ├── Out of memory (check RSS, OOM killer logs)
│   ├── Unhandled exception (check error logs)
│   └── Deadlock (check thread dump)
├── OR: Database unreachable
│   ├── Connection pool exhausted (check pool metrics)
│   ├── Database host down (check DB status)
│   └── Network partition (check connectivity)
└── OR: Load balancer misconfigured
    ├── Health check endpoint changed (check LB config)
    └── Backend deregistered (check target group)
```

### When to Use
- The failure has multiple possible causes
- You need to be systematic (not just guessing)
- Post-mortem requires showing you explored all paths

## Timeline Construction

Reconstruct exactly what happened and when.

### Template
```
Timezone: UTC

HH:MM  [Source]  Event description
-----  ------   ------------------
14:00  deploy   v2.3.1 deployed to production
14:02  monitor  Error rate increases from 0.1% to 2%
14:05  alert    PagerDuty fires: "High 5xx rate"
14:07  human    On-call acknowledges alert
14:10  human    Identifies database connection errors in logs
14:12  human    Checks database — connections at max (100/100)
14:15  human    Rolls back to v2.3.0
14:17  monitor  Error rate returns to 0.1%
14:20  human    Declares incident resolved
```

### Sources to Check
- Deployment logs (what changed and when)
- Application logs (errors, warnings)
- Monitoring dashboards (metrics timeline)
- Alert history (when alerts fired)
- Chat/Slack history (who did what)
- Git log (what code changed)
- Infrastructure events (scaling, restarts)

### Rules
- Use a single timezone (UTC preferred)
- Include the source for every entry
- Note gaps ("14:05-14:07 — no action taken, pager was missed")
- Separate facts from interpretation

## Hypothesis Testing

Structured approach to validating potential causes.

### Process
```
1. List all hypotheses
2. Rank by likelihood (based on evidence so far)
3. For the top hypothesis, identify a test
4. Run the test — does it confirm or eliminate?
5. If eliminated, move to next hypothesis
6. If confirmed, verify with a second independent test
```

### Template
```
| # | Hypothesis | Likelihood | Test | Result |
|---|-----------|-----------|------|--------|
| 1 | Connection leak in new code | High | Check pool metrics | CONFIRMED |
| 2 | DB server overloaded | Medium | Check DB CPU/memory | Eliminated |
| 3 | DNS resolution failure | Low | Check DNS logs | Not tested |
```

### Rules
- Test one hypothesis at a time
- Start with cheapest test (log check before load test)
- A single confirming test is not enough — verify independently
- Keep eliminated hypotheses in the record (shows thoroughness)

## Choosing the Right Pattern

| Situation | Use |
|-----------|-----|
| Single clear failure, need root cause | 5 Whys |
| Multiple possible causes, systematic exploration | Fault Tree |
| Need to reconstruct what happened and when | Timeline |
| Have several theories, need to narrow down | Hypothesis Testing |
| Complex incident (all of the above) | Timeline first, then Fault Tree + 5 Whys |
