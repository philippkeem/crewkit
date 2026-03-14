---
description: "Crewkit — run role-based pipelines: /crew build, /crew fix, /crew review, /crew ship, /crew qa, /crew plan, /crew status, /crew doctor"
---

# Crewkit Command

This command invokes the **Crewkit engine** to orchestrate role-based pipelines.

## Usage

```
/crew <command> [args] [options]
```

## Available Commands

| Command | Pipeline | Description |
|---------|----------|-------------|
| `plan [topic]` | planner | Design and plan |
| `build [topic]` | planner → builder → reviewer | Full implementation cycle |
| `fix [issue]` | planner(debug) → builder → tester | Bug fix cycle |
| `review` | reviewer → tester | Code review current changes |
| `ship` | reviewer → tester → shipper | Release cycle |
| `qa` | tester | QA testing |
| `status` | — | Show pipeline state |
| `doctor` | — | Environment check |
| `config` | — | Edit configuration |
| `install` | — | Setup crewkit |

## Options

```
--skip <role>      Skip a specific role in the pipeline
--only <role>      Run only a specific role
--dry-run          Show what would happen without executing
--resume           Resume a previously paused pipeline
```

## How It Works

When invoked, this command delegates to the Crewkit engine skill (`skills/crew/SKILL.md`) which:

1. Parses the command and options
2. Loads project config (`.crewkit.yml` or defaults)
3. Selects the pipeline (sequence of roles)
4. Executes each role in order via Agent subprocesses
5. Passes structured handoff data between roles
6. Shows real-time progress via status bar

Each role has its own SKILL.md with detailed instructions. The engine reads the role's SKILL.md and launches it as an Agent with full context.

## Examples

```bash
/crew build add user authentication    # Full build cycle
/crew fix login button not responding  # Debug and fix
/crew review                           # Review current changes
/crew ship                             # Release current work
/crew qa                               # Run all tests
/crew build --skip reviewer            # Build without review gate
/crew status                           # Check pipeline state
```
