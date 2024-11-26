// lib/Store/inAppPurchase_services.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:alphanessone/Store/inAppPurchase_model.dart';

class InAppPurchaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Funzione per ottenere i prodotti disponibili
  Future<List<Product>> getProducts() async {
    try {
      final result = await _functions.httpsCallable('getStripeProducts').call();
      final products = (result.data['products'] as List)
          .map((product) => Product(
                id: product['id'],
                title: product['name'],
                description: product['description'] ?? '',
                price: '${product['price']} ${product['currency'].toUpperCase()}',
                rawPrice: product['price'].toDouble(),
                currencyCode: product['currency'],
              ))
          .toList();
      return products;
    } catch (e) {
      throw Exception('Errore nel recupero dei prodotti: $e');
    }
  }

  // Getter per i dettagli dei prodotti
  Map<String, List<Product>> get productDetailsByProductId {
    final Map<String, List<Product>> result = {};
    _products.forEach((product) {
      if (!result.containsKey(product.id)) {
        result[product.id] = [];
      }
      result[product.id]!.add(product);
    });
    return result;
  }

  // Lista interna dei prodotti
  final List<Product> _products = [];

  // Funzione per verificare lo stato dell'abbonamento
  Future<SubscriptionDetails?> getSubscriptionDetails({String? userId}) async {
    try {
      final result = await _functions.httpsCallable('getSubscriptionDetails').call({
        if (userId != null) 'userId': userId,
      });
      
      if (!result.data['hasSubscription']) {
        return null;
      }

      final subscription = result.data['subscription'];
      return SubscriptionDetails(
        id: subscription['id'],
        status: subscription['status'],
        currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(
          subscription['current_period_end'] * 1000,
        ),
        items: (subscription['items'] as List).map((item) => SubscriptionItem(
          priceId: item['priceId'],
          productId: item['productId'],
          quantity: item['quantity'],
        )).toList(),
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
        throw Exception(result.data['message'] ?? 'Errore nell\'aggiornamento dell\'abbonamento');
      }
    } catch (e) {
      throw Exception('Errore nell\'aggiornamento dell\'abbonamento: $e');
    }
  }

  // Funzione per creare un abbonamento regalo
  Future<void> giftSubscription(String userId, int durationInDays) async {
    try {
      final result = await _functions.httpsCallable('createGiftSubscription').call({
        'userId': userId,
        'durationInDays': durationInDays,
      });

      if (!result.data['success']) {
        throw Exception(result.data['message'] ?? 'Errore nella creazione dell\'abbonamento regalo');
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
}
