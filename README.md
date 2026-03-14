# Crewkit

Turn Claude Code into a team of specialized experts.

**5 roles. 6 commands. One pipeline.**

```
[crewkit] build │ ██████░░░░ 2/3 │ builder │ writing tests... 12/12 pass
```

## What is Crewkit?

Crewkit is an open-source skill framework for [Claude Code](https://claude.com/claude-code). It organizes AI assistance into **5 expert roles** connected by **automated pipelines** with **real-time monitoring**.

Instead of memorizing dozens of skills, you use 6 commands. Crewkit's engine automatically routes your intent to the right roles, passes context between them, and shows you progress in real time.

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
Environment:  ✓ git  ✓ node
Installation: ✓ engine  ✓ planner  ✓ builder  ✓ reviewer  ✓ tester  ✓ shipper
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

Crewkit runs: **planner** (designs the solution) → **builder** (implements with TDD) → **reviewer** (code review with scoring)

### Fix a Bug

```bash
/crew fix login fails when email has uppercase letters
```

Crewkit runs: **planner** (debug mode — finds root cause) → **builder** (implements fix) → **tester** (verifies fix)

### Plan Before Building

```bash
/crew plan migrate database from MySQL to PostgreSQL
```

The **planner** designs the solution, asks clarifying questions, and saves a design doc. Nothing gets built until you approve.

### Review Current Changes

```bash
/crew review
```

The **reviewer** checks your git diff for security, performance, and quality issues, then the **tester** runs your test suite.

### Ship a Release

```bash
/crew ship
```

The **reviewer** and **tester** verify quality, then the **shipper** bumps the version, generates a changelog, and creates a PR.

### Run QA

```bash
/crew qa
```

The **tester** runs unit tests, analyzes coverage, and optionally tests in a headless browser.

## The 6 Commands

| Command | Pipeline | What It Does |
|---------|----------|-------------|
| `/crew plan` | planner | Design and plan a feature or investigation |
| `/crew build` | planner → builder → reviewer | Full implementation cycle with TDD |
| `/crew fix` | planner(debug) → builder → tester | Systematic bug fix with verification |
| `/crew review` | reviewer → tester | Code review + test run |
| `/crew ship` | reviewer → tester → shipper | Quality gate + release |
| `/crew qa` | tester | Test suite + coverage + browser QA |

### Options

```bash
/crew build add search --skip reviewer    # Skip code review
/crew build add search --only planner     # Only run planning
/crew build add search --dry-run          # Simulate, no file changes
/crew resume                              # Resume a paused pipeline
```

## The 5 Roles

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

Automatically parallelizes independent work streams using sub-agents.

### Reviewer

The paranoid staff engineer. Checks every changed file for:

- **Security** — injection, XSS, secrets, auth gaps
- **Data safety** — migration reversibility, transactions
- **Logic** — edge cases, error handling, race conditions
- **Performance** — N+1 queries, missing indexes, pagination

Scores: **A** (excellent) / **B** (good) / **C** (acceptable) / **D** (needs work → pipeline pauses)

### Tester

Quality guardian with 4 modes:

- **Unit** — Run test suite, check coverage against threshold
- **Diff-QA** — Analyze git diff, test only affected areas
- **Browse** — Headless browser testing with screenshots
- **Full** — Everything above combined

### Shipper

Release engineer. Pre-flight checks → version bump → changelog → PR → retrospective.

## Pipeline Monitor

Every command shows real-time progress:

```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner  │ analyzing requirements...
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner  │ writing design doc...
[crewkit] build │ ██████░░░░ 2/3 │ builder  │ writing tests...
[crewkit] build │ ██████░░░░ 2/3 │ builder  │ implementing... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer │ security check... Score: A
✅ crewkit build complete │ 3/3 │ elapsed: 4m 32s
```

If the reviewer gates the pipeline:

```
[crewkit] build │ ██████░░░░ 2/3 │ reviewer │ ❌ Score: D — 2 critical issues
⏸ Pipeline paused │ /crew status to see issues │ fix then /crew resume
```

## Configuration

Create `.crewkit.yml` in your project root to customize behavior:

```yaml
project:
  name: "my-app"
  stack: "next.js + typescript"

pipeline:
  build:
    skip: []                          # roles to skip: [reviewer, tester]
    reviewer:
      gate: "C"                       # minimum score: A | B | C | D
  ship:
    strategy: "pr"                    # pr | auto-merge | direct-push
    changelog: true
    version-bump: "semver"            # semver | calver | manual

tester:
  browse:
    base-url: "http://localhost:3000"
    cookies-from: "chrome"
  coverage:
    minimum: 80

monitor:
  verbose: true
```

**No config needed to start** — sensible defaults work out of the box (gate: C, strategy: pr, coverage: 80%).

See [.crewkit.yml.example](.crewkit.yml.example) for all options.

## Management Commands

| Command | Description |
|---------|-------------|
| `/crew install` | Interactive setup wizard |
| `/crew update` | Update to latest version |
| `/crew doctor` | Environment diagnostics |
| `/crew config` | Edit `.crewkit.yml` interactively |
| `/crew status` | Show current pipeline state and history |

## How It Works Internally

```
User: /crew build add search feature
  │
  ▼
Engine: parse command → select pipeline [planner, builder, reviewer]
  │
  ▼
Engine: init state (.crewkit/state.json) → show progress bar
  │
  ├──▶ Agent(planner) → design + file list + plan steps
  │    └─ handoff ──┐
  │                 ▼
  ├──▶ Agent(builder) → TDD implementation + tests
  │    └─ handoff ──┐
  │                 ▼
  └──▶ Agent(reviewer) → security/quality check → score → gate decision
       └─ handoff ──┐
                    ▼
Engine: ✅ complete  or  ⏸ paused (if score below gate)
```

Each role receives the previous role's **handoff** — structured data containing design decisions, changed files, test results, or review scores. No context is lost between roles.

## Project Structure

```
crewkit/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest
│   └── marketplace.json      # Marketplace catalog
├── skills/                   # Plugin skill entry points
│   ├── crew/SKILL.md         # /crew engine — command routing & pipeline orchestration
│   ├── crewkit-planner/      # Design, architecture, debugging
│   ├── crewkit-builder/      # TDD implementation
│   ├── crewkit-reviewer/     # Code review & quality gates
│   ├── crewkit-tester/       # Testing & QA
│   └── crewkit-shipper/      # Release & retrospective
├── engine/                   # Engine support files
│   ├── state.sh              # Pipeline state management helpers
│   ├── pipeline.md           # Pipeline execution spec
│   ├── monitor.md            # Status bar rendering spec
│   └── handoff.md            # Role-to-role data contract
├── roles/                    # Role reference (legacy/manual install)
├── presets/                  # Pipeline preset definitions
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
