# Handoff Specification

## Overview

Handoff is the data contract between roles in a pipeline. When a role completes, it produces a handoff object that the next role consumes as input context.

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
```

### Reviewer Handoff

```yaml
role: reviewer
output:
  score: A | B | C | D
  approved: true | false
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

### Tester Handoff

```yaml
role: tester
mode: unit | diff-qa | browse | full
output:
  passed: 12
  failed: 0
  skipped: 1
  coverage: "87%"
  screenshots:
    - .crewkit/screenshots/login-page.png
    - .crewkit/screenshots/dashboard.png
  report: |
    All 12 tests passed. Coverage at 87%.
    Browser QA: 3 pages checked, no issues.
```

### Shipper Handoff

```yaml
role: shipper
output:
  version: "1.2.0"
  changelog_updated: true
  pr_url: "https://github.com/org/repo/pull/123"
  retro:
    commits: 15
    files_changed: 23
    contributors:
      - name: "developer"
        commits: 15
    summary: "Feature implementation with full test coverage."
```

## Rules

1. Every role MUST produce a handoff before the pipeline advances
2. The next role MUST read the previous handoff before starting
3. If a role fails, it should produce a partial handoff with error details
4. Handoff data is ephemeral — exists only during pipeline execution
