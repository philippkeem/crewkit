# Quick Fix Preset

## Pipeline
```
planner(debug) → builder → tester
```

## Used By
- `/crew fix`

## Description
Bug fix cycle: diagnose, fix, verify. Skips formal review and security for speed but always runs tests.

## Role Configuration

### planner
- Mode: **debug** (forced)
- Investigates root cause before any fix is attempted
- Outputs hypothesis and evidence

### builder
- Implements the fix based on planner's diagnosis
- TDD: writes regression test first, then fixes
- Scaffolding templates used when available

### tester
- Mode: unit + diff-qa
- Verifies the fix resolves the issue
- Checks no regressions introduced
