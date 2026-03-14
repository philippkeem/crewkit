# Doctor — Environment Diagnostics

## Check Categories

### 1. Runtime Dependencies

| Check | Command | Fix |
|-------|---------|-----|
| Claude Code | `claude --version` | Install from https://claude.com/claude-code |
| Git | `git --version` | `brew install git` / system package manager |
| Bun | `bun --version` | `curl -fsSL https://bun.sh/install \| bash` |

### 2. Crewkit Installation

| Check | Method | Fix |
|-------|--------|-----|
| Skill directory | Check `~/.claude/skills/crewkit/` exists | `/crew install` |
| Settings registered | Parse `settings.json` for crewkit path | Add path to settings |
| Config valid | Parse `.crewkit.yml` YAML syntax | `/crew config` to regenerate |

### 3. Browser Binary

| Check | Method | Fix |
|-------|--------|-----|
| Binary exists | Check `roles/tester/browse/dist/browse` | `cd crewkit && bun build ...` |
| Binary runs | Execute with `--version` flag | Rebuild with `bun build` |

### 4. Role Files

For each role (planner, builder, reviewer, tester, shipper):
- Check `roles/<name>/SKILL.md` exists
- Validate YAML frontmatter
- Check required fields (name, version, description, allowed-tools)

## Output Format

```
[crewkit] doctor

  환경:
    ✓ Claude Code v1.x
    ✓ Git 2.x
    ✓ Bun 1.2.x
    ✗ Chromium binary missing
      → Fix: cd ~/.claude/skills/crewkit && bun build ...

  ✅ 4/5 checks passed, 1 issue found
```
