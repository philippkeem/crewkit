# Product Mode — Detailed Guide

## When to Use Product Mode

Activate product mode when the task involves feature scoping, user-facing decisions,
or trade-offs between effort and value. If the request is purely technical
(refactoring internals, fixing a bug with a known cause), use architecture or debug
mode instead.

## Step 1: Identify MVP Scope

Ask three questions:
1. What is the smallest change that delivers user value?
2. What can be deferred without blocking the core flow?
3. What assumptions are we making about user behavior?

### Example — "Add search to the dashboard"
| In MVP | Deferred |
|--------|----------|
| Text input with basic substring match | Fuzzy search, typo tolerance |
| Results list with name + status | Faceted filters, pagination |
| Loading spinner | Skeleton loaders, optimistic UI |
| Error state for empty results | Search analytics, recent searches |

## Step 2: Trade-off Analysis Template

For each scope decision, fill in:

```
Feature: <name>
Effort: S / M / L
User impact: High / Medium / Low
Risk if deferred: <what breaks or degrades>
Decision: Include / Defer / Cut
Rationale: <one sentence>
```

### Example
```
Feature: Fuzzy search
Effort: M
User impact: Medium — most users type exact names
Risk if deferred: Some users won't find items with typos
Decision: Defer
Rationale: Exact match covers 90% of use cases; add fuzzy in v2.
```

## Step 3: Structure a Design Doc

Use this outline for any feature that touches more than one file:

```markdown
## Problem
What user pain or opportunity are we addressing?

## Proposed Solution
How does it work from the user's perspective?

## Technical Approach
Key components, data flow, and API changes.

## Alternatives Considered
What else was evaluated and why it was rejected.

## Open Questions
Unresolved decisions that need input.
```

Keep it under two pages. If it's longer, the scope is too big — split it.

## Step 4: Handoff to Builder

A complete handoff includes:
1. **Task list** — ordered, each task achievable in one session
2. **Acceptance criteria** — observable behaviors, not implementation details
3. **Edge cases** — explicitly listed so the builder doesn't have to guess
4. **Out of scope** — things the builder should NOT build

### Example Handoff
```
Task: Add search to dashboard

Tasks:
1. Add SearchInput component with onChange handler
2. Filter dashboard items by substring match on name field
3. Show "No results" state when filter returns empty
4. Add unit tests for filter logic

Acceptance criteria:
- Typing in the search box filters the list in real time
- Clearing the input restores the full list
- Empty results show a message, not a blank screen

Edge cases:
- Special characters in search input (escape them)
- Very long search strings (truncate at 200 chars)

Out of scope:
- Server-side search, pagination, search history
```

## Common Mistakes

- Skipping trade-off analysis and building everything
- Writing acceptance criteria that describe implementation ("use useState")
- Forgetting to list what is out of scope
- Making the design doc a novel instead of a decision record
