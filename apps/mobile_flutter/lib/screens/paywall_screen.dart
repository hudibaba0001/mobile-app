import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/external_links.dart';
import '../models/user_entitlement.dart';
import '../services/billing_service.dart';
import '../services/entitlement_service.dart';
import '../services/supabase_auth_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../design/app_theme.dart';
import '../widgets/standard_app_bar.dart';

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
      final t = AppLocalizations.of(context);
      setState(() {
        _screenError = t.paywall_notAuthenticated;
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
    final t = AppLocalizations.of(context);
    final product = _billingService.productDetails;
    final isBusy = _billingService.isProcessingPurchase ||
        _billingService.isLoadingProducts ||
        _isCheckingEntitlement;

    return Scaffold(
      appBar: StandardAppBar(
        title: t.paywall_title,
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: isBusy ? null : _refreshEntitlement,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.workspace_premium,
                size: AppIconSize.xl * 1.7,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.paywall_unlockAllFeatures,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.paywall_subscribeWithGooglePlay,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildFeatureTile(Icons.history, t.paywall_featureFullHistoryReports),
              _buildFeatureTile(Icons.cloud_sync, t.paywall_featureCloudSync),
              _buildFeatureTile(Icons.shield_outlined, t.paywall_featureSecureSubscription),
              const SizedBox(height: AppSpacing.xl),
              if (_entitlement != null)
                Text(
                  t.paywall_currentEntitlement(_entitlement!.status),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: isBusy || product == null ? null : _buyNow,
                child: isBusy
                    ? const SizedBox(
                        width: AppIconSize.sm,
                        height: AppIconSize.sm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        product == null
                            ? t.paywall_subscriptionUnavailable
                            : t.paywall_subscribe(product.price),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: isBusy ? null : _billingService.restorePurchases,
                child: Text(t.paywall_restorePurchase),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(ExternalLinks.manageSubscriptionUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(t.paywall_manageSubscriptionGooglePlay),
              ),
              if (widget.showSignOut)
                TextButton(
                  onPressed: () async {
                    await context.read<SupabaseAuthService>().signOut();
                  },
                  child: Text(t.paywall_signOut),
                ),
              if (_screenError != null) ...[
                const SizedBox(height: AppSpacing.sm),
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
