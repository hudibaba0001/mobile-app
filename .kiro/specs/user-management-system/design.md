# User Management and Subscription System Design

## Overview

This design document outlines the technical architecture for transforming the Travel Time Logger into a comprehensive SaaS platform. The system will integrate Firebase/Supabase for backend services, implement secure authentication, cloud data storage, subscription management, and a super admin panel while maintaining offline functionality and backward compatibility.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                       │
├─────────────────────────────────────────────────────────────┤
│  Authentication Layer │  Data Sync Layer │  UI Layer        │
│  - Firebase Auth      │  - Cloud Firestore│  - Auth Screens  │
│  - Local Session     │  - Local Hive     │  - Admin Panel   │
│  - Biometric Auth    │  - Sync Manager   │  - Subscription  │
├─────────────────────────────────────────────────────────────┤
│                    Backend Services                         │
│  - Firebase/Supabase  │  - Stripe/RevenueCat │  - Analytics │
│  - Cloud Functions    │  - Subscription API   │  - Monitoring│
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

**Frontend (Flutter App):**
- Firebase Auth for authentication
- Cloud Firestore for cloud data storage
- Hive for local/offline storage
- RevenueCat for subscription management
- Provider for state management

**Backend Services:**
- Firebase (Authentication, Firestore, Cloud Functions, Analytics)
- Stripe/RevenueCat for payment processing
- Firebase Admin SDK for super admin operations

**Admin Panel:**
- Flutter Web or React admin dashboard
- Firebase Admin SDK for user management
- Analytics dashboard for business metrics

## Components and Interfaces

### 1. Authentication System

#### User Model
```dart
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserSubscription subscription;
  final UserPreferences preferences;
  final bool isEmailVerified;
  final UserRole role; // user, admin, superAdmin
}

class UserSubscription {
  final String? subscriptionId;
  final SubscriptionTier tier; // free, premium, pro
  final DateTime? expiresAt;
  final SubscriptionStatus status; // active, expired, cancelled
  final PaymentMethod? paymentMethod;
  final int usageCount; // current month usage
  final int usageLimit; // tier limit
}

enum SubscriptionTier { free, premium, pro }
enum SubscriptionStatus { active, expired, cancelled, pastDue }
enum UserRole { user, admin, superAdmin }
```

#### Authentication Service
```dart
abstract class AuthService {
  Future<User?> signInWithEmailPassword(String email, String password);
  Future<User?> signUpWithEmailPassword(String email, String password, String displayName);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<User?> getCurrentUser();
  Stream<User?> authStateChanges();
  Future<void> deleteAccount();
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Implementation details...
}
```

### 2. Data Synchronization System

#### Sync Manager
```dart
class SyncManager {
  final CloudDataService _cloudService;
  final LocalDataService _localService;
  final ConnectivityService _connectivity;
  
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
  Future<void> handleConflicts(List<DataConflict> conflicts);
  Stream<SyncStatus> get syncStatusStream;
}

class DataConflict {
  final String id;
  final TravelTimeEntry localEntry;
  final TravelTimeEntry cloudEntry;
  final ConflictType type; // modified, deleted, created
}

enum SyncStatus { idle, syncing, error, offline }
```

#### Cloud Data Service
```dart
abstract class CloudDataService {
  Future<List<TravelTimeEntry>> getTravelEntries(String userId);
  Future<void> saveTravelEntry(String userId, TravelTimeEntry entry);
  Future<void> deleteTravelEntry(String userId, String entryId);
  Future<List<Location>> getLocations(String userId);
  Future<void> saveLocation(String userId, Location location);
  Stream<List<TravelTimeEntry>> watchTravelEntries(String userId);
}

class FirestoreDataService implements CloudDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Implementation with Firestore collections:
  // /users/{userId}/travelEntries/{entryId}
  // /users/{userId}/locations/{locationId}
  // /users/{userId}/settings/preferences
}
```

### 3. Subscription Management

#### Subscription Service
```dart
abstract class SubscriptionService {
  Future<List<SubscriptionPlan>> getAvailablePlans();
  Future<PurchaseResult> purchaseSubscription(String planId);
  Future<UserSubscription> getCurrentSubscription(String userId);
  Future<void> cancelSubscription(String userId);
  Future<bool> checkFeatureAccess(String userId, Feature feature);
  Stream<UserSubscription> watchSubscription(String userId);
}

class RevenueCatSubscriptionService implements SubscriptionService {
  // Integration with RevenueCat for cross-platform subscriptions
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final SubscriptionTier tier;
  final List<Feature> features;
  final Duration billingPeriod;
}

enum Feature {
  unlimitedEntries,
  cloudSync,
  advancedReports,
  teamSharing,
  prioritySupport,
  analytics,
  exportFormats,
}
```

### 4. Super Admin Panel

