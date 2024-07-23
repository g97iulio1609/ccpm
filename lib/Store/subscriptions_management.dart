import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportSubscriptionsScreen extends StatefulWidget {
  const ImportSubscriptionsScreen({super.key});

  @override
  _ImportSubscriptionsScreenState createState() => _ImportSubscriptionsScreenState();
}

class _ImportSubscriptionsScreenState extends State<ImportSubscriptionsScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _kIdController = TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _importSubscription() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final String kId = _kIdController.text.trim();
    debugPrint("Step 1: Start importing subscription with kId: $kId");

    if (kId.isEmpty) {
      debugPrint("Step 1.1: kId is empty");
      setState(() {
        _isLoading = false;
        _message = 'Please enter a valid kId.';
      });
      return;
    }

    try {
      debugPrint("Step 2: Querying product details for kId: $kId");
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({kId});

      if (response.notFoundIDs.contains(kId)) {
        debugPrint("Step 2.1: Product not found for kId: $kId");
        setState(() {
          _isLoading = false;
          _message = 'Product not found: $kId';
        });
        return;
      }

      debugPrint("Step 3: Product details found for kId: $kId");
      for (var product in response.productDetails) {
        await _saveSubscriptionToFirestore(product);
      }

      setState(() {
        _isLoading = false;
        _message = 'Subscription imported successfully for all plans associated with: $kId';
      });
      debugPrint("Step 4: Subscription imported successfully for all plans associated with: $kId");
    } catch (e) {
      debugPrint("Step 5: Error importing subscription: $e");
      setState(() {
        _isLoading = false;
        _message = 'Error importing subscription: $e';
      });
    }
  }

  Future<void> _saveSubscriptionToFirestore(ProductDetails product) async {
    final docRef = _firestore.collection('subscriptions').doc(product.id);
    debugPrint("Step 3.1: Saving subscription to Firestore with id: ${product.id}");
    await docRef.set({
      'kId': product.id,
      'displayName': product.title,
      'description': product.description,
      'durationDays': _getDurationDaysFromProductId(product.id), // Adjust based on product ID or other logic
      'roleOnPurchase': 'coach', // Adjust as necessary
      'roleOnExpire': 'client', // Adjust as necessary
      'gracePeriodDays': 3 // Adjust as necessary
    });
    debugPrint("Step 3.2: Subscription saved to Firestore: ${product.title}");
  }

  int _getDurationDaysFromProductId(String productId) {
    // Implement your logic to determine the duration days based on the product ID
    if (productId.contains('monthly')) {
      return 30;
    } else if (productId.contains('quarterly')) {
      return 90;
    } else if (productId.contains('semiannual')) {
      return 180;
    } else if (productId.contains('annual')) {
      return 365;
    } else {
      return 30; // Default to 30 days
    }
  }

  Future<void> _importPromoCode() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final String promoCode = _promoCodeController.text.trim();
    debugPrint("Step 1: Start importing promo code: $promoCode");

    if (promoCode.isEmpty) {
      debugPrint("Step 1.1: Promo code is empty");
      setState(() {
        _isLoading = false;
        _message = 'Please enter a valid promo code.';
      });
      return;
    }

    try {
      debugPrint("Step 2: Saving promo code to Firestore: $promoCode");
      final docRef = _firestore.collection('coupons').doc(promoCode);
      await docRef.set({
        'productId': promoCode,
      });

      setState(() {
        _isLoading = false;
        _message = 'Promo code imported successfully: $promoCode';
      });
      debugPrint("Step 3: Promo code imported successfully: $promoCode");
    } catch (e) {
      debugPrint("Step 4: Error importing promo code: $e");
      setState(() {
        _isLoading = false;
        _message = 'Error importing promo code: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _kIdController,
              decoration: const InputDecoration(labelText: 'Enter Subscription kId'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _importSubscription,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Import Subscription'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _promoCodeController,
              decoration: const InputDecoration(labelText: 'Enter Promo Code'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _importPromoCode,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Import Promo Code'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 20),
              Text(
                _message!,
                style: TextStyle(color: _message!.contains('Error') ? Colors.red : Colors.green),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
