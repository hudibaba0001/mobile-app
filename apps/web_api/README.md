# KvikTime Admin API

Next.js API for super admin functions, user management, and analytics.

## Features

- **User Management**: Create, read, and manage user accounts
- **Analytics**: System-wide analytics and reporting
- **Authentication**: JWT-based authentication using Supabase
- **Admin Middleware**: Protected routes with admin role verification

## Tech Stack

- Next.js 14+ (App Router)
- TypeScript
- Supabase (Admin SDK)
- Tailwind CSS

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Supabase project with service role key

### Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create environment file:
   ```bash
   cp .env.example .env.local
   ```

3. Configure environment variables in `.env.local`:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
   ```

4. Run development server:
   ```bash
   npm run dev
   ```

5. Open [http://localhost:3000](http://localhost:3000)

## API Routes

### Admin Endpoints

All admin endpoints require authentication via Bearer token in the Authorization header.

#### GET /api/admin/users
Get all users in the system.

**Response:**
```json
{
  "users": [
    {
      "id": "uuid",
      "email": "user@example.com",
      "full_name": "John Doe",
      "is_admin": false,
      "created_at": "2025-01-01T00:00:00Z"
    }
  ]
}
```

#### POST /api/admin/users
Create a new user account.

**Request:**
```json
{
  "email": "newuser@example.com",
  "fullName": "Jane Smith",
  "isAdmin": false
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "newuser@example.com",
    "full_name": "Jane Smith",
    "is_admin": false
  }
}
```

#### GET /api/admin/analytics
Get system-wide analytics.

**Query Parameters:**
- `start_date` (optional): Start date for entry count (YYYY-MM-DD)
- `end_date` (optional): End date for entry count (YYYY-MM-DD)

**Response:**
```json
{
  "totalUsers": 150,
  "totalEntries": 5420,
  "activeUsersLast30Days": 87,
  "dateRange": {
    "start": "2025-01-01",
    "end": "2025-01-31"
  }
}
```

## Project Structure

```
app/
  api/
    admin/          - Admin API routes
      users/        - User management endpoints
      analytics/    - Analytics endpoints
lib/
  supabase.ts       - Supabase admin client
  middleware.ts     - Authentication middleware
```

## Development

### Adding New API Routes

1. Create a new route file in `app/api/[path]/route.ts`
2. Use `withAdminAuth` middleware to protect the route
3. Implement GET, POST, PUT, DELETE handlers as needed

Example:
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { withAdminAuth } from '@/lib/middleware';
import { supabaseAdmin } from '@/lib/supabase';

export async function GET(request: NextRequest) {
  return withAdminAuth(request, async (req, adminUserId) => {
    // Your implementation here
    return NextResponse.json({ data: 'success' });
  });
}
```

## Deployment

### Vercel (Recommended)

1. Push your code to GitHub
2. Import the project in Vercel
3. Set the root directory to `apps/web_api`
4. Add environment variables in Vercel dashboard
5. Deploy

### Environment Variables

Required environment variables for production:
- `NEXT_PUBLIC_SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

## Security Notes

- The `SUPABASE_SERVICE_ROLE_KEY` bypasses Row Level Security (RLS) - keep it secure
- Always validate admin permissions before performing sensitive operations
- TODO: Implement proper admin role checking in middleware
- Use HTTPS in production
- Rotate service role keys periodically

## TODO

- [ ] Implement admin role verification in `withAdminAuth` middleware
- [ ] Add rate limiting
- [ ] Add request logging
- [ ] Add email notifications for user creation
- [ ] Add pagination to user list endpoint
- [ ] Add user search and filtering
- [ ] Add audit logging for admin actions

## License

Proprietary
