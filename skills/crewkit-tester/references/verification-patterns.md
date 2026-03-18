# Product Verification — Assertion Patterns

## Element Assertions

### Visibility and Presence
```typescript
// Element is rendered and visible
await expect(page.locator('.welcome-banner')).toBeVisible();

// Element exists in DOM but may be hidden
await expect(page.locator('.hidden-field')).toBeAttached();

// Element is NOT visible
await expect(page.locator('.loading-spinner')).not.toBeVisible();

// Element has correct text
await expect(page.locator('.user-name')).toHaveText('Alice');
await expect(page.locator('.item-count')).toContainText('3 items');
```

### Dynamic Content
```typescript
// Wait for content to change (e.g., after API call)
await expect(page.locator('.status')).toHaveText('Active', { timeout: 5000 });

// Verify list items
const items = page.locator('.todo-item');
await expect(items).toHaveCount(5);
await expect(items.first()).toContainText('Buy groceries');
await expect(items.last()).toContainText('Clean house');

// Verify table data
const rows = page.locator('table tbody tr');
await expect(rows).toHaveCount(10);
const firstRow = rows.first();
await expect(firstRow.locator('td').nth(0)).toHaveText('Alice');
await expect(firstRow.locator('td').nth(1)).toHaveText('admin');
```

## Network Assertions

### API Response Verification
```typescript
// Verify API was called with correct parameters
const [request] = await Promise.all([
  page.waitForRequest(req =>
    req.url().includes('/api/orders') && req.method() === 'POST'
  ),
  page.click('#submit-order'),
]);
const body = request.postDataJSON();
expect(body.items).toHaveLength(2);

// Verify API response
const [response] = await Promise.all([
  page.waitForResponse('**/api/orders'),
  page.click('#submit-order'),
]);
expect(response.status()).toBe(201);
const data = await response.json();
expect(data.id).toBeDefined();
```

### Network Error Handling
```typescript
// Mock network failure and verify UI handles it
await page.route('**/api/data', route => route.abort());
await page.goto('/dashboard');
await expect(page.locator('.error-state')).toBeVisible();
await expect(page.locator('.error-state')).toContainText('Failed to load');

// Mock slow response
await page.route('**/api/data', async route => {
  await new Promise(resolve => setTimeout(resolve, 3000));
  await route.fulfill({ status: 200, body: '[]' });
});
await page.goto('/dashboard');
await expect(page.locator('.loading-spinner')).toBeVisible();
```

## State Assertions

### Local Storage and Cookies
```typescript
// Verify localStorage was updated
await page.evaluate(() => {
  return localStorage.getItem('theme');
}).then(value => expect(value).toBe('dark'));

// Verify cookie was set
const cookies = await page.context().cookies();
const authCookie = cookies.find(c => c.name === 'session');
expect(authCookie).toBeDefined();
expect(authCookie!.httpOnly).toBe(true);
expect(authCookie!.secure).toBe(true);
```

### URL and Navigation State
```typescript
// Verify redirect after action
await page.click('#logout');
await expect(page).toHaveURL('/login');

// Verify query parameters
await page.fill('#search', 'widget');
await page.click('#search-btn');
await expect(page).toHaveURL(/q=widget/);

// Verify URL after form submission
await page.click('#save');
await expect(page).toHaveURL(/\/orders\/[a-z0-9-]+/);
```

## Form Testing

### Input Validation
```typescript
test('shows validation errors', async ({ page }) => {
  await page.goto('/register');

  // Submit empty form
  await page.click('button[type="submit"]');

  // Check validation messages
  await expect(page.locator('#email-error')).toHaveText('Email is required');
  await expect(page.locator('#password-error')).toHaveText('Password is required');

  // Enter invalid email
  await page.fill('#email', 'not-an-email');
  await page.click('button[type="submit"]');
  await expect(page.locator('#email-error')).toHaveText('Invalid email format');

  // Enter valid data — errors should clear
  await page.fill('#email', 'user@example.com');
  await page.fill('#password', 'StrongPass123!');
  await expect(page.locator('#email-error')).not.toBeVisible();
});
```

### File Upload
```typescript
test('upload profile picture', async ({ page }) => {
  await page.goto('/settings');
  const fileInput = page.locator('input[type="file"]');
  await fileInput.setInputFiles('fixtures/avatar.png');
  await expect(page.locator('.avatar-preview')).toBeVisible();
  await page.click('#save-avatar');
  await expect(page.locator('.success-toast')).toHaveText('Avatar updated');
});
```

## Auth Flow Testing

### Login Flow
```typescript
test('complete login flow', async ({ page }) => {
  await page.goto('/login');
  await page.fill('#email', 'test@example.com');
  await page.fill('#password', 'password123');
  await page.click('button[type="submit"]');

  // Verify redirect to dashboard
  await expect(page).toHaveURL('/dashboard');
  await expect(page.locator('.user-menu')).toContainText('test@example.com');
});

test('rejects invalid credentials', async ({ page }) => {
  await page.goto('/login');
  await page.fill('#email', 'test@example.com');
  await page.fill('#password', 'wrong');
  await page.click('button[type="submit"]');

  // Should stay on login page with error
  await expect(page).toHaveURL('/login');
  await expect(page.locator('.error-alert')).toHaveText('Invalid credentials');
});
```

### Protected Route
```typescript
test('redirects unauthenticated user to login', async ({ page }) => {
  // Access protected page without auth
  await page.goto('/dashboard');
  await expect(page).toHaveURL('/login?redirect=/dashboard');
});
```

## Assertion Checklist

For any feature verification, check:
- [ ] Happy path works end-to-end
- [ ] Error states display correctly
- [ ] Loading states appear and disappear
- [ ] Empty states show appropriate message
- [ ] Navigation works (forward, back, direct URL)
- [ ] Form validation shows and clears errors
- [ ] Data persists after page reload
- [ ] Auth gates redirect unauthenticated users
