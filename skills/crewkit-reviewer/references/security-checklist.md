# Security Checklist — OWASP-Based Review Guide

## How to Use This Checklist

For every code review, scan for these categories. Mark each as PASS, FAIL, or N/A.
Any FAIL is a blocking issue — the PR cannot merge until resolved.

## 1. Injection (SQL, NoSQL, Command)

### Bad — String concatenation in queries
```python
# VULNERABLE: SQL injection
def get_user(name):
    query = f"SELECT * FROM users WHERE name = '{name}'"
    cursor.execute(query)
```

### Good — Parameterized queries
```python
# SAFE: Parameterized query
def get_user(name):
    cursor.execute("SELECT * FROM users WHERE name = %s", (name,))
```

### What to look for
- String interpolation in SQL/NoSQL queries
- `exec()`, `eval()`, `child_process.exec()` with user input
- ORM raw query methods without parameter binding

## 2. Cross-Site Scripting (XSS)

### Bad — Unescaped output
```jsx
// VULNERABLE: dangerouslySetInnerHTML with user data
<div dangerouslySetInnerHTML={{ __html: userComment }} />
```

### Good — Escaped or sanitized output
```jsx
// SAFE: React auto-escapes by default
<div>{userComment}</div>

// SAFE: Sanitized if HTML is truly needed
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userComment) }} />
```

### What to look for
- `dangerouslySetInnerHTML`, `v-html`, `innerHTML` with user data
- Template literals rendered as HTML
- User input reflected in error messages without escaping

## 3. Authentication Bypass

### Bad — Client-side auth check only
```typescript
// VULNERABLE: Only checks on frontend
if (user.role === 'admin') {
  showAdminPanel();
}
// API endpoint has no auth check
app.get('/admin/users', (req, res) => {
  res.json(getAllUsers()); // Anyone can call this directly
});
```

### Good — Server-side enforcement
```typescript
// SAFE: Middleware enforces auth
app.get('/admin/users', requireRole('admin'), (req, res) => {
  res.json(getAllUsers());
});
```

### What to look for
- API routes without auth middleware
- Role checks only on the frontend
- JWT validation that doesn't check expiration
- Password comparison not using constant-time comparison

## 4. Insecure Direct Object Reference (IDOR)

### Bad — No ownership check
```typescript
// VULNERABLE: Any logged-in user can access any order
app.get('/orders/:id', auth, async (req, res) => {
  const order = await db.orders.findById(req.params.id);
  res.json(order);
});
```

### Good — Ownership verification
```typescript
// SAFE: Verify the order belongs to the requesting user
app.get('/orders/:id', auth, async (req, res) => {
  const order = await db.orders.findById(req.params.id);
  if (!order) return res.status(404).json({ error: 'Not found' });
  if (order.userId !== req.user.id) return res.status(403).json({ error: 'Forbidden' });
  res.json(order);
});
```

### What to look for
- Database lookups using only the URL parameter (no user filter)
- File access using user-provided paths
- API endpoints that return data without checking ownership

## 5. Security Misconfiguration

### What to look for
- Debug mode enabled in production configs
- Default credentials in config files
- CORS set to `*` (allow all origins)
- Sensitive data in error messages returned to client
- Missing security headers (CSP, HSTS, X-Frame-Options)

## Review Checklist Summary

```
[ ] No string interpolation in queries (use parameterized)
[ ] No unescaped user input in HTML output
[ ] All API routes have server-side auth checks
[ ] Resource access checks ownership, not just authentication
[ ] No secrets or credentials in source code
[ ] CORS configured to specific origins (not *)
[ ] Error messages don't leak internal details
[ ] File uploads validate type and size
[ ] Rate limiting on auth endpoints
[ ] HTTPS enforced, no mixed content
```

## Automatic FAIL Triggers

Any one of these is an automatic D score and blocks the PR:
- SQL/NoSQL injection vector
- Hardcoded credentials or API keys
- Auth bypass (missing middleware on protected route)
- Unescaped user input rendered as HTML
- Secrets committed to version control
