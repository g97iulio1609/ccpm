// lib/Store/inAppPurchase.dart

import 'package:alphanessone/Store/inAppPurchase_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';
import 'inAppPurchase_model.dart'; // Assicurati di importare il modello corretto
import '../utils/debug_logger.dart'; // Importa la funzione di logging personalizzata

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

  @override
  void initState() {
    super.initState();
    debugLog('InAppSubscriptionsPage: initState called');
    ref.read(usersServiceProvider);
    _inAppPurchaseService = InAppPurchaseService();
    _initialize();
    _checkAdminStatus();
  }

  Future<void> _initialize() async {
    debugLog('Initializing store info...');
    try {
      await _inAppPurchaseService.initStoreInfo();
      debugLog('Store info initialized successfully');
    } catch (e) {
      debugLog("Error during initialization: $e");
      _showSnackBar('Errore durante l\'inizializzazione dello store: $e');
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
      debugLog('Loading state set to false');
    }
  }

  Future<void> _checkAdminStatus() async {
    debugLog('Checking admin status...');
    final userRole = ref.read(usersServiceProvider).getCurrentUserRole();
    setState(() {
      _isAdmin = userRole == 'admin';
    });
    debugLog('Admin status: $_isAdmin');
  }

  @override
  void dispose() {
    debugLog('Disposing InAppSubscriptionsPage');
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _redeemPromoCode() async {
    debugLog('Redeeming promo code: ${_promoCodeController.text}');
    setState(() {
      _promoCodeError = null;
    });
    try {
      await _inAppPurchaseService.redeemPromoCode(_promoCodeController.text);
      if (mounted) {
        _showSnackBar('Promo code redeemed successfully!');
      }
    } catch (e) {
      debugLog('Error redeeming promo code: $e');
      setState(() {
        _promoCodeError = e.toString();
      });
      _showSnackBar('Errore nel redeem del promo code: $e');
    }
  }

  void _showSnackBar(String message) {
    debugLog('Showing SnackBar: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showPromoCodeDialog() {
    debugLog('Showing promo code dialog');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Redeem Promo Code', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _promoCodeController,
            decoration: InputDecoration(
              labelText: 'Enter Promo Code',
              errorText: _promoCodeError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                debugLog('Cancel promo code dialog');
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Redeem'),
              onPressed: () {
                debugLog('Redeem button pressed in promo code dialog');
                Navigator.of(dialogContext).pop();
                _redeemPromoCode();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncProducts() async {
    debugLog('Syncing products...');
    try {
      await _inAppPurchaseService.manualSyncProducts();
      _showSnackBar('Products synced successfully');
      await _initialize();
    } catch (e) {
      debugLog('Error syncing products: $e');
      _showSnackBar('Error syncing products: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugLog('Building InAppSubscriptionsPage');
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.redeem),
                  label: const Text('Redeem Promo Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showPromoCodeDialog,
                ),
                const SizedBox(height: 24),
                ..._inAppPurchaseService.productDetailsByProductId.entries.expand((entry) {
                  final productDetailsList = entry.value;
                  return productDetailsList.map((productDetails) {
                    // Usa direttamente il campo 'title' del prodotto
                    String planTitle = productDetails.title;

                    // Gestisci eventuali descrizioni nulle
                    String description = productDetails.description ?? 'No description available.';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titolo del Prodotto (Utilizza 'title' dal prodotto)
                            Text(
                              planTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Descrizione del Prodotto (Modificata per essere Chiara)
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${productDetails.price} ${productDetails.currencyCode}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    debugLog('Subscribe button pressed for productId: ${productDetails.id}');
                                    _inAppPurchaseService.makePurchase(productDetails.id);
                                  },
                                  child: const Text('Subscribe'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList();
                }),
                if (_isAdmin)
                  ElevatedButton.icon(
                    icon: Icon(Icons.sync),
                    label: Text('Sync Products'),
                    onPressed: _syncProducts,
                  ),
              ],
            ),
    );
  }
}
