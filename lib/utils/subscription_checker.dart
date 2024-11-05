import 'package:flutter/material.dart';
import '../Store/inAppPurchase_services.dart';

class SubscriptionChecker {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();

  Future<bool> checkSubscription(BuildContext context) async {
    try {
      final subscriptionDetails = await _inAppPurchaseService.getSubscriptionDetails();
      
      if (subscriptionDetails == null) {
        return false;
      }

      // Check if subscription is expired
      final now = DateTime.now();
      if (subscriptionDetails.currentPeriodEnd.isBefore(now)) {
        return false;
      }

      // Check if subscription status is active
      return subscriptionDetails.status.toLowerCase() == 'active';
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }
}
