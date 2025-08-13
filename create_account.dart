import 'package:firebase_core/firebase_core.dart';
import 'lib/services/firebase_registration_helper.dart';
import 'lib/firebase_options.dart';

/// Simple script to create a Firebase account
/// Run with: dart run create_account.dart
void main() async {
  print('🔥 Creating Firebase account...');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create account with your details
  final result = await FirebaseRegistrationHelper.registerUser(
    email: 'developer@travellogger.com',
    password: 'DevPassword123!',
    displayName: 'Developer Account',
  );

  print('\n📋 Registration Result:');
  print(result.toString());

  if (result.success && result.user != null) {
    print('\n✅ Account Created Successfully!');
    print('📧 Email: ${result.user!.email}');
    print('👤 Name: ${result.user!.displayName}');
    print('🆔 User ID: ${result.user!.uid}');
    print('📬 Email Verified: ${result.user!.emailVerified}');
    print('\n💡 You can now use these credentials to sign in to your app!');
    print('💡 Check your email for verification link.');
  } else {
    print('\n❌ Account creation failed!');
    print('Error: ${result.error}');
  }
}
