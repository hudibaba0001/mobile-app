import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import '../config/external_links.dart';
import '../config/app_router.dart';
import '../l10n/generated/app_localizations.dart';

/// Gate screen that checks legal acceptance and subscription status
/// Blocks access to app if requirements are not met
class AccountStatusGate extends StatefulWidget {
  final Widget child;

  const AccountStatusGate({
    super.key,
    required this.child,
  });

  @override
  State<AccountStatusGate> createState() => _AccountStatusGateState();
}

class _AccountStatusGateState extends State<AccountStatusGate> with WidgetsBindingObserver {
  final _profileService = ProfileService();
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh profile when app resumes (e.g., after returning from payment portal)
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<SupabaseAuthService>();
      if (!authService.isAuthenticated) {
        // Not authenticated, redirect to login
        if (mounted) {
          context.goNamed(AppRouter.loginName);
        }
        return;
      }

      final profile = await _profileService.fetchProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openSignupPage() async {
    try {
      final url = Uri.parse(ExternalLinks.signupUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.auth_signupFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openManageSubscription() async {
    try {
      final url = Uri.parse(ExternalLinks.manageSubscriptionUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.auth_subscriptionFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSubscriptionMessage() {
    if (_profile == null) {
      return 'Your subscription is not active.';
    }
    
    final status = _profile!.subscriptionStatus;
    if (status == 'pending') {
      return 'Your payment was not completed. Please complete the signup process to start your free trial.';
    } else if (status == 'past_due') {
      return 'Your payment failed. Please update your payment method to continue using the app.';
    } else if (status == 'canceled') {
      return 'Your subscription has been canceled. Please resubscribe to continue using the app.';
    }
    return 'Your subscription is not active. Please manage your subscription to continue using the app.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Checking account status...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).common_error,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: Text(AppLocalizations.of(context).common_retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If profile doesn't exist, show message to complete registration
    if (_profile == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Complete Registration',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your account needs to be completed. Please visit our signup page to accept terms and privacy policy, and set up your subscription.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _openSignupPage,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppLocalizations.of(context).auth_completeRegistration),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final authService = context.read<SupabaseAuthService>();
                    await authService.signOut();
                    if (mounted) {
                      context.goNamed(AppRouter.loginName);
                    }
                  },
                  child: Text(AppLocalizations.of(context).auth_signOut),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check if terms/privacy not accepted
    if (!_profile!.hasAcceptedLegal) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.gavel_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 32),
                Text(
                  AppLocalizations.of(context).auth_legalRequired,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).auth_legalDescription,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).auth_legalVisitSignup,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _openSignupPage,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppLocalizations.of(context).auth_openSignupPage),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final authService = context.read<SupabaseAuthService>();
                    await authService.signOut();
                    if (mounted) {
                      context.goNamed(AppRouter.loginName);
                    }
                  },
                  child: Text(AppLocalizations.of(context).auth_signOut),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check if subscription is inactive
    if (!_profile!.hasActiveSubscription) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 32),
                Text(
                  'Subscription Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _getSubscriptionMessage(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _openManageSubscription,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppLocalizations.of(context).settings_manageSubscription),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final authService = context.read<SupabaseAuthService>();
                    await authService.signOut();
                    if (mounted) {
                      context.goNamed(AppRouter.loginName);
                    }
                  },
                  child: Text(AppLocalizations.of(context).auth_signOut),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // All checks passed, show the app
    return widget.child;
  }
}

