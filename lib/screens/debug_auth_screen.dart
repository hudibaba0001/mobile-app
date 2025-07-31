import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dummy_auth_service.dart';

/// Debug screen for testing dummy authentication
/// This screen allows switching between different test users
class DebugAuthScreen extends StatelessWidget {
  const DebugAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Debug Auth'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer<DummyAuthService>(
        builder: (context, authService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current User Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '👤 Current User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (authService.isAuthenticated &&
                            authService.currentUser != null) ...[
                          _buildUserInfo('Name', authService.currentUser!.name),
                          _buildUserInfo(
                            'Email',
                            authService.currentUser!.email,
                          ),
                          _buildUserInfo('ID', authService.currentUser!.id),
                          _buildUserInfo(
                            'Tier',
                            authService.currentUser!.subscriptionTier
                                .toUpperCase(),
                          ),
                          _buildUserInfo(
                            'Verified',
                            authService.currentUser!.isVerified
                                ? '✅ Yes'
                                : '❌ No',
                          ),
                          _buildUserInfo(
                            'Premium Features',
                            authService.hasPremiumFeatures ? '✅ Yes' : '❌ No',
                          ),
                          _buildUserInfo(
                            'Pro Features',
                            authService.hasProFeatures ? '✅ Yes' : '❌ No',
                          ),
                        ] else ...[
                          const Text(
                            '❌ Not authenticated',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Test User Buttons
                const Text(
                  '🧪 Switch Test Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildTestUserButton(
                  context,
                  'Free User',
                  'Basic user with free tier',
                  Colors.grey,
                  () => authService.signInWithDummyAccount(),
                ),

                _buildTestUserButton(
                  context,
                  'Premium User',
                  'User with premium subscription',
                  Colors.blue,
                  () => authService.signInWithTestUser('premium'),
                ),

                _buildTestUserButton(
                  context,
                  'Pro User',
                  'User with pro subscription',
                  Colors.purple,
                  () => authService.signInWithTestUser('pro'),
                ),

                const SizedBox(height: 24),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: authService.isAuthenticated
                        ? () => authService.signOut()
                        : null,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Firebase Registration Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/firebase-registration'),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Register Firebase Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const Spacer(),

                // Info Card
                Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ℹ️ Debug Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This is a dummy authentication system for testing. '
                          'It bypasses Firebase Auth and creates fake user sessions. '
                          'All data is stored locally with the dummy user ID.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _buildTestUserButton(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
