// inAppSubscriptions_services.dart

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'inAppSubscriptions_model.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final List<ProductDetails> _productDetails = [];
  final List<Purchase> _purchases = [];

  Stream<List<PurchaseDetails>> get purchaseStream => _inAppPurchase.purchaseStream;

  Future<void> initStoreInfo() async {
    debugPrint("Checking store availability...");
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint("Store not available");
      throw Exception("Store not available");
    }
    debugPrint("Store is available");

    const Set<String> _kIds = {'alphanessoneplussubscription', 'alphanessoneplusathlete3m'}; // Sostituisci con gli ID dei tuoi prodotti
    debugPrint("Querying product details for IDs: $_kIds");
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("Products not found: ${response.notFoundIDs}");
    }

    debugPrint("Products found: ${response.productDetails.map((pd) => pd.id).toList()}");
    _productDetails.addAll(response.productDetails);
  }

  Future<void> makePurchase(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    debugPrint("Initiating purchase for product: ${productDetails.id}");
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased) {
        debugPrint("Purchase completed: ${purchase.productID}");
        _purchases.add(Purchase(
          productId: purchase.productID,
          purchaseId: purchase.purchaseID!,
          purchaseDate: DateTime.fromMillisecondsSinceEpoch(int.parse(purchase.transactionDate!)),
        ));
      }
      if (purchase.pendingCompletePurchase) {
        debugPrint("Completing purchase: ${purchase.productID}");
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  List<ProductDetails> get productDetails => _productDetails;
  List<Purchase> get purchases => _purchases;
}
