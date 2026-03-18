# Pipeline Execution Engine

## Pipeline Definition

A pipeline is an ordered sequence of **stages**. Each stage contains one or more roles. Roles within the same stage run **in parallel**; stages execute **sequentially**. Each role receives handoffs from all previous roles and produces a handoff for the next stage.

## Available Presets

### full-cycle
```
planner → builder → [reviewer + security] → tester → shipper
```
Used by: `/crew build` (without shipper), `/crew ship` (full)

### quick-fix
```
planner(debug) → builder → tester
```
Used by: `/crew fix`

### review-only
```
[reviewer + security] → tester
```
Used by: `/crew review`

### ship-only
```
[reviewer + security] → tester → shipper
```
Used by: `/crew ship`

### security-audit
```
security
```
Used by: `/crew audit`

### diagnose
```
runbook
```
Used by: `/crew diagnose`

## Parallel Stage Syntax

Roles wrapped in `[role_a + role_b]` run as parallel agents in a single stage. Both must complete before the pipeline advances.

```yaml
# In .crewkit.yml custom pipeline
pipelines:
  my-flow:
    stages:
      - planner
      - builder
      - parallel: [reviewer, security]    # both run simultaneously
      - tester
```

### Parallel Rules
1. Parallel roles receive the **same** handoff from the previous stage
2. Both roles must produce their handoff before the next stage starts
3. If ANY parallel role triggers a gate failure, the pipeline pauses
4. Handoffs from parallel roles are **merged** — the next stage receives all of them

## Execution Rules

1. **Sequential stages, parallel roles** — stages execute one at a time, roles within a stage can run in parallel
2. **Handoff required** — each role MUST produce a handoff object before the next stage starts
3. **Gate checks** — reviewer and security can halt the pipeline if thresholds are not met
4. **Resume support** — if paused, the pipeline can resume from the last incomplete stage
5. **Retry support** — failed roles can be retried individually with `--retry <role>`
6. **Execution log** — every pipeline run is appended to `.crewkit/history.jsonl` for memory

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

security handoff:
  - verdict: string (PASS/WARN/FAIL)
  - issues: object[] (severity + category + fix suggestion)
  - dependencies_vulnerable: number
  - secrets_found: boolean

tester handoff:
  - passed: number
  - failed: number
  - screenshots: string[] (paths to screenshots if browse mode)
  - report: string (test report summary)

runbook handoff:
  - mode: string (investigate/diagnose/correlate)
  - findings: object[] (system + status + evidence)
  - root_cause: string
  - remediation: object (immediate + permanent)
```

## Option Processing

### --skip
Remove the specified role from the pipeline. Example:
```
/crew build --skip reviewer
→ planner → builder → security (reviewer removed from parallel stage)
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

### --retry <role>
Re-run a specific role that failed, using the same handoff inputs it received before.

### --adversarial
Enable adversarial review mode for the reviewer (sub-agent critic loop).

### --babysit
After shipping, monitor PR CI status and auto-retry flaky tests.

## Custom Pipelines

Users can define custom pipelines in `.crewkit.yml`:

```yaml
pipelines:
  secure-build:
    stages:
      - planner
      - builder
      - parallel: [reviewer, security]
      - tester
    gate:
      reviewer: "B"
      security: "PASS"

  quick-review:
    stages:
      - parallel: [reviewer, tester]
```

Custom pipelines are invoked with: `/crew run <pipeline-name> [args]`

### Custom Pipeline Validation

The engine validates custom pipelines at load time (`/crew run` and `/crew doctor`):

| Check | Error |
|-------|-------|
| Pipeline name exists in `pipelines:` | `unknown pipeline: "<name>". Available: [list]` |
| All role names are valid | `unknown role: "<name>" in pipeline "<pipeline>". Valid roles: planner, builder, reviewer, tester, shipper, security, runbook` |
| `parallel:` arrays have 2+ roles | `parallel stage needs 2+ roles, got 1 in pipeline "<pipeline>"` |
| Gate references existing roles | `⚠ gate references "<role>" which is not in pipeline "<pipeline>" (gate ignored)` |
| No duplicate roles across stages | `⚠ role "<name>" appears in multiple stages in pipeline "<pipeline>"` |

Validation errors are **blocking** (pipeline won't start). Validation warnings (⚠) are shown but don't block execution.

---

## Flow Diagram

### Pipeline Lifecycle

```
INIT ──► EXECUTE STAGE ──► GATE CHECK ──► COMPLETE or PAUSE
  │           │                 │
  │           │                 ├── all approved ──► next stage ──► loop
  │           │                 └── any rejected ──► PAUSE state
  │           │
  │           ├── single role? ──► run agent ──► produce handoff
  │           └── parallel?    ──► run agents concurrently ──► merge handoffs
  │
  └── state.json created { status: running, stages: [...] }
```

### Option Processing

```
Original pipeline: [planner, builder, [reviewer + security]]
  │
  ├── --skip reviewer   ──► [planner, builder, security]
  ├── --only builder    ──► [builder]
  ├── --dry-run         ──► [planner, builder, [reviewer + security]] (read-only)
  ├── --resume          ──► load state ──► continue from paused stage
  ├── --retry security  ──► re-run security with same inputs
  └── --adversarial     ──► reviewer uses adversarial sub-agent loop
```

### Handoff Data Flow Between Stages

```
planner ──► { design, files, decisions, plan_steps }
    │
    ▼
builder ──► { changes, tests, coverage, build_status }
    │
    ├──────────────────┐
    ▼                  ▼
reviewer             security          ← parallel stage
    │                  │
    ├── { score,       ├── { verdict,
    │    approved,     │    issues,
    │    issues }      │    secrets_found }
    │                  │
    └────────┬─────────┘
             ▼
         [merged handoffs]
             │
             ▼
tester ──► { passed, failed, coverage, screenshots, report }
    │
    ▼
shipper ──► { version, changelog_updated, pr_url, retro }
```

### Execution History

```
Each pipeline run appends to .crewkit/history.jsonl:

{ "id": "1710...", "command": "build", "args": "...", "status": "complete",
  "started_at": "...", "completed_at": "...", "roles_executed": [...],
  "duration_seconds": 272, "summary": "..." }

History enables:
- Delta comparison: "what changed since last build?"
- Pattern detection: "which role fails most often?"
- Resume context: previous run's handoffs available for reference
```
