# Handoff Specification

## Overview

Handoff is the data contract between roles in a pipeline. When a role completes, it produces a handoff object that the next stage consumes as input context. In parallel stages, multiple roles produce handoffs simultaneously — they are merged before passing to the next stage.

## Schema

### Planner Handoff

```yaml
role: planner
mode: product | architecture | debug
output:
  design: |
    Summary of the design decisions made.
    Can reference a saved design document path.
  files:
    - path/to/file1.ts
    - path/to/file2.ts
  decisions:
    - "Use PostgreSQL for storage"
    - "Implement as REST API, not GraphQL"
  plan_steps:
    - step: 1
      description: "Create database schema"
    - step: 2
      description: "Implement API endpoints"
```

### Builder Handoff

```yaml
role: builder
output:
  changes:
    - file: src/api/users.ts
      action: created
    - file: src/api/auth.ts
      action: modified
  tests:
    - src/api/__tests__/users.test.ts
    - src/api/__tests__/auth.test.ts
  coverage: "87%"
  build_status: pass | fail
  scaffolded_from: "api-endpoint"  # template used, if any
```

### Reviewer Handoff

```yaml
role: reviewer
mode: standard | adversarial
output:
  score: A | B | C | D
  approved: true | false
  adversarial_iterations: 0  # number of adversarial review loops (0 = standard mode)
  issues:
    - severity: critical | warning | info
      file: src/api/users.ts
      line: 42
      message: "SQL injection vulnerability"
    - severity: warning
      file: src/api/auth.ts
      line: 15
      message: "Missing rate limiting"
  summary: "2 issues found. 1 critical, 1 warning."
```

### Security Handoff

```yaml
role: security
output:
  verdict: PASS | WARN | FAIL
  files_scanned: 15
  high_risk_files:
    - src/api/auth.ts
    - src/api/payment.ts
  issues:
    - severity: CRITICAL | HIGH | MEDIUM | LOW
      category: injection | xss | auth | secrets | crypto | dependency | ssrf | csrf
      file: src/api/users.ts
      line: 42
      description: "Unsanitized user input in SQL query"
      fix_suggestion: "Use parameterized query instead of string interpolation"
  dependencies:
    vulnerable: 2
    details:
      - package: "lodash@4.17.20"
        severity: HIGH
        advisory: "Prototype pollution"
  secrets:
    found: false
    locations: []
```

### Tester Handoff

```yaml
role: tester
mode: unit | diff-qa | browse | full | verify
output:
  passed: 12
  failed: 0
  skipped: 1
  coverage: "87%"
  screenshots:
    - .crewkit/artifacts/20260318/login-page.png
    - .crewkit/artifacts/20260318/dashboard.png
  video: .crewkit/artifacts/20260318/test-run.webm  # if product verification mode
  assertions:
    - step: "login"
      status: pass
      evidence: "h1 text matches 'Dashboard'"
    - step: "submit form"
      status: pass
      evidence: "network request POST /api/users returned 201"
  report: |
    All 12 tests passed. Coverage at 87%.
    Browser QA: 3 pages checked, no issues.
```

### Runbook Handoff

```yaml
role: runbook
mode: investigate | diagnose | correlate
output:
  findings:
    - system: "api-server"
      status: RED | YELLOW | GREEN
      evidence: "OOM killed at 14:32 UTC, memory usage 98%"
      timestamp: "2026-03-18T14:32:00Z"
    - system: "database"
      status: GREEN
      evidence: "connections normal, query latency < 50ms"
  timeline:
    - timestamp: "2026-03-18T14:30:00Z"
      event: "Deploy v1.5.2 completed"
    - timestamp: "2026-03-18T14:32:00Z"
      event: "API server OOM killed"
  root_cause: "Memory leak in connection pool after v1.5.2 deploy"
  remediation:
    immediate: "Restart API server, revert to v1.5.1"
    permanent: "Fix connection pool cleanup in src/db/pool.ts"
  incident_report:
    severity: P2
    duration: "15 minutes"
    affected_users: "all API consumers"
    summary: "API outage due to memory leak introduced in v1.5.2"
```

### Shipper Handoff

```yaml
role: shipper
output:
  version: "1.2.0"
  changelog_updated: true
  pr_url: "https://github.com/org/repo/pull/123"
  babysit:  # only present when --babysit is used
    ci_status: pass | fail | pending
    retries: 0
    auto_merge: true | false
  retro:
    commits: 15
    files_changed: 23
    contributors:
      - name: "developer"
        commits: 15
    summary: "Feature implementation with full test coverage."
```

## Parallel Handoff Merging

