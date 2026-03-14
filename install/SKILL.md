---
name: crewkit-install
version: 0.1.0
description: |
  Interactive installer for Crewkit — guides users through setup within Claude Code.
  Handles /crew install, /crew update, /crew uninstall, /crew doctor, /crew config.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# Crewkit Installer

## /crew install

### Flow

```
[crewkit] install │ ██░░░░░░░░ 1/4 │ 환경 확인 중...
```

#### Step 1: Environment Check
- [ ] Claude Code detected
- [ ] Git installed
- [ ] Bun installed (if not, offer to install)

#### Step 2: Install Crewkit
```bash
# Global install
git clone https://github.com/crewkit/crewkit.git ~/.claude/skills/crewkit

# Project install
cp -Rf ~/.claude/skills/crewkit .claude/skills/crewkit
rm -rf .claude/skills/crewkit/.git
```

#### Step 3: Build Browser Binary
```bash
cd ~/.claude/skills/crewkit
bun install
bun build ./roles/tester/browse/src/index.ts --compile --outfile ./roles/tester/browse/dist/browse
```

#### Step 4: Register in Settings
Add crewkit skill path to `~/.claude/settings.json` or project `.claude/settings.json`.

#### Step 5: Interactive Configuration
Ask user (one at a time):
1. Install scope: global or project?
2. Default reviewer gate: A / B / C?
3. Enable browser testing: Y / n?
4. Ship strategy: pr / auto-merge?

Generate `.crewkit.yml` from answers.

### Completion
```
✅ Crewkit 설치 완료! /crew build 로 시작하세요.
```

---

## /crew update

```bash
cd ~/.claude/skills/crewkit
git pull origin main
bun install
# Rebuild browser binary if needed
```

---

## /crew uninstall

1. Remove skill directory
2. Clean settings.json reference
3. Optionally remove .crewkit.yml

---

## /crew config

Interactive `.crewkit.yml` editor:
1. Read current config (or create new)
2. Show current values
3. Ask what to change (one at a time)
4. Write updated config

---

## /crew doctor

### Checks
```
[crewkit] doctor

  환경:
    ✓/✗ Claude Code
    ✓/✗ Git
    ✓/✗ Bun
    ✓/✗ Chromium binary

  설정:
    ✓/✗ skills/crewkit/ 존재
    ✓/✗ settings.json 등록
    ✓/✗ .crewkit.yml 유효

  역할:
    ✓/✗ planner   loaded
    ✓/✗ builder   loaded
    ✓/✗ reviewer  loaded
    ✓/✗ tester    loaded
    ✓/✗ shipper   loaded

  ✅ 모든 항목 정상 / ❌ N개 문제 발견
```

For each failure, suggest the fix command.
