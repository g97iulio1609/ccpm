import 'package:flutter_riverpod/flutter_riverpod.dart';

final workoutIdProvider = StateProvider<String>((ref) => '');
final exercisesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
final loadingProvider = StateProvider<bool>((ref) => false);
