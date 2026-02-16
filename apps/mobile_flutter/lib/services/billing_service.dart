import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_config.dart';
import '../config/supabase_config.dart';

class BillingService extends ChangeNotifier {
  static const String defaultProductId = 'kviktime_susbcription';

  final InAppPurchase _inAppPurchase;
  final String productId;
  final _supabase = SupabaseConfig.client;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _productDetails;
  bool _storeAvailable = false;
  bool _isLoadingProducts = false;
  bool _isProcessingPurchase = false;
  String? _errorMessage;
  String? _lastVerifiedStatus;
  VoidCallback? _onEntitlementUpdated;

  BillingService({
    InAppPurchase? inAppPurchase,
    this.productId = defaultProductId,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  bool get storeAvailable => _storeAvailable;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isProcessingPurchase => _isProcessingPurchase;
  String? get errorMessage => _errorMessage;
  String? get lastVerifiedStatus => _lastVerifiedStatus;
  ProductDetails? get productDetails => _productDetails;

  String get _apiBase {
    final configured = AppConfig.apiBase.trim();
    if (configured.isNotEmpty) return configured;
    return 'https://app.kviktime.se';
  }

  Future<void> initialize({VoidCallback? onEntitlementUpdated}) async {
    _onEntitlementUpdated = onEntitlementUpdated;

    _purchaseSubscription ??=
        _inAppPurchase.purchaseStream.listen(_handlePurchaseUpdates,
            onError: (Object error) {
      _errorMessage = 'Purchase stream error: $error';
      _isProcessingPurchase = false;
      notifyListeners();
    });

    _storeAvailable = await _inAppPurchase.isAvailable();
    if (!_storeAvailable) {
      _errorMessage = 'Google Play billing is unavailable on this device.';
      notifyListeners();
      return;
    }

    await loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response =
          await _inAppPurchase.queryProductDetails(<String>{productId});

      if (response.error != null) {
        _errorMessage = response.error!.message;
        _productDetails = null;
      } else if (response.productDetails.isEmpty) {
        _errorMessage = 'Subscription product not found in Google Play.';
        _productDetails = null;
      } else {
        _productDetails = response.productDetails.first;
      }
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
      _productDetails = null;
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> buySubscription({required String userId}) async {
    if (!_storeAvailable) {
      throw Exception('Google Play billing unavailable');
    }
    if (_productDetails == null) {
      throw Exception('Subscription product unavailable');
    }

    _errorMessage = null;
    _isProcessingPurchase = true;
    notifyListeners();

    final purchaseParam = PurchaseParam(
      productDetails: _productDetails!,
      applicationUserName: userId,
    );

    final started =
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      _isProcessingPurchase = false;
      _errorMessage = 'Unable to start purchase flow.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _errorMessage = null;
    notifyListeners();
    await _inAppPurchase.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      await _handleSinglePurchaseUpdate(purchase);
    }
  }

  Future<void> _handleSinglePurchaseUpdate(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _isProcessingPurchase = true;
        notifyListeners();
        return;
      case PurchaseStatus.error:
        _isProcessingPurchase = false;
        _errorMessage =
            purchase.error?.message ?? 'Purchase failed. Please try again.';
        notifyListeners();
        return;
      case PurchaseStatus.canceled:
        _isProcessingPurchase = false;
        _errorMessage = 'Purchase canceled.';
        notifyListeners();
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        break;
    }

    try {
      final purchaseToken = _extractPurchaseToken(purchase);
      if (purchaseToken == null || purchaseToken.isEmpty) {
        throw Exception('Unable to read purchase token from Google Play.');
      }

      final status = await _verifyPurchaseWithBackend(
        purchaseToken: purchaseToken,
        productId: purchase.productID,
      );
      _lastVerifiedStatus = status;

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }

      _isProcessingPurchase = false;
      _errorMessage = null;
      _onEntitlementUpdated?.call();
      notifyListeners();
    } catch (e) {
      _isProcessingPurchase = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  String? _extractPurchaseToken(PurchaseDetails purchase) {
    final purchaseToken = purchase.verificationData.serverVerificationData;
    if (purchaseToken.isEmpty) return null;
    return purchaseToken;
  }

  Future<String> _verifyPurchaseWithBackend({
    required String purchaseToken,
    required String productId,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$_apiBase/api/billing/google/verify');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'purchaseToken': purchaseToken,
        'productId': productId,
      }),
    );

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] ?? 'Purchase verification failed';
      throw Exception(message.toString());
    }

    final status = body['status'] as String? ?? 'pending_subscription';
    return status;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    super.dispose();
  }
}
