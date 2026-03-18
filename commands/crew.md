---
description: "Crewkit — run role-based pipelines: /crew build, /crew fix, /crew review, /crew ship, /crew qa, /crew plan, /crew audit, /crew diagnose, /crew run, /crew status, /crew history, /crew doctor"
---

# Crewkit Command

This command invokes the **Crewkit engine** to orchestrate role-based pipelines with 7 specialized roles, parallel stage execution, and execution memory.

## Usage

```
/crew <command> [args] [options]
```

## Available Commands

### Workflow Commands

| Command | Pipeline | Description |
|---------|----------|-------------|
| `plan [topic]` | planner | Design and plan |
| `build [topic]` | planner → builder → [reviewer + security] | Full implementation cycle |
| `fix [issue]` | planner(debug) → builder → tester | Bug fix cycle |
| `review` | [reviewer + security] → tester | Code review + security audit |
| `ship` | [reviewer + security] → tester → shipper | Release cycle |
| `qa` | tester | QA testing |
| `audit` | security | Security audit current changes |
| `diagnose [symptom]` | runbook | Investigate production issue |
| `run <pipeline>` | (custom) | Run a custom pipeline from .crewkit.yml |

### Management Commands

| Command | Description |
|---------|-------------|
| `status` | Show current pipeline state |
| `resume` | Resume a paused pipeline |
| `history` | Show past pipeline runs |
| `doctor` | Environment check |
| `config` | Edit configuration |
| `install` | Setup crewkit |

## Options

```
--skip <role>      Skip a specific role in the pipeline
--only <role>      Run only a specific role
--dry-run          Show what would happen without executing
--resume           Resume a previously paused pipeline
--retry <role>     Re-run a specific failed role with same inputs
--adversarial      Enable adversarial review mode (critic sub-agent loop)
--babysit          Monitor PR after ship (retry flaky CI, auto-merge)
```

## The 7 Roles

| Role | Expertise | Gate |
|------|-----------|------|
| **Planner** | Design, architecture, debugging | — |
| **Builder** | TDD implementation, scaffolding | — |
| **Reviewer** | Code quality, adversarial review | Score A/B/C/D |
| **Security** | OWASP, dependency audit, secrets scan | PASS/WARN/FAIL |
| **Tester** | Unit, diff-QA, browser, product verification | — |
| **Shipper** | Release, babysit-pr, deploy verification | — |
| **Runbook** | Incident investigation, diagnostics | — |

## How It Works

When invoked, this command delegates to the Crewkit engine skill (`skills/crew/SKILL.md`) which:

1. Parses the command and options
2. Loads project config (`.crewkit.yml` or defaults)
3. Loads previous run context for delta comparison
4. Selects the pipeline (sequence of stages, some parallel)
5. Executes each stage via Agent subprocesses (parallel where possible)
6. Passes structured handoff data between stages
7. Enforces quality gates (reviewer score + security verdict)
8. Shows real-time progress via status bar
9. Appends to execution history for future reference

## Examples

```bash
# Workflow commands
/crew build add user authentication          # Full build with security audit
/crew fix login button not responding        # Debug and fix
/crew review                                 # Review + security audit current changes
/crew ship                                   # Release with quality gates
/crew ship --babysit                         # Release + monitor CI + auto-merge
/crew qa                                     # Run all tests
/crew audit                                  # Security-only audit
/crew diagnose "500 errors on /api/users"    # Investigate production issue

# Options
/crew build --skip security                  # Build without security audit
/crew build --adversarial                    # Build with adversarial review mode
/crew resume --retry reviewer                # Resume and re-run failed reviewer

# Custom pipelines (defined in .crewkit.yml)
/crew run secure-build add payment flow      # Run custom pipeline

# Management
/crew status                                 # Check pipeline state
/crew history                                # View past runs
/crew doctor                                 # Environment diagnostics
```
