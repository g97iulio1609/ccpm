// lib/Store/in_app_purchase_services.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:alphanessone/Store/in_app_purchase_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class InAppPurchaseService implements BaseInAppPurchaseService {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl = 'https://europe-west1-alphaness-322423.cloudfunctions.net';

  static const Map<String, String> _kProductIds = {
    'prod_PbVZOzg6Nol294': 'alphanessone.monthly',
    'prod_Pagb2CFGJUcuxl': 'alphanessone.yearly',
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

  Future<List<Product>> _getWebProducts() async {
    try {
      final QuerySnapshot productsSnapshot = await _firestore.collection('products').get();

      if (productsSnapshot.docs.isEmpty) {
        throw Exception('Nessun prodotto disponibile');
      }

      final products = productsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product(
          id: doc.id,
          title: data['name'] ?? '',
          description: data['description'] ?? '',
          price: '€${data['price']}',
          rawPrice: (data['price'] as num).toDouble(),
          currencyCode: data['currency'] ?? 'EUR',
          stripePriceId: data['stripePriceId'] ?? '',
          role: data['role'] ?? 'client_premium',
        );
      }).toList();

      return products;
    } catch (e, stackTrace) {
      _logger.e('Errore nel recupero dei prodotti da Firestore', error: e, stackTrace: stackTrace);
      throw Exception('Errore nel recupero dei prodotti: $e');
    }
  }

  @override
  Future<List<Product>> getProducts() async {
    try {
      if (kIsWeb) {
        final products = await _getWebProducts();
        _products.clear();
        _products.addAll(products);
        return products;
      }

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

      if (response.notFoundIDs.isNotEmpty) {
        throw Exception('Prodotti non trovati: ${response.notFoundIDs.join(", ")}');
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
    } catch (e, stackTrace) {
      _logger.e('Errore nel recupero dei prodotti', error: e, stackTrace: stackTrace);
      throw Exception('Errore nel recupero dei prodotti: $e');
    }
  }

  Future<SubscriptionDetails?> getSubscriptionDetails({String? userId}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _logger.w('Utente non autenticato');
        throw Exception('Utente non autenticato');
      }

      // Prima prova con Cloud Functions
      try {
        final callable = _functions.httpsCallable('getSubscriptionDetails');
        final result = await callable.call({'userId': userId ?? currentUser.uid});

        final data = result.data;
        if (data == null || !data['hasSubscription']) {
          _logger.i('Nessuna sottoscrizione trovata tramite Cloud Functions');
          return null;
        }

        final subscription = data['subscription'];
        return SubscriptionDetails(
          id: subscription['id'],
          status: subscription['status'],
          currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(
            subscription['current_period_end'] * 1000,
          ),
          items: (subscription['items'] as List)
              .map(
                (item) => SubscriptionItem(
                  priceId: item['priceId'],
                  productId: item['productId'],
                  quantity: item['quantity'],
                ),
              )
              .toList(),
          platform: 'store',
        );
      } catch (e) {
        _logger.w('Errore nella chiamata Cloud Functions: $e');

        // Se fallisce, prova con HTTP diretto
        final token = await currentUser.getIdToken();
        final response = await http.post(
          Uri.parse('$_baseUrl/getSubscriptionDetails'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: json.encode({'userId': userId ?? currentUser.uid}),
        );

        if (response.statusCode != 200) {
          _logger.w('Errore nella risposta HTTP: ${response.statusCode}');
          _logger.w('Risposta: ${response.body}');
          return null;
        }

        final data = json.decode(response.body);
        if (!data['hasSubscription']) {
          _logger.i('Nessuna sottoscrizione trovata tramite HTTP');
          return null;
        }

        final subscription = data['subscription'];
        return SubscriptionDetails(
          id: subscription['id'],
          status: subscription['status'],
          currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(
            subscription['current_period_end'] * 1000,
          ),
          items: (subscription['items'] as List)
              .map(
                (item) => SubscriptionItem(
                  priceId: item['priceId'],
                  productId: item['productId'],
                  quantity: item['quantity'],
                ),
              )
              .toList(),
          platform: 'store',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Errore nel recupero dei dettagli dell\'abbonamento',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> handleSuccessfulPayment(String purchaseId, String productId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/handleSuccessfulPayment'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'userId': currentUser.uid,
          'purchaseId': purchaseId,
          'productId': productId,
          'platform': 'store',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Errore nella gestione del pagamento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nella gestione del pagamento: $e');
    }
  }

  Future<void> cancelSubscription() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/cancelSubscription'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'userId': currentUser.uid, 'platform': 'store'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Errore nella cancellazione dell\'abbonamento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nella cancellazione dell\'abbonamento: $e');
    }
  }

  Future<void> createGiftSubscription(String userId, int durationInDays) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('createGiftSubscription');

      final result = await callable.call({
        'data': {'userId': userId, 'durationInDays': durationInDays},
      });

      if (result.data == null || result.data['success'] != true) {
        final error = result.data?['error']?.toString() ?? 'Errore sconosciuto';
        throw Exception('Errore nella creazione dell\'abbonamento regalo: $error');
      }
    } catch (e) {
      throw Exception('Errore nella creazione dell\'abbonamento regalo: $e');
    }
  }

  String _getStoreProductId(String firestoreId) {
    final storeId = _kProductIds[firestoreId];
    if (storeId == null) {
      throw Exception('ID prodotto non valido per lo store: $firestoreId');
    }
    return storeId;
  }

  Future<void> handlePurchase(String firestoreProductId) async {
    try {
      if (kIsWeb) {
        throw Exception('Acquisti in-app non supportati sul web');
      }

      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        throw Exception('Store non disponibile');
      }

      final storeProductId = _getStoreProductId(firestoreProductId);
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({
        storeProductId,
      });

      if (response.notFoundIDs.isNotEmpty) {
        throw Exception(
          'Prodotto non trovato nello store. Verifica che il prodotto sia stato configurato correttamente nell\'App Store/Play Store.',
        );
      }

      if (response.productDetails.isEmpty) {
        throw Exception(
          'Nessun dettaglio prodotto trovato. Verifica la configurazione del prodotto nell\'App Store/Play Store.',
        );
      }

      final purchaseParam = PurchaseParam(productDetails: response.productDetails.first);

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _logger.e('Errore durante l\'acquisto', error: e);
      rethrow;
    }
  }

  Future<void> updateSubscription(String firestoreProductId) async {
    try {
      await handlePurchase(firestoreProductId);
    } catch (e) {
      throw Exception('Errore nell\'aggiornamento dell\'abbonamento: $e');
    }
  }

  Future<Map<String, dynamic>> syncStripeSubscription(String userId, {bool syncAll = false}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _logger.w('Utente non autenticato');
        return {'success': false, 'message': 'Utente non autenticato'};
      }

      _logger.i('Chiamata a syncSubscription con userId: $userId, syncAll: $syncAll');
      final callable = _functions.httpsCallable('syncSubscription');
      final result = await callable.call({'userId': userId, 'syncAll': syncAll});

      _logger.i('Risposta ricevuta: ${result.data}');

      if (result.data == null) {
        _logger.w('Risposta nulla dalla Cloud Function');
        return {'success': false, 'message': 'Errore nella sincronizzazione: risposta nulla'};
      }

      return result.data;
    } catch (e, stackTrace) {
      _logger.e('Errore nella sincronizzazione', error: e, stackTrace: stackTrace);
      return {'success': false, 'message': 'Errore nella sincronizzazione: ${e.toString()}'};
    }
  }

  Future<void> syncProducts() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/syncProducts'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Errore nella sincronizzazione dei prodotti: ${response.statusCode}');
      }

      await getProducts();
    } catch (e) {
      throw Exception('Errore nella sincronizzazione dei prodotti: $e');
    }
  }

  @override
  Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        final purchaseUpdated = _inAppPurchase.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _listenToPurchaseUpdated,
          onDone: () {
            _subscription?.cancel();
          },
          onError: (error) {
            _logger.e('Errore nello stream degli acquisti', error: error);
          },
        );
      }

      await getProducts();
    } catch (e) {
      _logger.e('Errore inizializzazione', error: e);
      rethrow;
    }
  }

  void dispose() {
    if (!kIsWeb) {
      _subscription?.cancel();
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.error) {
        _logger.e('Errore nell\'acquisto', error: purchaseDetails.error);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  @override
  Future<Map<String, dynamic>> createCheckoutSession(String userId, String productId) async {
    throw UnimplementedError('createCheckoutSession non è disponibile su mobile');
  }
}
