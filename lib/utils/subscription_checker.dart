import 'package:flutter/material.dart';
import '../Store/in_app_purchase_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionChecker {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> checkSubscription(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check subscription through Cloud Function first
      final subscriptionDetails =
          await _inAppPurchaseService.getSubscriptionDetails();

      if (subscriptionDetails != null) {
        if (subscriptionDetails.status.toLowerCase() == 'active' &&
            subscriptionDetails.currentPeriodEnd.isAfter(DateTime.now())) {
          return true;
        }
      }

      // If no valid subscription from Cloud Function, check Firestore for gift subscription
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final isGifted = data['giftedAt'] != null;

      if (!isGifted) return false;

      final subscriptionStatus = data['subscriptionStatus'] as String?;
      final subscriptionExpiryDate =
          data['subscriptionExpiryDate'] as Timestamp?;

      if (subscriptionStatus == null || subscriptionExpiryDate == null) {
        return false;
      }

      return subscriptionStatus.toLowerCase() == 'active' &&
          subscriptionExpiryDate.toDate().isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }
}
