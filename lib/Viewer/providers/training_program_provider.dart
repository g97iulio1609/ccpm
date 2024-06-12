import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/training_program_services.dart';

final trainingServiceProvider = Provider<TrainingService>((ref) => TrainingService());
final trainingWeeksProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
final trainingLoadingProvider = StateProvider<bool>((ref) => false);
