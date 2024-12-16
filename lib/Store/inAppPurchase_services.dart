// lib/Store/inAppPurchase_services.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class InAppPurchaseService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');
  static const String _baseUrl =
      'https://europe-west1-alphaness-322423.cloudfunctions.net';

  // Funzione per ottenere i prodotti disponibili
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getStripeProducts'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella risposta del server: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final products = (data['products'] as List)
          .map((product) => Product(
                id: product['id'],
                title: product['name'],
                description: product['description'] ?? '',
                price:
                    '${product['price']} ${product['currency'].toUpperCase()}',
                rawPrice: product['price'].toDouble(),
                currencyCode: product['currency'],
              ))
          .toList();
      return products;
    } catch (e) {
      throw Exception('Errore nel recupero dei prodotti: $e');
    }
  }

  // Funzione per creare un PaymentIntent
  Future<Map<String, dynamic>> createPaymentIntent(
      String productId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/createPaymentIntent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'productId': productId,
          'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella creazione del PaymentIntent: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Errore nella creazione del PaymentIntent: $e');
    }
  }

  // Getter per i dettagli dei prodotti
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

  // Lista interna dei prodotti
  final List<Product> _products = [];

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
        platform: 'stripe',
      );
    } catch (e) {
      throw Exception('Errore nel recupero dei dettagli dell\'abbonamento: $e');
    }
  }

  // Funzione per cancellare l'abbonamento
  Future<void> cancelSubscription() async {
    try {
      await _functions.httpsCallable('cancelSubscription').call();
    } catch (e) {
      throw Exception('Errore nella cancellazione dell\'abbonamento: $e');
    }
  }

  // Funzione per applicare un codice promozionale
  Future<void> redeemPromoCode(String code) async {
    try {
      await _functions.httpsCallable('redeemPromoCode').call({
        'code': code,
      });
    } catch (e) {
      throw Exception('Errore nell\'applicazione del codice promozionale: $e');
    }
  }

  // Funzione per aggiornare l'abbonamento
  Future<void> updateSubscription(String newPriceId) async {
    try {
      final result = await _functions.httpsCallable('updateSubscription').call({
        'newPriceId': newPriceId,
      });

      if (!result.data['success']) {
        throw Exception(result.data['message'] ??
            'Errore nell\'aggiornamento dell\'abbonamento');
      }
    } catch (e) {
      throw Exception('Errore nell\'aggiornamento dell\'abbonamento: $e');
    }
  }

  // Funzione per creare un abbonamento regalo
  Future<void> giftSubscription(String userId, int durationInDays) async {
    try {
      final result =
          await _functions.httpsCallable('createGiftSubscription').call({
        'userId': userId,
        'durationInDays': durationInDays,
      });

      if (!result.data['success']) {
        throw Exception(result.data['message'] ??
            'Errore nella creazione dell\'abbonamento regalo');
      }
    } catch (e) {
      throw Exception('Errore nella creazione dell\'abbonamento regalo: $e');
    }
  }

  // Funzione per sincronizzare i prodotti
  Future<void> syncProducts() async {
    try {
      final products = await getProducts();
      _products.clear();
      _products.addAll(products);
    } catch (e) {
      throw Exception('Errore nella sincronizzazione dei prodotti: $e');
    }
  }

  // Funzione per inizializzare il servizio
  Future<void> initialize() async {
    await syncProducts();
  }

  // Funzione per sincronizzare le sottoscrizioni con Stripe
  Future<Map<String, dynamic>> syncStripeSubscription(String userId,
      {bool syncAll = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/syncStripeSubscription'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'syncAll': syncAll,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella sincronizzazione: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Errore nella sincronizzazione: $e');
    }
  }
}
