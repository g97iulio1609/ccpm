// lib/Store/in_app_purchase_services.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:alphanessone/Store/in_app_purchase_model.dart';
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
        Uri.parse('$_baseUrl/getProducts'),
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
                stripePriceId: product['stripePriceId'],
                role: product['role'] ?? 'client_premium',
              ))
          .toList();
      return products;
    } catch (e) {
      throw Exception('Errore nel recupero dei prodotti: $e');
    }
  }

  // Funzione per creare una sessione di checkout
  Future<Map<String, dynamic>> createCheckoutSession(String productId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/createCheckoutSession'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': productId,
          'userId': currentUser.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella creazione della sessione di checkout: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return {
        'sessionId': data['sessionId'],
        'url': data['url'],
      };
    } catch (e) {
      throw Exception('Errore nella creazione della sessione di checkout: $e');
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

  // Funzione per aggiornare l'abbonamento
  Future<void> updateSubscription(String newPriceId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/updateSubscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': currentUser.uid,
          'newPriceId': newPriceId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nell\'aggiornamento dell\'abbonamento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nell\'aggiornamento dell\'abbonamento: $e');
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

  // Funzione per gestire il pagamento riuscito
  Future<void> handleSuccessfulPayment(
      String paymentId, String productId) async {
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
          'paymentId': paymentId,
          'productId': productId,
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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/syncStripeSubscription'),
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
        throw Exception(
            'Errore nella sincronizzazione: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Errore nella sincronizzazione: $e');
    }
  }

  // Funzione per testare la connessione a Stripe
  Future<Map<String, dynamic>> testStripeConnection() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final callable = _functions.httpsCallable('testStripeConnection');
      final result = await callable.call();

      if (!result.data['success']) {
        throw Exception('Errore nel test della connessione a Stripe');
      }

      return result.data;
    } catch (e) {
      throw Exception('Errore nel test della connessione a Stripe: $e');
    }
  }

  // Funzione per ottenere i dettagli dell'abbonamento di un utente specifico (solo per admin)
  Future<Map<String, dynamic>> getUserSubscriptionDetails(String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final callable = _functions.httpsCallable('getUserSubscriptionDetails');
      final result = await callable.call({
        'userId': userId,
      });

      return result.data;
    } catch (e) {
      throw Exception(
          'Errore nel recupero dei dettagli dell\'abbonamento dell\'utente: $e');
    }
  }

  // Funzione per elencare tutte le sottoscrizioni dell'utente
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final callable = _functions.httpsCallable('listSubscriptions');
      final result = await callable.call();

      return List<Map<String, dynamic>>.from(result.data['subscriptions']);
    } catch (e) {
      throw Exception('Errore nel recupero delle sottoscrizioni: $e');
    }
  }

  // Funzione per creare un intent di pagamento
  Future<Map<String, dynamic>> createPaymentIntent(
      String productId, String userId) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw Exception('Utente non autenticato');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/createPaymentIntent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': productId,
          'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Errore nella creazione dell\'intent di pagamento: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Errore nella creazione dell\'intent di pagamento: $e');
    }
  }

  // Funzione per regalare un abbonamento
  Future<void> giftSubscription(String userId, int durationInDays) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utente non autenticato');
      }

      final token = await currentUser.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/giftSubscription'),
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
}
