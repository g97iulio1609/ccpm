import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'inAppSubscriptions_services.dart';
import 'inAppSubscriptions_model.dart';

class ActiveSubscriptionsPage extends StatefulWidget {
  const ActiveSubscriptionsPage({super.key});

  @override
  ActiveSubscriptionsPageState createState() => ActiveSubscriptionsPageState();
}

class ActiveSubscriptionsPageState extends State<ActiveSubscriptionsPage> {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Handle error here
    });
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint("Initializing store info...");
      await _inAppPurchaseService.initStoreInfo();
      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error during initialization: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _inAppPurchaseService.handlePurchaseUpdate(purchaseDetails);
        setState(() {});  // Refresh the UI
      }
    });
  }

  Future<void> _launchSubscriptionManagement() async {
    final Uri url = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abbonamenti Attivi'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _inAppPurchaseService.activeSubscriptions.isEmpty
              ? const Center(child: Text('Nessun abbonamento attivo'))
              : ListView.builder(
                  itemCount: _inAppPurchaseService.activeSubscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = _inAppPurchaseService.activeSubscriptions[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription.plan.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text('Descrizione: ${subscription.plan.description ?? 'N/A'}'),
                            Text('Stato: ${subscription.status.toString().split('.').last}'),
                            Text('Data di inizio: ${_formatDate(subscription.startDate)}'),
                            Text('Data di fine: ${_formatDate(subscription.endDate)}'),
                            Text('Periodo di grazia: ${subscription.plan.gracePeriodDays} giorni'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _launchSubscriptionManagement,
                              child: const Text('Gestisci Abbonamento'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}