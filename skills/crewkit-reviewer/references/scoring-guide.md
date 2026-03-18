# Scoring Guide — Review Quality Ratings

## Score Definitions

| Score | Meaning | Action |
|-------|---------|--------|
| **A** | Excellent — merge as-is or with nits only | Approve and merge |
| **B** | Good — minor issues that should be fixed | Approve with comments, author fixes and merges |
| **C** | Needs work — significant issues | Request changes, re-review required |
| **D** | Unacceptable — critical issues | Block merge, requires substantial rework |

## Score A — Excellent

The code is correct, secure, well-tested, and follows project conventions.

### Example A code
```typescript
// Clear naming, proper error handling, tested edge cases
export async function getUser(id: string): Promise<User | null> {
  if (!isValidUuid(id)) return null;

  const user = await db.users.findUnique({ where: { id } });
  return user;
}

// Corresponding test covers happy path + edge cases
test('returns null for invalid uuid', () => { ... });
test('returns null for non-existent user', () => { ... });
test('returns user for valid id', () => { ... });
```

An A score still permits nit-level comments (rename suggestion, minor style).

## Score B — Good

The code works and is safe, but has issues worth addressing.

### Example B issues
- Missing test for an edge case that's unlikely but possible
- Function is longer than ideal (could extract a helper)
- Error message could be more descriptive
- Inconsistent with project patterns but not incorrect

```typescript
// Works, but could be cleaner
export async function getUser(id: string) {
  // B issue: no input validation — should check uuid format
  const user = await db.users.findUnique({ where: { id } });
  if (!user) {
    // B issue: generic error, could be more specific
    throw new Error('not found');
  }
  return user;
}
```

## Score C — Needs Work

The code has issues that affect correctness, reliability, or maintainability.

### Example C issues
- Missing error handling for a likely failure mode
- Business logic error (wrong calculation, off-by-one)
- No tests for the main feature being added
- Breaking API change without migration
- Performance issue under expected load

```typescript
// C: Race condition — two concurrent calls could create duplicate orders
export async function createOrder(userId: string, items: Item[]) {
  const existing = await db.orders.findFirst({
    where: { userId, status: 'pending' }
  });
  // C: Gap between check and create allows duplicates
  if (!existing) {
    return db.orders.create({ data: { userId, items, status: 'pending' } });
  }
  return existing;
}
```

## Score D — Unacceptable

The code has critical issues that would cause real harm in production.

### Example D issues
- Security vulnerability (injection, auth bypass, data exposure)
- Data loss or corruption possible
- Completely untested change to critical path
- Hardcoded secrets or credentials

```typescript
// D: SQL injection — user input directly in query
app.get('/search', (req, res) => {
  const results = db.raw(`SELECT * FROM products WHERE name LIKE '%${req.query.q}%'`);
  res.json(results);
});
```

## Automatic D Triggers

These are always a D, regardless of other code quality:

- SQL/NoSQL injection vector
- Hardcoded secrets (API keys, passwords, tokens)
- Authentication bypass (missing auth middleware on protected route)
- Unescaped user content rendered as HTML (XSS)
- `eval()` or `exec()` with user-controlled input
- Sensitive data logged or exposed in error responses
- File path traversal with user input

## Edge Cases in Scoring

### "Code works but has no tests" → C
Even if the code is correct today, untested code will break silently later.

### "Tests pass but code has a subtle bug" → C or D
Depends on impact. Wrong calculation in billing = D. Wrong sort order in a list = C.

### "Minor security issue with low exploitability" → C minimum
Security issues are never B, even if exploitation is unlikely.

### "Great code but wrong approach entirely" → C
Correct implementation of the wrong solution still needs rework.

### "Prototype/experiment explicitly marked as such" → B floor
Prototypes still need basic safety. No D-trigger issues allowed.

## Consistency Guidelines

- Score the worst issue, not the average. One D issue makes it a D.
- Compare scores across reviews. If similar issues got B last time, they're B now.
- Don't let author seniority affect scoring. Same standards for everyone.
- Document the reason for the score. "C because: missing error handling for
  payment failures (likely in production), no tests for the new endpoint."
- When in doubt between two scores, pick the lower one and explain why.

## Communicating Scores

```markdown
## Review Score: B

### Summary
Clean implementation of the search feature. Two issues to address before merge.

### Issues
1. **[Minor]** Missing test for empty search query — add a test for `q=""`
2. **[Minor]** `searchProducts` should return `[]` not `null` for no results
   (matches existing API conventions)

### Strengths
- Good use of parameterized queries
- Pagination follows existing patterns
- Clear error messages
```
