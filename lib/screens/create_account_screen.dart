import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_router.dart';
import '../config/external_links.dart';
import '../design/app_theme.dart';
import '../design/components/app_card.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/supabase_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Professional Sign-Up screen based on modern design principles.
/// Features: Gradient background, centered card, trial info, and legal consent checkboxes.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreedToTerms || !_agreedToPrivacy) {
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms and Privacy Policy'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final auth = context.read<SupabaseAuthService>();
      final t = AppLocalizations.of(context);
      
      // Perform Sign Up
      await auth.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // Update profile with names
      await auth.updateUserProfile(
        displayName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please check your email for verification.'),
            backgroundColor: Colors.green,
          ),
        );
        context.goNamed(AppRouter.loginName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.8),
              colorScheme.primary.withValues(alpha: 0.6),
              colorScheme.secondary.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Text(
                            t.account_createTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.account_trialSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Name Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: t.account_firstName,
                                  controller: _firstNameController,
                                  hint: 'John',
                                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: t.account_lastName,
                                  controller: _lastNameController,
                                  hint: 'Doe',
                                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Email
                          _buildTextField(
                            label: t.account_email,
                            controller: _emailController,
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                          ),
                          const SizedBox(height: 20),

                          // Phone (Optional)
                          _buildTextField(
                            label: '${t.account_phoneNumber} ${t.account_optional}',
                            controller: _phoneController,
                            hint: '+46 70 123 4567',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),

                          // Password
                          _buildTextField(
                            label: t.account_password,
                            controller: _passwordController,
                            hint: t.account_passwordHint,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) => (v?.length ?? 0) < 8 ? 'Min 8 characters' : null,
                          ),
                          const SizedBox(height: 24),

                          // Pricing Box
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  t.account_priceTag,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Checkboxes
                          _buildCheckboxRow(
                            value: _agreedToTerms,
                            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                            child: Row(
                              children: [
                                Text(t.account_agreeTerms.split(' ').sublist(0, 3).join(' ') + ' '),
                                GestureDetector(
                                  onTap: () => _launchUrl(ExternalLinks.termsUrl),
                                  child: Text(
                                    'Terms of Service',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildCheckboxRow(
                            value: _agreedToPrivacy,
                            onChanged: (v) => setState(() => _agreedToPrivacy = v ?? false),
                            child: Row(
                              children: [
                                Text(t.account_agreePrivacy.split(' ').sublist(0, 3).join(' ') + ' '),
                                GestureDetector(
                                  onTap: () => _launchUrl(ExternalLinks.privacyUrl),
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isSaving ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    t.account_continuePayment,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(height: 20),

                          // Switch to Login
                          TextButton(
                            onPressed: () => context.goNamed(AppRouter.loginName),
                            child: Text(
                              t.account_alreadyHaveAccount,
                              style: TextStyle(color: colorScheme.primary),
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

