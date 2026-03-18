# Diagnose Preset

## Pipeline
```
runbook
```

## Used By
- `/crew diagnose`

## Description
Incident investigation and system diagnostics. No code changes, just analysis and recommendations.

## Role Configuration

### runbook
- Mode: auto-detect based on input
  - Symptom description → **investigate** mode
  - No specific symptom → **diagnose** mode (health check all services)
  - Request ID or timestamp → **correlate** mode
- Uses service definitions from `.crewkit.yml` runbook config
- Output: investigation report with findings, timeline, root cause, remediation
- No gate check (standalone — always reports, never pauses)
