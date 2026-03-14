# Full Cycle Preset

## Pipeline
```
planner → builder → reviewer → tester → shipper
```

## Used By
- `/crew build` (planner → builder → reviewer, without shipper)
- `/crew ship` when starting from scratch

## Description
The complete development lifecycle from design to deployment.

## Role Configuration

### planner
- Mode: auto-detect (product for new features, architecture for refactoring)
- Gate: user approval on design required

### builder
- TDD enforced
- Parallel dispatch for independent tasks

### reviewer
- Full checklist (security, data, logic, performance, quality)
- Gate: configurable (default C)

### tester
- Mode: unit + diff-qa
- Coverage threshold enforced

### shipper
- Pre-flight check required
- Strategy from .crewkit.yml
