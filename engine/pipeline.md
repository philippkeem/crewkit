# Pipeline Execution Engine

## Pipeline Definition

A pipeline is an ordered sequence of roles. Each role receives a handoff from the previous role and produces a handoff for the next.

## Available Presets

### full-cycle
```
planner → builder → reviewer → tester → shipper
```
Used by: `/crew build` (without shipper), `/crew ship` (full)

### quick-fix
```
planner(debug) → builder → tester
```
Used by: `/crew fix`

### review-only
```
reviewer → tester
```
Used by: `/crew review`

### ship-only
```
reviewer → tester → shipper
```
Used by: `/crew ship`

## Execution Rules

1. **Sequential by default** — roles execute one at a time
2. **Handoff required** — each role MUST produce a handoff object before the next role starts
3. **Gate checks** — reviewer can halt the pipeline if score is below threshold
4. **Resume support** — if paused, the pipeline can resume from the last incomplete role

## Handoff Schema

Each role produces a structured handoff:

```
planner handoff:
  - design: string (design summary or doc path)
  - files: string[] (files to create/modify)
  - decisions: string[] (key decisions made)

builder handoff:
  - changes: string[] (files changed)
  - tests: string[] (test files created/modified)
  - coverage: string (coverage percentage)

reviewer handoff:
  - issues: object[] (found issues with severity)
  - approved: boolean
  - score: string (A/B/C/D)

tester handoff:
  - passed: number
  - failed: number
  - screenshots: string[] (paths to screenshots if browse mode)
  - report: string (test report summary)
```

## Option Processing

### --skip
Remove the specified role from the pipeline. Example:
```
/crew build --skip reviewer
→ planner → builder (reviewer removed)
```

### --only
Run only the specified role. Example:
```
/crew build --only planner
→ planner (builder and reviewer removed)
```

### --dry-run
Execute roles but prevent any write operations (no file edits, no git commits, no PRs).

### --resume
Find the last paused pipeline state and continue from where it stopped.