When roles run in parallel (e.g., `[reviewer + security]`), their handoffs are stored as **separate keys** — no deep merge is performed. Each role writes to its own namespaced key:

```json
{
  "reviewer": {
    "score": "B",
    "approved": true,
    "issues": [...]
  },
  "security": {
    "verdict": "PASS",
    "issues": [...]
  }
}
```

**Merge rules**:
1. Each parallel role writes to `.crewkit/handoff-<role>.json` independently (no file conflicts)
2. The engine stores both under `state.handoffs.<role>` as separate top-level keys
3. The next stage reads from `handoffs.<role>.*` — e.g., `handoffs.reviewer.score`, `handoffs.security.verdict`
4. No key collisions are possible because role names are unique
5. If one parallel role produces an error handoff, the other role's handoff is still preserved

## Rules

1. Every role MUST produce a handoff before the pipeline advances
2. The next role MUST read the previous handoff before starting
3. If a role fails, it should produce a **partial handoff** with error details and `status: error`
4. If a role's response contains no handoff at all, the engine creates an error handoff (see below)
5. Handoff data is saved to `.crewkit/handoff-<role>.json` per role
6. Handoffs are preserved after pipeline completion for history/delta comparison
7. Previous run's handoffs are available at `.crewkit/prev-handoff-<role>.json` for delta comparison
8. Handoff files should not exceed 1MB — for very large changesets, summarize rather than listing every detail

## Error Handoff

When a role fails, it produces a partial handoff:

```yaml
role: builder
status: error
error:
  message: "Build failed: TypeScript compilation error"
  phase: "implementation"  # which phase the role was in when it failed
  recoverable: true        # can this be retried?
  context: "Error in src/api/users.ts:42 — Type 'string' not assignable to 'number'"
output:
  changes: [...]  # partial results, if any
```

**Engine-generated error handoff** (when role response has no handoff at all):

```yaml
role: <role-name>
status: error
error:
  message: "Failed to extract handoff from role response"
  phase: "handoff_extraction"
  recoverable: true
  context: "<first 200 chars of role response>"
```

This is created automatically by the engine when handoff extraction fails. The pipeline pauses and the user can retry with `/crew resume --retry <role>`.

---

## Flow Diagram

### Complete Handoff Chain

```
                    ┌─────────────────────────────────────────────┐
                    │           PIPELINE DATA FLOW                │
                    └─────────────────────────────────────────────┘

USER REQUEST ──► planner
                   │
                   ├── design: "summary of solution"
                   ├── files: [src/api.ts, src/model.ts]
                   ├── decisions: ["use REST not GraphQL"]
                   └── plan_steps: [{step:1, ...}, {step:2, ...}]
                        │
                        ▼
                   builder (reads planner handoff)
                   │
                   ├── changes: [{file: src/api.ts, action: created}]
                   ├── tests: [tests/api.test.ts]
                   ├── coverage: "87%"
                   └── build_status: "pass"
                        │
                  ┌─────┴──────┐
                  ▼            ▼
             reviewer      security        ← PARALLEL STAGE
                  │            │
                  ├── score    ├── verdict
                  ├── issues   ├── issues
                  └── approved └── secrets_found
                  │            │
                  └─────┬──────┘
                        ▼
                   [merged handoffs]
                        │
                        ▼
                   tester (reads builder + reviewer + security handoffs)
                   │
                   ├── passed: 12, failed: 0
                   ├── coverage: "87%"
                   ├── assertions: [{step, status, evidence}]
                   └── report: "all tests pass"
                        │
                        ▼
                   shipper (reads all previous handoffs)
                   │
                   ├── version: "1.2.0"
                   ├── changelog_updated: true
                   ├── pr_url: "https://github.com/.../pull/42"
                   └── retro: {commits: 5, summary: "clean release"}


Storage: .crewkit/handoff-<role>.json (per role)
Previous: .crewkit/prev-handoff-<role>.json (from last run, for delta comparison)
History:  .crewkit/history.jsonl (append-only execution log)
```

### What Each Role Reads From Previous Handoffs

```
planner   ──► reads: nothing (first in pipeline) + prev-handoff-* for delta context
builder   ──► reads: planner.plan_steps, planner.files, planner.design
reviewer  ──► reads: builder.changes, builder.tests, builder.coverage
security  ──► reads: builder.changes, builder.tests (parallel with reviewer)
tester    ──► reads: builder.changes, reviewer.issues, security.issues
runbook   ──► reads: nothing (standalone) or tester.report (in debug pipeline)
shipper   ──► reads: reviewer.approved, reviewer.score, security.verdict, tester.passed, tester.failed
```
