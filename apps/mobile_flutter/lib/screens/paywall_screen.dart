import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/external_links.dart';
import '../models/user_entitlement.dart';
import '../services/billing_service.dart';
import '../services/entitlement_service.dart';
import '../services/supabase_auth_service.dart';

class PaywallScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  final bool showSignOut;

  const PaywallScreen({
    super.key,
    this.onUnlocked,
    this.showSignOut = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final BillingService _billingService = BillingService();
  final EntitlementService _entitlementService = EntitlementService();

  bool _isCheckingEntitlement = true;
  UserEntitlement? _entitlement;
  String? _screenError;

  @override
  void initState() {
    super.initState();
    _billingService.addListener(_onBillingChanged);
    _initialize();
  }

  @override
  void dispose() {
    _billingService.removeListener(_onBillingChanged);
    _billingService.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _billingService.initialize(onEntitlementUpdated: _refreshEntitlement);
      await _refreshEntitlement();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _screenError = e.toString();
      });
    }
  }

  void _onBillingChanged() {
    if (!mounted) return;
    setState(() {
      _screenError = _billingService.errorMessage;
    });
  }

  Future<void> _refreshEntitlement() async {
    if (!mounted) return;
    setState(() {
      _isCheckingEntitlement = true;
    });

    try {
      final entitlement = await _entitlementService.fetchCurrentEntitlement();
      if (!mounted) return;

      setState(() {
        _entitlement = entitlement;
        _isCheckingEntitlement = false;
      });

      if (entitlement?.hasAccess == true) {
        widget.onUnlocked?.call();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingEntitlement = false;
        _screenError = e.toString();
      });
    }
  }

  Future<void> _buyNow() async {
    final userId = context.read<SupabaseAuthService>().currentUser?.id;
    if (userId == null) {
      setState(() {
        _screenError = 'Not authenticated';
      });
      return;
    }

    try {
      await _billingService.buySubscription(userId: userId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _screenError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = _billingService.productDetails;
    final isBusy = _billingService.isProcessingPurchase ||
        _billingService.isLoadingProducts ||
        _isCheckingEntitlement;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('KvikTime Premium'),
        actions: [
          IconButton(
            onPressed: isBusy ? null : _refreshEntitlement,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.workspace_premium,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Unlock all KvikTime features',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Subscribe with Google Play Billing to continue.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildFeatureTile(Icons.history, 'Full history & reports'),
              _buildFeatureTile(Icons.cloud_sync, 'Cloud sync across devices'),
              _buildFeatureTile(Icons.shield_outlined, 'Secure subscription state'),
              const SizedBox(height: 24),
              if (_entitlement != null)
                Text(
                  'Current entitlement: ${_entitlement!.status}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: isBusy || product == null ? null : _buyNow,
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        product == null
                            ? 'Subscription unavailable'
                            : 'Subscribe ${product.price}',
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isBusy ? null : _billingService.restorePurchases,
                child: const Text('Restore purchase'),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(ExternalLinks.manageSubscriptionUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Manage subscription in Google Play'),
              ),
              if (widget.showSignOut)
                TextButton(
                  onPressed: () async {
                    await context.read<SupabaseAuthService>().signOut();
                  },
                  child: const Text('Sign out'),
                ),
              if (_screenError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _screenError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
