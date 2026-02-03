# KvikTime Monorepo

A monorepo containing the KvikTime time tracking application suite.

## Repository Structure

```
/apps
  /mobile_flutter      - Flutter mobile app (iOS & Android)
  /web_api             - Next.js admin API with built-in web UI
```

## Applications

### Mobile App (`apps/mobile_flutter`)
Flutter-based mobile application for time tracking with offline support, travel time logging, and comprehensive reporting features.

**Tech Stack:**
- Flutter 3.x
- Supabase for backend
- Hive for local storage
- Provider for state management

**Getting Started:**
```bash
cd apps/mobile_flutter
flutter pub get
flutter run
```

### Admin API & Web UI (`apps/web_api`)
Next.js application providing both the admin API and web-based admin dashboard.

**Features:**
- Admin authentication with role-based access control
- Analytics dashboard
- User management
- Audit logging for all admin actions
- Rate limiting on admin endpoints

**Tech Stack:**
- Next.js 16+
- TypeScript
- Tailwind CSS
- Supabase (admin client with service role key)

**Getting Started:**
```bash
cd apps/web_api
npm install

# Create .env.local with your credentials
cp .env.example .env.local

npm run dev
```

**Access admin UI:**
- Admin UI: http://localhost:3000/admin/login
- API endpoints: http://localhost:3000/api/admin/*

**Security Features:**
- Proper admin role verification (checks `is_admin` column)
- Rate limiting (50 requests per 15 minutes)
- Audit logging of all admin actions
- No hardcoded secrets (all loaded from env vars)

## Development

### Prerequisites
- Flutter SDK 3.x+
- Node.js 18+
- Supabase CLI (optional)

### Monorepo Management
This repository uses a monorepo structure without a specific monorepo tool. Each app maintains its own dependencies and build configuration.

## Documentation
- [Mobile App README](apps/mobile_flutter/README.md)
- Project documentation files in root directory

## License
Proprietary
