# Version Strategy Guide

## Semver vs Calver Decision

### Semantic Versioning (Semver): `MAJOR.MINOR.PATCH`

Use semver when:
- You publish a library or API that others depend on
- Breaking changes need explicit signaling
- Consumers need to pin compatible version ranges

| Component | When to bump | Example |
|-----------|-------------|---------|
| MAJOR | Breaking change to public API | Remove endpoint, rename field |
| MINOR | New feature, backward compatible | Add endpoint, add optional field |
| PATCH | Bug fix, no behavior change | Fix calculation, fix typo |

### Calendar Versioning (Calver): `YYYY.MM.DD` or `YYYY.MM.PATCH`

Use calver when:
- You deploy a web app or service (no external consumers of your version)
- Releases are time-based, not feature-based
- You want deployment dates visible in version numbers

| Format | Example | Use case |
|--------|---------|----------|
| `YYYY.MM.DD` | `2025.03.19` | Single deploy per day |
| `YYYY.MM.PATCH` | `2025.03.2` | Multiple deploys per month |
| `YYYY.WW.PATCH` | `2025.12.1` | Weekly release cadence |

### Decision Matrix

| Factor | Choose Semver | Choose Calver |
|--------|--------------|--------------|
| Public library/API | Yes | — |
| Internal web app | — | Yes |
| Breaking changes matter to consumers | Yes | — |
| Time-based release cadence | — | Yes |
| Need to communicate compatibility | Yes | — |

## Automatic Bump Detection from Commits

Detect version bump type by scanning commit messages since last tag:

### Conventional Commits Pattern
```
feat: add user search         → MINOR
fix: correct price calc       → PATCH
feat!: redesign auth API      → MAJOR
BREAKING CHANGE: remove v1    → MAJOR
docs: update readme           → no bump (or PATCH)
chore: update deps            → PATCH
```

### Detection Algorithm
```bash
# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LAST_TAG" ]; then
  COMMITS=$(git log --oneline)
else
  COMMITS=$(git log --oneline "$LAST_TAG"..HEAD)
fi

# Check for breaking changes first (MAJOR)
if echo "$COMMITS" | grep -qiE "BREAKING|feat!|fix!"; then
  echo "MAJOR"
# Check for features (MINOR)
elif echo "$COMMITS" | grep -qiE "^[a-f0-9]+ feat"; then
  echo "MINOR"
# Default to PATCH
else
  echo "PATCH"
fi
```

### Bump Calculation
```
Current: 2.3.1
Detected: MINOR
Next: 2.4.0  (minor bumps, patch resets to 0)

Current: 2.3.1
Detected: MAJOR
Next: 3.0.0  (major bumps, minor and patch reset to 0)
```

## Pre-release Versions

Use pre-release tags for testing before official release:

| Type | Format | Purpose |
|------|--------|---------|
| Alpha | `1.2.0-alpha.1` | Internal testing, unstable |
| Beta | `1.2.0-beta.1` | External testing, feature-complete |
| RC | `1.2.0-rc.1` | Release candidate, bug fixes only |

### Pre-release Workflow
```bash
# Create pre-release
git tag v1.2.0-beta.1
git push origin v1.2.0-beta.1

# Iterate on feedback
git tag v1.2.0-beta.2

# Promote to release
git tag v1.2.0
git push origin v1.2.0
```

### npm Pre-release
```bash
# Publish with dist-tag so it's not installed by default
npm publish --tag beta

# Users opt in:
npm install mypackage@beta
```

## Tagging and Release Checklist

```
1. [ ] Determine bump type (major/minor/patch) from commits
2. [ ] Update version in package.json / pyproject.toml / Cargo.toml
3. [ ] Update CHANGELOG.md with release notes
4. [ ] Commit: "chore: bump version to X.Y.Z"
5. [ ] Create git tag: git tag vX.Y.Z
6. [ ] Push tag: git push origin vX.Y.Z
7. [ ] CI publishes package / creates GitHub release
8. [ ] Verify published artifact
```

## Common Mistakes

- Bumping MAJOR for internal changes that don't affect the public API
- Forgetting to reset PATCH to 0 when bumping MINOR
- Using semver for applications (calver is simpler for deploy tracking)
- Skipping pre-release for major version bumps
- Not tagging the exact commit that was tested
