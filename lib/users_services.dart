import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_core/firebase_core.dart';

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
  final num maxWeight;
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

class MeasurementModel {
  final String id;
  final String userId;
  final DateTime date;
  final double weight;
  final double height;
  final double bmi;
  final double bodyFatPercentage;
  final double waistCircumference;
  final double hipCircumference;
  final double chestCircumference;
  final double bicepsCircumference;

  MeasurementModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bodyFatPercentage,
    required this.waistCircumference,
    required this.hipCircumference,
    required this.chestCircumference,
    required this.bicepsCircumference,
  });

  factory MeasurementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeasurementModel(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      weight: data['weight'],
      height: data['height'],
      bmi: data['bmi'],
      bodyFatPercentage: data['bodyFatPercentage'],
      waistCircumference: data['waistCircumference'],
      hipCircumference: data['hipCircumference'],
      chestCircumference: data['chestCircumference'],
      bicepsCircumference: data['bicepsCircumference'],
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
  FirebaseAuth? _authForUserCreation;
  final _usersStreamController = BehaviorSubject<List<UserModel>>();
  String _searchQuery = '';
  StreamSubscription? _userChangesSubscription;

  UsersService(this.ref, this._firestore, this._auth) {
    _initializeUserCreationAuth();
    _auth.authStateChanges().listen((user) async {
      //debugPrint('Main auth state changed. User: $user');
      if (user != null) {
        _updateUserName(user.displayName);
        if (user.uid != _auth.currentUser?.uid) {
          //debugPrint('Updating user role for user: ${user.uid}');
          await _updateUserRole(user.uid);
        }
        _initializeUsersStream();
      } else {
        _clearUsersStream();
      }
    });
  }

  Future<void> _initializeUserCreationAuth() async {
    final FirebaseApp userCreationApp = await Firebase.initializeApp(
      name: 'UserCreationApp',
      options: Firebase.app().options,
    );
    _authForUserCreation = FirebaseAuth.instanceFor(app: userCreationApp);
  }

  void _initializeUsersStream() {
    _userChangesSubscription?.cancel();
    _userChangesSubscription =
        _firestore.collection('users').snapshots().listen((snapshot) {
      final users =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
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
      return users
          .where((user) =>
              user.name.toLowerCase().contains(lowercaseQuery) ||
              user.email.toLowerCase().contains(lowercaseQuery) ||
              user.role.toLowerCase().contains(lowercaseQuery))
          .toList();
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
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      final String userRole = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['role'] ?? ''
          : '';
      ref.read(userRoleProvider.notifier).state = userRole;
    } catch (error) {
      //debugPrint('Error updating user role: $error');
      // In caso di errore di permessi o se il documento utente non esiste, imposta il ruolo predefinito a 'client'
      ref.read(userRoleProvider.notifier).state = 'client';
    }
  }

  Future<void> fetchUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      ref.read(userNameProvider.notifier).state = user.displayName ?? '';
      try {
        await _updateUserRole(user.uid);
      } catch (error) {
        //debugPrint('Error fetching user role: $error');
        // In caso di errore di permessi, imposta il ruolo predefinito a 'client'
        ref.read(userRoleProvider.notifier).state = 'client';
      }
    }
  }

  String getCurrentUserRole() {
    return ref.read(userRoleProvider);
  }

