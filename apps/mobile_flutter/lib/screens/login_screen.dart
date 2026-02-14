import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/app_router.dart';
import '../services/supabase_auth_service.dart';
import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';

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
        String errorMessage = 'An error occurred during sign in.';
        final errStr = e.toString();

        if (errStr.contains('invalid-credential') ||
            errStr.contains('Invalid login credentials')) {
          errorMessage =
              'Invalid email or password. Please check your credentials.';
        }

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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.xxxl),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageSwitcher(t, localeProvider),
                      const SizedBox(height: AppSpacing.lg),

                      // Logo Card with glassmorphism
                      _buildLogoCard(),
                      const SizedBox(height: AppSpacing.xxl),

                      // Form Card with glassmorphism
                      _buildFormCard(),
                      const SizedBox(height: AppSpacing.xxl),

                      // Divider with text
                      _buildDividerWithText(t.auth_newToKvikTime),
                      const SizedBox(height: AppSpacing.xl),

                      // Create Account Button
                      _buildCreateAccountButton(),
                      const SizedBox(height: AppSpacing.lg),

                      // Disclaimer text
                      Text(
                        t.auth_redirectNote,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
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
      alignment: Alignment.centerRight,
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
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                color: Colors.white.withValues(alpha: 0.9),
                size: AppIconSize.sm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                selectedLanguageLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withValues(alpha: 0.9),
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
          horizontal: AppSpacing.xxxl, vertical: AppSpacing.xxl),
      child: Column(
        children: [
          // Clock icon with glow effect
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: AppIconSize.xl,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'KvikTime',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).auth_signInPrompt,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final theme = Theme.of(context);
    return _GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            _buildGlassTextField(
              controller: _emailController,
              hintText: AppLocalizations.of(context).auth_emailLabel,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || !v.contains('@')
                  ? AppLocalizations.of(context).auth_invalidEmail
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Password field
            _buildGlassTextField(
              controller: _passwordController,
              hintText: AppLocalizations.of(context).auth_passwordLabel,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => (v?.length ?? 0) < 6
                  ? AppLocalizations.of(context).auth_passwordRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),

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
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Sign In Button
            _buildSignInButton(),
            const SizedBox(height: AppSpacing.lg),

            // Forgot Password
            Center(
              child: TextButton(
                onPressed: () => AppRouter.goToForgotPassword(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.9),
                ),
                child: Text(
                  AppLocalizations.of(context).auth_forgotPassword,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: Colors.white.withValues(alpha: 0.7),
                size: AppIconSize.sm,
              ),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
          ),
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
          backgroundColor: Colors.white,
          foregroundColor: _gradientStart,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white.withValues(alpha: 0.0),
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
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg, horizontal: AppSpacing.xxxl),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pillRadius,
        ),
      ),
      child: Text(
        AppLocalizations.of(context).auth_createAccount,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
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
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
