// lib/Store/inAppPurchase.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:alphanessone/Store/stripe_checkout_widget.dart';
import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:alphanessone/Store/inAppPurchase_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/utils/debug_logger.dart' as logger;

class InAppSubscriptionsPage extends ConsumerStatefulWidget {
  const InAppSubscriptionsPage({super.key});

  @override
  InAppSubscriptionsPageState createState() => InAppSubscriptionsPageState();
}

class InAppSubscriptionsPageState extends ConsumerState<InAppSubscriptionsPage> {
  late final InAppPurchaseService _inAppPurchaseService;
  bool _loading = true;
  final TextEditingController _promoCodeController = TextEditingController();
  String? _promoCodeError;
  bool _isAdmin = false;
  List<Product> _products = [];
  SubscriptionDetails? _currentSubscription;

  @override
  void initState() {
    super.initState();
    logger.debugLog('InAppSubscriptionsPage: initState called');
    ref.read(usersServiceProvider);
    _inAppPurchaseService = InAppPurchaseService();
    _initialize();
    _checkAdminStatus();
  }

  Future<void> _initialize() async {
    logger.debugLog('Initializing store info...');
    setState(() => _loading = true);
    try {
      // Carica i prodotti disponibili
      final List<Product> products = await _inAppPurchaseService.getProducts();
      // Carica l'abbonamento corrente se esiste
      final subscription = await _inAppPurchaseService.getSubscriptionDetails();
      
      if (mounted) {
        setState(() {
          _products = products;
          _currentSubscription = subscription;
          _loading = false;
        });
      }
      logger.debugLog('Store info initialized successfully');
    } catch (e) {
      logger.debugLog("Error during initialization: $e");
      if (mounted) {
        _showSnackBar('Errore durante l\'inizializzazione dello store: $e');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkAdminStatus() async {
    logger.debugLog('Checking admin status...');
    final userRole = ref.read(usersServiceProvider).getCurrentUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = userRole == 'admin';
      });
    }
    logger.debugLog('Admin status: $_isAdmin');
  }

  Future<void> _handlePurchase(Product product) async {
    logger.debugLog('Starting purchase for product: ${product.id}');
    try {
      // Crea il PaymentIntent
      final result = await FirebaseFunctions.instance
          .httpsCallable('createPaymentIntent')
          .call({'productId': product.id});

      final clientSecret = result.data['clientSecret'];
      final amount = result.data['amount'] / 100; // Converti da centesimi
      final currency = result.data['currency'];

      if (mounted) {
        // Mostra il widget di checkout
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: StripeCheckoutWidget(
              clientSecret: clientSecret,
              amount: amount,
              currency: currency,
              onPaymentSuccess: (String paymentId) async {
                Navigator.of(context).pop(); // Chiudi il bottom sheet
                await _initialize(); // Ricarica i dati
                if (mounted) {
                  _showSnackBar('Abbonamento attivato con successo!');
                }
              },
              onPaymentError: (String error) {
                if (mounted) {
                  _showSnackBar('Errore nel pagamento: $error');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      logger.debugLog('Error during purchase: $e');
      if (mounted) {
        _showSnackBar('Errore durante l\'acquisto: $e');
      }
    }
  }

  Future<void> _cancelSubscription() async {
    logger.debugLog('Cancelling subscription');
    try {
      await _inAppPurchaseService.cancelSubscription();
      await _initialize(); // Ricarica i dati
      if (mounted) {
        _showSnackBar('Abbonamento cancellato con successo');
      }
    } catch (e) {
      logger.debugLog('Error cancelling subscription: $e');
      if (mounted) {
        _showSnackBar('Errore durante la cancellazione: $e');
      }
    }
  }

  @override
  void dispose() {
    logger.debugLog('Disposing InAppSubscriptionsPage');
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _redeemPromoCode() async {
    logger.debugLog('Redeeming promo code: ${_promoCodeController.text}');
    setState(() {
      _promoCodeError = null;
    });
    try {
      await _inAppPurchaseService.redeemPromoCode(_promoCodeController.text);
      if (mounted) {
        _showSnackBar('Codice promozionale applicato con successo!');
        await _initialize(); // Ricarica i dati
      }
    } catch (e) {
      logger.debugLog('Error redeeming promo code: $e');
      if (mounted) {
        setState(() {
          _promoCodeError = e.toString();
        });
        _showSnackBar('Errore nell\'applicazione del codice: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    logger.debugLog('Showing SnackBar: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abbonamenti'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentSubscription != null) ...[
                _buildCurrentSubscriptionCard(),
                const SizedBox(height: 24),
              ],
              ..._products.map((product) => _buildProductCard(product)),
              if (_isAdmin) ...[
                const SizedBox(height: 24),
                _buildPromoCodeSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Abbonamento Attivo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scade il: ${_currentSubscription!.currentPeriodEnd.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cancelSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancella Abbonamento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handlePurchase(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Acquista'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Codice Promozionale',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promoCodeController,
              decoration: InputDecoration(
                hintText: 'Inserisci il codice',
                errorText: _promoCodeError,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white10,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _redeemPromoCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Applica Codice'),
            ),
          ],
        ),
      ),
    );
  }
}
