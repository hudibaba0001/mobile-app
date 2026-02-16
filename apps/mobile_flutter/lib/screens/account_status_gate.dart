// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_auth_service.dart';
import '../services/entitlement_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import '../models/user_entitlement.dart';
import '../providers/contract_provider.dart';
import '../config/app_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../design/app_theme.dart';
import '../widgets/legal_document_dialog.dart';
import 'paywall_screen.dart';

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

class _AccountStatusGateState extends State<AccountStatusGate>
    with WidgetsBindingObserver {
  final _profileService = ProfileService();
  final _entitlementService = EntitlementService();
  UserProfile? _profile;
  UserEntitlement? _entitlement;
  LegalVersions? _requiredLegalVersions;
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

      var profile = await _profileService.fetchProfile();

      // In-app signup path: profile row may not exist yet. Bootstrap it server-side.
      if (profile == null) {
        await _entitlementService.bootstrapProfileAndPendingEntitlement();
        profile = await _profileService.fetchProfile();
      }

      // Run remaining checks in parallel
      final results = await Future.wait([
        // Sync contract settings from Supabase profile
        if (profile != null && mounted)
          context.read<ContractProvider>().loadFromSupabase()
        else
          Future.value(null),
        // Fetch legal versions
        _profileService.fetchCurrentLegalVersions().catchError((_) => null),
        // Fetch entitlement
        _entitlementService.fetchCurrentEntitlement(),
      ]);

      final requiredLegalVersions = results[1] as LegalVersions?;
      final entitlement = results[2] as UserEntitlement?;

      if (mounted) {
        setState(() {
          _profile = profile;
          _entitlement = entitlement;
          _requiredLegalVersions = requiredLegalVersions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  bool _isAcceptingLegal = false;

  Future<void> _acceptLegal() async {
    setState(() => _isAcceptingLegal = true);
    try {
      final updatedProfile = await _profileService.acceptLegal();
      LegalVersions? requiredLegalVersions = _requiredLegalVersions;
      try {
        requiredLegalVersions =
            await _profileService.fetchCurrentLegalVersions();
      } catch (_) {
        // Keep prior required versions if this lookup fails.
      }

      if (mounted) {
        setState(() {
          if (updatedProfile != null) {
            _profile = updatedProfile;
          }
          _requiredLegalVersions = requiredLegalVersions;
          _isAcceptingLegal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAcceptingLegal = false);
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.common_error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildLegalAcceptanceScreen(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.gavel_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                t.legal_acceptTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.legal_acceptBody,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Links to terms and privacy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => LegalDocumentDialog.showTerms(context),
                    child: Text(t.settings_terms),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  TextButton(
                    onPressed: () => LegalDocumentDialog.showPrivacy(context),
                    child: Text(t.settings_privacy),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              ElevatedButton(
                onPressed: _isAcceptingLegal ? null : _acceptLegal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                ),
                child: _isAcceptingLegal
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.legal_acceptButton),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () async {
                  final authService = context.read<SupabaseAuthService>();
                  await authService.signOut();
                  if (mounted) {
                    context.goNamed(AppRouter.loginName);
                  }
                },
                child: Text(t.auth_signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveEntitlement() {
    if (_entitlement?.hasAccess == true) return true;
    // Backward compatibility with legacy Stripe profile status.
    if (_profile?.hasActiveSubscription == true) return true;
    return false;
  }

  bool _isLegalVersionCurrent() {
    if (_profile == null) return false;
    final required = _requiredLegalVersions;
    if (required == null) return true;
    return _profile!.termsVersion == required.termsVersion &&
        _profile!.privacyVersion == required.privacyVersion;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Checking account status...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppIconSize.xl,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppLocalizations.of(context).common_error,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    child: Text(AppLocalizations.of(context).common_retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // If profile still doesn't exist after bootstrap attempt
    if (_profile == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Account setup incomplete',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'We could not finish setting up your account profile. Please retry.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                ElevatedButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).common_retry),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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

    // Check if user has accepted current legal terms
    if (!_profile!.hasAcceptedLegal || !_isLegalVersionCurrent()) {
      return _buildLegalAcceptanceScreen(context);
    }

    // Check if subscription entitlement is inactive
    if (!_hasActiveEntitlement()) {
      return PaywallScreen(
        onUnlocked: _loadProfile,
        showSignOut: true,
      );
    }

    // All checks passed, show the app
    return widget.child;
  }
}
