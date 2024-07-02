import 'dart:async';
import 'package:alphanessone/services/exercise_record_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/user_model.dart';
import '../providers/providers.dart';

class UsersService {
  final Ref _ref;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  FirebaseAuth? _authForUserCreation;
  final _usersStreamController = BehaviorSubject<List<UserModel>>();
  StreamSubscription? _userChangesSubscription;
  String _searchQuery = '';
  final ExerciseRecordService _exerciseRecordService;

  UsersService(this._ref, this._firestore, this._auth)
      : _exerciseRecordService = _ref.read(exerciseRecordServiceProvider) {
    _initializeUserCreationAuth();
    _auth.authStateChanges().listen(_handleAuthStateChanges);
  }

  Future<void> _initializeUserCreationAuth() async {
    final FirebaseApp userCreationApp = await Firebase.initializeApp(
      name: 'UserCreationApp',
      options: Firebase.app().options,
    );
    _authForUserCreation = FirebaseAuth.instanceFor(app: userCreationApp);
  }

  void _handleAuthStateChanges(User? user) async {
    if (user != null) {
      updateUserName(user.displayName);
      if (user.uid != _auth.currentUser?.uid) {
        await _updateUserRole(user.uid);
      }
      _initializeUsersStream();
    } else {
      _clearUsersStream();
    }
  }

  void _initializeUsersStream() {
    _userChangesSubscription?.cancel();
    _userChangesSubscription =
        _firestore.collection('users').snapshots().listen((snapshot) {
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
      return users.where((user) {
        return user.name.toLowerCase().contains(lowercaseQuery) ||
            user.email.toLowerCase().contains(lowercaseQuery) ||
            user.role.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
  }

  void searchUsers(String query) {
    _searchQuery = query;
    final users = _usersStreamController.value;
    _usersStreamController.add(_filterUsers(users));
  }

  void updateUserName(String? displayName) {
    final userName = displayName ?? '';
    _ref.read(userNameProvider.notifier).state = userName;
  }

  Future<void> _updateUserRole(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final String userRole = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['role'] ?? 'client'
          : 'client';
      _ref.read(userRoleProvider.notifier).state = userRole;
    } catch (error) {
      _ref.read(userRoleProvider.notifier).state = 'client';
    }
  }

  Future<void> fetchUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      updateUserName(user.displayName);
      await _updateUserRole(user.uid);
    }
  }

  String getCurrentUserRole() {
    return _ref.read(userRoleProvider);
  }

  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? '';
  }

  Future<void> setUserRole(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final String userRole = (userDoc.data() as Map<String, dynamic>)['role'] ?? 'client';
      _ref.read(userRoleProvider.notifier).state = userRole;
    }
  }

  Stream<List<UserModel>> getUsers() {
    return _usersStreamController.stream;
  }

  Future<UserModel?> getUserById(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.exists ? UserModel.fromFirestore(userDoc) : null;
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Elimina il documento dell'utente nella collection 'users'
      await _firestore.collection('users').doc(userId).delete();

      // Elimina l'utente dall'autenticazione Firebase
      User? user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
      } else {
        throw Exception("User not authenticated or mismatched userId.");
      }
    } catch (e) {
      throw Exception('Errore durante l\'eliminazione dell\'utente: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _authForUserCreation!
          .createUserWithEmailAndPassword(email: email, password: password);

      User? newUser = userCredential.user;
      if (newUser != null) {
        await _firestore.collection('users').doc(newUser.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'photoURL': '',
        });
        await _authForUserCreation!.signOut();
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void clearUserData() {
    _ref.read(userNameProvider.notifier).state = '';
    _ref.read(userRoleProvider.notifier).state = '';
  }

  // Access methods of ExerciseRecordService directly when needed
  ExerciseRecordService get exerciseRecordService => _exerciseRecordService;
}
