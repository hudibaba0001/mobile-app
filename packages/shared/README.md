# @kviktime/shared

Shared TypeScript types and utilities for the KvikTime monorepo.

## Overview

This package contains shared type definitions that are used across multiple applications in the KvikTime monorepo, primarily for the Next.js admin API and Flutter web admin UI.

## Contents

### User Types (`types/user.ts`)
- `UserProfile` - User profile data from Supabase
- `AdminUser` - Admin user data
- `CreateUserRequest` - Request body for creating users
- `UpdateUserRequest` - Request body for updating users

### Entry Types (`types/entry.ts`)
- `TravelTimeEntry` - Time tracking entries
- `LeaveEntry` - Leave/absence entries
- `ContractSettings` - User contract configuration

### Analytics Types (`types/analytics.ts`)
- `SystemAnalytics` - System-wide statistics
- `UserActivityStats` - Per-user activity data
- `EntryTrends` - Time-series trend data
- `LocationStats` - Location usage statistics

## Usage

### In Next.js API (`apps/web_api`)

1. Install the package (if using workspaces):
   ```bash
   npm install @kviktime/shared
   ```

2. Import types:
   ```typescript
   import type { UserProfile, SystemAnalytics } from '@kviktime/shared';

   export async function GET(request: NextRequest) {
     const analytics: SystemAnalytics = {
       totalUsers: 100,
       totalEntries: 5000,
       activeUsersLast30Days: 75,
       dateRange: { start: '2025-01-01', end: '2025-01-31' }
     };
     return NextResponse.json(analytics);
   }
   ```

### In Flutter (for code generation)

The TypeScript types can be used as a reference for creating corresponding Dart classes or for generating Dart types using tools like `json_serializable`.

## Development

### Building the Package

```bash
npm run build
```

This compiles TypeScript files from `src/` to `dist/` with type declarations.

### Watch Mode

```bash
npm run watch
```

Automatically rebuilds on file changes.

## Adding New Types

1. Create a new file in `src/types/` (e.g., `src/types/mytype.ts`)
2. Define and export your types
3. Add exports to `src/index.ts`
4. Run `npm run build` to compile
5. Use in other packages

Example:
```typescript
// src/types/mytype.ts
export interface MyType {
  id: string;
  name: string;
}

// src/index.ts
export type { MyType } from './types/mytype';
```

## Type Safety

All types in this package should match the Supabase database schema. When the database schema changes:

1. Update the corresponding types in this package
2. Rebuild the package
3. Update consuming applications to handle the changes

## License

Proprietary
