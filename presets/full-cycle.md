# Full Cycle Preset

## Pipeline
```
planner → builder → [reviewer + security] → tester → shipper
```

## Used By
- `/crew build` (planner → builder → [reviewer + security], without shipper/tester)
- `/crew ship` when starting from scratch

## Description
The complete development lifecycle from design to deployment, with parallel quality gates.

## Role Configuration

### planner
- Mode: auto-detect (product for new features, architecture for refactoring)
- Gate: user approval on design required

### builder
- TDD enforced
- Parallel dispatch for independent tasks
- Scaffolding templates used when available

### reviewer + security (parallel stage)
- Reviewer: full checklist (data, logic, performance, quality)
- Security: OWASP Top 10, dependency audit, secrets scan
- Gate: reviewer score (default C) + security verdict (default PASS)
- Both run simultaneously — pipeline pauses if either fails gate

### tester
- Mode: unit + diff-qa
- Coverage threshold enforced
- Product verification with assertions when browse mode enabled

### shipper
- Pre-flight check required
- Strategy from .crewkit.yml
- Optional babysit mode for CI monitoring
