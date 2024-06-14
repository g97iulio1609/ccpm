import 'package:flutter/material.dart';
import 'inAppSubscriptions_services.dart';

class InAppSubscriptionsPage extends StatefulWidget {
  @override
  _InAppSubscriptionsPageState createState() => _InAppSubscriptionsPageState();
}

class _InAppSubscriptionsPageState extends State<InAppSubscriptionsPage> {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();
  bool _loading = true;
  final TextEditingController _promoCodeController = TextEditingController();
  String? _promoCodeError;

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
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _redeemPromoCode() async {
    setState(() {
      _promoCodeError = null;
    });
    try {
      await _inAppPurchaseService.redeemPromoCode(_promoCodeController.text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promo code redeemed successfully!')));
    } catch (e) {
      setState(() {
        _promoCodeError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _promoCodeController,
                        decoration: InputDecoration(
                          labelText: 'Enter Promo Code',
                          errorText: _promoCodeError,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _redeemPromoCode,
                        child: Text('Redeem Promo Code'),
                      ),
                    ],
                  ),
                ),
                ..._inAppPurchaseService.productDetails.map((productDetails) {
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
                }).toList(),
              ],
            ),
    );
  }
}
