# Review Only Preset

## Pipeline
```
[reviewer + security] → tester
```

## Used By
- `/crew review`

## Description
Code review with security audit and automated testing. For reviewing already-written code before merging.

## Role Configuration

### reviewer + security (parallel stage)
- Reviewer: full quality checklist on current git diff
- Security: vulnerability scan on changed files
- Both run simultaneously for efficiency
- Optional `--adversarial` flag for critic sub-agent loop

### tester
- Mode: unit + diff-qa
- Tests only affected areas based on changed files
- Coverage check against threshold
