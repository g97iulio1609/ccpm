import 'package:alphanessone/Store/in_app_purchase_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InAppPurchaseServiceWeb implements BaseInAppPurchaseService {
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

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl =
      'https://europe-west1-alphaness-322423.cloudfunctions.net';

  // Lista interna dei prodotti
  final List<Product> _products = [];

  // Getter per i dettagli dei prodotti
  Map<String, List<Product>> get productDetailsByProductId {
    _logger.d(
      'Recupero dettagli prodotti. Prodotti disponibili: ${_products.length}',
    );
    final Map<String, List<Product>> result = {};
    for (var product in _products) {
      if (!result.containsKey(product.id)) {
        result[product.id] = [];
      }
      result[product.id]!.add(product);
    }
    return result;
  }

  @override
  Future<List<Product>> getProducts() async {
    _logger.i('🌐 Recupero prodotti da Firestore');
    try {
      final QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .get();
      _logger.d(
        'Trovati ${productsSnapshot.docs.length} prodotti in Firestore',
      );

      if (productsSnapshot.docs.isEmpty) {
        _logger.w('⚠️ Nessun prodotto trovato in Firestore');
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

      _products.clear();
      _products.addAll(products);
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

  @override
  Future<Map<String, dynamic>> createCheckoutSession(
    String userId,
    String productId,
  ) async {
    try {
      // Trova il prodotto corrispondente per ottenere lo stripePriceId
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Prodotto non trovato'),
      );

      _logger.d('🔄 Creazione sessione di checkout...');
      _logger.d('- UserId: $userId');
      _logger.d('- ProductId: $productId');
      _logger.d('- StripePriceId: ${product.stripePriceId}');

      final response = await _functions
          .httpsCallable('createCheckoutSession')
          .call({
            'userId': userId,
            'productId': productId,
            'priceId': product.stripePriceId,
          });

      final data = response.data as Map<String, dynamic>;
      _logger.d('🐛 Risposta server: $data');

      if (data['success'] == true && data['clientSecret'] != null) {
        return {'success': true, 'clientSecret': data['clientSecret']};
      } else {
        throw Exception(
          'Risposta non valida dal server: ${data['error'] ?? 'Errore sconosciuto'}',
        );
      }
    } catch (e) {
      _logger.e(
        '⛔ Errore nella creazione della sessione di checkout',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> handleSuccessfulPayment(
    String purchaseId,
    String productId,
  ) async {
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
          'platform': 'web',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Errore nella gestione del pagamento: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Errore nella gestione del pagamento: $e');
    }
  }

  @override
  Future<void> initialize() async {
    _logger.i('🔄 Inizializzazione InAppPurchaseService Web');
    try {
      await getProducts();
      _logger.i('✅ Inizializzazione completata');
    } catch (e) {
      _logger.e('❌ Errore inizializzazione', error: e);
      rethrow;
    }
  }

  // ... rest of the existing methods ...
}
