import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:collection/collection.dart';
import 'inAppSubscriptions_services.dart';
import 'inAppSubscriptions_model.dart';

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
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<SubscriptionPlan> _availablePlans = [];
  List<Subscription> _activeSubscriptions = [];
  late StreamSubscription _subscriptionPlanSubscription;

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen(_listenToPurchaseUpdated, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint("Error in purchase stream: $error");
    });
    _initialize();
    _subscriptionPlanSubscription = _inAppPurchaseService.firestore.collection('subscriptions').snapshots().listen((snapshot) {
      setState(() {
        _availablePlans = _inAppPurchaseService.availablePlans;
      });
    });
  }

  Future<void> _initialize() async {
    try {
      debugPrint("Initializing store info...");
      await _inAppPurchaseService.initStoreInfo();
      _availablePlans = _inAppPurchaseService.availablePlans;
      _activeSubscriptions = _inAppPurchaseService.activeSubscriptions;
      debugPrint("Available plans: ${_availablePlans.length}");
      debugPrint("Active subscriptions: ${_activeSubscriptions.length}");
    } catch (e) {
      debugPrint("Error during initialization: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _inAppPurchaseService.handlePurchaseUpdate(purchaseDetails);
        _updateSubscriptions();
      }
    }
  }

  void _updateSubscriptions() {
    setState(() {
      _activeSubscriptions = _inAppPurchaseService.activeSubscriptions;
    });
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _subscription.cancel();
    _subscriptionPlanSubscription.cancel();
    super.dispose();
  }

  Future<void> _redeemPromoCode() async {
    if (!mounted) return;

    setState(() {
      _promoCodeError = null;
    });
    try {
      await _inAppPurchaseService.redeemPromoCode(_promoCodeController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo code redeemed successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _promoCodeError = e.toString();
      });
    }
  }

  void _showPromoCodeDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Redeem Promo Code'),
          content: TextField(
            controller: _promoCodeController,
            decoration: InputDecoration(
              labelText: 'Enter Promo Code',
              errorText: _promoCodeError,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Redeem'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _redeemPromoCode();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionCard(SubscriptionPlan plan) {
    String durationText = plan.duration.inDays == 30 ? 'Monthly' : 'Quarterly';
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text('${plan.displayName} ($durationText)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.description ?? ''),
            Text('Duration: ${plan.duration.inDays} days'),
            Text('Grace Period: ${plan.gracePeriodDays} days'),
          ],
        ),
        trailing: ElevatedButton(
          child: const Text('Subscribe'),
          onPressed: () {
            _inAppPurchaseService.purchaseSubscription(plan.kId);
          },
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(Subscription subscription) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(subscription.plan.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${subscription.status.toString().split('.').last}'),
            Text('Start Date: ${subscription.startDate.toLocal()}'),
            if (subscription.endDate != null)
              Text('End Date: ${subscription.endDate!.toLocal()}'),
            if (_availablePlans.isNotEmpty)
              DropdownButton<String>(
                hint: const Text('Change Subscription'),
                items: _availablePlans
                    .where((plan) => plan.kId != subscription.plan.kId)
                    .map((plan) {
                  return DropdownMenuItem<String>(
                    value: plan.kId,
                    child: Text(plan.displayName),
                  );
                }).toList(),
                onChanged: (newPlanId) async {
                  if (newPlanId != null) {
                    final oldPurchaseDetails = await _getPurchaseDetailsForPlan(subscription.plan.kId);
                    if (oldPurchaseDetails != null) {
                      await _inAppPurchaseService.changeSubscription(newPlanId, oldPurchaseDetails);
                      _updateSubscriptions();
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<GooglePlayPurchaseDetails?> _getPurchaseDetailsForPlan(String planId) async {
    final purchases = await _inAppPurchaseService.purchaseStream.first;
    return purchases
        .whereType<GooglePlayPurchaseDetails>()
        .firstWhereOrNull((purchase) => purchase.productID == planId);
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
                  child: ElevatedButton(
                    onPressed: _showPromoCodeDialog,
                    child: const Text('Redeem Promo Code'),
                  ),
                ),
                if (_activeSubscriptions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Active Subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ..._activeSubscriptions.map(_buildActiveSubscriptionCard),
                ],
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Available Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (_availablePlans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No subscription plans available at the moment. Please try again later.'),
                  )
                else
                  ..._availablePlans.map(_buildSubscriptionCard),
              ],
            ),
    );
  }
}
