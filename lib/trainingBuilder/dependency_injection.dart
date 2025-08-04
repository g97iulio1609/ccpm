import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Repository interfaces implementations
import 'infrastructure/repositories/firestore_training_repository.dart';

// Business services
import 'domain/services/training_business_service.dart';
import 'domain/services/week_business_service.dart';
import 'domain/services/workout_business_service.dart';
import 'domain/services/exercise_business_service.dart';

// Controllers refactored
import 'controller/training_program_controller_refactored.dart';
import 'controller/week_controller_refactored.dart';
import 'controller/workout_controller_refactored.dart';
import 'controller/exercise_controller_refactored.dart';
import 'controller/progression_controller_refactored.dart';

// Models
import 'models/training_model.dart';

// External dependencies
import '../ExerciseRecords/exercise_record_services.dart';
import '../services/users_services.dart';

/// Dependency Injection container per il Training Builder
/// Implementa il principio Dependency Inversion (SOLID)
class TrainingBuilderDI {
  TrainingBuilderDI._();

  /// Provider per il Training Repository
  static final trainingRepositoryProvider = Provider((ref) {
    return FirestoreTrainingRepository();
  });

  /// Provider per il Series Repository
  static final seriesRepositoryProvider = Provider((ref) {
    return FirestoreSeriesRepository();
  });

  /// Provider per l'Exercise Record Service (servizio esterno)
  /// Configurato per utilizzare FirebaseFirestore.instance
  static final exerciseRecordServiceProvider =
      Provider<ExerciseRecordService>((ref) {
    return ExerciseRecordService(FirebaseFirestore.instance);
  });

