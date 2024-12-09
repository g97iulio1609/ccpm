import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfileUpdateService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileUpdateService(this._firestore, this._auth);

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Convert string date to Timestamp if birthdate is being updated
    if (updates.containsKey('birthdate') && updates['birthdate'] is String) {
      try {
        final date = DateTime.parse(updates['birthdate']);
        updates['birthdate'] = Timestamp.fromDate(date);
      } catch (e) {
        throw Exception('Invalid date format. Please use YYYY-MM-DD');
      }
    }

    // Validate height (in cm)
    if (updates.containsKey('height')) {
      final height = double.tryParse(updates['height'].toString());
      if (height == null || height < 50 || height > 250) {
        throw Exception('Invalid height. Please enter a value between 50 and 250 cm');
      }
      updates['height'] = height;
    }

    // Validate phone number (basic format)
    if (updates.containsKey('phoneNumber')) {
      final phone = updates['phoneNumber'].toString();
      if (!RegExp(r'^\+?[\d\s-]{8,}$').hasMatch(phone)) {
        throw Exception('Invalid phone number format');
      }
    }

    // Validate activity level
    if (updates.containsKey('activityLevel')) {
      final level = updates['activityLevel'].toString().toLowerCase();
      final validLevels = ['sedentary', 'light', 'moderate', 'very active', 'extremely active'];
      if (!validLevels.contains(level)) {
        throw Exception('Invalid activity level. Please choose from: ${validLevels.join(", ")}');
      }
      updates['activityLevel'] = level;
    }

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data() ?? {};
  }
}

final profileUpdateServiceProvider = Provider<ProfileUpdateService>((ref) {
  return ProfileUpdateService(FirebaseFirestore.instance, FirebaseAuth.instance);
});
