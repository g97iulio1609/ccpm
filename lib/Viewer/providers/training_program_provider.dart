import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Viewer/services/training_program_services.dart';

// Minimal providers kept for UI titles; legacy providers removed as non utilizzati
final currentWorkoutNameProvider = StateProvider<String>(
  (ref) => 'Allenamento',
);
final currentWeekNameProvider = StateProvider<String>((ref) => 'Settimana');

// Service provider centralizzato
final trainingProgramServicesProvider = Provider<TrainingProgramServices>(
  (ref) => TrainingProgramServices(),
);
