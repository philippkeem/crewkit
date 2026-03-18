# Deployment Verification Patterns

## Health Check Strategies

### HTTP Health Endpoint
```typescript
// Basic health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: process.env.APP_VERSION });
});

// Deep health check (checks dependencies)
app.get('/health/deep', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    cache: await checkRedis(),
    queue: await checkQueue(),
  };
  const allHealthy = Object.values(checks).every(c => c.status === 'ok');
  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? 'ok' : 'degraded',
    checks,
    version: process.env.APP_VERSION,
  });
});
```

### Health Check Polling After Deploy
```bash
# Poll until healthy or timeout
MAX_ATTEMPTS=30
INTERVAL=10
URL="https://app.example.com/health"

for i in $(seq 1 $MAX_ATTEMPTS); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  if [ "$STATUS" = "200" ]; then
    echo "Health check passed on attempt $i"
    exit 0
  fi
  echo "Attempt $i: status $STATUS, retrying in ${INTERVAL}s..."
  sleep $INTERVAL
done

echo "Health check failed after $MAX_ATTEMPTS attempts"
exit 1
```

### Version Verification
```bash
# Confirm the deployed version matches what was released
EXPECTED_VERSION="2.3.0"
DEPLOYED_VERSION=$(curl -s https://app.example.com/health | jq -r '.version')

if [ "$DEPLOYED_VERSION" = "$EXPECTED_VERSION" ]; then
  echo "Version verified: $DEPLOYED_VERSION"
else
  echo "Version mismatch! Expected $EXPECTED_VERSION, got $DEPLOYED_VERSION"
  exit 1
fi
```

## Smoke Test Patterns

Smoke tests verify critical paths work after deploy. They run against production
with real infrastructure but use test accounts.

### Critical Path Checklist
```
[ ] Homepage loads (GET / returns 200)
[ ] Login works (POST /auth/login returns token)
[ ] Core API responds (GET /api/items returns data)
[ ] Database reads work (list endpoint returns results)
[ ] Database writes work (create and delete test item)
[ ] Static assets load (CSS, JS bundles return 200)
[ ] Third-party integrations respond (payment, email, etc.)
```

### Smoke Test Script
```bash
BASE_URL="https://app.example.com"

# Test homepage
curl -sf "$BASE_URL/" > /dev/null || { echo "FAIL: Homepage"; exit 1; }

# Test API health
curl -sf "$BASE_URL/health" > /dev/null || { echo "FAIL: Health"; exit 1; }

# Test auth endpoint
TOKEN=$(curl -sf -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"smoke@test.com","password":"smoketest"}' \
  | jq -r '.token')
[ -n "$TOKEN" ] || { echo "FAIL: Auth"; exit 1; }

# Test authenticated endpoint
curl -sf -H "Authorization: Bearer $TOKEN" \
  "$BASE_URL/api/me" > /dev/null || { echo "FAIL: Auth API"; exit 1; }

echo "All smoke tests passed"
```

## Rollback Automation

### Rollback Triggers
- Health check fails after MAX_ATTEMPTS
- Error rate exceeds threshold (e.g., >5% 5xx responses)
- Smoke tests fail
- Manual trigger by operator

### Rollback Strategies

| Strategy | How | When |
|----------|-----|------|
| **Revert deploy** | Deploy previous version | Container/serverless platforms |
| **Git revert** | Revert merge commit, re-deploy | Git-based deploy pipelines |
| **Feature flag** | Disable new feature, keep deploy | Feature-flagged changes |
| **Database rollback** | Run down migration | Schema changes (risky) |

### Container Rollback
```bash
# Kubernetes: rollback to previous revision
kubectl rollout undo deployment/app

# Verify rollback
kubectl rollout status deployment/app

# Docker Compose: deploy previous image
docker compose pull  # pulls previous tag
docker compose up -d
```

### Git-Based Rollback
```bash
# Revert the merge commit
git revert -m 1 <merge-commit-sha>
git push origin main

# CI/CD will auto-deploy the reverted state
```

## Gradual Rollout

### Canary Deployment
```
1. Deploy new version to 5% of traffic
2. Monitor error rates for 10 minutes
3. If error rate < threshold → increase to 25%
4. Monitor for 10 minutes
5. If error rate < threshold → increase to 100%
6. If error rate exceeds threshold at any stage → rollback to 0%
```

### Feature Flag Rollout
```typescript
// Gradual rollout via feature flag
const flag = await getFeatureFlag('new-search');

// flag.rolloutPercentage: 0 → 5 → 25 → 50 → 100
if (flag.isEnabled(userId)) {
  return newSearchImplementation(query);
} else {
  return oldSearchImplementation(query);
}
```

### Monitoring During Rollout
Key metrics to watch:
- **Error rate**: 5xx responses (threshold: <1%)
- **Latency**: p50 and p99 response times (no more than 20% increase)
- **Throughput**: Requests per second (should stay stable)
- **Business metrics**: Conversion rate, signup rate (no unexpected drops)

## Post-Deploy Verification Checklist

```
Immediate (0-5 min):
[ ] Health endpoint returns 200
[ ] Correct version deployed
[ ] Smoke tests pass
[ ] No spike in error logs

Short-term (5-30 min):
[ ] Error rate stable
[ ] Latency stable
[ ] No increase in support tickets
[ ] Background jobs processing normally

Medium-term (30 min - 2 hours):
[ ] Business metrics normal
[ ] No memory leaks (RSS stable)
[ ] No connection pool exhaustion
[ ] Scheduled jobs complete successfully
```

## Common Mistakes

- Skipping version verification (deploying the wrong artifact)
- Running smoke tests against staging instead of production
- No automated rollback — relying on humans to notice and act
- Monitoring only server errors, ignoring client-side errors
- Rolling out 100% immediately without canary phase
