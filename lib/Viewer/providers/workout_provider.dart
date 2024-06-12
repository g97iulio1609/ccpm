import 'package:flutter_riverpod/flutter_riverpod.dart';

final workoutIdProvider = StateProvider<String?>((ref) => null);
final exercisesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
final loadingProvider = StateProvider<bool>((ref) => true);
