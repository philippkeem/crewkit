# Review Only Preset

## Pipeline
```
reviewer → tester
```

## Used By
- `/crew review`

## Description
Code review with automated testing. Use when code is already written and needs review before merging.

## Role Configuration

### reviewer
- Full checklist
- Gate: configurable (default C)
- Review all changes in current branch vs base branch

### tester
- Mode: unit + diff-qa
- Run tests to validate reviewer's findings
- Coverage check