  /// Provider per l'Users Service (servizio esterno)
  /// Configurato con Ref, FirebaseFirestore e FirebaseAuth
  static final usersServiceProvider = Provider<UsersService>((ref) {
    return UsersService(
      ref,
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
  });

  // Business Services Providers

  /// Provider per il Week Business Service
  static final weekBusinessServiceProvider = Provider((ref) {
    return WeekBusinessService();
  });

  /// Provider per il Workout Business Service
  static final workoutBusinessServiceProvider = Provider((ref) {
    return WorkoutBusinessService();
  });

  /// Provider per l'Exercise Business Service
  static final exerciseBusinessServiceProvider = Provider((ref) {
    return ExerciseBusinessService(
      exerciseRecordService: ref.read(exerciseRecordServiceProvider),
    );
  });

  /// Provider per il Training Business Service (principale)
  static final trainingBusinessServiceProvider = Provider((ref) {
    return TrainingBusinessService(
      trainingRepository: ref.read(trainingRepositoryProvider),
      exerciseRecordService: ref.read(exerciseRecordServiceProvider),
    );
  });

  // Controllers Providers

  /// Provider per il Training Program Controller refactorizzato
  static final trainingProgramControllerProvider =
      ChangeNotifierProvider((ref) {
    return TrainingProgramControllerRefactored(
      businessService: ref.read(trainingBusinessServiceProvider),
      usersService: ref.read(usersServiceProvider),
    );
  });

  /// Provider per il Week Controller refactorizzato
  static final weekControllerProvider = ChangeNotifierProvider((ref) {
    return WeekControllerRefactored(
      businessService: ref.read(weekBusinessServiceProvider),
    );
  });

  /// Provider per il Workout Controller refactorizzato
  static final workoutControllerProvider = ChangeNotifierProvider((ref) {
    return WorkoutControllerRefactored(
      businessService: ref.read(workoutBusinessServiceProvider),
    );
  });

  /// Provider per l'Exercise Controller refactorizzato
  static final exerciseControllerProvider = ChangeNotifierProvider((ref) {
    return ExerciseControllerRefactored(
      businessService: ref.read(exerciseBusinessServiceProvider),
    );
  });

  /// Provider per il Progression Controller refactorizzato
  static final progressionControllerProvider = ChangeNotifierProvider((ref) {
    return ProgressionControllerRefactored();
  });

  // Provider Factory per configurazioni specifiche

  /// Factory per creare Training Program Controller con programma specifico
  static ChangeNotifierProvider<TrainingProgramControllerRefactored>
      trainingProgramControllerWithProgramProvider(
          TrainingProgram? initialProgram) {
    return ChangeNotifierProvider((ref) {
      return TrainingProgramControllerRefactored(
        businessService: ref.read(trainingBusinessServiceProvider),
        usersService: ref.read(usersServiceProvider),
        initialProgram: initialProgram,
      );
    });
  }

  // Utility methods per testing e sviluppo

  /// Metodo per ottenere tutti i provider (utile per testing)
  static Map<String, Provider> getAllProviders() {
    return {
      'trainingRepository': trainingRepositoryProvider,
      'seriesRepository': seriesRepositoryProvider,
      'exerciseRecordService': exerciseRecordServiceProvider,
      'usersService': usersServiceProvider,
      'weekBusinessService': weekBusinessServiceProvider,
      'workoutBusinessService': workoutBusinessServiceProvider,
      'exerciseBusinessService': exerciseBusinessServiceProvider,
      'trainingBusinessService': trainingBusinessServiceProvider,
    };
  }

  /// Metodo per ottenere tutti i controller provider (utile per testing)
  static Map<String, ChangeNotifierProvider> getAllControllerProviders() {
    return {
      'trainingProgramController': trainingProgramControllerProvider,
      'weekController': weekControllerProvider,
      'workoutController': workoutControllerProvider,
      'exerciseController': exerciseControllerProvider,
      'progressionController': progressionControllerProvider,
    };
  }

  /// Metodo per validare che tutte le dipendenze siano configurate correttamente
  static bool validateDependencies(ProviderContainer container) {
    try {
      // Testa che tutti i service possano essere creati
      container.read(trainingRepositoryProvider);
      container.read(seriesRepositoryProvider);

      container.read(weekBusinessServiceProvider);
      container.read(workoutBusinessServiceProvider);
      container.read(exerciseBusinessServiceProvider);
      container.read(trainingBusinessServiceProvider);

      // Testa che tutti i controller possano essere creati
      container.read(trainingProgramControllerProvider);
      container.read(weekControllerProvider);
      container.read(workoutControllerProvider);
      container.read(exerciseControllerProvider);
      container.read(progressionControllerProvider);

      return true;
    } catch (e) {
      // Error in dependency validation - logged internally
      return false;
    }
  }
}

/// Estensione per facilitare l'uso dei provider nei widget
extension TrainingBuilderProviders on WidgetRef {
  /// Ottiene il Training Program Controller
  TrainingProgramControllerRefactored get trainingProgramController =>
      read(TrainingBuilderDI.trainingProgramControllerProvider);

  /// Ottiene il Week Controller
  WeekControllerRefactored get weekController =>
      read(TrainingBuilderDI.weekControllerProvider);

  /// Ottiene il Workout Controller
  WorkoutControllerRefactored get workoutController =>
      read(TrainingBuilderDI.workoutControllerProvider);

  /// Ottiene l'Exercise Controller
  ExerciseControllerRefactored get exerciseController =>
      read(TrainingBuilderDI.exerciseControllerProvider);

  /// Ottiene il Progression Controller
  ProgressionControllerRefactored get progressionController =>
      read(TrainingBuilderDI.progressionControllerProvider);

  /// Watch per il Training Program Controller
  TrainingProgramControllerRefactored get watchTrainingProgramController =>
      watch(TrainingBuilderDI.trainingProgramControllerProvider);

  /// Watch per il Week Controller
  WeekControllerRefactored get watchWeekController =>
      watch(TrainingBuilderDI.weekControllerProvider);

  /// Watch per il Workout Controller
  WorkoutControllerRefactored get watchWorkoutController =>
      watch(TrainingBuilderDI.workoutControllerProvider);

  /// Watch per l'Exercise Controller
  ExerciseControllerRefactored get watchExerciseController =>
      watch(TrainingBuilderDI.exerciseControllerProvider);

  /// Watch per il Progression Controller
  ProgressionControllerRefactored get watchProgressionController =>
      watch(TrainingBuilderDI.progressionControllerProvider);
}
