import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class StripeService {
  static const String _stripePublishableKey = 'pk_test_...'; // Replace with your Stripe publishable key
  
  // Initialize Stripe
  static Future<void> initialize() async {
    Stripe.publishableKey = _stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  // Create payment intent
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.functionBaseUrl}/stripe/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'customerId': customerId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  // Create subscription
  static Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required String priceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.functionBaseUrl}/stripe/create-subscription'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'customerId': customerId,
          'priceId': priceId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create subscription: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating subscription: $e');
    }
  }

  // Create customer
  static Future<Map<String, dynamic>> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.functionBaseUrl}/stripe/create-customer'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create customer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  // Process payment
  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String customerId,
  }) async {
    try {
      // Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        customerId: customerId,
      );

      // Confirm payment with Stripe
      final paymentResult = await Stripe.instance.confirmPayment(
        paymentIntent['clientSecret'],
        PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      return {
        'success': true,
        'paymentIntent': paymentIntent,
        'paymentResult': paymentResult,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get subscription plans
  static Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.functionBaseUrl}/stripe/plans'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['plans']);
      } else {
        throw Exception('Failed to get subscription plans: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting subscription plans: $e');
    }
  }

  // Cancel subscription
  static Future<Map<String, dynamic>> cancelSubscription({
    required String subscriptionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.functionBaseUrl}/stripe/cancel-subscription'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'subscriptionId': subscriptionId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to cancel subscription: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error canceling subscription: $e');
    }
  }

  // Get customer subscriptions
  static Future<List<Map<String, dynamic>>> getCustomerSubscriptions({
    required String customerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.functionBaseUrl}/stripe/customer-subscriptions/$customerId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['subscriptions']);
      } else {
        throw Exception('Failed to get customer subscriptions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting customer subscriptions: $e');
    }
  }
}

// Subscription plan model
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval; // monthly, yearly
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
    this.isPopular = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      currency: json['currency'],
      interval: json['interval'],
      features: List<String>.from(json['features']),
      isPopular: json['isPopular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'features': features,
      'isPopular': isPopular,
    };
  }
} 