String getCurrentUserId() {
  return _auth.currentUser?.uid ?? '';
}

  Future<void> setUserRole(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final String userRole =
            (userDoc.data() as Map<String, dynamic>)['role'] ?? '';
        ref.read(userRoleProvider.notifier).state = userRole;
        //debugPrint('User role: $userRole');
      }
    } catch (error) {
      //debugPrint('Error setting user role: $error');
    }
  }

  Stream<List<UserModel>> getUsers() {
    return _usersStreamController.stream;
  }

  Future<UserModel?> getUserById(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return UserModel.fromFirestore(userDoc);
    } else {
      return null;
    }
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
      return snapshot.docs
          .map((doc) => ExerciseRecord.fromFirestore(doc))
          .toList();
    });
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

    // Aggiorna i pesi del programma corrente dopo aver aggiunto il record
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

    // Aggiorna i pesi del programma corrente dopo aver aggiornato il record
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
      //debugPrint('Creating user with email: $email');
      UserCredential userCredential =
          await _authForUserCreation!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = userCredential.user;
      if (newUser != null) {
        //debugPrint('User created. User ID: ${newUser.uid}');
        await _firestore.collection('users').doc(newUser.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'photoURL': '', // Imposta il valore predefinito per photoURL
        });
        //debugPrint('User document created in Firestore.');

        await _authForUserCreation!.signOut();
        //debugPrint('Signed out from user creation auth instance.');
      }
    } catch (e) {
      //debugPrint('Error creating user: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> _updateCurrentProgramWeights(
      String userId, String exerciseId, num newMaxWeight) async {
    //debugPrint('Updating current program weights for user: $userId, exercise: $exerciseId');
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentProgramId = userDoc.data()?['currentProgram'];
    //debugPrint('Current program ID: $currentProgramId');

    if (currentProgramId != null) {
      // Aggiorna solo le settimane, workout, esercizi e serie senza toccare la mappa weeks in programs
      await _updateWeeksWeights(currentProgramId, exerciseId, newMaxWeight);
      //debugPrint('Updated current program weights without touching the weeks map in programs document');
    } else {
      //debugPrint('No current program found for user: $userId');
    }
  }

  Future<List<Map<String, dynamic>>> _updateWeeksWeights(
      String programId, String exerciseId, num newMaxWeight) async {
    //debugPrint('Updating weeks weights for program: $programId, exercise: $exerciseId');
    final weeksSnapshot = await _firestore
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .get();
    final updatedWeeks =
        await Future.wait(weeksSnapshot.docs.map((weekDoc) async {
      final weekData = weekDoc.data();
      final updatedWorkouts =
          await _updateWorkoutsWeights(weekDoc.id, exerciseId, newMaxWeight);
      //debugPrint('Updated workouts for week: ${weekDoc.id}');
      return {
        'id': weekDoc.id,
        ...weekData,
        'workouts': updatedWorkouts.map((workout) => workout['id']).toList(),
      };
    }));
    //debugPrint('Updated weeks weights');
    return updatedWeeks;
  }

  Future<List<Map<String, dynamic>>> _updateWorkoutsWeights(
      String weekId, String exerciseId, num newMaxWeight) async {
    //debugPrint('Updating workouts weights for week: $weekId, exercise: $exerciseId');
    final workoutsSnapshot = await _firestore
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .get();
    final updatedWorkouts =
        await Future.wait(workoutsSnapshot.docs.map((workoutDoc) async {
      final workoutData = workoutDoc.data();
      final updatedExercises = await _updateExercisesWeights(
          workoutDoc.id, exerciseId, newMaxWeight);
      //debugPrint('Updated exercises for workout: ${workoutDoc.id}');
      return {
        'id': workoutDoc.id,
        ...workoutData,
        'exercises':
            updatedExercises.map((exercise) => exercise['id']).toList(),
      };
    }));
    //debugPrint('Updated workouts weights');
    return updatedWorkouts;
  }

  Future<List<Map<String, dynamic>>> _updateExercisesWeights(
      String workoutId, String exerciseId, num newMaxWeight) async {
    //debugPrint('Updating exercises weights for workout: $workoutId, exercise: $exerciseId');
    final exercisesSnapshot = await _firestore
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .get();
    final updatedExercises =
        await Future.wait(exercisesSnapshot.docs.map((exerciseDoc) async {
      final exerciseData = exerciseDoc.data();
      if (exerciseData['exerciseId'] == exerciseId) {
        final updatedSeries =
            await _updateSeriesWeights(exerciseDoc.id, newMaxWeight);
        //debugPrint('Updated series for exercise: ${exerciseDoc.id}');
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
    //debugPrint('Updated exercises weights');
    return updatedExercises;
  }

  Future<List<Map<String, dynamic>>> _updateSeriesWeights(
      String exerciseWorkoutId, num newMaxWeight) async {
    //debugPrint('Updating series weights for exercise workout: $exerciseWorkoutId');
    final seriesSnapshot = await _firestore
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseWorkoutId)
        .get();
    final updatedSeries =
        await Future.wait(seriesSnapshot.docs.map((serieDoc) async {
      final serieData = serieDoc.data();
      final intensity = double.parse(serieData['intensity']);
      final calculatedWeight = (newMaxWeight * intensity) / 100;

      // Aggiorna il documento della serie sul Firestore
      await _firestore.collection('series').doc(serieDoc.id).update({
        'weight': calculatedWeight,
      });

      return {
        'id': serieDoc.id,
        ...serieData,
        'weight': calculatedWeight,
      };
    }));
    //debugPrint('Updated series weights');
    return updatedSeries;
  }

  Future<num> _getLatestMaxWeight(String exerciseId) async {
    final snapshot = await _firestore
        .collectionGroup('records')
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    //debugPrint("exerciseId: $exerciseId");

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final maxWeightData = data['maxWeight'];
      if (maxWeightData is int) {
        final maxWeight = maxWeightData.toDouble();
        //debugPrint("maxWeight: $maxWeight");
        return maxWeight;
      } else if (maxWeightData is double) {
        //debugPrint("maxWeight: $maxWeightData");
        return maxWeightData;
      } else {
        //debugPrint("Invalid data type for maxWeight: $maxWeightData");
        return 0.0;
      }
    } else {
      //debugPrint("No records found for exerciseId: $exerciseId");
      return 0.0;
    }
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

  Stream<List<MeasurementModel>> getMeasurements({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MeasurementModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> deleteMeasurement({
    required String userId,
    required String measurementId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc(measurementId)
        .delete();
  }
}
