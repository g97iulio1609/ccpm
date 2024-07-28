/*import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'inAppSubscriptions_services.dart';

class ActiveSubscriptionsPage extends StatefulWidget {
  const ActiveSubscriptionsPage({super.key});

  @override
  ActiveSubscriptionsPageState createState() => ActiveSubscriptionsPageState();
}

class ActiveSubscriptionsPageState extends State<ActiveSubscriptionsPage> {
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

  Future<void> _launchSubscriptionManagement() async {
    final Uri url = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Subscriptions'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: _inAppPurchaseService.purchases.map((purchase) {
                final productDetails = _inAppPurchaseService.productDetails.firstWhere(
                  (pd) => pd.id == purchase.productId,
                  orElse: () => ProductDetails(
                    id: purchase.productId,
                    title: 'Unknown',
                    description: 'Unknown',
                    price: 'Unknown',
                    rawPrice: 0.0,  // Add appropriate rawPrice
                    currencyCode: 'USD'  // Add appropriate currencyCode
                  ),
                );
                return ListTile(
                  title: Text(productDetails.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purchased on: ${purchase.purchaseDate}'),
                      Text('Price: ${productDetails.price}'),
                      Text('Subscription Duration: ${_inAppPurchaseService.subscriptionDurations[purchase.productId]}'),
                    ],
                  ),
                  trailing: TextButton(
                    onPressed: _launchSubscriptionManagement,
                    child: const Text('Manage Subscription'),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
*/