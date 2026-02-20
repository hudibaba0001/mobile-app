import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_router.dart';
import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/legal_document_dialog.dart';
import '../services/entitlement_service.dart';
import '../services/profile_service.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/onboarding/onboarding_scaffold.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _entitlementService = EntitlementService();
  final _profileService = ProfileService();

  bool _isLoading = false;
  bool _acceptedLegal = false;
  String? _error;

  String _buildSignupErrorMessage(Object error) {
    final t = AppLocalizations.of(context);
    if (error is AuthException) {
      switch (error.code) {
        case 'over_email_send_rate_limit':
          return t.signup_errorRateLimit;
        case 'email_not_confirmed':
          return t.signup_errorEmailNotConfirmed;
        case 'user_already_exists':
          return t.signup_errorUserExists;
        default:
          return error.message;
      }
    }
    return t.signup_errorGeneric;
  }

  bool _isStrongPassword(String value) {
    if (value.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final hasSpecial =
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(value);
    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // Guard against double-taps
    if (_isLoading) return;

    final t = AppLocalizations.of(context);

    // Collect all field values upfront
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // --- All validation MUST pass before any network call ---
    if (firstName.isEmpty) {
      setState(() => _error = t.signup_firstNameRequired);
      return;
    }
    if (lastName.isEmpty) {
      setState(() => _error = t.signup_lastNameRequired);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = t.password_emailInvalid);
      return;
    }
    if (password.isEmpty || !_isStrongPassword(password)) {
      setState(() => _error = t.signup_passwordStrongRequired);
      return;
    }
    if (confirmPassword != password) {
      setState(() => _error = t.signup_passwordsDoNotMatch);
      return;
    }
    if (!_acceptedLegal) {
      setState(() => _error = t.signup_acceptLegalRequired);
      return;
    }

    // Show inline field errors too
    _formKey.currentState?.validate();

    // Lock the UI immediately — no network calls can happen above this line
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<SupabaseAuthService>();
      final signUpResponse = await authService.signUp(
        email,
        password,
        firstName: firstName,
        lastName: lastName,
      );

      if (signUpResponse.session == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.signup_errorEmailNotConfirmed),
            backgroundColor: AppColors.success,
          ),
        );
        AppRouter.goToLogin(context, email: email);
        return;
      }

      // Account created — now record legal acceptance.
      // If this fails, sign out so the user doesn't end up half-registered.
      try {
        await _entitlementService.bootstrapProfileAndPendingEntitlement(
          firstName: firstName,
          lastName: lastName,
        );
        await _profileService.acceptLegal();
      } catch (legalError) {
        // Clean up: sign out to prevent access without legal acceptance
        try {
          await authService.signOut();
        } catch (_) {}
        rethrow;
      }

      if (!mounted) return;
      context.go(AppRouter.homePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _buildSignupErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final canSubmit = !_isLoading && _acceptedLegal;

    return OnboardingScaffold(
      title: t.auth_createAccount,
      subtitle: t.signup_subtitle,
      primaryLabel: _isLoading ? t.common_loading : t.auth_createAccount,
      onPrimary: canSubmit ? _handleSignup : null,
      secondaryLabel: t.password_backToSignIn,
      onSecondary: _isLoading ? null : () => AppRouter.goToLogin(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextFormField(
                    controller: _firstNameController,
                    labelText: t.signup_firstNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() {
                          _error = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t.signup_firstNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextFormField(
                    controller: _lastNameController,
                    labelText: t.signup_lastNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() {
                          _error = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t.signup_lastNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextFormField(
                    controller: _emailController,
                    labelText: t.password_emailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() {
                          _error = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t.password_emailRequired;
                      }
                      if (!value.contains('@')) {
                        return t.password_emailInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextFormField(
                    controller: _passwordController,
                    labelText: t.auth_passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() {
                          _error = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return t.auth_passwordRequired;
                      }
                      if (!_isStrongPassword(value)) {
                        return t.signup_passwordStrongRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextFormField(
                    controller: _confirmPasswordController,
                    labelText: t.signup_confirmPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() {
                          _error = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return t.signup_confirmPasswordRequired;
                      }
                      if (value != _passwordController.text) {
                        return t.signup_passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedLegal,
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(
                            () {
                              _acceptedLegal = value ?? false;
                              _error = null;
                            },
                          ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          t.signup_acceptLegalPrefix,
                          style: theme.textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => LegalDocumentDialog.showTerms(context),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(t.settings_terms),
                        ),
                        Text(
                          t.signup_acceptLegalAnd,
                          style: theme.textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => LegalDocumentDialog.showPrivacy(context),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(t.settings_privacy),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
