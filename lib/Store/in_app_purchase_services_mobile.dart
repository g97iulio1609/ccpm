import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:alphanessone/Store/in_app_purchase_model.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class InAppPurchaseServiceMobile {
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

  // ID dei prodotti per iOS e Android
  static const Map<String, String> _kProductIds = {
    // AlphanessOne+
    'monthly': 'alphanessoneplusathlete', // Mensile
    'yearly': 'alphanessoneplusathlete1y', // Annuale
    'quarterly': 'alphanessoneplusathlete3m', // Trimestrale
    'semiannual': 'alphanessoneplusathlete6m', // Semestrale

    // AlphanessOne+ Coaching
    'coaching_monthly': 'coachinga1monthly', // Mensile
    'coaching_quarterly': 'coachinga1quarterly', // Trimestrale
    'coaching_semiannual': 'coachinga1semiannual', // Semestrale
  };

  // Lista interna dei prodotti
  final List<Product> _products = [];
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Getter per i dettagli dei prodotti
  Map<String, List<Product>> get productDetailsByProductId {
    print(
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

  // Funzione per ottenere i prodotti disponibili
  Future<List<Product>> getProducts() async {
    print('\n==================== RECUPERO PRODOTTI ====================');
    try {
      print('1. Verifica disponibilità store...');
      final bool available = await _inAppPurchase.isAvailable();
      print('Store disponibile: $available');

      if (!available) {
        print('❌ ERRORE: Store non disponibile');
        throw Exception('Store non disponibile');
      }

      print('2. Query prodotti allo store...');
      print('Ricerca prodotti con IDs: ${_kProductIds.values.toList()}');

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_kProductIds.values.toSet());

      print('\nRisposta store:');
      print('- Prodotti trovati: ${response.productDetails.length}');
      print('- Prodotti non trovati: ${response.notFoundIDs}');
      print('- Errore: ${response.error}');

      if (response.error != null) {
        print('❌ ERRORE: ${response.error}');
        throw Exception('Errore nel recupero dei prodotti: ${response.error}');
      }

      if (response.productDetails.isEmpty) {
        print('❌ ERRORE: Nessun prodotto trovato');
        throw Exception('Nessun prodotto trovato nello store');
      }

      print('\n3. Elaborazione prodotti trovati:');
      _products.clear();
      final products = response.productDetails.map((details) {
        print('\nProdotto trovato:');
        print('- ID: ${details.id}');
        print('- Titolo: ${details.title}');
        print('- Prezzo: ${details.price}');
        print('- Descrizione: ${details.description}');

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
      print('\n✅ Recuperati ${products.length} prodotti con successo');
      print(
          '==================== FINE RECUPERO PRODOTTI ====================\n');
      return products;
    } catch (e, stackTrace) {
      print('\n❌ ERRORE DURANTE IL RECUPERO PRODOTTI:');
      print('Errore: $e');
      print('Stack trace: $stackTrace');
      print('==================== FINE ERRORE ====================\n');
      rethrow;
    }
  }

  // Funzione per gestire l'acquisto
  Future<void> handlePurchase(String productId) async {
    try {
      print('\n');
      print('==================== INIZIO ACQUISTO ====================');
      print('🛒 Tentativo di acquisto per il prodotto: $productId');
      print('Lista prodotti disponibili:');
      for (var prod in _products) {
        print('- ${prod.id} (${prod.title}): ${prod.price}');
      }

      final bool available = await _inAppPurchase.isAvailable();
      print('Store disponibile: $available');

      if (!available) {
        print('❌ ERRORE: Store non disponibile');
        throw Exception('Store non disponibile');
      }

      // Verifica se il prodotto è già nella lista dei prodotti caricati
      print('\nRicerca prodotto nella cache...');
      final existingProduct = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () {
          print('❌ ERRORE: Prodotto non trovato nella cache dei prodotti');
          print('ID cercato: $productId');
          print(
              'Prodotti disponibili: ${_products.map((p) => p.id).join(', ')}');
          throw Exception('Prodotto non trovato nella cache');
        },
      );

      print('✅ Prodotto trovato nella cache:');
      print('- ID: ${existingProduct.id}');
      print('- Titolo: ${existingProduct.title}');
      print('- Prezzo: ${existingProduct.price}');

      print('\nVerifica prodotto nello store...');
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails({productId});

      print('Risposta dallo store:');
      print('- Prodotti trovati: ${response.productDetails.length}');
      print('- Prodotti non trovati: ${response.notFoundIDs}');
      print('- Errore: ${response.error}');

      if (response.notFoundIDs.isNotEmpty) {
        print('❌ ERRORE: Prodotto non trovato nello store');
        print('ID non trovati: ${response.notFoundIDs.join(', ')}');
        throw Exception('Prodotto non trovato nello store');
      }

      if (response.productDetails.isEmpty) {
        print('❌ ERRORE: Nessun dettaglio prodotto trovato nello store');
        throw Exception('Nessun dettaglio prodotto trovato');
      }

      print('\nPreparazione acquisto...');
      final productDetails = response.productDetails.first;
      print('Dettagli prodotto dallo store:');
      print('- ID: ${productDetails.id}');
      print('- Titolo: ${productDetails.title}');
      print('- Descrizione: ${productDetails.description}');
      print('- Prezzo: ${productDetails.price}');
      print('- Raw Price: ${productDetails.rawPrice}');
      print('- Currency: ${productDetails.currencyCode}');

      final currentUser = FirebaseAuth.instance.currentUser;
      print('\nInformazioni utente:');
      print('- User ID: ${currentUser?.uid}');
      print('- Email: ${currentUser?.email}');

      print('\nCreazione parametri di acquisto...');
      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: currentUser?.uid,
      );

      print('\nAvvio acquisto tramite store...');
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      print('Risultato avvio acquisto: ${success ? 'Successo' : 'Fallito'}');

      if (!success) {
        print('❌ ERRORE: Impossibile avviare l\'acquisto');
        throw Exception('Errore nell\'avvio dell\'acquisto');
      }

      print('✅ Richiesta di acquisto inviata con successo');
      print('==================== FINE ACQUISTO ====================\n');
    } catch (e, stackTrace) {
      print('\n❌ ERRORE DURANTE L\'ACQUISTO:');
      print('Errore: $e');
      print('Stack trace: $stackTrace');
      print('==================== FINE ERRORE ====================\n');
      rethrow;
    }
  }

  // Funzione per inizializzare il servizio
  Future<void> initialize() async {
    print('\n==================== INIZIALIZZAZIONE STORE ====================');
    try {
      print('1. Verifica disponibilità store...');
      bool isAvailable = await _inAppPurchase.isAvailable();
      int retryCount = 0;
      const maxRetries = 3;

      print(
          'Stato iniziale store: ${isAvailable ? 'Disponibile' : 'Non disponibile'}');
      print('Verifica connessione al Play Store...');

      // Riprova alcune volte se lo store non è disponibile immediatamente
      while (!isAvailable && retryCount < maxRetries) {
        print(
            'Store non disponibile, tentativo ${retryCount + 1} di $maxRetries');
        print('Attendo 2 secondi prima del prossimo tentativo...');
        await Future.delayed(Duration(seconds: 2));

        print('Nuovo tentativo di connessione al Play Store...');
        isAvailable = await _inAppPurchase.isAvailable();
        print(
            'Risultato tentativo ${retryCount + 1}: ${isAvailable ? 'Successo' : 'Fallito'}');

        retryCount++;
      }

      if (!isAvailable) {
        print('\n❌ ERRORE CRITICO:');
        print('- Store non disponibile dopo $maxRetries tentativi');
        print('- Verifica che il Play Store sia installato e aggiornato');
        print('- Verifica che l\'app sia stata installata dal Play Store');
        print(
            '- Verifica che il dispositivo abbia una connessione internet attiva');
        throw Exception(
            'Store non disponibile dopo $maxRetries tentativi. Verifica la connessione al Play Store.');
      }

      print('\n✅ Store disponibile e connesso');
      print('2. Inizializzazione stream degli acquisti...');

      // Inizializza lo stream degli acquisti
      final purchaseUpdated = _inAppPurchase.purchaseStream;
      _subscription?.cancel(); // Cancella eventuali subscription precedenti

      _subscription = purchaseUpdated.listen(
        (purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        },
        onDone: () {
          print('Stream degli acquisti terminato');
          _subscription?.cancel();
        },
        onError: (error) {
          print('❌ Errore nello stream degli acquisti: $error');
        },
      );

      print('✅ Stream degli acquisti inizializzato');
      print('3. Caricamento prodotti...');
      print('ID prodotti da caricare: ${_kProductIds.values.join(", ")}');

      final products = await getProducts();

      print('✅ Caricati ${products.length} prodotti con successo');
      print('Prodotti disponibili:');
      for (var product in products) {
        print('- ${product.id}: ${product.title} (${product.price})');
      }

      print(
          '==================== INIZIALIZZAZIONE COMPLETATA ====================\n');
    } catch (e, stackTrace) {
      print('\n❌ ERRORE DURANTE L\'INIZIALIZZAZIONE:');
      print('Errore: $e');
      print('Stack trace: $stackTrace');
      print('==================== FINE ERRORE ====================\n');
      rethrow;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    print('\n==================== AGGIORNAMENTO ACQUISTO ====================');
    print('Ricevuto aggiornamento per ${purchaseDetailsList.length} acquisti');

    for (final purchaseDetails in purchaseDetailsList) {
      print('\nDettagli acquisto:');
      print('- ID Prodotto: ${purchaseDetails.productID}');
      print('- ID Acquisto: ${purchaseDetails.purchaseID}');
      print('- Stato: ${purchaseDetails.status}');
      print('- Pending Complete: ${purchaseDetails.pendingCompletePurchase}');

      if (purchaseDetails.error != null) {
        print('- Errore: ${purchaseDetails.error}');
      }

      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('⏳ Acquisto in corso...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('❌ Errore nell\'acquisto: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        print('✅ Acquisto completato con successo');
        _handleSuccessfulPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        print('📦 Completamento acquisto...');
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
    print('==================== FINE AGGIORNAMENTO ====================\n');
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      _logger.i('🎉 Gestione acquisto completato');
      print('ID Acquisto: ${purchase.purchaseID}');
      print('ID Prodotto: ${purchase.productID}');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _logger.e('❌ Utente non autenticato');
        throw Exception('Utente non autenticato');
      }

      // Qui puoi aggiungere la logica per verificare la ricevuta con il tuo backend
      // e aggiornare lo stato dell'abbonamento dell'utente
    } catch (e) {
      _logger.e('❌ Errore nella gestione dell\'acquisto completato', error: e);
    }
  }
}
