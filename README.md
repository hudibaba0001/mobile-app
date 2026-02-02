# KvikTime Monorepo

A monorepo containing the KvikTime time tracking application suite.

## Repository Structure

```
/apps
  /mobile_flutter      - Flutter mobile app (iOS & Android)
  /admin_flutter_web   - Flutter web admin UI
  /web_api             - Next.js admin API and super admin functions
/packages
  /shared              - Shared types and utilities
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

### Admin Web UI (`apps/admin_flutter_web`)
Flutter web application for administrative functions and super admin capabilities.

**Coming soon**

### Admin API (`apps/web_api`)
Next.js API for super admin functions, analytics, and backend services.

**Tech Stack:**
- Next.js 14+
- TypeScript
- Supabase client

**Getting Started:**
```bash
cd apps/web_api
npm install
npm run dev
```

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
