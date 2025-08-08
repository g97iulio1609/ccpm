import 'package:alphanessone/shared/shared.dart';

/// Groups exercises by superSetId. Singletons are returned as their own groups.
Map<String?, List<Exercise>> groupExercisesBySuperSet(
  List<Exercise> exercises,
) {
  final Map<String?, List<Exercise>> temp = {};
  for (final exercise in exercises) {
    final superSetId = exercise.superSetId;
    (temp[superSetId] ??= <Exercise>[]).add(exercise);
  }

  final Map<String?, List<Exercise>> result = {};
  temp.forEach((superSetId, group) {
    if (superSetId == null || superSetId.isEmpty || group.length < 2) {
      for (final ex in group) {
        result[ex.id] = [ex];
      }
    } else {
      group.sort((a, b) => a.order.compareTo(b.order));
      result[superSetId] = group;
    }
  });

  return result;
}
