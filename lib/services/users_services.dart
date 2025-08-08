import 'dart:async';
import 'dart:math';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';

class UniqueNumberGenerator {
  static String generate() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

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
      await _fetchAndSetUserRole(user.uid);
      _initializeUsersStream();
    } else {
      _clearUsersStream();
      clearUserData();
    }
  }

  Future<void> _fetchAndSetUserRole(String userId) async {
    await fetchUserRole();
  }

  void _initializeUsersStream() {
    _userChangesSubscription?.cancel();
    _userChangesSubscription = _firestore
        .collection('users')
        .snapshots()
        .listen((snapshot) {
          final users = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
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

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      _ref.read(userRoleProvider.notifier).state = newRole;
    } catch (e) {
      throw Exception('Failed to update user role');
    }
  }

  Future<void> updateUserSubscription(
    String userId,
    DateTime expiryDate,
    String productId,
    String purchaseToken,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
        'productId': productId,
        'purchaseToken': purchaseToken,
      });
    } catch (e) {
      throw Exception('Failed to update user subscription expiry date');
    }
  }

  Future<void> checkAndExpireSubscriptions() async {
    try {
      final now = DateTime.now();
      final users = await _firestore.collection('users').get();

      for (var userDoc in users.docs) {
        final userData = userDoc.data();
        final expiryDate = (userData['subscriptionExpiryDate'] as Timestamp?)
            ?.toDate();
        final currentRole = userData['role'] as String?;

        if (expiryDate != null &&
            expiryDate.isBefore(now) &&
            (currentRole == 'client_premium' || currentRole == 'coach')) {
          await updateUserRole(userDoc.id, 'client');
        }
      }
    } catch (e) {
      throw Exception('Failed to check and expire subscriptions');
    }
  }

  Future<DateTime?> getUserSubscriptionExpiryDate(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data()?['subscriptionExpiryDate']?.toDate();
  }

  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? '';
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

  Future<void> setUserRole(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final String userRole =
          (userDoc.data() as Map<String, dynamic>)['role'] ?? 'client';
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

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> deleteUser(String userId) async {
    try {
      String currentUserRole = getCurrentUserRole();

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        if (currentUserRole == 'admin') {
          final result = await _functions.httpsCallable('deleteUser').call({
            'userId': userId,
          });
          if (result.data['success'] != true) {
            throw Exception('Failed to delete user via Cloud Function');
          }
        } else {
          User? currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.uid == userId) {
            await currentUser.delete();
            await _firestore.collection('users').doc(userId).delete();
            await _auth.signOut();
          } else {
            throw Exception(
              'Gli utenti non-admin possono eliminare solo il proprio account.',
            );
          }
        }

        final updatedUsers = _usersStreamController.value
            .where((user) => user.id != userId)
            .toList();
        _usersStreamController.add(updatedUsers);
      } else {
        throw Exception('Utente non trovato in Firestore.');
      }
    } catch (e) {
      throw Exception("Errore durante l'eliminazione dell'utente: $e");
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
    String? gender,
  }) async {
    try {
      UserCredential userCredential = await _authForUserCreation!
          .createUserWithEmailAndPassword(email: email, password: password);

      User? newUser = userCredential.user;
      if (newUser != null) {
        String? uniqueNumber;
        if (role == 'coach') {
          uniqueNumber = await _generateUniqueNumber();
        }

        int genderValue;
        switch (gender!.toLowerCase()) {
          case 'male':
            genderValue = 1;
            break;
          case 'female':
            genderValue = 2;
            break;
          default:
            genderValue = 0;
        }

        await _firestore.collection('users').doc(newUser.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'photoURL': '',
          'gender': genderValue,
          'uniqueNumber': uniqueNumber,
        });
        await _authForUserCreation!.signOut();
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> _generateUniqueNumber() async {
    String uniqueNumber;
    bool isUnique = false;
    do {
      uniqueNumber = UniqueNumberGenerator.generate();
      final querySnapshot = await _firestore
          .collection('users')
          .where('uniqueNumber', isEqualTo: uniqueNumber)
          .get();
      isUnique = querySnapshot.docs.isEmpty;
    } while (!isUnique);
    return uniqueNumber;
  }

  Future<String?> getUniqueNumber(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data()?['uniqueNumber'];
  }

  Future<UserModel?> getUserByUniqueNumber(String uniqueNumber) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('uniqueNumber', isEqualTo: uniqueNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  void clearUserData() {
    _ref.read(userNameProvider.notifier).state = '';
    _ref.read(userRoleProvider.notifier).state = '';
  }

  ExerciseRecordService get exerciseRecordService => _exerciseRecordService;

  Future<UserModel?> getCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId.isEmpty) return null;
    return await getUserById(userId);
  }
}
