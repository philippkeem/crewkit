# Parallel Dispatch — Sub-Agent Guide

## When to Use Sub-Agents

Use parallel dispatch when:
- Multiple independent files need creation or modification
- Tasks have no data dependencies between them
- The total work would take more than 2 cycles sequentially
- Each sub-task is self-contained and testable

Do NOT use parallel dispatch when:
- Tasks depend on each other's output
- The work touches the same files
- Context sharing would be larger than the work itself
- A single sequential pass is simpler and fast enough

## Dependency Analysis

Before dispatching, map the dependency graph:

```
Task A: Create user model          → no deps
Task B: Create user API routes     → depends on A (needs model types)
Task C: Create user tests          → depends on A and B
Task D: Create email service       → no deps
Task E: Create notification worker → depends on D
```

Parallel groups:
- **Batch 1**: A, D (independent)
- **Batch 2**: B, E (each depends on one from batch 1)
- **Batch 3**: C (depends on A and B)

## Batch Grouping Rules

1. **Same-layer grouping**: Tasks at the same architectural layer can often
   run in parallel (all API routes, all DB migrations, all test files).

2. **Size balancing**: Don't put one 5-minute task and one 30-second task in
   the same batch — the fast one waits for the slow one.

3. **Maximum batch size**: Keep batches to 3-5 sub-agents. More than that
   increases merge complexity and context overhead.

## Context Passing

Each sub-agent needs enough context to work independently. Provide:

```markdown
## Sub-Agent Task: Create User API Routes

### Context
- User model is defined in `src/models/user.ts`
- Model exports: `User`, `CreateUserInput`, `UpdateUserInput`
- Project uses Express with Zod validation
- Routes follow pattern in `src/routes/products.ts`

### Task
Create `src/routes/users.ts` with:
- POST /users — create user (validate with Zod)
- GET /users/:id — get user by ID
- PATCH /users/:id — update user fields
- DELETE /users/:id — soft delete

### Constraints
- Use existing error handler middleware
- Follow existing route patterns exactly
- Do not modify any other files
```

### Context Checklist
- [ ] Relevant type definitions or interfaces
- [ ] Existing patterns to follow (reference file)
- [ ] File paths for inputs and outputs
- [ ] Constraints (what NOT to do)
- [ ] How this piece connects to the whole

## Merge Strategies

After sub-agents complete, merge their work:

### Strategy 1: Independent Files (Easiest)
Each sub-agent creates different files. No merge needed — just verify
all files are created and run tests.

### Strategy 2: Shared Config Updates
Multiple sub-agents need to update a shared file (e.g., route index,
dependency list). Designate one "coordinator" pass that aggregates:

```typescript
// src/routes/index.ts — coordinator merges these
import { userRoutes } from './users';    // from sub-agent 1
import { emailRoutes } from './email';   // from sub-agent 2
import { orderRoutes } from './orders';  // from sub-agent 3

export function registerRoutes(app: Express) {
  app.use('/users', userRoutes);
  app.use('/email', emailRoutes);
  app.use('/orders', orderRoutes);
}
```

### Strategy 3: Sequential Merge
When later tasks depend on earlier ones, merge in dependency order
and run tests after each merge.

## Verification After Merge

After all sub-agents complete:

1. **Run full test suite** — catches integration issues
2. **Check for import conflicts** — duplicate names, circular deps
3. **Verify shared state** — config files, type exports, route registration
4. **Run linter** — sub-agents may have slightly different formatting

## Example Dispatch Plan

```
Feature: Add user management with email notifications

Batch 1 (parallel):
  Agent A: Create User model + migration
  Agent B: Create EmailService + templates

Batch 2 (parallel, after batch 1):
  Agent C: Create User API routes (uses model from A)
  Agent D: Create notification worker (uses EmailService from B)

Batch 3 (sequential):
  Agent E: Wire everything together (route registration, worker startup)
  Then: Run full test suite

Coordinator tasks (not parallelized):
  - Update route index
  - Update dependency injection container
  - Add integration test
```

## Common Mistakes

- Dispatching tasks that modify the same file (causes conflicts)
- Not providing enough context (sub-agent guesses wrong patterns)
- Skipping the verification step after merge
- Over-parallelizing simple work (coordination overhead exceeds savings)
