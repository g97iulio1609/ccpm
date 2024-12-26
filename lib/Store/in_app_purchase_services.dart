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
      printTime: true,
    ),
  );

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl =
      'https://europe-west1-alphaness-322423.cloudfunctions.net';

  // ID dei prodotti per iOS e Android
  static const Map<String, String> _kProductIds = {
    'prod_PbVZOzg6Nol294': 'alphanessone.monthly',
    'prod_Pagb2CFGJUcuxl': 'alphanessone.yearly',
  };

  // Lista interna dei prodotti
  final List<Product> _products = [];
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Getter per i dettagli dei prodotti
  Map<String, List<Product>> get productDetailsByProductId {
    _logger.d(
        'Recupero dettagli prodotti. Prodotti disponibili: ${_products.length}');
    final Map<String, List<Product>> result = {};
    for (var product in _products) {
      _logger.v('Processando prodotto: ${product.id}');
      if (!result.containsKey(product.id)) {
        result[product.id] = [];
      }
      result[product.id]!.add(product);
    }
    return result;
  }

  // Funzione per ottenere i prodotti da Firestore
  Future<List<Product>> _getWebProducts() async {
    _logger.i('🌐 Recupero prodotti da Firestore');
    try {
      final QuerySnapshot productsSnapshot =
          await _firestore.collection('products').get();
      _logger
          .d('Trovati ${productsSnapshot.docs.length} prodotti in Firestore');

      if (productsSnapshot.docs.isEmpty) {
        _logger.w('⚠️ Nessun prodotto trovato in Firestore');
        throw Exception('Nessun prodotto disponibile');
      }

      final products = productsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        _logger.v('📦 Dettagli prodotto da Firestore:');
        _logger.v('- ID: ${doc.id}');
        _logger.v('- Nome: ${data['name']}');
        _logger.v('- Prezzo: ${data['price']}');

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

      _logger.i('✅ Recuperati ${products.length} prodotti da Firestore');
      return products;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Errore nel recupero dei prodotti da Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Errore nel recupero dei prodotti: $e');
    }
  }

  // Funzione per ottenere i prodotti disponibili
  Future<List<Product>> getProducts() async {
    _logger.i('🚀 Inizio getProducts()');
    _logger.d('Piattaforma: ${kIsWeb ? "Web" : "Mobile"}');

    try {
      if (kIsWeb) {
        _logger.w('Piattaforma Web rilevata - recupero prodotti da Firestore');
        final products = await _getWebProducts();
        _products.clear();
        _products.addAll(products);
        return products;
      }

      _logger.d('👉 Verifico disponibilità store...');
      final bool available = await _inAppPurchase.isAvailable();
      _logger.d('Store disponibile: $available');

      if (!available) {
        _logger.e('❌ Store non disponibile');
        throw Exception('Store non disponibile');
      }

      _logger.d('🔍 Ricerca prodotti con IDs: ${_kProductIds.values}');
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_kProductIds.values.toSet());

      _logger.d('📦 Risposta store:');
      _logger.d('- Prodotti trovati: ${response.productDetails.length}');
      _logger.d('- Prodotti non trovati: ${response.notFoundIDs}');
      _logger.d('- Errore: ${response.error}');

      if (response.error != null) {
        _logger.e('❌ Errore store: ${response.error}');
        throw Exception('Errore nel recupero dei prodotti: ${response.error}');
      }

      if (response.productDetails.isEmpty) {
        _logger.w('⚠️ Nessun prodotto trovato');
        throw Exception('Nessun prodotto trovato nello store');
      }

      if (response.notFoundIDs.isNotEmpty) {
        _logger.w('⚠️ Prodotti mancanti: ${response.notFoundIDs.join(", ")}');
        throw Exception(
            'Prodotti non trovati: ${response.notFoundIDs.join(", ")}');
      }

      _products.clear();
      final products = response.productDetails.map((details) {
        _logger.i('📱 Dettagli prodotto:');
        _logger.i('- ID: ${details.id}');
        _logger.i('- Titolo: ${details.title}');
        _logger.i('- Prezzo: ${details.price}');
        _logger.v('- Descrizione: ${details.description}');
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
      _logger.i('✅ Recuperati ${products.length} prodotti con successo');
      return products;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Errore nel recupero dei prodotti',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Errore nel recupero dei prodotti: $e');
    }
  }

  // Funzione per verificare lo stato dell'abbonamento
  Future<SubscriptionDetails?> getSubscriptionDetails({String? userId}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/getSubscriptionDetails'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId ?? currentUser.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella risposta del server: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (!data['hasSubscription']) {
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
            .map((item) => SubscriptionItem(
                  priceId: item['priceId'],
                  productId: item['productId'],
                  quantity: item['quantity'],
                ))
            .toList(),
        platform: 'store',
      );
    } catch (e) {
      throw Exception('Errore nel recupero dei dettagli dell\'abbonamento: $e');
    }
  }

  // Funzione per gestire il pagamento riuscito
  Future<void> handleSuccessfulPayment(
      String purchaseId, String productId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/handleSuccessfulPayment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': currentUser.uid,
          'purchaseId': purchaseId,
          'productId': productId,
          'platform': 'store',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella gestione del pagamento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nella gestione del pagamento: $e');
    }
  }

  // Funzione per cancellare l'abbonamento
  Future<void> cancelSubscription() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/cancelSubscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': currentUser.uid,
          'platform': 'store',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella cancellazione dell\'abbonamento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nella cancellazione dell\'abbonamento: $e');
    }
  }

  // Funzione per creare un abbonamento regalo (solo per admin)
  Future<void> createGiftSubscription(String userId, int durationInDays) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/createGiftSubscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'adminUid': currentUser.uid,
          'userId': userId,
          'durationInDays': durationInDays,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella creazione dell\'abbonamento regalo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nella creazione dell\'abbonamento regalo: $e');
    }
  }

  // Funzione per convertire ID Firestore in ID Store
  String _getStoreProductId(String firestoreId) {
    _logger.d('🔄 Conversione ID Firestore ($firestoreId) in ID Store');
    final storeId = _kProductIds[firestoreId];
    if (storeId == null) {
      _logger.e('❌ ID prodotto Firestore non mappato: $firestoreId');
      throw Exception('ID prodotto non valido per lo store: $firestoreId');
    }
    _logger.d('✅ ID Store trovato: $storeId');
    return storeId;
  }

  // Funzione per gestire l'acquisto
  Future<void> handlePurchase(String firestoreProductId) async {
    try {
      _logger.i('🛒 Avvio acquisto prodotto Firestore: $firestoreProductId');
      _logger.d('📦 Prodotti disponibili nello store: ${_kProductIds}');

      if (kIsWeb) {
        throw Exception('Acquisti in-app non supportati sul web');
      }

      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        _logger.e('❌ Store non disponibile');
        throw Exception('Store non disponibile');
      }

      // Converti l'ID Firestore in ID Store
      final storeProductId = _getStoreProductId(firestoreProductId);
      _logger.d('🔍 Ricerca prodotto nello store con ID: $storeProductId');

      // Verifica se il prodotto è disponibile nello store
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails({storeProductId});

      _logger.d('📦 Risposta store:');
      _logger.d('- Prodotti trovati: ${response.productDetails.length}');
      _logger.d('- Prodotti non trovati: ${response.notFoundIDs}');
      _logger.d('- Errore: ${response.error}');

      if (response.notFoundIDs.isNotEmpty) {
        _logger
            .e('❌ Prodotto non trovato nello store: ${response.notFoundIDs}');
        _logger.e('ID Firestore: $firestoreProductId');
        _logger.e('ID Store mappato: $storeProductId');
        throw Exception(
            'Prodotto non trovato nello store. Verifica che il prodotto sia stato configurato correttamente nell\'App Store/Play Store.');
      }

      if (response.productDetails.isEmpty) {
        _logger.e('❌ Nessun dettaglio prodotto trovato');
        throw Exception(
            'Nessun dettaglio prodotto trovato. Verifica la configurazione del prodotto nell\'App Store/Play Store.');
      }

      _logger.d('📦 Prodotto trovato, preparazione acquisto...');
      _logger.d('Dettagli prodotto:');
      _logger.d('- ID: ${response.productDetails.first.id}');
      _logger.d('- Titolo: ${response.productDetails.first.title}');
      _logger.d('- Descrizione: ${response.productDetails.first.description}');
      _logger.d('- Prezzo: ${response.productDetails.first.price}');

      final purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );

      _logger.d('🚀 Avvio transazione acquisto...');
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      _logger.i('✅ Richiesta di acquisto inviata con successo');
    } catch (e) {
      _logger.e('❌ Errore durante l\'acquisto', error: e);
      rethrow;
    }
  }

  // Funzione per aggiornare l'abbonamento
  Future<void> updateSubscription(String firestoreProductId) async {
    try {
      _logger
          .i('🔄 Aggiornamento abbonamento con prodotto: $firestoreProductId');
      await handlePurchase(firestoreProductId);
    } catch (e) {
      _logger.e('❌ Errore nell\'aggiornamento dell\'abbonamento', error: e);
      throw Exception('Errore nell\'aggiornamento dell\'abbonamento: $e');
    }
  }

  // Funzione per sincronizzare gli abbonamenti
  Future<Map<String, dynamic>> syncStripeSubscription(String userId,
      {bool syncAll = false}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'Utente non autenticato'};
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/syncSubscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'syncAll': syncAll,
        }),
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Errore nella sincronizzazione: ${response.statusCode}'
        };
      }

      final data = json.decode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Sincronizzazione completata con successo'
      };
    } catch (e) {
      return {'success': false, 'message': 'Errore nella sincronizzazione: $e'};
    }
  }

  // Funzione per sincronizzare i prodotti
  Future<void> syncProducts() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/syncProducts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella sincronizzazione dei prodotti: ${response.statusCode}');
      }

      await getProducts(); // Aggiorna la lista dei prodotti dopo la sincronizzazione
    } catch (e) {
      throw Exception('Errore nella sincronizzazione dei prodotti: $e');
    }
  }

  // Funzione per inizializzare il servizio
  Future<void> initialize() async {
    _logger.i('🔄 Inizializzazione InAppPurchaseService');
    try {
      _logger.d('Ambiente: ${kIsWeb ? "Web" : "Mobile"}');

      if (!kIsWeb) {
        // Inizializza lo stream degli acquisti solo su mobile
        final purchaseUpdated = _inAppPurchase.purchaseStream;
        _subscription = purchaseUpdated.listen(
          (purchaseDetailsList) {
            _listenToPurchaseUpdated(purchaseDetailsList);
          },
          onDone: () {
            _subscription?.cancel();
          },
          onError: (error) {
            _logger.e('Errore nello stream degli acquisti', error: error);
          },
        );
      }

      await getProducts();
      _logger.i('✅ Inizializzazione completata');
    } catch (e) {
      _logger.e(
        '❌ Errore inizializzazione',
        error: e,
      );
      rethrow;
    }
  }

  void dispose() {
    if (!kIsWeb) {
      _subscription?.cancel();
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    _logger.d('🔄 Aggiornamento acquisti ricevuto');
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _logger.i('⏳ Acquisto in corso...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _logger.e('❌ Errore nell\'acquisto', error: purchaseDetails.error);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _logger.i('✅ Acquisto completato con successo');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _logger.d('📦 Completamento acquisto in corso...');
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  @override
  Future<Map<String, dynamic>> createCheckoutSession(
      String userId, String productId) async {
    throw UnimplementedError(
        'createCheckoutSession non è disponibile su mobile');
  }
}
