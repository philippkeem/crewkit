# Dependency Audit Guide

## Overview

Audit dependencies for known vulnerabilities. Run audits as part of CI and
before every release. Each ecosystem has its own tooling.

## npm (Node.js)

### Run Audit
```bash
# Basic audit
npm audit

# JSON output for parsing
npm audit --json

# Only production dependencies
npm audit --omit=dev

# Fix automatically (safe patches only)
npm audit fix

# Fix with breaking changes (review carefully)
npm audit fix --force
```

### Interpret Results
```
# Severity levels
critical  → Remote code execution, data breach → Fix immediately
high      → Significant impact → Fix within 24 hours
moderate  → Limited impact → Fix within 1 week
low       → Minimal impact → Fix in next maintenance cycle
```

### Common Issues
- **Nested dependency vulnerability**: You don't control the direct dep. Options:
  1. `npm audit fix` — auto-update if compatible range allows
  2. `overrides` in package.json to force a specific version
  3. Open an issue on the parent package to update their dep
- **No fix available**: Add to `audit-ci` allowlist with expiration date

```json
// package.json — force nested dependency version
{
  "overrides": {
    "vulnerable-package": ">=2.0.1"
  }
}
```

### CI Integration
```bash
# Fail CI on high+ severity
npx audit-ci --high

# Or with npm native
npm audit --audit-level=high
```

## pip (Python)

### Run Audit
```bash
# Install pip-audit
pip install pip-audit

# Audit installed packages
pip-audit

# Audit from requirements file
pip-audit -r requirements.txt

# JSON output
pip-audit --format json

# Fix automatically
pip-audit --fix
```

### Using Safety (Alternative)
```bash
pip install safety
safety check
safety check -r requirements.txt
```

### Interpret Results
```
pip-audit output:
Name        Version  ID             Fix Versions
----------  -------  -------------- ------------
requests    2.25.0   PYSEC-2023-XX  2.31.0

Action: Update requests to >= 2.31.0
```

### Common Issues
- **Pinned version conflicts**: Use `pip-compile` (pip-tools) to resolve
- **Transitive dependency**: Check what depends on it with `pip show <package>`
- **No fix available**: Document the risk and set a reminder to check back

### CI Integration
```bash
# Fail CI on any vulnerability
pip-audit --strict

# Ignore specific advisories (with justification)
pip-audit --ignore-vuln PYSEC-2023-XX
```

## govulncheck (Go)

### Run Audit
```bash
# Install
go install golang.org/x/vuln/cmd/govulncheck@latest

# Audit current module
govulncheck ./...

# JSON output
govulncheck -json ./...
```

### Interpret Results
```
govulncheck output:
Vulnerability #1: GO-2023-XXXX
  Found in: golang.org/x/net@v0.1.0
  Fixed in: golang.org/x/net@v0.7.0
  Call stacks:
    main.go:15 → pkg.Function → net/http.Get

Key: Only reports vulnerabilities in code paths actually called.
If "No vulnerabilities found" but deps have CVEs, your code doesn't
reach the vulnerable functions.
```

### Fix
```bash
# Update specific dependency
go get golang.org/x/net@v0.7.0
go mod tidy

# Update all dependencies
go get -u ./...
go mod tidy
```

### CI Integration
```bash
# Fail CI on any reachable vulnerability
govulncheck ./...
# Exit code 3 = vulnerabilities found
```

## cargo audit (Rust)

### Run Audit
```bash
# Install
cargo install cargo-audit

# Run audit
cargo audit

# JSON output
cargo audit --json

# Fix automatically (updates Cargo.lock)
cargo audit fix
```

### Interpret Results
```
cargo audit output:
Crate:     smallvec
Version:   1.6.0
Title:     Buffer overflow in smallvec
ID:        RUSTSEC-2021-XXXX
URL:       https://rustsec.org/advisories/RUSTSEC-2021-XXXX
Solution:  Upgrade to >= 1.6.1
```

### Fix
```bash
# Update specific crate
cargo update -p smallvec

# Update all dependencies
cargo update

# If locked to old version in Cargo.toml, update the version requirement
```

### CI Integration
```bash
# Fail CI on any advisory
cargo audit
# Non-zero exit code on findings

# Deny specific categories
cargo audit --deny warnings --deny unmaintained
```

## Universal Audit Checklist

```
1. [ ] Run ecosystem-specific audit tool
2. [ ] Review all critical and high findings
3. [ ] Update direct dependencies with available fixes
4. [ ] For transitive deps: use override/resolution to force safe version
5. [ ] For no-fix-available: document risk and set review reminder
6. [ ] Verify fixes don't break tests
7. [ ] Add audit check to CI pipeline
8. [ ] Schedule recurring audits (weekly at minimum)
```

## Common Mistakes

- Running audit only before releases (run in CI on every PR)
- Using `--force` without reviewing what it changes
- Ignoring advisories permanently instead of setting expiration dates
- Not auditing dev dependencies (supply chain attacks target dev tooling)
- Updating major versions without running tests
