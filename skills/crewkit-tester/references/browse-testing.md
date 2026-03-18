# Headless Browser Testing Guide

## Playwright Setup

### Installation
```bash
npm init playwright@latest
# Or add to existing project:
npm install -D @playwright/test
npx playwright install
```

### Configuration
```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  retries: 1,
  use: {
    baseURL: 'http://localhost:3000',
    headless: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: true,
  },
});
```

## Page Navigation

### Basic Navigation
```typescript
import { test, expect } from '@playwright/test';

test('navigate to dashboard', async ({ page }) => {
  // Go to URL
  await page.goto('/dashboard');

  // Wait for navigation after click
  await page.click('a[href="/settings"]');
  await page.waitForURL('**/settings');

  // Go back/forward
  await page.goBack();
  await page.goForward();

  // Reload
  await page.reload();
});
```

### Waiting Strategies
```typescript
// Wait for element to appear
await page.waitForSelector('.dashboard-loaded');

// Wait for network idle (all requests finished)
await page.waitForLoadState('networkidle');

// Wait for specific API response
await page.waitForResponse('**/api/users');

// Wait for element to be visible
await page.locator('.modal').waitFor({ state: 'visible' });
```

## Element Interaction

```typescript
test('fill and submit form', async ({ page }) => {
  await page.goto('/signup');

  // Text input
  await page.fill('#email', 'user@example.com');
  await page.fill('#password', 'secure123');

  // Dropdown
  await page.selectOption('#role', 'admin');

  // Checkbox
  await page.check('#terms');

  // Click button
  await page.click('button[type="submit"]');

  // Wait for result
  await expect(page.locator('.success-message')).toBeVisible();
});
```

## Assertions

```typescript
test('dashboard displays correctly', async ({ page }) => {
  await page.goto('/dashboard');

  // Text content
  await expect(page.locator('h1')).toHaveText('Dashboard');

  // Element visibility
  await expect(page.locator('.sidebar')).toBeVisible();
  await expect(page.locator('.error')).not.toBeVisible();

  // Element count
  await expect(page.locator('.card')).toHaveCount(3);

  // Attribute
  await expect(page.locator('input')).toHaveAttribute('placeholder', 'Search...');

  // URL
  await expect(page).toHaveURL(/dashboard/);

  // Title
  await expect(page).toHaveTitle('My App - Dashboard');
});
```

## Screenshot Capture

```typescript
test('visual check', async ({ page }) => {
  await page.goto('/dashboard');

  // Full page screenshot
  await page.screenshot({ path: 'screenshots/dashboard-full.png', fullPage: true });

  // Element screenshot
  const chart = page.locator('.revenue-chart');
  await chart.screenshot({ path: 'screenshots/chart.png' });

  // Visual comparison (snapshot testing)
  await expect(page).toHaveScreenshot('dashboard.png', {
    maxDiffPixels: 100,
  });
});
```

## Video Recording

Configure in `playwright.config.ts`:
```typescript
use: {
  // Record video for all tests
  video: 'on',
  // Or only on failure
  video: 'retain-on-failure',
}
```

Access video after test:
```typescript
test.afterEach(async ({}, testInfo) => {
  if (testInfo.status !== 'passed') {
    const video = testInfo.attachments.find(a => a.name === 'video');
    if (video) console.log('Video:', video.path);
  }
});
```

## Common Patterns

### Authentication
```typescript
// Save auth state once, reuse across tests
test('login and save state', async ({ page }) => {
  await page.goto('/login');
  await page.fill('#email', 'test@example.com');
  await page.fill('#password', 'password');
  await page.click('button[type="submit"]');
  await page.waitForURL('/dashboard');
  await page.context().storageState({ path: 'auth.json' });
});

// Reuse in other tests
test.use({ storageState: 'auth.json' });
```

### API Mocking
```typescript
test('handles API error', async ({ page }) => {
  await page.route('**/api/users', route =>
    route.fulfill({ status: 500, body: 'Internal Server Error' })
  );
  await page.goto('/users');
  await expect(page.locator('.error-message')).toBeVisible();
});
```

## Run Commands
```bash
npx playwright test                    # Run all tests
npx playwright test e2e/login.spec.ts  # Run specific file
npx playwright test --headed           # See the browser
npx playwright test --debug            # Step-through debugger
npx playwright show-report             # View HTML report
```
