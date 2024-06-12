import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exercise_services.dart';

final exerciseServiceProvider = Provider<ExerciseService>((ref) => ExerciseService());
