# Scaffolding — Template System Guide

## Overview

Scaffolding generates boilerplate files from templates, ensuring consistency
across the codebase. Use scaffolding when creating repeated structures:
API endpoints, React components, database models, test files.

## Template Format

Templates are files with placeholders wrapped in double curly braces.
The scaffolder replaces placeholders with provided values.

```
src/templates/
  api-endpoint.ts.template
  react-component.tsx.template
  model.ts.template
  test.ts.template
```

## Placeholder Syntax

| Syntax | Meaning | Example Input | Output |
|--------|---------|---------------|--------|
| `{{name}}` | Raw value | `user` | `user` |
| `{{Name}}` | PascalCase | `user` | `User` |
| `{{NAME}}` | UPPER_CASE | `user` | `USER` |
| `{{name_plural}}` | Pluralized | `user` | `users` |
| `{{Name_plural}}` | Plural PascalCase | `user` | `Users` |

## Example: API Endpoint Template

```typescript
// src/templates/api-endpoint.ts.template
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { {{Name}} } from '../models/{{name}}';
import { db } from '../db';

const router = Router();

const create{{Name}}Schema = z.object({
  // TODO: Define validation schema
});

// POST /{{name_plural}}
router.post('/', async (req: Request, res: Response) => {
  const input = create{{Name}}Schema.parse(req.body);
  const {{name}} = await db.{{name}}.create(input);
  res.status(201).json({{name}});
});

// GET /{{name_plural}}/:id
router.get('/:id', async (req: Request, res: Response) => {
  const {{name}} = await db.{{name}}.findById(req.params.id);
  if (!{{name}}) return res.status(404).json({ error: '{{Name}} not found' });
  res.json({{name}});
});

// PATCH /{{name_plural}}/:id
router.patch('/:id', async (req: Request, res: Response) => {
  const {{name}} = await db.{{name}}.update(req.params.id, req.body);
  res.json({{name}});
});

// DELETE /{{name_plural}}/:id
router.delete('/:id', async (req: Request, res: Response) => {
  await db.{{name}}.delete(req.params.id);
  res.status(204).send();
});

export { router as {{name}}Routes };
```

**Usage**: Scaffold with `name=product` produces `src/routes/products.ts` with
all instances of `{{name}}` replaced with `product`, `{{Name}}` with `Product`, etc.

## Example: React Component Template

```tsx
// src/templates/react-component.tsx.template
import React from 'react';

interface {{Name}}Props {
  // TODO: Define props
}

export function {{Name}}({ }: {{Name}}Props) {
  return (
    <div className="{{name}}-container">
      <h2>{{Name}}</h2>
      {/* TODO: Implement component */}
    </div>
  );
}
```

## Creating a New Template

1. Build one real instance manually (e.g., `src/routes/users.ts`)
2. Identify the varying parts (entity name, field names)
3. Replace varying parts with placeholders
4. Save as `<template-name>.ext.template`
5. Test by scaffolding a second instance and comparing to a hand-built version

## Scaffolding Process

```
1. Select template
2. Provide placeholder values: { name: "order", fields: [...] }
3. Generate files with placeholders replaced
4. Place files in correct directories
5. Update index/barrel files to export new modules
6. Run linter to verify generated code
7. Run tests to confirm no breakage
```

## When to Scaffold vs. Write by Hand

| Scaffold | Write by Hand |
|----------|---------------|
| CRUD endpoint (follows pattern) | Custom algorithm |
| Standard React component | Complex stateful component |
| Database model + migration | One-off script |
| Test file for existing module | Integration test with unique setup |

## Template Maintenance

- When you change a pattern in one file, update the template too
- Review templates quarterly — they drift from actual code
- Keep templates minimal — fewer TODOs mean less post-scaffold editing
- Store templates in the repo so the whole team uses the same ones

## Common Mistakes

- Over-templating: making templates for things that aren't repeated
- Under-customizing: leaving too many TODOs in generated code
- Forgetting to update barrel/index files after scaffolding
- Not running tests after generating files
