import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_router.dart';
import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/legal_document_dialog.dart';
import '../services/entitlement_service.dart';
import '../services/profile_service.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/glass_text_form_field.dart';

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

  static const _gradientStart = AppColors.gradientStart;
  static const _gradientEnd = AppColors.gradientEnd;

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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradientStart, _gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.auth_createAccount,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppColors.neutral50,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.signup_subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral50.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _SignupGlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GlassTextFormField(
                              controller: _firstNameController,
                              hintText: t.signup_firstNameLabel,
                              prefixIcon: Icons.person_outline,
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
                            GlassTextFormField(
                              controller: _lastNameController,
                              hintText: t.signup_lastNameLabel,
                              prefixIcon: Icons.person_outline,
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
                            GlassTextFormField(
                              controller: _emailController,
                              hintText: t.password_emailLabel,
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
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
                            GlassTextFormField(
                              controller: _passwordController,
                              hintText: t.auth_passwordLabel,
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
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
                            GlassTextFormField(
                              controller: _confirmPasswordController,
                              hintText: t.signup_confirmPasswordLabel,
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
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
                                  checkColor: _gradientStart,
                                  fillColor: WidgetStateProperty.all(
                                      AppColors.neutral50),
                                  side: BorderSide(
                                    color: AppColors.neutral50
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.md - 2,
                                    ),
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          t.signup_acceptLegalPrefix,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.neutral50
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () =>
                                                  LegalDocumentDialog.showTerms(
                                                      context),
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 0,
                                            ),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            t.settings_terms,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: AppColors.neutral50,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          t.signup_acceptLegalAnd,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.neutral50
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () => LegalDocumentDialog
                                                  .showPrivacy(context),
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 0,
                                            ),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            t.settings_privacy,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: AppColors.neutral50,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
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
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(
                                    color: AppColors.error.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.neutral50,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            ElevatedButton(
                              onPressed: (_isLoading || !_acceptedLegal)
                                  ? null
                                  : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neutral50,
                                foregroundColor: _gradientStart,
                                disabledBackgroundColor:
                                    AppColors.neutral50.withValues(alpha: 0.4),
                                disabledForegroundColor:
                                    _gradientStart.withValues(alpha: 0.5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: AppIconSize.sm,
                                      width: AppIconSize.sm,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _gradientStart,
                                      ),
                                    )
                                  : Text(
                                      t.auth_createAccount,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: _gradientStart,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => AppRouter.goToLogin(context),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.neutral50,
                              ),
                              child: Text(
                                t.password_backToSignIn,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.neutral50
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupGlassCard extends StatelessWidget {
  final Widget child;

  const _SignupGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neutral50.withValues(alpha: 0.25),
                AppColors.neutral50.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.neutral50.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neutral900.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
