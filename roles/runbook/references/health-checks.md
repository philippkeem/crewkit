# Health Check Patterns

## HTTP Health Endpoints

### Liveness vs Readiness

| Check | Purpose | Failure Action |
|-------|---------|---------------|
| **Liveness** (`/healthz`) | Is the process alive? | Restart the container |
| **Readiness** (`/readyz`) | Can it serve traffic? | Remove from load balancer |

A service can be alive but not ready (e.g., still warming cache).

### Node.js (Express)
```typescript
app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'alive' });
});

app.get('/readyz', async (req, res) => {
  try {
    await db.query('SELECT 1');
    await redis.ping();
    res.status(200).json({ status: 'ready' });
  } catch (err) {
    res.status(503).json({ status: 'not ready', error: err.message });
  }
});
```

### Python (FastAPI)
```python
@app.get("/healthz")
def liveness():
    return {"status": "alive"}

@app.get("/readyz")
async def readiness():
    checks = {}
    try:
        await database.execute("SELECT 1")
        checks["database"] = "ok"
    except Exception as e:
        checks["database"] = str(e)

    try:
        await redis_client.ping()
        checks["cache"] = "ok"
    except Exception as e:
        checks["cache"] = str(e)

    all_ok = all(v == "ok" for v in checks.values())
    status_code = 200 if all_ok else 503
    return JSONResponse({"status": "ready" if all_ok else "degraded", "checks": checks},
                       status_code=status_code)
```

### Go
```go
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]string{"status": "alive"})
})

http.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
    if err := db.Ping(); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]string{"status": "not ready", "error": err.Error()})
        return
    }
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]string{"status": "ready"})
})
```

## Database Connectivity

### PostgreSQL
```bash
# CLI check
pg_isready -h localhost -p 5432

# Query check
psql -c "SELECT 1" -h localhost -U postgres
```

### In application code
```typescript
async function checkDatabase(): Promise<HealthResult> {
  const start = Date.now();
  try {
    await db.query('SELECT 1');
    return { status: 'ok', latencyMs: Date.now() - start };
  } catch (err) {
    return { status: 'error', error: err.message, latencyMs: Date.now() - start };
  }
}
```

### Warning thresholds
- Query latency > 100ms: warn (usually < 5ms for SELECT 1)
- Connection pool > 80% used: warn
- Connection pool exhausted: critical

## Queue Depth

### Check queue size
```typescript
// Bull/BullMQ (Redis-based)
async function checkQueue(): Promise<HealthResult> {
  const waiting = await queue.getWaitingCount();
  const active = await queue.getActiveCount();
  const failed = await queue.getFailedCount();

  const status = waiting > 1000 ? 'warning' : 'ok';
  return { status, waiting, active, failed };
}
```

### Warning thresholds
- Queue depth growing steadily: consumers can't keep up
- Failed jobs > 0: check for poison messages
- Queue depth > 10x normal: something is producing too fast or consuming too slow

## Memory and Disk Checks

### Memory (Node.js)
```typescript
function checkMemory(): HealthResult {
  const usage = process.memoryUsage();
  const heapUsedMB = Math.round(usage.heapUsed / 1024 / 1024);
  const heapTotalMB = Math.round(usage.heapTotal / 1024 / 1024);
  const percent = Math.round((usage.heapUsed / usage.heapTotal) * 100);

  return {
    status: percent > 90 ? 'warning' : 'ok',
    heapUsedMB,
    heapTotalMB,
    percent,
  };
}
```

### Disk (Bash)
```bash
# Check disk usage percentage
USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$USAGE" -gt 90 ]; then
  echo "CRITICAL: Disk usage at ${USAGE}%"
elif [ "$USAGE" -gt 80 ]; then
  echo "WARNING: Disk usage at ${USAGE}%"
else
  echo "OK: Disk usage at ${USAGE}%"
fi
```

### Warning thresholds
| Resource | Warning | Critical |
|----------|---------|----------|
| Heap memory | > 80% | > 95% |
| RSS memory | > 80% of limit | > 90% of limit |
| Disk usage | > 80% | > 90% |
| Open file descriptors | > 80% of ulimit | > 90% of ulimit |

## Aggregate Health Response

Combine all checks into a single endpoint:

```typescript
app.get('/health', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    cache: await checkRedis(),
    queue: await checkQueue(),
    memory: checkMemory(),
  };

  const worstStatus = Object.values(checks).reduce((worst, check) => {
    const order = { ok: 0, warning: 1, error: 2 };
    return order[check.status] > order[worst] ? check.status : worst;
  }, 'ok');

  const statusCode = worstStatus === 'error' ? 503 : 200;
  res.status(statusCode).json({ status: worstStatus, checks });
});
```

## Monitoring Checklist

```
[ ] Liveness endpoint responds (container orchestrator uses this)
[ ] Readiness endpoint checks all dependencies
[ ] Health checks have timeouts (don't hang forever)
[ ] Health checks don't do expensive work (fast and lightweight)
[ ] Metrics exported for alerting (Prometheus, Datadog, etc.)
[ ] Alerts configured for critical thresholds
[ ] Dashboard shows current health at a glance
```
