# Adversarial Review Protocol

## Purpose

Adversarial review uses a structured critic process to find issues that normal
review misses. The reviewer deliberately tries to break the code by thinking
like an attacker, a confused user, or a malicious input source.

## Critic Agent Prompt Template

Use this prompt to engage the adversarial critic mindset:

```
You are a code critic reviewing this change. Your job is to find problems.

For each issue found, provide:
1. Category (security, correctness, performance, reliability, maintainability)
2. Severity (critical, major, minor, nit)
3. Location (file:line)
4. Description (what's wrong)
5. Suggestion (how to fix it)

Rules:
- Assume all user input is malicious
- Assume all network calls will fail
- Assume all concurrent operations will race
- Assume the next developer has no context about this code
- Do NOT comment on style preferences — only objective issues
```

## Categorization Rules

### Critical (blocks merge)
- Security vulnerability (injection, auth bypass, data exposure)
- Data loss or corruption possible
- Crash or unhandled exception in production path

### Major (should fix before merge)
- Missing error handling for likely failure modes
- Race condition under normal load
- Breaking change to public API without migration path
- Logic error that produces wrong results

### Minor (fix recommended, non-blocking)
- Missing edge case handling for unlikely inputs
- Suboptimal performance (but not a bottleneck)
- Inconsistent with codebase patterns
- Missing validation that another layer might catch

### Nit (optional, author's discretion)
- Naming could be clearer
- Comment is misleading but code is correct
- Test could be more descriptive

## The Iteration Loop

```
Round 1: Initial adversarial review
  → List all findings, categorized and ranked

Round 2: Author responds
  → Fix critical and major issues
  → Explain or acknowledge minor issues
  → Optionally address nits

Round 3: Re-review changed code only
  → Verify fixes don't introduce new issues
  → Re-check any "acknowledged but not fixed" items

Round 4 (if needed): Final check
  → Only for items from Round 3
```

## Adversarial Test Scenarios

For each code path, ask:

### Input Attacks
- What if the input is empty? Null? Undefined?
- What if the string is 10MB long?
- What if the number is negative? Zero? MAX_SAFE_INTEGER?
- What if the array has 1 million elements?
- What if the JSON has deeply nested objects (100 levels)?

### State Attacks
- What if this function is called twice in rapid succession?
- What if the database connection drops mid-transaction?
- What if the cache is cold (first request after deploy)?
- What if the feature flag is in an unexpected state?

### Auth Attacks
- What if the token is expired but not yet cleaned up?
- What if the user's role changed between the check and the action?
- What if the request is replayed (same token, same body)?

### Concurrency Attacks
- What if two users update the same record simultaneously?
- What if a webhook fires while a related API call is in-flight?
- What if the queue consumer processes the same message twice?

## When to Stop

Stop the adversarial loop when:
1. All critical and major issues are resolved
2. Remaining minors have been acknowledged with rationale
3. No new issues were found in the latest round
4. The code would survive a production incident without causing data loss

Do NOT stop just because:
- The author says "it's fine" without evidence
- The review has gone through many rounds (complexity may warrant it)
- Time pressure (security and correctness don't have deadlines)

## Documenting Adversarial Findings

```markdown
## Adversarial Review: PR #123

### Critical
- [ ] **IDOR in /orders/:id** (orders.ts:45) — no ownership check

### Major
- [ ] **No retry on payment webhook** (webhook.ts:78) — transient failure loses payment confirmation

### Minor
- [ ] Missing rate limit on login endpoint
- [ ] Error message leaks database column name

### Acknowledged (won't fix this PR)
- Pagination performance with 100k+ records (separate optimization PR)
```

## Common Mistakes

- Being adversarial about style instead of substance
- Not distinguishing severity (treating nits as criticals)
- Stopping after finding the first issue (keep going)
- Not re-reviewing after fixes (fixes often introduce new problems)
