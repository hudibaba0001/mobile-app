# KvikTime Admin Web UI

Flutter-based web admin dashboard for managing users, viewing analytics, and performing super admin functions.

## Features

- **Dashboard**: Overview of system statistics and metrics
- **User Management**: View, create, and manage user accounts
- **Analytics**: System-wide analytics and reporting
- **Authentication**: Secure login with Supabase authentication
- **Responsive UI**: Material Design 3 with dark mode support

## Tech Stack

- Flutter 3.x (Web)
- Supabase for authentication and backend
- Provider for state management
- GoRouter for navigation
- Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Chrome or another web browser for development
- Supabase project with admin credentials

### Installation

1. Navigate to the project directory:
   ```bash
   cd apps/admin_flutter_web
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app with environment variables:
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
   ```

### Environment Variables

The following environment variables are required:

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

You can also set these in your IDE's run configuration or in a `.env` file (requires additional setup).

## Project Structure

```
lib/
  config/
    app_router.dart       - GoRouter configuration
  providers/
    auth_provider.dart    - Authentication state management
  screens/
    login_screen.dart     - Login page
    dashboard_screen.dart - Main dashboard
    users_screen.dart     - User management
    analytics_screen.dart - Analytics and reports
  main.dart               - App entry point
```

## Features Overview

### Dashboard
- Overview statistics (total users, entries, active users)
- Quick access to key metrics
- Navigation to other admin sections

### User Management (Coming Soon)
- View all users in the system
- Create new user accounts
- Edit user details
- Manage user permissions

### Analytics (Coming Soon)
- System-wide usage statistics
- Time entry reports
- User activity trends
- Export capabilities

## Development

### Running in Development Mode

```bash
flutter run -d chrome
```

### Building for Production

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

The built files will be in `build/web/`.

### Deployment Options

#### Firebase Hosting
```bash
firebase init hosting
firebase deploy --only hosting
```

#### Vercel
```bash
vercel --prod
```

#### Netlify
Drag and drop the `build/web` folder to Netlify dashboard.

## Configuration

### Router Configuration
Routes are configured in `lib/config/app_router.dart`. The app uses GoRouter with authentication-based redirects:
- Unauthenticated users are redirected to `/login`
- Authenticated users are redirected from `/login` to `/`

### Authentication
Authentication is handled via Supabase Auth. The `AuthProvider` manages:
- User session state
- Sign in/sign out operations
- Auth state change listeners

## Security

- All API calls require authentication
- Admin routes are protected by the router
- JWT tokens are managed by Supabase client
- TODO: Implement role-based access control (RBAC)

## TODO

- [ ] Connect to Next.js admin API (`/apps/web_api`)
- [ ] Implement user list fetching
- [ ] Add user creation dialog
- [ ] Add user editing functionality
- [ ] Implement analytics data fetching
- [ ] Add charts and visualizations (using fl_chart)
- [ ] Add data tables with sorting/filtering (using data_table_2)
- [ ] Implement role-based access control
- [ ] Add email templates management
- [ ] Add system settings page
- [ ] Implement audit logs viewer

## Contributing

This is a private project. For questions or issues, contact the development team.

## License

Proprietary
