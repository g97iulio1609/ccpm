import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/exercise_services.dart';

final exerciseServiceProvider = Provider<ExerciseService>((ref) => ExerciseService());
