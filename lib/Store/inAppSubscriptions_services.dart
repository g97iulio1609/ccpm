import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'inAppSubscriptions_model.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Map<String, SubscriptionPlan> _plans = {};
  final List<Subscription> _activeSubscriptions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<PurchaseDetails>> get purchaseStream => _inAppPurchase.purchaseStream;

  InAppPurchaseService() {
    _listenToSubscriptionChanges();
    _listenToCouponChanges();
  }

  FirebaseFirestore get firestore => _firestore; // Getter per Firestore

  void _listenToSubscriptionChanges() {
    _firestore.collection('subscriptions').snapshots().listen((snapshot) async {
      _plans.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String kId = data['kId'];

        // Query product details for the subscription
        final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({kId});
        if (response.productDetails.isNotEmpty) {
          final product = response.productDetails.first;
          final plan = SubscriptionPlan(
            kId: product.id,
            displayName: product.title,
            description: product.description,
            duration: Duration(days: data['durationDays']),
            roleOnPurchase: data['roleOnPurchase'],
            roleOnExpire: data['roleOnExpire'],
            gracePeriodDays: data['gracePeriodDays'],
          );
          _plans[plan.kId] = plan;
        }
      }
    });
  }

  void _listenToCouponChanges() {
    // Implementa la logica per ascoltare i cambiamenti nella collezione 'coupons' se necessario
  }

  Future<void> initStoreInfo() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint("Store not available");
      return;
    }

    debugPrint("Store is available");
    await _loadSubscriptionPlansFromFirestore();
  }

Future<void> changeSubscription(String newPlanId, GooglePlayPurchaseDetails oldPurchaseDetails) async {
  final ProductDetails? newProduct = await _getProductDetails(newPlanId);
  if (newProduct == null) {
    throw Exception('Product details not found for new subscription plan');
  }

  final GooglePlayPurchaseParam purchaseParam = GooglePlayPurchaseParam(
    productDetails: newProduct,
    changeSubscriptionParam: ChangeSubscriptionParam(
      oldPurchaseDetails: oldPurchaseDetails,
      replacementMode: ReplacementMode.withTimeProration,  // Utilizza il valore corretto
    ),
  );

  await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
}

  Future<void> _loadSubscriptionPlansFromFirestore() async {
    final QuerySnapshot querySnapshot = await _firestore.collection('subscriptions').get();
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String kId = data['kId'];

      // Query product details for the subscription
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({kId});
      if (response.productDetails.isNotEmpty) {
        final product = response.productDetails.first;
        final plan = SubscriptionPlan(
          kId: product.id,
          displayName: product.title,
          description: product.description,
          duration: Duration(days: data['durationDays']),
          roleOnPurchase: data['roleOnPurchase'],
          roleOnExpire: data['roleOnExpire'],
          gracePeriodDays: data['gracePeriodDays'],
        );
        _plans[plan.kId] = plan;
      }
    }
  }

  Future<void> purchaseSubscription(String kId) async {
    final plan = _plans[kId];
    if (plan == null) {
      throw Exception('Subscription plan not found');
    }

    final ProductDetails? product = await _getProductDetails(kId);
    if (product == null) {
      throw Exception('Product details not found');
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<ProductDetails?> _getProductDetails(String kId) async {
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({kId});
    return response.productDetails.isEmpty ? null : response.productDetails.first;
  }

  Future<void> handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      final plan = _plans[purchaseDetails.productID];
      if (plan != null) {
        final subscription = Subscription(
          id: purchaseDetails.purchaseID!,
          plan: plan,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(plan.duration),
        );
        _activeSubscriptions.add(subscription);
        await _updateUserRole(plan.roleOnPurchase);
      }
    }
  }

  Future<void> checkSubscriptionStatus() async {
    final now = DateTime.now();
    for (var subscription in _activeSubscriptions) {
      if (subscription.endDate != null && subscription.endDate!.isBefore(now)) {
        if (subscription.status == SubscriptionStatus.active) {
          subscription.status = SubscriptionStatus.gracePeriod;
          subscription.endDate = subscription.endDate!.add(Duration(days: subscription.plan.gracePeriodDays));
        } else if (subscription.status == SubscriptionStatus.gracePeriod) {
          subscription.status = SubscriptionStatus.expired;
          await _updateUserRole(subscription.plan.roleOnExpire);
        }
      }
    }
  }

  Future<void> _updateUserRole(String? newRole) async {
    if (newRole != null) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({'role': newRole});
      }
    }
  }

  Future<void> redeemPromoCode(String promoCode) async {
    try {
      final trimmedPromoCode = promoCode.trim();
      final DocumentSnapshot couponDoc = await _firestore.collection('coupons').doc(trimmedPromoCode).get();

      if (!couponDoc.exists) {
        throw Exception("Promo code not found: $trimmedPromoCode");
      }

      final data = couponDoc.data() as Map<String, dynamic>;
      final productId = data['productId'];
      final plan = _plans[productId];

      if (plan == null) {
        throw Exception("Subscription plan not found for promo code: $trimmedPromoCode");
      }

      final ProductDetails? product = await _getProductDetails(productId);
      if (product == null) {
        throw Exception("Product details not found for promo code: $trimmedPromoCode");
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("Error redeeming promo code: $e");
      rethrow;
    }
  }

  List<SubscriptionPlan> get availablePlans => _plans.values.toList();
  List<Subscription> get activeSubscriptions => _activeSubscriptions;

  void logAvailableProducts(ProductDetailsResponse response) {
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("Products not found: ${response.notFoundIDs}");
    }

    for (var product in response.productDetails) {
      debugPrint("Product available: ${product.id} - ${product.title} - ${product.description}");
    }

    debugPrint("Available plans: ${_plans.length}");
    for (var plan in _plans.values) {
      debugPrint("Plan ID: ${plan.kId}, Title: ${plan.displayName}, Duration: ${plan.duration.inDays} days");
    }
  }
}