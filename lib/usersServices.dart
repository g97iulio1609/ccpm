// usersServices.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userNameProvider = StateProvider<String>((ref) => '');
final userRoleProvider = StateProvider<String>((ref) => '');

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
    );
  }
}

class ExerciseRecord {
  final String id;
  final String exerciseId;
  final int maxWeight;
  final int repetitions;
  final String date;

  ExerciseRecord({
    required this.id,
    required this.exerciseId,
    required this.maxWeight,
    required this.repetitions,
    required this.date,
  });

  factory ExerciseRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseRecord(
      id: doc.id,
      exerciseId: data['exerciseId'],
      maxWeight: data['maxWeight'],
      repetitions: data['repetitions'],
      date: data['date'],
    );
  }
}

final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, FirebaseFirestore.instance, FirebaseAuth.instance);
});

class UsersService {
  final ProviderRef ref;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UsersService(this.ref, this._firestore, this._auth) {
    _auth.userChanges().listen((user) async {
      if (user != null) {
        _updateUserName(user.displayName);
        await _updateUserRole(user.uid);
      }
    });
  }

  void _updateUserName(String? displayName) {
    final userName = displayName ?? '';
    ref.read(userNameProvider.notifier).state = userName;
  }
  
  void updateUserName(String? displayName) {
    final userName = displayName ?? '';
    ref.read(userNameProvider.notifier).state = userName;
  }

  Future<void> _updateUserRole(String userId) async {
    final DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    final String userRole = userDoc['role'] ?? '';
    ref.read(userRoleProvider.notifier).state = userRole;
  }

  Future<void> fetchUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      ref.read(userNameProvider.notifier).state = user.displayName ?? '';
      await _updateUserRole(user.uid);
    }
  }

  String getCurrentUserRole() {
    return ref.read(userRoleProvider);
  }

  Future<void> setUserRole(String userId) async {
    final DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    final String userRole = userDoc['role'] ?? '';
    ref.read(userRoleProvider.notifier).state = userRole;
  }

  Stream<List<UserModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<ExerciseRecord>> getExerciseRecords({
    required String userId,
    required String exerciseId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExerciseRecord.fromFirestore(doc)).toList();
    });
  }

  Future<void> addExerciseRecord({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required int maxWeight,
    required int repetitions,
    required String date,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .add({
      'date': date,'exerciseId': exerciseId,
'exerciseName': exerciseName,
'maxWeight': maxWeight,
'repetitions': repetitions,
'userId': userId,
});
}

Future<void> updateExerciseRecord({
required String userId,
required String exerciseId,
required String recordId,
required int maxWeight,
required int repetitions,
}) async {
await _firestore
   .collection('users')
   .doc(userId)
   .collection('exercises')
   .doc(exerciseId)
   .collection('records')
   .doc(recordId)
   .update({
 'maxWeight': maxWeight,
 'repetitions': repetitions,
});
}

Future<void> deleteExerciseRecord({
required String userId,
required String exerciseId,
required String recordId,
}) async {
await _firestore
   .collection('users')
   .doc(userId)
   .collection('exercises')
   .doc(exerciseId)
   .collection('records')
   .doc(recordId)
   .delete();
}
}