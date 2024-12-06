import 'package:alphanessone/Viewer/UI/workout_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import '../services/training_program_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider per le note degli esercizi
final exerciseNotesProvider = StateProvider<Map<String, String>>((ref) => {});

// Provider per la cache degli esercizi
final exerciseCacheProvider =
    StateProvider<Map<String, List<Map<String, dynamic>>>>((ref) => {});

// Provider per la cache dei nomi dei workout
final workoutNameCacheProvider = StateProvider<Map<String, String>>((ref) => {});

// Provider per la lista degli esercizi del workout corrente
final exercisesProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// Provider per il caricamento
final loadingProvider = StateProvider<bool>((ref) => false);

// Provider per l'ID del workout corrente
final workoutIdProvider = StateProvider<String?>((ref) => null);

// Provider per il nome del workout corrente
final currentWorkoutNameProvider = StateProvider<String>((ref) => '');

// Provider per il ruolo dell'utente (per es. admin o user)
final userRoleProvider = StateProvider<String?>((ref) => null);

// Provider per l'ID dell'utente
final userIdProvider = StateProvider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid;
});

// Provider per il service che si occupa della logica di business
final trainingProgramServicesProvider =
    Provider<TrainingProgramServices>((ref) {
  return TrainingProgramServices();
});

final exerciseRecordServiceProvider = Provider<ExerciseRecordService>((ref) {
  return ExerciseRecordService(FirebaseFirestore.instance);
});

// Provider per istanziare il WorkoutService, a cui passiamo i servizi necessari
final workoutServiceProvider = Provider((ref) => WorkoutService(
  ref: ref,
  trainingProgramServices: ref.read(trainingProgramServicesProvider),
  exerciseRecordService: ref.read(exerciseRecordServiceProvider)
));
