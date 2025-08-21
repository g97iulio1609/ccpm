import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:alphanessone/Store/in_app_purchase_model.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class InAppPurchaseServiceMobile {
  static const Map<String, String> _kProductIds = {
    'monthly': 'alphanessoneplusathlete',
    'yearly': 'alphanessoneplusathlete1y',
    'quarterly': 'alphanessoneplusathlete3m',
    'semiannual': 'alphanessoneplusathlete6m',
    'coaching_monthly': 'coachinga1monthly',
    'coaching_quarterly': 'coachinga1quarterly',
    'coaching_semiannual': 'coachinga1semiannual',
  };

  final List<Product> _products = [];
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Map<String, List<Product>> get productDetailsByProductId {
    final Map<String, List<Product>> result = {};
    for (var product in _products) {
      if (!result.containsKey(product.id)) {
        result[product.id] = [];
      }
      result[product.id]!.add(product);
    }
    return result;
  }

  Future<List<Product>> getProducts() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();

      if (!available) {
        throw Exception('Store non disponibile');
      }

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
        _kProductIds.values.toSet(),
      );

      if (response.error != null) {
        throw Exception('Errore nel recupero dei prodotti: ${response.error}');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('Nessun prodotto trovato nello store');
      }

      _products.clear();
      final products = response.productDetails.map((details) {
        return Product(
          id: details.id,
          title: details.title,
          description: details.description,
          price: details.price,
          rawPrice: details.rawPrice,
          currencyCode: details.currencyCode,
          stripePriceId: '',
          role: 'client_premium',
        );
      }).toList();

      _products.addAll(products);
      return products;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> handlePurchase(String productId) async {
    try {
      final bool available = await _inAppPurchase.isAvailable();

      if (!available) {
        throw Exception('Store non disponibile');
      }

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});

      if (response.notFoundIDs.isNotEmpty) {
        throw Exception('Prodotto non trovato nello store');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('Nessun dettaglio prodotto trovato');
      }

      final productDetails = response.productDetails.first;
      final currentUser = FirebaseAuth.instance.currentUser;

      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: currentUser?.uid,
      );

      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        throw Exception('Errore nell\'avvio dell\'acquisto');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> initialize() async {
    try {
      bool isAvailable = await _inAppPurchase.isAvailable();
      int retryCount = 0;
      const maxRetries = 3;

      while (!isAvailable && retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: 2));
        isAvailable = await _inAppPurchase.isAvailable();
        retryCount++;
      }

      if (!isAvailable) {
        throw Exception(
          'Store non disponibile dopo $maxRetries tentativi. Verifica la connessione al Play Store.',
        );
      }

      final purchaseUpdated = _inAppPurchase.purchaseStream;
      _subscription?.cancel();

      _subscription = purchaseUpdated.listen(
        _listenToPurchaseUpdated,
        onDone: () {
          _subscription?.cancel();
        },
      );

      await getProducts();
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }
    } catch (e) {
      rethrow;
    }
  }
}
