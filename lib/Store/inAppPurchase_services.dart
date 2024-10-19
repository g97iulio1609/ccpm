// lib/Store/inAppPurchase_services.dart

import 'package:alphanessone/utils/debug_logger.dart';
import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'url_redirect.dart'; // Assicurati di avere questo file
import 'package:flutter/material.dart';

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

  final Map<String, List<ProductDetails>> _productDetailsByProductId = {};
  Map<String, List<ProductDetails>> get productDetailsByProductId => _productDetailsByProductId;

  Future<void> initStoreInfo() async {
    debugLog('initStoreInfo called');
    if (isWeb) {
      await _initStripe();
    } else {
      await _initGooglePlay();
    }
  }

  Future<void> _initStripe() async {
    debugLog('Initializing Stripe...');
    try {
      debugLog('Calling getStripeProducts Cloud Function...');
      final result = await _functions.httpsCallable('getStripeProducts').call();
      debugLog('Cloud Function call successful. Raw result: ${result.data}');

      if (result.data == null || !result.data.containsKey('products')) {
        throw Exception('Invalid response format from getStripeProducts');
      }

      final products = List<Map<String, dynamic>>.from(result.data['products']);
      debugLog('Number of products received: ${products.length}');

      _productDetails.clear(); // Clear existing products before adding new ones
      for (var product in products) {
        debugLog('Processing product: ${product['id']}');
        final productDetails = ProductDetails(
          id: product['id'],
          title: product['name'] ?? 'Unknown',
          description: product['description'] ?? '',
          price: ((product['price'] as double?)?.toStringAsFixed(2) ?? '0.00'),
          rawPrice: (product['price'] as double?) ?? 0,
          currencyCode: product['currency'] ?? 'USD',
        );
        _productDetails.add(productDetails);
        _addToProductDetailsByProductId(productDetails);
        debugLog('Added product: ${productDetails.id}');
      }
      debugLog('Stripe initialization completed successfully');
    } catch (e) {
      debugLog('Error initializing Stripe: $e');
      if (e is FirebaseFunctionsException) {
        debugLog('Firebase Functions Error Code: ${e.code}');
        debugLog('Firebase Functions Error Details: ${e.details}');
        debugLog('Firebase Functions Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> _initGooglePlay() async {
    debugLog('Initializing Google Play...');
    try {
      final bool available = await _inAppPurchase.isAvailable();
      debugLog('Google Play Store available: $available');
      if (!available) {
        throw Exception("Store not available");
      }

      const Set<String> kIds = {'alphanessoneplussubscription', 'coachingalphaness'};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugLog('Products not found: ${response.notFoundIDs}');
      }

      _productDetails.addAll(response.productDetails);
      for (var product in response.productDetails) {
        _addToProductDetailsByProductId(product);
      }
      debugLog('Google Play initialization completed successfully');
    } catch (e) {
      debugLog('Error initializing Google Play: $e');
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
    debugLog('makePurchase called for productId: $productId');
    if (isWeb) {
      await _makeStripePurchase(productId);
    } else {
      await _makeGooglePlayPurchase(productId);
    }
  }

  Future<void> _makeStripePurchase(String productId) async {
    debugLog('Making Stripe purchase for productId: $productId');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugLog('User not authenticated');
        throw Exception('User not authenticated');
      }

      debugLog('Calling createCheckoutSession Cloud Function...');
      final result = await _functions.httpsCallable('createCheckoutSession').call({
        'productId': productId,
      });

      debugLog('Cloud Function call successful. Result: ${result.data}');

      if (result.data == null || !result.data.containsKey('url')) {
        debugLog('Invalid response format from createCheckoutSession.');
        throw Exception('Invalid response format from createCheckoutSession.');
      }

      final sessionUrl = result.data['url'] as String;
      debugLog('Received sessionUrl: $sessionUrl');

      final redirectUrl = Uri.parse(sessionUrl);
      debugLog('Redirecting to: $redirectUrl');

      // Utilizza il metodo di redirect condizionato
      await redirectToUrl(redirectUrl);
      debugLog('Stripe Checkout launched successfully');
    } catch (e) {
      debugLog('Error making Stripe purchase: $e');
      _showSnackBar('Errore durante l\'acquisto: $e');
      rethrow;
    }
  }

  Future<void> _makeGooglePlayPurchase(String productId) async {
    debugLog('Making Google Play purchase for productId: $productId');
    try {
      final ProductDetails productDetails = _productDetails.firstWhere(
        (element) => element.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      debugLog('Starting Google Play purchase for productId: $productId');
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugLog('Google Play purchase initiated successfully');
    } catch (e) {
      debugLog('Error making Google Play purchase: $e');
      rethrow;
    }
  }

  Future<void> redeemPromoCode(String promoCode) async {
    debugLog('Redeeming promo code: $promoCode');
    try {
      final result = await _functions.httpsCallable('redeemPromoCode').call({
        'promoCode': promoCode,
      });

      debugLog('Promo code redemption result: ${result.data}');

      if (result.data['success']) {
        debugLog('Promo code redeemed successfully');
      } else {
        debugLog('Promo code redemption failed: ${result.data['message']}');
        throw Exception(result.data['message']);
      }
    } catch (e) {
      debugLog('Error redeeming promo code: $e');
      rethrow;
    }
  }

Future<void> syncStripeSubscription({bool syncAll = false}) async {
  try {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('syncStripeSubscription');
    final result = await callable.call(<String, dynamic>{
      'syncAll': syncAll,
    });

    if (result.data['success']) {
      debugLog(syncAll 
        ? 'Tutte le sottoscrizioni Stripe sincronizzate con successo.'
        : 'Abbonamento Stripe sincronizzato con successo.');
    } else {
      throw Exception(result.data['message']);
    }
  } catch (e) {
    debugLog('Errore nella sincronizzazione dell\'abbonamento Stripe: $e');
    rethrow;
  }
}


  Stream<List<ProductDetails>> getProducts() {
    debugLog('getProducts called');
    return _firestore.collection('products').snapshots().map((snapshot) {
      debugLog('Fetched ${snapshot.docs.length} products from Firestore');
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
    debugLog('handlePurchaseUpdates called with ${purchaseDetailsList.length} purchases');
    for (var purchaseDetails in purchaseDetailsList) {
      debugLog('Processing purchase: ${purchaseDetails.productID}, status: ${purchaseDetails.status}');
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        await _verifyAndUpdateSubscription(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        debugLog('Completed purchase: ${purchaseDetails.productID}');
      }
    }
  }

  Future<void> _verifyAndUpdateSubscription(PurchaseDetails purchaseDetails) async {
    debugLog('Verifying and updating subscription for productId: ${purchaseDetails.productID}');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugLog('User not authenticated');
        throw Exception('User not authenticated');
      }

      final result = await _functions.httpsCallable('verifyPurchase').call({
        'productId': purchaseDetails.productID,
        'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
      });

      debugLog('Purchase verification result: ${result.data}');

      if (result.data['valid']) {
        debugLog('Purchase is valid. Updating user subscription.');
        await _updateUserSubscription(
          user.uid,
          purchaseDetails.productID,
          DateTime.parse(result.data['expiryDate']),
        );
        debugLog('User subscription updated successfully.');
      } else {
        debugLog('Invalid purchase');
        throw Exception('Invalid purchase');
      }
    } catch (e) {
      debugLog('Error verifying and updating subscription: $e');
      rethrow;
    }
  }

  Future<void> _updateUserSubscription(String userId, String productId, DateTime expiryDate) async {
    debugLog('Updating subscription for userId: $userId, productId: $productId, expiryDate: $expiryDate');
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
        debugLog('User subscription updated in Firestore');
      } else {
        debugLog('No role mapping found for productId: $productId');
        throw Exception('No role mapping found for productId: $productId');
      }
    } catch (e) {
      debugLog('Error updating user subscription: $e');
      rethrow;
    }
  }

  Future<void> cancelSubscription() async {
    debugLog('Cancelling subscription');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugLog('User not authenticated');
        throw Exception('User not authenticated');
      }

      final result = await _functions.httpsCallable('cancelSubscription').call();

      debugLog('Cancel subscription result: ${result.data}');

      if (result.data['success']) {
        await _firestore.collection('users').doc(user.uid).update({
          'subscriptionStatus': 'cancelled',
        });
        debugLog('Subscription cancelled successfully');
      } else {
        debugLog('Failed to cancel subscription: ${result.data['message']}');
        throw Exception('Failed to cancel subscription');
      }
    } catch (e) {
      debugLog('Error cancelling subscription: $e');
      rethrow;
    }
  }

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    debugLog('Getting subscription status');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugLog('User not authenticated');
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null || !data.containsKey('subscriptionStatus')) {
        debugLog('No subscription status found');
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
      debugLog('Error getting subscription status: $e');
      return SubscriptionStatus.inactive;
    }
  }

  Future<void> manualSyncProducts() async {
    debugLog('manualSyncProducts called');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugLog('User not authenticated');
        throw Exception('User not authenticated');
      }

      // Verifica che l'utente sia un amministratore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.data()?['role'] != 'admin') {
        debugLog('Unauthorized access: User is not admin');
        throw Exception('Unauthorized access');
      }

      debugLog('Calling manualSyncStripeProducts Cloud Function...');
      final result = await _functions.httpsCallable('manualSyncStripeProducts').call();

      debugLog('manualSyncStripeProducts result: ${result.data}');

      if (result.data['success']) {
        debugLog('Products synced successfully');
        await initStoreInfo();
        debugLog('Products initialized successfully after sync');
      } else {
        debugLog('Failed to sync products: ${result.data['message']}');
        throw Exception(result.data['message']);
      }
    } catch (e) {
      debugLog('Error in manual sync: $e');
      rethrow;
    }
  }

  List<ProductDetails> get productDetails => _productDetails;
  List<Purchase> get purchases => _purchases;

  void _showSnackBar(String message) {
    // Implementa la logica per mostrare uno SnackBar se necessario
    debugLog('SnackBar message: $message');
    // Potresti voler implementare un modo per mostrare SnackBar da qui, ad esempio tramite un callback
  }

  // Recupera i dettagli della sottoscrizione
