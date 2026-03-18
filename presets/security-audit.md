# Security Audit Preset

## Pipeline
```
security
```

## Used By
- `/crew audit`

## Description
Standalone security audit on current git diff or entire codebase. No code changes, just analysis and reporting.

## Role Configuration

### security
- OWASP Top 10 scan on changed files
- Dependency vulnerability check (npm audit / pip audit / go vuln check)
- Secrets detection (hardcoded API keys, passwords, tokens)
- Auth/AuthZ flow verification
- Output: security report with PASS/WARN/FAIL verdict
- No gate check (standalone — always reports, never pauses)
