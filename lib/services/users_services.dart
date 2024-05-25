import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/user_model.dart';
import '../models/exercise_record.dart';
import '../models/measurement_model.dart';

// Providers
final userNameProvider = StateProvider<String>((ref) => '');
final userRoleProvider = StateProvider<String>((ref) => '');

// Service Provider
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, FirebaseFirestore.instance, FirebaseAuth.instance);
});

class UsersService {
  final Ref _ref;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  FirebaseAuth? _authForUserCreation;
  final _usersStreamController = BehaviorSubject<List<UserModel>>();
  StreamSubscription? _userChangesSubscription;
  String _searchQuery = '';

  UsersService(this._ref, this._firestore, this._auth) {
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
        .map((snapshot) => snapshot.docs.map((doc) => ExerciseRecord.fromFirestore(doc)).toList());
  }

  Future<void> addExerciseRecord({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required num maxWeight,
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
    await _updateCurrentProgramWeights(userId, exerciseId, maxWeight);
  }

  Future<void> updateExerciseRecord({
    required String userId,
    required String exerciseId,
    required String recordId,
    required num maxWeight,
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
    await _updateCurrentProgramWeights(userId, exerciseId, maxWeight);
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

  Future<void> _updateCurrentProgramWeights(String userId, String exerciseId, num newMaxWeight) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentProgramId = userDoc.data()?['currentProgram'];
    if (currentProgramId != null) {
      await _updateWeeksWeights(currentProgramId, exerciseId, newMaxWeight);
    }
  }

  Future<void> updateMeasurement({
    required String userId,
    required String measurementId,
    required DateTime date,
    required double weight,
    required double height,
    required double bmi,
    required double bodyFatPercentage,
    required double waistCircumference,
    required double hipCircumference,
    required double chestCircumference,
    required double bicepsCircumference,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc(measurementId)
        .update({
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'bodyFatPercentage': bodyFatPercentage,
      'waistCircumference': waistCircumference,
      'hipCircumference': hipCircumference,
      'chestCircumference': chestCircumference,
      'bicepsCircumference': bicepsCircumference,
      'userId': userId,
    });
  }

  Future<String> addMeasurement({
    required String userId,
    required DateTime date,
    required double weight,
    required double height,
    required double bmi,
    required double bodyFatPercentage,
    required double waistCircumference,
    required double hipCircumference,
    required double chestCircumference,
    required double bicepsCircumference,
  }) async {
    final measurementData = {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'bodyFatPercentage': bodyFatPercentage,
      'waistCircumference': waistCircumference,
      'hipCircumference': hipCircumference,
      'chestCircumference': chestCircumference,
      'bicepsCircumference': bicepsCircumference,
      'userId': userId,
    };

    final measurementDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .add(measurementData);

    return measurementDoc.id;
  }

  Stream<List<MeasurementModel>> getMeasurements({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MeasurementModel.fromFirestore(doc)).toList());
  }

  Future<void> deleteMeasurement({required String userId, required String measurementId}) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc(measurementId)
        .delete();
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

  Future<Map<String, dynamic>?> getTDEEData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      return {
        'birthDate': userData['birthDate'],
        'height': userData['height'],
        'weight': userData['weight'],
        'gender': userData['gender'],
        'activityLevel': userData['activityLevel'],
        'tdee': userData['tdee'],
      };
    }
    return null;
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

  Future<Map<String, dynamic>> getUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data() ?? {};
  }

  Future<num> _getLatestMaxWeight(String exerciseId) async {
    final snapshot = await _firestore
        .collectionGroup('records')
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return data['maxWeight'] is int ? data['maxWeight'].toDouble() : data['maxWeight'];
    }
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> _updateWeeksWeights(
      String programId, String exerciseId, num newMaxWeight) async {
    final weeksSnapshot = await _firestore
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .get();
    return await Future.wait(weeksSnapshot.docs.map((weekDoc) async {
      final weekData = weekDoc.data();
      final updatedWorkouts = await _updateWorkoutsWeights(weekDoc.id, exerciseId, newMaxWeight);
      return {
        'id': weekDoc.id,
        ...weekData,
        'workouts': updatedWorkouts.map((workout) => workout['id']).toList(),
      };
    }));
  }

  Future<List<Map<String, dynamic>>> _updateWorkoutsWeights(
      String weekId, String exerciseId, num newMaxWeight) async {
    final workoutsSnapshot = await _firestore
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .get();
    return await Future.wait(workoutsSnapshot.docs.map((workoutDoc) async {
      final workoutData = workoutDoc.data();
      final updatedExercises = await _updateExercisesWeights(workoutDoc.id, exerciseId, newMaxWeight);
      return {
        'id': workoutDoc.id,
        ...workoutData,
        'exercises': updatedExercises.map((exercise) => exercise['id']).toList(),
      };
    }));
  }

  Future<List<Map<String, dynamic>>> _updateExercisesWeights(
      String workoutId, String exerciseId, num newMaxWeight) async {
    final exercisesSnapshot = await _firestore
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .get();
    return await Future.wait(exercisesSnapshot.docs.map((exerciseDoc) async {
      final exerciseData = exerciseDoc.data();
      if (exerciseData['exerciseId'] == exerciseId) {
        final updatedSeries = await _updateSeriesWeights(exerciseDoc.id, newMaxWeight);
        return {
          'id': exerciseDoc.id,
          ...exerciseData,
          'series': updatedSeries.map((serie) => serie['id']).toList(),
        };
      }
      return {
        'id': exerciseDoc.id,
        ...exerciseData,
      };
    }));
  }

  Future<List<Map<String, dynamic>>> _updateSeriesWeights(
      String exerciseWorkoutId, num newMaxWeight) async {
    final seriesSnapshot = await _firestore
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseWorkoutId)
        .get();
    return await Future.wait(seriesSnapshot.docs.map((serieDoc) async {
      final serieData = serieDoc.data();
      final intensity = double.parse(serieData['intensity']);
      final calculatedWeight = (newMaxWeight * intensity) / 100;
      await _firestore.collection('series').doc(serieDoc.id).update({'weight': calculatedWeight});
      return {
        'id': serieDoc.id,
        ...serieData,
        'weight': calculatedWeight,
      };
    }));
  }

  void clearUserData() {
    _ref.read(userNameProvider.notifier).state = '';
    _ref.read(userRoleProvider.notifier).state = '';
  }
}