// usersServices.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

final userNameProvider = StateProvider<String>((ref) => '');
final userRoleProvider = StateProvider<String>((ref) => '');

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String photoURL;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.photoURL,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      photoURL: data['photoURL'] ?? '',
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
  final _usersStreamController = BehaviorSubject<List<UserModel>>();
  String _searchQuery = '';
  StreamSubscription? _userChangesSubscription;

  UsersService(this.ref, this._firestore, this._auth) {
    _auth.userChanges().listen((user) async {
      if (user != null) {
        _updateUserName(user.displayName);
        await _updateUserRole(user.uid);
        _initializeUsersStream();
      } else {
        _clearUsersStream();
      }
    });
  }

  void _initializeUsersStream() {
    _userChangesSubscription?.cancel();
    _userChangesSubscription = _firestore.collection('users').snapshots().listen((snapshot) {
      final users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      _usersStreamController.add(_filterUsers(users));
    });
  }

  void _clearUsersStream() {
    _userChangesSubscription?.cancel();
    _usersStreamController.add([]);
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) {
      return users;
    } else {
      final lowercaseQuery = _searchQuery.toLowerCase();
      return users.where((user) =>
          user.name.toLowerCase().contains(lowercaseQuery) ||
          user.email.toLowerCase().contains(lowercaseQuery) ||
          user.role.toLowerCase().contains(lowercaseQuery)).toList();
    }
  }

  void searchUsers(String query) {
    _searchQuery = query;
    final users = _usersStreamController.value;
    _usersStreamController.add(_filterUsers(users));
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
  print('User role: $userRole');
}

  Stream<List<UserModel>> getUsers() {
    return _usersStreamController.stream;
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
      'date': date,
      'exerciseId': exerciseId,
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

  void clearUserData() {
    ref.read(userNameProvider.notifier).state = '';
    ref.read(userRoleProvider.notifier).state = '';
  }

  Future<ExerciseRecord?> getLatestExerciseRecord({
    required String userId,
    required String exerciseId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ExerciseRecord.fromFirestore(snapshot.docs.first);
    } else {
      return null;
    }
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'photoURL': '',
        });
        await user.updateDisplayName(name);
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}