Future<SubscriptionDetails?> getSubscriptionDetails({String? userId}) async {
    try {
      HttpsCallable callable;

      if (userId != null) {
        // Chiama la funzione Cloud per ottenere i dettagli della sottoscrizione di un utente specifico
        callable = _functions.httpsCallable('getUserSubscriptionDetails');
        final results = await callable.call(<String, dynamic>{
          'userId': userId,
        });

        if (results.data['hasSubscription']) {
          final sub = results.data['subscription'];
          return SubscriptionDetails(
            id: sub['id'],
            status: sub['status'],
            currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(sub['current_period_end'] * 1000),
            items: List<SubscriptionItem>.from(
              sub['items'].map((item) => SubscriptionItem(
                    priceId: item['priceId'],
                    productId: item['productId'],
                    quantity: item['quantity'],
                  )),
            ),
          );
        } else {
          return null;
        }
      } else {
        // Chiama la funzione Cloud per ottenere i dettagli della sottoscrizione dell'utente corrente
        callable = _functions.httpsCallable('getSubscriptionDetails');
        final results = await callable.call();

        if (results.data['hasSubscription']) {
          final sub = results.data['subscription'];
          return SubscriptionDetails(
            id: sub['id'],
            status: sub['status'],
            currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(sub['current_period_end'] * 1000),
            items: List<SubscriptionItem>.from(
              sub['items'].map((item) => SubscriptionItem(
                    priceId: item['priceId'],
                    productId: item['productId'],
                    quantity: item['quantity'],
                  )),
            ),
          );
        } else {
          return null;
        }
      }
    } catch (e) {
      debugLog('Error getting subscription details: $e');
      return null;
    }
  }

  // Aggiorna la sottoscrizione
  Future<void> updateSubscription(String newPriceId) async {
    try {
      final result = await _functions.httpsCallable('updateSubscription').call({
        'newPriceId': newPriceId,
      });
      if (result.data['success']) {
        debugLog('Subscription updated successfully.');
      } else {
        throw Exception('Failed to update subscription.');
      }
    } catch (e) {
      debugLog('Error updating subscription: $e');
      rethrow;
    }
  }

  // Elenca tutte le sottoscrizioni (opzionale)
  Future<List<SubscriptionDetails>> listSubscriptions() async {
    try {
      final result = await _functions.httpsCallable('listSubscriptions').call();
      final List subscriptions = result.data['subscriptions'];
      return subscriptions.map((sub) {
        return SubscriptionDetails(
          id: sub['id'],
          status: sub['status'],
          currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(sub['current_period_end'] * 1000),
          items: List<SubscriptionItem>.from(
            sub['items'].map((item) => SubscriptionItem(
              priceId: item['priceId'],
              productId: item['productId'],
              quantity: item['quantity'],
            )),
          ),
        );
      }).toList();
    } catch (e) {
      debugLog('Error listing subscriptions: $e');
      return [];
    }
  }
}

enum SubscriptionStatus {
  active,
  cancelled,
  expired,
  inactive,
}
