# Quick Fix Preset

## Pipeline
```
planner(debug) → builder → tester
```

## Used By
- `/crew fix`

## Description
Bug fix cycle — diagnose, fix, verify. Skips formal review for speed but always runs tests.

## Role Configuration

### planner
- Mode: debug (forced)
- Systematic debugging: hypothesis → evidence → root cause

### builder
- Write regression test first (proves the bug exists)
- Implement minimal fix
- Verify regression test passes

### tester
- Mode: unit + diff-qa
- Run full test suite to check for regressions
- Focus on the area around the fix
