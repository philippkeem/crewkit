# Crewkit

Turn Claude Code into a team of specialized experts.

**7 roles. 9 commands. Parallel pipelines.**

```
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ running in parallel...
```

## What is Crewkit?

Crewkit is an open-source skill framework for [Claude Code](https://claude.com/claude-code). It organizes AI assistance into **7 expert roles** connected by **automated pipelines** with **parallel execution**, **quality gates**, and **execution memory**.

Instead of memorizing dozens of skills, you use 9 commands. Crewkit's engine automatically routes your intent to the right roles, passes context between them, runs independent roles in parallel, and shows you progress in real time.

## Installation

### Prerequisites

- [Claude Code](https://claude.com/claude-code) installed and working
- Git

### Method 1: Plugin Marketplace (Recommended)

Claude Code 안에서 두 줄이면 끝입니다:

```bash
# Step 1: crewkit 마켓플레이스 등록
/plugin marketplace add philippkeem/crewkit

# Step 2: 플러그인 설치
/plugin install crewkit@crewkit
```

설치 완료. `/crew build` 로 바로 시작할 수 있습니다.

> **Update**: 업데이트가 필요할 때는 동일한 명령으로 재설치하면 최신 버전이 적용됩니다.

### Method 2: Git Clone (Global)

모든 프로젝트에서 사용할 수 있도록 글로벌로 설치합니다:

```bash
# Step 1: Clone
git clone https://github.com/philippkeem/crewkit.git ~/.claude/skills/crewkit

# Step 2: Setup
cd ~/.claude/skills/crewkit && ./setup
```

> **Update**: `cd ~/.claude/skills/crewkit && git pull`

### Method 3: Git Clone (Per Project)

특정 프로젝트에서만 사용하려면:

```bash
cd your-project
mkdir -p .claude/skills
git clone https://github.com/philippkeem/crewkit.git .claude/skills/crewkit
```

> 프로젝트에 `.claude/skills/` 디렉토리가 있으면 Claude Code가 자동으로 인식합니다.

### Verify

설치 후 Claude Code 안에서:

```bash
/crew doctor
```

```
Crewkit Doctor
══════════════
Environment:  ✓ git  ✓ node  ✓ gh
Installation: ✓ engine  ✓ planner  ✓ builder  ✓ reviewer  ✓ tester  ✓ shipper  ✓ security  ✓ runbook
✅ All checks passed
```

### Uninstall

```bash
# Plugin 방식
/plugin uninstall crewkit@crewkit

# Git Clone 방식
rm -rf ~/.claude/skills/crewkit
```

## Usage

### Build a Feature

```bash
/crew build add user authentication with JWT
```

Crewkit runs: **planner** → **builder** (TDD) → **[reviewer + security]** (parallel quality gates)

### Fix a Bug

```bash
/crew fix login fails when email has uppercase letters
```

Crewkit runs: **planner** (debug mode) → **builder** (regression test + fix) → **tester** (verification)

### Plan Before Building

```bash
/crew plan migrate database from MySQL to PostgreSQL
```

The **planner** designs the solution, asks clarifying questions, and saves a design doc.

### Review Current Changes

```bash
/crew review
```

The **[reviewer + security]** check your code in parallel, then the **tester** runs your test suite.

### Ship a Release

```bash
/crew ship --babysit
```

Quality gates → version bump → changelog → PR → CI monitoring → auto-merge.

### Security Audit

```bash
/crew audit
```

The **security** role scans for OWASP vulnerabilities, dependency issues, and hardcoded secrets.

### Diagnose Production Issues

```bash
/crew diagnose "500 errors on /api/users"
```

The **runbook** role investigates, correlates logs, and suggests remediation.

### Run QA

```bash
/crew qa
```

The **tester** runs unit tests, analyzes coverage, and optionally tests in a headless browser with video recording.

### Custom Pipelines

```bash
/crew run secure-build add payment flow
```

Run your own pipeline defined in `.crewkit.yml`.

## The 9 Commands

| Command | Pipeline | What It Does |
|---------|----------|-------------|
| `/crew plan` | planner | Design and plan a feature or investigation |
| `/crew build` | planner → builder → [reviewer + security] | Full implementation with parallel quality gates |
| `/crew fix` | planner(debug) → builder → tester | Systematic bug fix with verification |
| `/crew review` | [reviewer + security] → tester | Parallel code review + security audit |
| `/crew ship` | [reviewer + security] → tester → shipper | Quality gate + release + optional babysit |
| `/crew qa` | tester | Test suite + coverage + browser QA |
| `/crew audit` | security | Security-only audit (OWASP, deps, secrets) |
| `/crew diagnose` | runbook | Incident investigation and diagnostics |
| `/crew run` | (custom) | Run a custom pipeline from config |

### Options

```bash
/crew build add search --skip security       # Skip security audit
/crew build add search --only planner        # Only run planning
/crew build add search --dry-run             # Simulate, no file changes
/crew build add search --adversarial         # Adversarial review mode
/crew ship --babysit                         # Monitor CI after PR creation
/crew resume                                 # Resume a paused pipeline
/crew resume --retry reviewer                # Re-run failed reviewer
```

## The 7 Roles

### Planner

Thinks before anyone builds. Three modes:

- **Product** — CEO-level thinking. Challenges premises, scopes the MVP, proposes approaches with trade-offs.
- **Architecture** — Staff engineer thinking. Data flow, edge cases, interfaces, test matrix.
- **Debug** — Detective thinking. Hypothesis → evidence → root cause. Never guesses.

### Builder

Implements with discipline. Follows strict TDD:

```
RED   → Write failing test
GREEN → Write minimal code to pass
REFACTOR → Clean up, tests still green
```

Supports scaffolding templates and automatically parallelizes independent work streams.

### Reviewer

The paranoid staff engineer. Checks every changed file for:

- **Data safety** — migration reversibility, transactions
- **Logic** — edge cases, error handling, race conditions
- **Performance** — N+1 queries, missing indexes, pagination
- **Quality** — readability, dead code, test coverage
- **Accessibility** — keyboard navigation, WCAG contrast (if UI changes)
- **Backwards compatibility** — API signatures, migration safety
- **Type safety** — proper types, null handling (if typed language)

Scores: **A** (excellent) / **B** (good) / **C** (acceptable) / **D** (needs work → pipeline pauses)

Optional **adversarial mode**: spawns a critic sub-agent that attacks the code, iterating until all issues are minor.

### Security

Dedicated security auditor (runs parallel with reviewer):

- **OWASP Top 10** — injection, XSS, CSRF, SSRF, broken auth
- **Dependencies** — npm audit / pip audit / go vuln check
- **Secrets** — hardcoded API keys, passwords, tokens
- **Auth/AuthZ** — authentication flows, authorization logic

Verdicts: **PASS** / **WARN** (user decides) / **FAIL** (pipeline stops)

### Tester

Quality guardian with 5 modes:

- **Unit** — Run test suite, check coverage against threshold
- **Diff-QA** — Analyze git diff, test only affected areas
- **Browse** — Headless browser testing with screenshots
- **Verify** — Product verification with programmatic assertions and video recording
- **Full** — Everything above combined

### Shipper

Release engineer with CI babysitting:

- Pre-flight checks → version bump → changelog → PR
- **Babysit mode**: monitor CI → retry flaky tests → auto-merge
- **Deploy verification**: smoke test → rollback on failure

### Runbook

Incident responder with 3 modes:

- **Investigate** — symptom → hypothesis → evidence → root cause → remediation
- **Diagnose** — automated health checks across all configured services
- **Correlate** — trace request across systems using ID or timestamp

## Pipeline Monitor

Every command shows real-time progress, including parallel stages:

```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ analyzing requirements...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ implementing... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ running in parallel...
[crewkit] build │ ██████████ 3/3 │ reviewer ✓ security ✓ │ stage complete
✅ crewkit build complete │ 3/3 │ elapsed: 4m 32s │ score:B security:PASS
```

If a gate fails:

```
[crewkit] build │ ██████████ 3/3 │ security │ ❌ FAIL — 1 critical vulnerability
⏸ Pipeline paused │ fix security issues │ /crew resume or /crew resume --retry security
```

## Configuration

Create `.crewkit.yml` in your project root to customize behavior:

```yaml
project:
  name: "my-app"
  stack: "next.js + typescript"

pipeline:
  build:
    skip: []
    reviewer:
      gate: "C"
    security:
      gate: "PASS"
  ship:
    strategy: "pr"
    babysit: false
    changelog: true
    version-bump: "semver"

# Custom pipelines
pipelines:
  secure-build:
    stages:
      - planner
      - builder
      - parallel: [reviewer, security]
      - tester

tester:
  browse:
    base-url: "http://localhost:3000"
  coverage:
    minimum: 80

security:
  dependency-audit: true
  secrets-scan: true

monitor:
  verbose: true
```

**No config needed to start** — sensible defaults work out of the box.

See [.crewkit.yml.example](.crewkit.yml.example) for all options.

## Management Commands

| Command | Description |
|---------|-------------|
| `/crew install` | Interactive setup wizard |
| `/crew doctor` | Environment diagnostics |
| `/crew config` | Edit `.crewkit.yml` interactively |
| `/crew status` | Show current pipeline state |
| `/crew history` | Show past pipeline runs |
| `/crew resume` | Resume a paused pipeline |

## How It Works Internally

```
User: /crew build add search feature
  │
  ▼
Engine: parse command → load config → load previous run context
  │
  ▼
Engine: build pipeline [planner] → [builder] → [reviewer + security]
  │
  ▼
Engine: init state (.crewkit/state.json) → show progress bar
  │
  ├──▶ Stage 1: Agent(planner) → design + file list + plan steps
  │    └─ handoff ──┐
  │                 ▼
  ├──▶ Stage 2: Agent(builder) → TDD implementation + tests
  │    └─ handoff ──┐
  │                 ▼
  └──▶ Stage 3: Agent(reviewer) + Agent(security) ← PARALLEL
       │              │
       ├─ handoff ────┤
       │              │
       ▼              ▼
       Gate check: score ≥ C? + verdict = PASS?
       │
       ▼
Engine: ✅ complete → append to history.jsonl
    or: ⏸ paused (if gate fails) → /crew resume
```

## Project Structure

```
crewkit/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest
│   └── marketplace.json      # Marketplace catalog
├── skills/                   # Plugin skill entry points
│   ├── crew/SKILL.md         # /crew engine — command routing & pipeline orchestration
│   ├── crewkit-planner/      # Design, architecture, debugging
│   ├── crewkit-builder/      # TDD implementation + scaffolding
│   ├── crewkit-reviewer/     # Code review + adversarial mode
│   ├── crewkit-tester/       # Testing + product verification
│   ├── crewkit-shipper/      # Release + babysit-pr + deploy verification
│   ├── crewkit-security/     # OWASP audit + dependency scan + secrets detection
│   └── crewkit-runbook/      # Incident investigation + diagnostics
├── engine/                   # Engine support files
│   ├── state.sh              # Pipeline state management helpers
│   ├── pipeline.md           # Pipeline execution spec (parallel stages)
│   ├── monitor.md            # Status bar rendering spec
│   └── handoff.md            # Role-to-role data contract
├── roles/                    # Role reference (legacy/manual install)
│   ├── planner/              # + references/ for progressive disclosure
│   ├── builder/              # + references/
│   ├── reviewer/             # + references/
│   ├── tester/               # + references/
│   ├── shipper/              # + references/
│   ├── security/             # + references/
│   └── runbook/              # + references/
├── presets/                  # Pipeline preset definitions (6 presets)
├── .crewkit.yml.example      # Configuration template
├── setup                     # CLI install script
└── package.json
```

## Contributing

We welcome contributions! Please read our [Git Policy](docs/GIT_POLICY.md) which includes the full contributing guide.

**Quick summary:**

1. Fork the repo
2. Create a branch: `feat/42-my-feature`
3. Follow [Conventional Commits](https://www.conventionalcommits.org/): `feat(engine): add retry logic`
4. Submit a PR targeting `main`
5. All PRs are squash merged

## Acknowledgments

Crewkit is inspired by and builds upon ideas from:
- [gstack](https://github.com/garrytan/gstack) by Garry Tan
- [superpowers](https://github.com/anthropics/courses) community patterns

## License

[MIT](LICENSE)