#### Admin Service
```dart
abstract class AdminService {
  Future<List<User>> getAllUsers({int page, int limit});
  Future<List<User>> searchUsers(String query);
  Future<AdminDashboardData> getDashboardData();
  Future<void> updateUserSubscription(String userId, UserSubscription subscription);
  Future<void> suspendUser(String userId, String reason);
  Future<List<SupportTicket>> getSupportTickets();
  Future<AnalyticsData> getAnalytics(DateRange range);
}

class AdminDashboardData {
  final int totalUsers;
  final int activeSubscriptions;
  final double monthlyRevenue;
  final int newUsersThisMonth;
  final Map<SubscriptionTier, int> subscriptionBreakdown;
  final List<UsageMetric> usageMetrics;
}

class AnalyticsData {
  final Map<String, int> userGrowth;
  final Map<String, double> revenue;
  final Map<String, int> featureUsage;
  final double churnRate;
  final double conversionRate;
}
```

### 5. Migration System

#### Data Migration Service
```dart
class MigrationService {
  final LocalDataService _localService;
  final CloudDataService _cloudService;
  
  Future<MigrationResult> migrateLocalDataToCloud(String userId);
  Future<bool> hasLocalDataToMigrate();
  Future<void> backupLocalData();
  Future<MigrationStatus> getMigrationStatus(String userId);
}

class MigrationResult {
  final bool success;
  final int entriesMigrated;
  final int locationsMigrated;
  final List<String> errors;
  final Duration migrationTime;
}

enum MigrationStatus { notStarted, inProgress, completed, failed }
```

## Data Models

### Enhanced Data Schema

#### Cloud Firestore Structure
```
/users/{userId}
├── profile/
│   ├── email: string
│   ├── displayName: string
│   ├── createdAt: timestamp
│   └── preferences: map
├── subscription/
│   ├── tier: string
│   ├── status: string
│   ├── expiresAt: timestamp
│   └── usageCount: number
├── travelEntries/{entryId}
│   ├── date: timestamp
│   ├── departure: string
│   ├── arrival: string
│   ├── minutes: number
│   ├── journeyId: string?
│   ├── segmentOrder: number?
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
└── locations/{locationId}
    ├── name: string
    ├── address: string
    ├── usageCount: number
    └── createdAt: timestamp

/admin/
├── analytics/
├── users/
└── subscriptions/
```

#### Local Hive Schema (Enhanced)
```dart
@HiveType(typeId: 3)
class UserProfile extends HiveObject {
  @HiveField(0) String? userId;
  @HiveField(1) String? email;
  @HiveField(2) String? displayName;
  @HiveField(3) DateTime? lastSyncAt;
  @HiveField(4) bool isOfflineMode;
}

@HiveType(typeId: 4)
class SyncMetadata extends HiveObject {
  @HiveField(0) String entryId;
  @HiveField(1) DateTime lastModified;
  @HiveField(2) bool needsSync;
  @HiveField(3) SyncAction action; // create, update, delete
}
```

## Security Architecture

### Authentication Security
- Firebase Auth with email/password and social providers
- JWT tokens for API authentication
- Biometric authentication for app access
- Session management with automatic refresh
- Account lockout after failed attempts

### Data Security
- End-to-end encryption for sensitive data
- HTTPS/TLS for all network communications
- Firebase Security Rules for data access control
- Input validation and sanitization
- SQL injection prevention (NoSQL injection for Firestore)

### Privacy Protection
- GDPR compliance with data export/deletion
- Minimal data collection principle
- User consent management
- Data anonymization for analytics
- Secure data deletion procedures

## Subscription Tiers

### Free Tier
- 50 travel entries per month
- Basic reporting
- Local storage only
- Community support

### Premium Tier ($4.99/month)
- Unlimited travel entries
- Cloud sync across devices
- Advanced reports and analytics
- Export to multiple formats
- Email support

### Pro Tier ($9.99/month)
- All Premium features
- Team sharing (up to 5 members)
- Advanced analytics dashboard
- Priority support
- Custom integrations
- Bulk operations

## Error Handling and Resilience

### Network Resilience
- Offline-first architecture
- Automatic retry with exponential backoff
- Graceful degradation when services unavailable
- Connection state monitoring
- Queue-based sync operations

### Data Integrity
- Conflict resolution strategies
- Data validation at multiple layers
- Backup and recovery procedures
- Transaction-based operations
- Consistency checks

### User Experience
- Clear error messages
- Progress indicators for long operations
- Fallback to cached data
- Graceful handling of subscription changes
- Smooth migration experience

## Performance Considerations

### Scalability
- Firestore automatic scaling
- Efficient data pagination
- Lazy loading of large datasets
- Caching strategies
- CDN for static assets

### Mobile Performance
- Minimal battery usage
- Efficient sync algorithms
- Background processing limits
- Memory management
- Network usage optimization

## Monitoring and Analytics

### Business Metrics
- User acquisition and retention
- Subscription conversion rates
- Feature usage analytics
- Revenue tracking
- Churn analysis

### Technical Metrics
- App performance monitoring
- Crash reporting
- API response times
- Sync success rates
- Error tracking

### User Analytics
- User journey tracking
- Feature adoption rates
- Support ticket analysis
- Usage patterns
- Satisfaction metrics