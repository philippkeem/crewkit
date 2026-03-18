# Architecture Mode — Detailed Guide

## When to Use Architecture Mode

Activate when the task involves system structure, component boundaries, data flow,
or interface contracts. Use this mode before writing code when the change touches
multiple modules or introduces new abstractions.

## Component Diagram Template

Map the system using this text format (paste into any Markdown renderer):

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client     │────▶│   API GW    │────▶│   Service   │
│  (React)     │◀────│  (Express)  │◀────│  (Worker)   │
└─────────────┘     └──────┬──────┘     └──────┬──────┘
                           │                    │
                    ┌──────▼──────┐     ┌──────▼──────┐
                    │   Cache     │     │   Database  │
                    │  (Redis)    │     │  (Postgres) │
                    └─────────────┘     └─────────────┘
```

For each box, document:
- **Responsibility**: one sentence describing what it owns
- **Inputs**: what data it receives and from where
- **Outputs**: what data it produces and to where
- **Scaling model**: stateless, sharded, replicated, or singleton

## Data Flow Mapping

Trace a single request end-to-end:

```
1. User clicks "Submit Order"
2. Client POST /api/orders { items, address }
3. API GW validates auth token → 401 if invalid
4. API GW validates request body → 400 if malformed
5. Service creates order record (status: pending)
6. Service publishes OrderCreated event to queue
7. Worker picks up event, charges payment
8. Worker updates order status to confirmed
9. Client receives 201 with order ID
10. Client polls GET /api/orders/:id for status updates
```

Number every step. This makes it easy to reference during review:
"Step 7 can fail — what happens to the order?"

## Interface Definition Guide

Define interfaces before implementation. Use this template:

```typescript
// Contract: OrderService
interface OrderService {
  // Create a new order. Returns order ID.
  // Throws: ValidationError if items array is empty.
  // Throws: PaymentError if charge fails.
  create(input: CreateOrderInput): Promise<string>;

  // Get order by ID. Returns null if not found.
  getById(id: string): Promise<Order | null>;

  // List orders for a user, paginated.
  list(userId: string, cursor?: string, limit?: number): Promise<PaginatedResult<Order>>;
}
```

Rules for good interfaces:
- Document error cases, not just happy paths
- Use domain types, not primitives (OrderId, not string)
- Keep interfaces small — split if more than 7 methods
- Version interfaces when breaking changes are unavoidable

## Risk Assessment Matrix

For each architectural decision, assess:

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Database bottleneck under load | Medium | High | Add read replica, cache hot queries |
| Message queue loses events | Low | Critical | Use persistent queue with dead-letter |
| Third-party API goes down | Medium | Medium | Circuit breaker + graceful degradation |
| Schema migration breaks old clients | High | High | Additive-only changes, deprecation period |

### Scoring Guide
- **Likelihood**: Low (< 10%), Medium (10-50%), High (> 50%)
- **Impact**: Low (cosmetic), Medium (degraded experience), High (feature broken), Critical (data loss or outage)
- **Action threshold**: Any Critical impact or High+High combination requires mitigation before proceeding

## Architecture Decision Record (ADR) Format

```markdown
## ADR-NNN: <Title>
Date: YYYY-MM-DD
Status: Proposed | Accepted | Deprecated

### Context
What situation are we in?

### Decision
What are we choosing to do?

### Consequences
What becomes easier? What becomes harder?
```

## Common Mistakes

- Drawing diagrams without defining interfaces
- Ignoring failure modes ("what if this call times out?")
- Over-engineering for scale that may never arrive
- Skipping the risk matrix for "simple" changes that touch shared infrastructure
