# Test Framework Detection and Configuration

## Framework Detection

Detect the test framework by checking these files in order:

| Framework | Detection File | Config Key |
|-----------|---------------|------------|
| Jest | `jest.config.{js,ts,json}` or `package.json → jest` | `"test": "jest"` |
| Vitest | `vitest.config.{js,ts}` or `vite.config.{js,ts}` with test block | `"test": "vitest"` |
| Bun | `bunfig.toml` or `package.json → scripts.test` contains `bun test` | `"test": "bun test"` |
| pytest | `pytest.ini`, `pyproject.toml → [tool.pytest]`, `conftest.py` | `python -m pytest` |
| go test | `go.mod` exists + `*_test.go` files | `go test ./...` |
| cargo test | `Cargo.toml` exists + `#[cfg(test)]` or `tests/` dir | `cargo test` |

## Jest Configuration

### Minimal Setup
```javascript
// jest.config.js
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.[jt]s?(x)', '**/?(*.)+(spec|test).[jt]s?(x)'],
  transform: {
    '^.+\\.tsx?$': 'ts-jest',
  },
};
```

### Common Issues
- **ESM imports fail**: Add `transformIgnorePatterns: []` or use `--experimental-vm-modules`
- **Slow startup**: Add `--maxWorkers=50%` to limit parallel processes
- **Module aliases not resolved**: Mirror `tsconfig.json` paths in `moduleNameMapper`
- **CSS/asset imports fail**: Add mock in `moduleNameMapper`: `'\\.(css)$': 'identity-obj-proxy'`

### Run Commands
```bash
npx jest                    # Run all tests
npx jest --watch            # Watch mode
npx jest path/to/file       # Run specific file
npx jest --coverage         # With coverage report
```

## Vitest Configuration

### Minimal Setup
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.{test,spec}.{js,ts,tsx}'],
  },
});
```

### Common Issues
- **Vite plugins conflict**: Use `test.deps.inline` for problematic dependencies
- **Global types missing**: Set `globals: true` and add `vitest/globals` to tsconfig types
- **Threads cause flaky tests**: Use `pool: 'forks'` instead of default threads

### Run Commands
```bash
npx vitest                  # Watch mode (default)
npx vitest run              # Single run
npx vitest run src/utils    # Run tests in directory
npx vitest --coverage       # With coverage (needs @vitest/coverage-v8)
```

## Bun Test

### Minimal Setup
No config file needed. Bun discovers `*.test.{ts,js,tsx,jsx}` files automatically.

```toml
# bunfig.toml (optional)
[test]
coverage = true
coverageReporter = ["text", "lcov"]
```

### Common Issues
- **Node APIs missing**: Some Node.js APIs aren't fully implemented in Bun
- **Jest matchers missing**: Use `bun:test` matchers; `jest-dom` won't work directly
- **Snapshot format differs**: Bun snapshots aren't compatible with Jest snapshots

### Run Commands
```bash
bun test                    # Run all tests
bun test src/utils          # Run tests in directory
bun test --coverage         # With coverage
```

## pytest

### Minimal Setup
```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = "-v --tb=short"
```

### Common Issues
- **Import errors**: Add `__init__.py` to test directories or use `--rootdir`
- **Fixtures not found**: Ensure `conftest.py` is in the right directory level
- **Async tests**: Install `pytest-asyncio` and mark with `@pytest.mark.asyncio`
- **Slow collection**: Use `--collect-only` to debug, exclude venv with `--ignore=venv`

### Run Commands
```bash
python -m pytest              # Run all tests
python -m pytest tests/       # Run directory
python -m pytest -k "test_user"  # Filter by name
python -m pytest --cov=src    # With coverage (needs pytest-cov)
```

## go test

### Setup
No config needed. Go discovers `*_test.go` files automatically.

### Common Issues
- **Tests not found**: Test functions must start with `Test` and take `*testing.T`
- **Cache stale results**: Use `-count=1` to disable caching
- **Race conditions**: Run with `-race` flag to detect data races
- **Slow tests**: Use `-short` flag and skip with `testing.Short()`

### Run Commands
```bash
go test ./...               # Run all tests
go test ./pkg/user          # Run package tests
go test -v -run TestCreate  # Verbose, filter by name
go test -race ./...         # With race detector
go test -cover ./...        # With coverage
```

## cargo test

### Setup
Tests live inside source files or in `tests/` directory.

### Common Issues
- **Tests don't compile**: `#[cfg(test)]` module must be inside the source file
- **Integration tests can't access private items**: Use `tests/` dir for public API only
- **Slow compilation**: Use `cargo nextest` for faster test execution
- **Async tests**: Use `#[tokio::test]` for async test functions

### Run Commands
```bash
cargo test                  # Run all tests
cargo test user             # Filter by name
cargo test -- --nocapture   # Show println output
cargo test --release        # Test with optimizations
```
