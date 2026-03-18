# OWASP Top 10 — Code Examples

## A01: Broken Access Control

### Vulnerable
```python
# No authorization check — any user can access any profile
@app.get("/users/{user_id}/profile")
def get_profile(user_id: int):
    return db.query(User).filter(User.id == user_id).first()
```

### Fixed
```python
@app.get("/users/{user_id}/profile")
def get_profile(user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Forbidden")
    return db.query(User).filter(User.id == user_id).first()
```

## A02: Cryptographic Failures

### Vulnerable
```python
# Storing passwords in plain text
def create_user(email: str, password: str):
    db.execute("INSERT INTO users (email, password) VALUES (%s, %s)",
               (email, password))
```

### Fixed
```python
import bcrypt

def create_user(email: str, password: str):
    hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt())
    db.execute("INSERT INTO users (email, password_hash) VALUES (%s, %s)",
               (email, hashed.decode()))
```

## A03: Injection

### SQL Injection — Vulnerable
```typescript
// String interpolation in query
app.get('/search', (req, res) => {
  const query = `SELECT * FROM products WHERE name LIKE '%${req.query.q}%'`;
  db.query(query).then(results => res.json(results));
});
```

### SQL Injection — Fixed
```typescript
app.get('/search', (req, res) => {
  db.query('SELECT * FROM products WHERE name LIKE $1', [`%${req.query.q}%`])
    .then(results => res.json(results));
});
```

## A04: Insecure Design (IDOR)

### Vulnerable
```typescript
// Fetches any order by ID without ownership check
app.get('/orders/:id', auth, async (req, res) => {
  const order = await Order.findById(req.params.id);
  res.json(order);
});
```

### Fixed
```typescript
app.get('/orders/:id', auth, async (req, res) => {
  const order = await Order.findOne({
    _id: req.params.id,
    userId: req.user.id,  // Scoped to authenticated user
  });
  if (!order) return res.status(404).json({ error: 'Not found' });
  res.json(order);
});
```

## A05: Security Misconfiguration

### Vulnerable
```typescript
// CORS allows all origins
app.use(cors({ origin: '*' }));

// Debug info in production errors
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.message, stack: err.stack });
});
```

### Fixed
```typescript
app.use(cors({ origin: ['https://app.example.com'], credentials: true }));

app.use((err, req, res, next) => {
  console.error(err);  // Log internally
  res.status(500).json({ error: 'Internal server error' });  // Generic to client
});
```

## A06: Vulnerable Components

See `dependency-audit.md` for ecosystem-specific audit tooling.

## A07: Authentication Failures

### Vulnerable
```python
# No rate limiting on login
@app.post("/login")
def login(email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if user and user.password == password:  # Plain text comparison
        return {"token": create_token(user.id)}
    raise HTTPException(status_code=401)
```

### Fixed
```python
from slowapi import Limiter

limiter = Limiter(key_func=get_remote_address)

@app.post("/login")
@limiter.limit("5/minute")
def login(email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if user and bcrypt.checkpw(password.encode(), user.password_hash.encode()):
        return {"token": create_token(user.id)}
    # Generic message — don't reveal if email exists
    raise HTTPException(status_code=401, detail="Invalid credentials")
```

## A08: Software and Data Integrity

### Vulnerable
```javascript
// Loading script from CDN without integrity check
<script src="https://cdn.example.com/lib.js"></script>
```

### Fixed
```html
<script src="https://cdn.example.com/lib.js"
  integrity="sha384-abc123..."
  crossorigin="anonymous"></script>
```

## A09: Logging and Monitoring Failures

### Vulnerable
```python
# No logging of security events
@app.post("/login")
def login(credentials):
    user = authenticate(credentials)
    if not user:
        raise HTTPException(401)  # Silent failure
    return create_session(user)
```

### Fixed
```python
import logging
security_log = logging.getLogger("security")

@app.post("/login")
def login(credentials, request: Request):
    user = authenticate(credentials)
    if not user:
        security_log.warning(f"Failed login attempt for {credentials.email} "
                           f"from {request.client.host}")
        raise HTTPException(401)
    security_log.info(f"Successful login for {user.email}")
    return create_session(user)
```

## A10: Server-Side Request Forgery (SSRF)

### Vulnerable
```python
# User-controlled URL fetched by server
@app.post("/fetch-url")
def fetch_url(url: str):
    response = requests.get(url)  # Can access internal services!
    return response.text
```

### Fixed
```python
from urllib.parse import urlparse
ALLOWED_HOSTS = {"api.example.com", "cdn.example.com"}

@app.post("/fetch-url")
def fetch_url(url: str):
    parsed = urlparse(url)
    if parsed.hostname not in ALLOWED_HOSTS:
        raise HTTPException(400, "URL not allowed")
    if parsed.scheme not in ("http", "https"):
        raise HTTPException(400, "Invalid scheme")
    response = requests.get(url, timeout=5)
    return response.text
```

## Quick Reference

| Category | Key Check |
|----------|-----------|
| A01 Access Control | Every endpoint checks authorization, not just authentication |
| A02 Crypto | Passwords hashed with bcrypt/argon2, secrets not in code |
| A03 Injection | All queries parameterized, no string interpolation |
| A04 Insecure Design | Resource access scoped to authenticated user |
| A05 Misconfig | No debug in prod, CORS restricted, generic errors |
| A07 Auth Failures | Rate limiting, constant-time comparison, generic messages |
| A09 Logging | Security events logged with IP, email, timestamp |
| A10 SSRF | URL allowlist, no internal network access from user input |
