import 'package:alphanessone/services/users_services.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'inAppPurchase_model.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final List<ProductDetails> _productDetails = [];
  final List<Purchase> _purchases = [];
  final UsersService _usersService;

  InAppPurchaseService(this._usersService);

  final Map<String, String> promoCodeToProductId = {
    'A1PROMO': 'alphanessoneplussubscription',
  };

  final Map<String, String> subscriptionDurations = {
    'alphanessoneplussubscription': 'Monthly',
    'coachingalphaness': 'Monthly',
  };

  final Map<String, String> productIdToRole = {
    'alphanessoneplussubscription': 'client_premium',
    'coachingalphaness': 'coach',
  };

  Stream<List<PurchaseDetails>> get purchaseStream => _inAppPurchase.purchaseStream;

  Future<void> initStoreInfo() async {
    debugPrint("Checking store availability...");
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint("Store not available");
      throw Exception("Store not available");
    }
    debugPrint("Store is available");

    const Set<String> kIds = {'alphanessoneplussubscription', 'coachingalphaness'};
    debugPrint("Querying product details for IDs: $kIds");
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("Products not found: ${response.notFoundIDs}");
    }

    debugPrint("Products found: ${response.productDetails.map((pd) => pd.id).toList()}");
    debugPrint("Products found: ${response.productDetails.map((pd) => pd.rawPrice).toList()}");

    _productDetails.addAll(response.productDetails);

    Map<String, List<ProductDetails>> groupedProducts = {};
    for (var product in _productDetails) {
      if (!groupedProducts.containsKey(product.id)) {
        groupedProducts[product.id] = [];
      }
      groupedProducts[product.id]?.add(product);
    }

    for (var key in groupedProducts.keys) {
      groupedProducts[key]?.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    }

    _productDetailsByProductId = groupedProducts;
  }

  Future<void> makePurchase(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    debugPrint("Initiating purchase for product: ${productDetails.id}");
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> redeemPromoCode(String promoCode) async {
    _inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

    try {
      final trimmedPromoCode = promoCode.trim();
      final productId = promoCodeToProductId[trimmedPromoCode];
      if (productId == null) {
        throw Exception("Promo code not found: $trimmedPromoCode");
      }

      final productDetails = _productDetails.firstWhere(
        (pd) => pd.id == productId,
        orElse: () => throw Exception("Product not found for promo code: $trimmedPromoCode"),
      );

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      debugPrint("Initiating purchase with promo code: $trimmedPromoCode");
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("Error redeeming promo code: $e");
      throw Exception("Error redeeming promo code: $e");
    }
  }

  Future<void> handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        String? newRole = productIdToRole[purchaseDetails.productID];
        if (newRole != null) {
          await _usersService.updateUserRole(_usersService.getCurrentUserId(), newRole);
        }

        int durationInDays = _getDurationInDays(purchaseDetails.productID);
        DateTime newExpiryDate = DateTime.now().add(Duration(days: durationInDays));
        DateTime? currentExpiryDate = await _usersService.getUserSubscriptionExpiryDate(_usersService.getCurrentUserId());

        if (currentExpiryDate != null && currentExpiryDate.isAfter(DateTime.now())) {
          newExpiryDate = currentExpiryDate.add(Duration(days: durationInDays));
        }

        await _usersService.updateUserSubscription(
          _usersService.getCurrentUserId(),
          newExpiryDate,
          purchaseDetails.productID,
          purchaseDetails.purchaseID!,
        );

        _purchases.add(Purchase(
          productId: purchaseDetails.productID,
          purchaseId: purchaseDetails.purchaseID!,
          purchaseDate: DateTime.fromMillisecondsSinceEpoch(int.parse(purchaseDetails.transactionDate!)),
        ));
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  int _getDurationInDays(String productId) {
    switch (productId) {
      case 'alphanessoneplussubscription':
      case 'coachingalphaness':
        return 30; // Monthly subscription
      default:
        return 0;
    }
  }

  List<ProductDetails> get productDetails => _productDetails;
  List<Purchase> get purchases => _purchases;
  Map<String, List<ProductDetails>> _productDetailsByProductId = {};
  Map<String, List<ProductDetails>> get productDetailsByProductId => _productDetailsByProductId;
}
