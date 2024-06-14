// inAppSubscriptions.dart

import 'package:flutter/material.dart';
import 'inAppSubscriptions_services.dart';

class InAppSubscriptionsPage extends StatefulWidget {
  @override
  _InAppSubscriptionsPageState createState() => _InAppSubscriptionsPageState();
}

class _InAppSubscriptionsPageState extends State<InAppSubscriptionsPage> {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint("Initializing store info...");
      await _inAppPurchaseService.initStoreInfo();
    } catch (e) {
      debugPrint("Error during initialization: $e");
      // Non impostare _error per evitare di mostrare errori all'utente
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: _inAppPurchaseService.productDetails
                  .map((productDetails) {
                    debugPrint("Displaying product: ${productDetails.id}");
                    return ListTile(
                      title: Text(productDetails.title),
                      subtitle: Text(productDetails.description),
                      trailing: TextButton(
                        child: Text(productDetails.price),
                        onPressed: () {
                          _inAppPurchaseService.makePurchase(productDetails);
                        },
                      ),
                    );
                  })
                  .toList(),
            ),
    );
  }
}
