import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppPurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final bool isWeb = kIsWeb;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final List<ProductDetails> _productDetails = [];
  final List<Purchase> _purchases = [];

  Map<String, String> productIdToRole = {
    'alphanessoneplussubscription': 'client_premium',
    'coachingalphaness': 'coach',
  };

  Map<String, List<ProductDetails>> _productDetailsByProductId = {};
  Map<String, List<ProductDetails>> get productDetailsByProductId => _productDetailsByProductId;

  Future<void> initStoreInfo() async {
    debugPrint('initStoreInfo called');
    if (isWeb) {
      await _initStripe();
    } else {
      await _initGooglePlay();
    }
  }

  Future<void> _initStripe() async {
    debugPrint('Initializing Stripe...');
    try {
      debugPrint('Calling getStripeProducts Cloud Function...');
      final result = await _functions.httpsCallable('getStripeProducts').call();
      debugPrint('Cloud Function call successful. Raw result: ${result.data}');

      if (result.data == null || !result.data.containsKey('products')) {
        throw Exception('Invalid response format from getStripeProducts');
      }

      final products = List<Map<String, dynamic>>.from(result.data['products']);
      debugPrint('Number of products received: ${products.length}');

      _productDetails.clear(); // Clear existing products before adding new ones
      for (var product in products) {
        debugPrint('Processing product: ${product['id']}');
        final productDetails = ProductDetails(
          id: product['id'],
          title: product['name'] ?? 'Unknown',
          description: product['description'] ?? '',
          price: ((product['price'] as double?) ?? 0).toStringAsFixed(2),
          rawPrice: (product['price'] as double?) ?? 0,
          currencyCode: product['currency'] ?? 'USD',
        );
        _productDetails.add(productDetails);
        _addToProductDetailsByProductId(productDetails);
        debugPrint('Added product: ${productDetails.id}');
      }
      debugPrint('Stripe initialization completed successfully');
    } catch (e) {
      debugPrint('Error initializing Stripe: $e');
      if (e is FirebaseFunctionsException) {
        debugPrint('Firebase Functions Error Code: ${e.code}');
        debugPrint('Firebase Functions Error Details: ${e.details}');
        debugPrint('Firebase Functions Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> _initGooglePlay() async {
    debugPrint('Initializing Google Play...');
    try {
      final bool available = await _inAppPurchase.isAvailable();
      debugPrint('Google Play Store available: $available');
      if (!available) {
        throw Exception("Store not available");
      }

      const Set<String> kIds = {'alphanessoneplussubscription', 'coachingalphaness'};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _productDetails.addAll(response.productDetails);
      for (var product in response.productDetails) {
        _addToProductDetailsByProductId(product);
      }
      debugPrint('Google Play initialization completed successfully');
    } catch (e) {
      debugPrint('Error initializing Google Play: $e');
    }
  }

  void _addToProductDetailsByProductId(ProductDetails product) {
    if (!_productDetailsByProductId.containsKey(product.id)) {
      _productDetailsByProductId[product.id] = [];
    }
    _productDetailsByProductId[product.id]!.add(product);
    _productDetailsByProductId[product.id]!.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  Future<void> makePurchase(String productId) async {
    debugPrint('makePurchase called for productId: $productId');
    if (isWeb) {
      await _makeStripePurchase(productId);
    } else {
      await _makeGooglePlayPurchase(productId);
    }
  }

  Future<void> _makeStripePurchase(String productId) async {
    debugPrint('Making Stripe purchase for productId: $productId');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('Calling createCheckoutSession Cloud Function...');
      final result = await _functions.httpsCallable('createCheckoutSession').call({
        'productId': productId,
      });

      debugPrint('Cloud Function call successful. Result: ${result.data}');

      if (result.data == null || !result.data.containsKey('url')) {
        debugPrint('Invalid response format from createCheckoutSession.');
        throw Exception('Invalid response format from createCheckoutSession.');
      }

      final sessionUrl = result.data['url'];
      debugPrint('Received sessionUrl: $sessionUrl');

      // Redirect to Stripe Checkout
      final redirectUrl = sessionUrl;
      debugPrint('Redirecting to: $redirectUrl');
      if (await canLaunch(redirectUrl)) {
        await launch(redirectUrl);
        debugPrint('Stripe Checkout launched successfully');
      } else {
        debugPrint('Could not launch Stripe Checkout');
        throw Exception('Could not launch Stripe Checkout');
      }
    } catch (e) {
      debugPrint('Error making Stripe purchase: $e');
      rethrow;
    }
  }

  Future<void> _makeGooglePlayPurchase(String productId) async {
    debugPrint('Making Google Play purchase for productId: $productId');
    try {
      final ProductDetails? productDetails = _productDetails.firstWhere(
        (element) => element.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      if (productDetails == null) {
        debugPrint('Product details are null for productId: $productId');
        throw Exception('Product details are null');
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      debugPrint('Starting Google Play purchase for productId: $productId');
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('Google Play purchase initiated successfully');
    } catch (e) {
      debugPrint('Error making Google Play purchase: $e');
      rethrow;
    }
  }

  Future<void> redeemPromoCode(String promoCode) async {
    debugPrint('Redeeming promo code: $promoCode');
    try {
      final result = await _functions.httpsCallable('redeemPromoCode').call({
        'promoCode': promoCode,
      });

      debugPrint('Promo code redemption result: ${result.data}');

      if (result.data['success']) {
        debugPrint('Promo code redeemed successfully');
      } else {
        debugPrint('Promo code redemption failed: ${result.data['message']}');
        throw Exception(result.data['message']);
      }
    } catch (e) {
      debugPrint('Error redeeming promo code: $e');
      rethrow;
    }
  }

  Stream<List<ProductDetails>> getProducts() {
    debugPrint('getProducts called');
    return _firestore.collection('products').snapshots().map((snapshot) {
      debugPrint('Fetched ${snapshot.docs.length} products from Firestore');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductDetails(
          id: doc.id,
          title: data['name'],
          description: data['description'],
          price: (data['price'] / 100).toStringAsFixed(2),
          rawPrice: data['price'] / 100,
          currencyCode: data['currency'],
        );
      }).toList();
    });
  }

  Future<void> handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    debugPrint('handlePurchaseUpdates called with ${purchaseDetailsList.length} purchases');
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint('Processing purchase: ${purchaseDetails.productID}, status: ${purchaseDetails.status}');
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        await _verifyAndUpdateSubscription(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        debugPrint('Completed purchase: ${purchaseDetails.productID}');
      }
    }
  }

  Future<void> _verifyAndUpdateSubscription(PurchaseDetails purchaseDetails) async {
    debugPrint('Verifying and updating subscription for productId: ${purchaseDetails.productID}');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        throw Exception('User not authenticated');
      }

      final result = await _functions.httpsCallable('verifyPurchase').call({
        'productId': purchaseDetails.productID,
        'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
      });

      debugPrint('Purchase verification result: ${result.data}');

      if (result.data['valid']) {
        debugPrint('Purchase is valid. Updating user subscription.');
        await _updateUserSubscription(
          user.uid,
          purchaseDetails.productID,
          DateTime.parse(result.data['expiryDate']),
        );
        debugPrint('User subscription updated successfully.');
      } else {
        debugPrint('Invalid purchase');
        throw Exception('Invalid purchase');
      }
    } catch (e) {
      debugPrint('Error verifying and updating subscription: $e');
      rethrow;
    }
  }

  Future<void> _updateUserSubscription(String userId, String productId, DateTime expiryDate) async {
    debugPrint('Updating subscription for userId: $userId, productId: $productId, expiryDate: $expiryDate');
    try {
      String? newRole = productIdToRole[productId];
      if (newRole != null) {
        await _firestore.collection('users').doc(userId).update({
          'role': newRole,
          'subscriptionProductId': productId,
          'subscriptionPlatform': isWeb ? 'stripe' : 'google_play',
          'subscriptionStartDate': FieldValue.serverTimestamp(),
          'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
          'subscriptionStatus': 'active',
        });
        debugPrint('User subscription updated in Firestore');
      } else {
        debugPrint('No role mapping found for productId: $productId');
        throw Exception('No role mapping found for productId: $productId');
      }
    } catch (e) {
      debugPrint('Error updating user subscription: $e');
      rethrow;
    }
  }

  Future<void> cancelSubscription() async {
    debugPrint('Cancelling subscription');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        throw Exception('User not authenticated');
      }

      final result = await _functions.httpsCallable('cancelSubscription').call();

      debugPrint('Cancel subscription result: ${result.data}');

      if (result.data['success']) {
        await _firestore.collection('users').doc(user.uid).update({
          'subscriptionStatus': 'cancelled',
        });
        debugPrint('Subscription cancelled successfully');
      } else {
        debugPrint('Failed to cancel subscription: ${result.data['message']}');
        throw Exception('Failed to cancel subscription');
      }
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    }
  }

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    debugPrint('Getting subscription status');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null || !data.containsKey('subscriptionStatus')) {
        debugPrint('No subscription status found');
        return SubscriptionStatus.inactive;
      }

      switch (data['subscriptionStatus']) {
        case 'active':
          return SubscriptionStatus.active;
        case 'cancelled':
          return SubscriptionStatus.cancelled;
        case 'expired':
          return SubscriptionStatus.expired;
        default:
          return SubscriptionStatus.inactive;
      }
    } catch (e) {
      debugPrint('Error getting subscription status: $e');
      return SubscriptionStatus.inactive;
    }
  }

  Future<void> manualSyncProducts() async {
    debugPrint('manualSyncProducts called');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        throw Exception('User not authenticated');
      }

      // Verifica che l'utente sia un amministratore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.data()?['role'] != 'admin') {
        debugPrint('Unauthorized access: User is not admin');
        throw Exception('Unauthorized access');
      }

      debugPrint('Calling manualSyncStripeProducts Cloud Function...');
      final result = await _functions.httpsCallable('manualSyncStripeProducts').call();

      debugPrint('manualSyncStripeProducts result: ${result.data}');

      if (result.data['success']) {
        debugPrint('Products synced successfully');
        await initStoreInfo();
        debugPrint('Products initialized successfully after sync');
      } else {
        debugPrint('Failed to sync products: ${result.data['message']}');
        throw Exception(result.data['message']);
      }
    } catch (e) {
      debugPrint('Error in manual sync: $e');
      rethrow;
    }
  }

  List<ProductDetails> get productDetails => _productDetails;
  List<Purchase> get purchases => _purchases;
}

enum SubscriptionStatus {
  active,
  cancelled,
  expired,
  inactive,
}
