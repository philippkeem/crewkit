# TDD Workflow — Detailed Guide

## The RED-GREEN-REFACTOR Cycle

```
RED    → Write a failing test that describes the desired behavior
GREEN  → Write the minimum code to make the test pass
REFACTOR → Clean up without changing behavior (tests still pass)
```

Repeat. Each cycle should take 1-5 minutes. If it takes longer, the step is too big.

## What "Minimal" Means

GREEN phase means the **simplest code that passes**, even if it looks dumb.

### TypeScript Example

**RED** — write the test first:
```typescript
// sum.test.ts
import { sum } from './sum';

test('adds two positive numbers', () => {
  expect(sum(2, 3)).toBe(5);
});
```

**GREEN** — minimal implementation:
```typescript
// sum.ts
export function sum(a: number, b: number): number {
  return a + b;
}
```

This is simple enough. But for complex logic, minimal might mean hardcoding first:

**RED**:
```typescript
test('calculates shipping for US orders', () => {
  expect(calculateShipping({ country: 'US', weight: 2 })).toBe(5.99);
});
```

**GREEN** (minimal — yes, this is fine):
```typescript
export function calculateShipping(order: { country: string; weight: number }) {
  return 5.99;
}
```

Then add more tests to force generalization:
```typescript
test('calculates shipping for heavy US orders', () => {
  expect(calculateShipping({ country: 'US', weight: 10 })).toBe(12.99);
});
```

Now the hardcoded value fails, so you write real logic.

## Python Example

**RED**:
```python
# test_parser.py
from parser import parse_csv_line

def test_simple_csv():
    assert parse_csv_line("a,b,c") == ["a", "b", "c"]

def test_quoted_fields():
    assert parse_csv_line('"hello, world",b') == ["hello, world", "b"]
```

**GREEN**:
```python
# parser.py
def parse_csv_line(line: str) -> list[str]:
    import csv
    import io
    reader = csv.reader(io.StringIO(line))
    return next(reader)
```

**REFACTOR** — extract the reader setup:
```python
import csv
import io

def parse_csv_line(line: str) -> list[str]:
    reader = csv.reader(io.StringIO(line))
    return list(next(reader))
```

## When to Refactor

Refactor when:
- Tests are green AND you see duplication
- A function does two things (split it)
- A name doesn't describe what the code does (rename it)
- You need to add a feature and the current structure makes it hard

Do NOT refactor when:
- Tests are red (fix the test first)
- You're guessing about future requirements
- The code works and nobody needs to change it soon

## Common TDD Mistakes

### 1. Writing the implementation first, tests second
This isn't TDD — it's "testing after." You lose the design feedback.

### 2. Making RED-GREEN steps too big
If your test requires 50 lines of new code, break it into smaller tests.

### 3. Skipping REFACTOR
Technical debt accumulates. After every GREEN, ask: "Is this clean enough
for the next person to understand?"

### 4. Testing implementation details
```typescript
// BAD — tests HOW it works
test('calls database.save', () => {
  createUser({ name: 'Alice' });
  expect(database.save).toHaveBeenCalledWith({ name: 'Alice' });
});

// GOOD — tests WHAT it does
test('created user can be retrieved', () => {
  const id = createUser({ name: 'Alice' });
  const user = getUser(id);
  expect(user.name).toBe('Alice');
});
```

### 5. Not running tests between changes
Run tests after EVERY change. If something breaks, you know exactly which
change caused it.

## Test Structure: Arrange-Act-Assert

Every test should have three clear sections:

```typescript
test('removes expired items from cart', () => {
  // Arrange — set up the scenario
  const cart = createCart();
  cart.add({ id: '1', expiresAt: pastDate });
  cart.add({ id: '2', expiresAt: futureDate });

  // Act — perform the action
  cart.removeExpired();

  // Assert — verify the result
  expect(cart.items).toHaveLength(1);
  expect(cart.items[0].id).toBe('2');
});
```

## Quick Reference

| Phase | Do | Don't |
|-------|-----|-------|
| RED | Write one failing test | Write multiple tests at once |
| GREEN | Write minimum passing code | Optimize or generalize |
| REFACTOR | Clean up with tests green | Add new behavior |
