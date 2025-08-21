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
      if (user == null) {
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data()!;
      final role = data['role'] as String?;

      if (role == 'admin' || role == 'coach') {
        return true;
      }

      final subscriptionStatus = data['subscriptionStatus'] as String?;
      final subscriptionExpiryDate = data['subscriptionExpiryDate'] as Timestamp?;
      final isGifted = data['giftedAt'] != null;

      if (isGifted &&
          subscriptionStatus?.toLowerCase() == 'active' &&
          subscriptionExpiryDate != null &&
          subscriptionExpiryDate.toDate().isAfter(DateTime.now())) {
        return true;
      }

      try {
        final subscriptionDetails = await _inAppPurchaseService.getSubscriptionDetails();

        if (subscriptionDetails != null) {
          return subscriptionDetails.status.toLowerCase() == 'active' &&
              subscriptionDetails.currentPeriodEnd.isAfter(DateTime.now());
        }
      } catch (e) {
        // Continua con il controllo su Firestore
      }

      if (subscriptionStatus?.toLowerCase() == 'active' &&
          subscriptionExpiryDate != null &&
          subscriptionExpiryDate.toDate().isAfter(DateTime.now())) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
