import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/nutrition_stats.dart';

class NutritionService {
  final FirebaseFirestore _firestore;

  NutritionService(this._firestore);

  Future<NutritionStats?> getDailyStats(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('nutrition_stats')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      return NutritionStats.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateDailyStats(String userId, NutritionStats stats) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('nutrition_stats')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .get();

      if (snapshot.docs.isEmpty) {
        await _firestore.collection('nutrition_stats').add({
          'userId': userId,
          ...stats.toMap(),
        });
      } else {
        await snapshot.docs.first.reference.update(stats.toMap());
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking the flow
      Logger().e('Error updating daily nutrition stats: $e');
    }
  }
}
