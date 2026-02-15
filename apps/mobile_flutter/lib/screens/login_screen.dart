import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_router.dart';
import '../services/supabase_auth_service.dart';
import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/glass_text_form_field.dart';

class LoginScreen extends StatefulWidget {
  final String? initialEmail;

  const LoginScreen({super.key, this.initialEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Gradient colors from theme
  static const _gradientStart = AppColors.gradientStart;
  static const _gradientEnd = AppColors.gradientEnd;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _launchSignup() {
    AppRouter.goToSignup(context);
  }

  String _buildSignInErrorMessage(Object error) {
    final t = AppLocalizations.of(context);

    if (error is AuthException) {
      final code = error.code?.toLowerCase();
      const invalidCredentialCodes = {
        'invalid_credentials',
        'invalid_login_credentials',
        'invalid_grant',
      };

      if (code != null && invalidCredentialCodes.contains(code)) {
        return t.auth_signInInvalidCredentials;
      }
      if (code == 'email_not_confirmed') {
        return t.signup_errorEmailNotConfirmed;
      }
    }

    final errStr = error.toString().toLowerCase();
    final isConnectivityError = errStr.contains('failed host lookup') ||
        errStr.contains('socketexception') ||
        errStr.contains('connection') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('timed out');

    if (isConnectivityError) {
      return t.auth_signInNetworkError;
    }

    return t.auth_signInGenericError;
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final authService = context.read<SupabaseAuthService>();
        await authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          context.go(AppRouter.homePath);
        }
      } catch (e) {
        final errorMessage = _buildSignInErrorMessage(e);

        if (mounted) {
          setState(() {
            _errorMessage = errorMessage;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Card with glassmorphism
                      _buildLogoCard(),
                      const SizedBox(height: AppSpacing.lg),

                      // Form Card with glassmorphism
                      _buildFormCard(),
                      const SizedBox(height: AppSpacing.lg),

                      // Divider with text
                      _buildDividerWithText(t.auth_newToKvikTime),
                      const SizedBox(height: AppSpacing.md),

                      // Create Account Button
                      _buildCreateAccountButton(),
                      const SizedBox(height: AppSpacing.md),

                      // Disclaimer text
                      Text(
                        t.auth_redirectNote,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  AppColors.neutral50.withValues(alpha: 0.65),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Language selector at bottom
                      _buildLanguageSwitcher(t, localeProvider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher(
    AppLocalizations t,
    LocaleProvider localeProvider,
  ) {
    String selectedLanguageLabel;
    switch (localeProvider.locale?.languageCode) {
      case 'sv':
        selectedLanguageLabel = t.settings_languageSwedish;
        break;
      case 'en':
        selectedLanguageLabel = t.settings_languageEnglish;
        break;
      default:
        selectedLanguageLabel = t.settings_languageSystem;
        break;
    }

    return Align(
      alignment: Alignment.center,
      child: PopupMenuButton<String>(
        tooltip: t.settings_language,
        initialValue: localeProvider.localeCode ?? 'system',
        onSelected: (value) {
          switch (value) {
            case 'en':
              localeProvider.setLocale(const Locale('en'));
              break;
            case 'sv':
              localeProvider.setLocale(const Locale('sv'));
              break;
            default:
              localeProvider.setLocale(null);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'system',
            child: Text(t.settings_languageSystem),
          ),
          PopupMenuItem<String>(
            value: 'en',
            child: Text(t.settings_languageEnglish),
          ),
          PopupMenuItem<String>(
            value: 'sv',
            child: Text(t.settings_languageSwedish),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutral50.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.neutral50.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                color: AppColors.neutral50.withValues(alpha: 0.9),
                size: AppIconSize.sm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                selectedLanguageLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral50.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_drop_down,
                color: AppColors.neutral50.withValues(alpha: 0.9),
                size: AppIconSize.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    final theme = Theme.of(context);
    return _GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          // Clock icon with glow effect
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neutral50, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neutral50.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: AppIconSize.xl,
              color: AppColors.neutral50,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'KvikTime',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.neutral50,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).auth_signInPrompt,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral50.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final theme = Theme.of(context);
    return _GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            GlassTextFormField(
              controller: _emailController,
              hintText: AppLocalizations.of(context).auth_emailLabel,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || !v.contains('@')
                  ? AppLocalizations.of(context).auth_invalidEmail
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Password field
            GlassTextFormField(
              controller: _passwordController,
              hintText: AppLocalizations.of(context).auth_passwordLabel,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.neutral50.withValues(alpha: 0.6),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => (v?.length ?? 0) < 6
                  ? AppLocalizations.of(context).auth_passwordRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Error Message
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _errorMessage,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.neutral50),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Sign In Button
            _buildSignInButton(),
            const SizedBox(height: AppSpacing.sm),

            // Forgot Password
            Center(
              child: TextButton(
                onPressed: () => AppRouter.goToForgotPassword(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.neutral50.withValues(alpha: 0.9),
                ),
                child: Text(
                  AppLocalizations.of(context).auth_forgotPassword,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral50.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neutral50,
          foregroundColor: _gradientStart,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
                AppLocalizations.of(context).auth_signInButton,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: _gradientStart,
                ),
              ),
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neutral50.withValues(alpha: 0.0),
                  AppColors.neutral50.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral50.withValues(alpha: 0.8),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neutral50.withValues(alpha: 0.5),
                  AppColors.neutral50.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: _launchSignup,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neutral50,
        side: const BorderSide(color: AppColors.neutral50, width: 2),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xxl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pillRadius,
        ),
      ),
      child: Text(
        AppLocalizations.of(context).auth_createAccount,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.neutral50,
        ),
      ),
    );
  }
}

/// A reusable glassmorphism card widget
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
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
