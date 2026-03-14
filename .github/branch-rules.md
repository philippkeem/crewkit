# Branch Protection Rules

This document describes the branch protection configuration for the crewkit repository.
Apply these rules via **GitHub Settings > Branches > Branch protection rules**.

---

## Main Branch Protection

### Rule: `main`

Go to: `Settings > Branches > Add branch protection rule`

**Branch name pattern:** `main`

#### Pull Request Requirements

| Setting | Value | Why |
|---------|-------|-----|
| Require a pull request before merging | ON | No direct pushes to main |
| Required approving reviews | 1 | At least one reviewer |
| Dismiss stale pull request approvals | ON | New pushes invalidate old approvals |
| Require review from Code Owners | ON | CODEOWNERS file enforces ownership |

#### Status Checks

| Setting | Value | Why |
|---------|-------|-----|
| Require status checks to pass | ON | CI must be green |
| Require branches to be up to date | ON | PR must be rebased on latest main |
| Required checks | `validate` | The CI job name from `.github/workflows/ci.yml` |

#### Merge Strategy

| Setting | Value | Why |
|---------|-------|-----|
| Require linear history | ON | Forces squash merge, no merge commits |
| Allow squash merging | ON | One commit per PR |
| Allow merge commits | OFF | Keeps history clean |
| Allow rebase merging | OFF | Squash is the standard |

#### Safety

| Setting | Value | Why |
|---------|-------|-----|
| Allow force pushes | OFF | Prevents history rewriting |
| Allow deletions | OFF | Prevents accidental branch deletion |
| Lock branch | OFF | Keep it open for PRs |
| Require signed commits | OFF | Optional, can enable later |

---

## Branch Naming Convention

All branches must follow this naming pattern:

```
<type>/<issue-number>-<short-description>
```

### Types

| Type | Purpose | Example |
|------|---------|---------|
| `feat/` | New feature | `feat/12-pipeline-engine` |
| `fix/` | Bug fix | `fix/34-router-null-check` |
| `docs/` | Documentation | `docs/api-reference` |
| `chore/` | CI, config, refactor | `chore/eslint-setup` |
| `perf/` | Performance improvement | `perf/monitor-rendering` |
| `test/` | Test additions/changes | `test/planner-unit-tests` |
| `release/` | Release preparation | `release/v0.2.0` |

### Rules

- Lowercase only
- Words separated by hyphens (`-`)
- Include issue number when an issue exists
- Keep descriptions short (2-4 words)

---

## Setup Instructions (Step by Step)

### 1. Enable Branch Protection

```
GitHub repo page
  → Settings (tab)
  → Branches (sidebar)
  → Add branch protection rule
  → Branch name pattern: main
```

### 2. Configure Protection Settings

Check the following boxes:

```
[x] Require a pull request before merging
    [x] Require approvals: 1
    [x] Dismiss stale pull request approvals when new commits are pushed
    [x] Require review from Code Owners

[x] Require status checks to pass before merging
    [x] Require branches to be up to date before merging
    Search and add: "validate"

[x] Require linear history

[ ] Allow force pushes          ← leave unchecked
[ ] Allow deletions             ← leave unchecked
```

### 3. Configure Merge Settings

```
GitHub repo page
  → Settings (tab)
  → General (sidebar)
  → Pull Requests section

[x] Allow squash merging
    Default commit message: Pull request title and description

[ ] Allow merge commits         ← uncheck
[ ] Allow rebase merging        ← uncheck

[x] Automatically delete head branches
```

### 4. Verify

Create a test branch, push, and verify:
- Direct push to `main` is blocked
- PR requires CI to pass
- PR requires 1 approval
- Only squash merge is available

---

## Enforcing Branch Names (Optional)

GitHub doesn't natively enforce branch name patterns, but you can:

1. **Pre-push hook** (local enforcement):
   ```bash
   # .git/hooks/pre-push
   branch=$(git symbolic-ref --short HEAD)
   pattern="^(feat|fix|docs|chore|perf|test|release)/"
   if [[ ! "$branch" =~ $pattern ]] && [[ "$branch" != "main" ]]; then
     echo "Branch name '$branch' doesn't match pattern: $pattern"
     exit 1
   fi
   ```

2. **GitHub Actions** (CI enforcement):
   Add a step in `ci.yml` that checks the branch name on PRs.
