import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TDEEService {
  final FirebaseFirestore _firestore;

  TDEEService(this._firestore);

  Future<Map<String, dynamic>?> getMostRecentNutritionData(
    String userId,
  ) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mynutrition')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  Future<void> saveNutritionData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);

    // Calculate macronutrients based on TDEE
    final tdee = data['tdee'] as int;
    final carbs = _roundToTwoDecimals((tdee * 0.5) / 4);
    final protein = _roundToTwoDecimals((tdee * 0.3) / 4);
    final fat = _roundToTwoDecimals((tdee * 0.2) / 9);

    // Ensure the values are saved as numbers (double) with 2 decimal places
    final nutritionData = {
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'tdee': tdee.toDouble(),
      'weight': _roundToTwoDecimals(data['weight']),
      'activityLevel': data['activityLevel'],
      'date': Timestamp.now(),
    };

    try {
      final existingDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mynutrition')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        // Update the most recent document for today
        final docId = existingDocs.docs.first.id;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('mynutrition')
            .doc(docId)
            .update(nutritionData)
            .catchError((_) {});
      } else {
        // Create a new document for today
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('mynutrition')
            .add(nutritionData)
            .catchError((_) {});
      }
    } catch (e) {}
  }

  // Helper function to round to two decimal places
  double _roundToTwoDecimals(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return double.parse((value).toStringAsFixed(2));
    }
    throw ArgumentError('Value must be int or double');
  }
}
