# Ship Only Preset

## Pipeline
```
[reviewer + security] → tester → shipper
```

## Used By
- `/crew ship`

## Description
Release pipeline for complete, ready-for-release implementation. Includes quality gates and optional CI babysitting.

## Role Configuration

### reviewer + security (parallel stage)
- Stricter gate recommended (reviewer: B, security: PASS)
- Full quality and security review before release
- Both run simultaneously

### tester
- Mode: full (unit + diff-qa + browse if configured)
- Product verification with assertions

### shipper
- Pre-flight checks (reviewer approved, security passed, tests passed)
- Version bump, changelog, PR creation
- Optional `--babysit`: monitor CI → retry flaky → auto-merge
- Optional deploy verification: smoke test → rollback on failure
