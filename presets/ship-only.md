# Ship Only Preset

## Pipeline
```
reviewer → tester → shipper
```

## Used By
- `/crew ship`

## Description
Release pipeline — review, test, and ship. Use when implementation is complete and ready for release.

## Role Configuration

### reviewer
- Full checklist with strict gate (B recommended for releases)
- Review all commits since last release

### tester
- Mode: full (unit + diff-qa + browse)
- All tests must pass, coverage must meet threshold

### shipper
- Pre-flight check required
- Version bump + changelog
- PR creation based on strategy
- Post-ship retrospective
