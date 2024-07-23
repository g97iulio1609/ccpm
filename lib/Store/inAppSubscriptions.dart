import 'package:flutter/material.dart';
import 'inAppSubscriptions_services.dart';

class InAppSubscriptionsPage extends StatefulWidget {
  const InAppSubscriptionsPage({super.key});

  @override
  InAppSubscriptionsPageState createState() => InAppSubscriptionsPageState();
}

class InAppSubscriptionsPageState extends State<InAppSubscriptionsPage> {
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
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
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
      if (mounted) {
        _showSnackBar('Promo code redeemed successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _promoCodeError = e.toString();
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showPromoCodeDialog() {
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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Redeem'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _redeemPromoCode();
              },
            ),
          ],
        );
      },
    );
  }

  String _getPlanTitle(int index, String productId) {
    if (productId == 'alphanessoneplussubscription') {
      switch (index) {
        case 0:
          return 'AlphanessOne+ Monthly Plan';
        case 1:
          return 'AlphanessOne+ Quarterly Plan';
        case 2:
          return 'AlphanessOne+ Semi-Annual Plan';
           case 3:
          return 'AlphanessOne+ Yearly Plan';
        default:
          return 'Subscription Plan';
      }
    } else if (productId == 'coachingalphaness') {
      switch (index) {
        case 0:
          return 'Coaching 1:1 Monthly Plan';
        case 1:
          return 'Coaching 1:1 Quarterly Plan';
          case 2:
          return 'Coaching 1:1 Semi-Annual Plan';
        default:
          return 'Subscription Plan';
      }
    }
    return 'Subscription Plan';
  }

  @override
  Widget build(BuildContext context) {
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
                  return productDetailsList.asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final productDetails = mapEntry.value;
                    debugPrint("Displaying product: ${productDetails.id}");
                    String planTitle = _getPlanTitle(index, productDetails.id);
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planTitle,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              productDetails.description,
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  productDetails.price,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _inAppPurchaseService.makePurchase(productDetails),
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
              ],
            ),
    );
  }
}
