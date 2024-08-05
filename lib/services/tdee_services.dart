import 'package:cloud_firestore/cloud_firestore.dart';

class TDEEService {
  final FirebaseFirestore _firestore;

  TDEEService(this._firestore);

  Future<Map<String, dynamic>?> getTDEEData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      return {
        'birthDate': userData['birthDate'],
        'height': userData['height']?.toDouble() ?? 0.0,
        'weight': userData['weight']?.toDouble() ?? 0.0,
        'gender': userData['gender'],
        'activityLevel': userData['activityLevel'],
        'tdee': userData['tdee']?.toDouble() ?? 0.0,
      };
    } else {
      // If the user does not exist, return null
      return null;
    }
  }

  Future<void> updateTDEEData(String userId, Map<String, dynamic> tdeeData) async {
    await _firestore.collection('users').doc(userId).update(tdeeData);
  }

  Future<void> updateMacros(String userId, Map<String, double> macros) async {
    await _firestore.collection('users').doc(userId).update(macros);
  }

  Future<Map<String, double>> getUserMacros(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      return {
        'carbs': userData['carbs']?.toDouble() ?? 0.0,
        'protein': userData['protein']?.toDouble() ?? 0.0,
        'fat': userData['fat']?.toDouble() ?? 0.0,
      };
    }
    return {'carbs': 0.0, 'protein': 0.0, 'fat': 0.0};
  }
}
