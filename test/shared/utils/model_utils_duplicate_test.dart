import 'package:alphanessone/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharedSeriesUtils.duplicateSeries', () {
    test('generates a new serieId and resets progress data', () {
      final original = Series(
        id: 'series-1',
        serieId: 'series-1',
        exerciseId: 'exercise-1',
        order: 1,
        reps: 12,
        sets: 3,
        weight: 80,
        repsDone: 12,
        weightDone: 80,
        done: true,
        isCompleted: true,
      );

      final duplicated = SharedSeriesUtils.duplicateSeries(original);

      expect(duplicated.serieId, isNotNull);
      expect(duplicated.serieId, isNot(equals(original.serieId)));
      expect(duplicated.done, isFalse);
      expect(duplicated.isCompleted, isFalse);
      expect(duplicated.repsDone, equals(0));
      expect(duplicated.weightDone, equals(0));
    });
  });

  group('WorkoutUtils.duplicateWorkout', () {
    test('reassigns supersets and exercise references with new IDs', () {
      final originalSeries = Series(
        id: 'series-1',
        serieId: 'series-1',
        exerciseId: 'exercise-1',
        order: 1,
        reps: 10,
        sets: 1,
        weight: 50,
      );

      final originalExercise = Exercise(
        id: 'exercise-1',
        exerciseId: 'catalog-1',
        name: 'Bench Press',
        type: 'weight',
        order: 1,
        superSetId: 'superset-1',
        series: [originalSeries],
      );

      final originalWorkout = Workout(
        id: 'workout-1',
        order: 1,
        name: 'Upper A',
        exercises: [originalExercise],
        superSets: const <Map<String, dynamic>>[
          {
            'id': 'superset-1',
            'name': 'SS1',
            'exerciseIds': <String>['exercise-1'],
          },
        ],
      );

      final duplicated = WorkoutUtils.duplicateWorkout(originalWorkout);

      expect(duplicated.id, isNotNull);
      expect(duplicated.id, isNot(equals(originalWorkout.id)));
      expect(duplicated.superSets, isNotNull);
      expect(duplicated.superSets!.length, equals(1));

      final duplicatedSuperSet = duplicated.superSets!.first;
      final duplicatedExercise = duplicated.exercises.first;

      expect(duplicatedSuperSet['id'], isNot(equals('superset-1')));
      expect(duplicatedExercise.superSetId, equals(duplicatedSuperSet['id']));
      expect(duplicatedSuperSet['exerciseIds'], [duplicatedExercise.id]);
    });

    test('clears stale superset references when source has none', () {
      final originalExercise = Exercise(
        id: 'exercise-10',
        exerciseId: 'catalog-3',
        name: 'Lat Pulldown',
        type: 'weight',
        order: 1,
        superSetId: 'obsolete',
        series: const [],
      );

      final originalWorkout = Workout(
        id: 'workout-10',
        order: 1,
        name: 'Pull',
        exercises: [originalExercise],
        superSets: const <Map<String, dynamic>>[],
      );

      final duplicated = WorkoutUtils.duplicateWorkout(originalWorkout);

      expect(duplicated.superSets, isEmpty);
      expect(duplicated.exercises.first.superSetId, isNull);
    });
  });

  group('WeekUtils.duplicateWeek', () {
    test('creates independent copies with updated superset wiring', () {
      final originalSeries = Series(
        id: 'series-1',
        serieId: 'series-1',
        exerciseId: 'exercise-1',
        order: 1,
        reps: 8,
        sets: 3,
        weight: 70,
      );

      final originalExercise = Exercise(
        id: 'exercise-1',
        exerciseId: 'catalog-1',
        name: 'Squat',
        type: 'weight',
        order: 1,
        superSetId: 'superset-1',
        series: [originalSeries],
      );

      final originalWorkout = Workout(
        id: 'workout-1',
        order: 1,
        name: 'Lower A',
        exercises: [originalExercise],
        superSets: const <Map<String, dynamic>>[
          {
            'id': 'superset-1',
            'name': 'Leg Giant',
            'exerciseIds': <String>['exercise-1'],
          },
        ],
      );

      final originalWeek = Week(
        id: 'week-1',
        number: 1,
        workouts: [originalWorkout],
      );

      final duplicated = WeekUtils.duplicateWeek(originalWeek, newNumber: 2);

      expect(duplicated.id, isNot(equals(originalWeek.id)));
      expect(duplicated.number, equals(2));
      expect(duplicated.workouts, hasLength(1));

      final duplicatedWorkout = duplicated.workouts.first;
      final duplicatedExercise = duplicatedWorkout.exercises.first;
      final duplicatedSuperSet = duplicatedWorkout.superSets!.first;

      expect(duplicatedWorkout.id, isNot(equals(originalWorkout.id)));
      expect(duplicatedExercise.id, isNot(equals(originalExercise.id)));
      expect(duplicatedSuperSet['id'], isNot(equals('superset-1')));
      expect(duplicatedSuperSet['exerciseIds'], [duplicatedExercise.id]);
      expect(duplicatedExercise.superSetId, equals(duplicatedSuperSet['id']));
      expect(
        duplicatedExercise.series.first.serieId,
        isNot(equals(originalExercise.series.first.serieId)),
      );
    });

    test('preserves original names when requested', () {
      final originalExercise = Exercise(
        id: 'exercise-1',
        exerciseId: 'catalog-1',
        name: 'Overhead Press',
        type: 'weight',
        order: 1,
        series: const [],
      );

      final originalWorkout = Workout(
        id: 'workout-1',
        order: 1,
        name: 'Upper B',
        exercises: [originalExercise],
      );

      final originalWeek = Week(
        id: 'week-1',
        number: 3,
        name: 'Volume Week',
        workouts: [originalWorkout],
      );

      final duplicated = WeekUtils.duplicateWeek(
        originalWeek,
        preserveWorkoutNames: true,
        preserveExerciseNames: true,
      );

      expect(duplicated.name, equals(originalWeek.name));
      expect(duplicated.workouts.first.name, equals('Upper B'));
      expect(
        duplicated.workouts.first.exercises.first.name,
        equals('Overhead Press'),
      );
    });
  });

  group('Program duplication flow', () {
    test('duplicates full nested structure without trimming data', () {
      final exerciseFactory = (String id, String supersetId) => Exercise(
        id: id,
        exerciseId: 'catalog-$id',
        name: 'Exercise $id',
        type: 'weight',
        order: 1,
        superSetId: supersetId.isEmpty ? null : supersetId,
        series: [
          Series(
            id: 'series-$id-1',
            serieId: 'series-$id-1',
            exerciseId: id,
            order: 1,
            reps: 5,
            sets: 3,
            weight: 100,
          ),
          Series(
            id: 'series-$id-2',
            serieId: 'series-$id-2',
            exerciseId: id,
            order: 2,
            reps: 8,
            sets: 3,
            weight: 90,
          ),
        ],
      );

      final weekBuilder = (int weekNumber) {
        final workoutA = Workout(
          id: 'workout-$weekNumber-A',
          order: 1,
          name: 'Workout A$weekNumber',
          exercises: [
            exerciseFactory('ex-$weekNumber-A1', 'ss-$weekNumber-1'),
            exerciseFactory('ex-$weekNumber-A2', 'ss-$weekNumber-1'),
          ],
          superSets: [
            {
              'id': 'ss-$weekNumber-1',
              'name': 'Superset $weekNumber',
              'exerciseIds': ['ex-$weekNumber-A1', 'ex-$weekNumber-A2'],
            },
          ],
        );

        final workoutB = Workout(
          id: 'workout-$weekNumber-B',
          order: 2,
          name: 'Workout B$weekNumber',
          exercises: [exerciseFactory('ex-$weekNumber-B1', '')],
          superSets: const <Map<String, dynamic>>[],
        );

        return Week(
          id: 'week-$weekNumber',
          number: weekNumber,
          workouts: [workoutA, workoutB],
        );
      };

      final originalProgram = TrainingProgram(
        id: 'program-1',
        name: 'Hypertrophy',
        description: 'Base block',
        athleteId: 'athlete-1',
        mesocycleNumber: 2,
        hide: false,
        status: 'private',
        weeks: [weekBuilder(1), weekBuilder(2)],
      );

      final duplicatedWeeks = originalProgram.weeks.map((week) {
        return WeekUtils.resetWeek(
          WeekUtils.duplicateWeek(
            week,
            newNumber: week.number,
            preserveWorkoutNames: true,
            preserveExerciseNames: true,
          ),
        );
      }).toList();

      final newProgram = TrainingProgram(
        id: ModelUtils.generateId(),
        name: 'Hypertrophy Copy',
        description: originalProgram.description,
        athleteId: originalProgram.athleteId,
        mesocycleNumber: originalProgram.mesocycleNumber,
        hide: originalProgram.hide,
        status: originalProgram.status,
        weeks: duplicatedWeeks,
      );

      expect(newProgram.weeks.length, equals(originalProgram.weeks.length));
      for (int i = 0; i < newProgram.weeks.length; i++) {
        final originalWeek = originalProgram.weeks[i];
        final duplicatedWeek = newProgram.weeks[i];

        expect(duplicatedWeek.number, equals(originalWeek.number));
        expect(
          duplicatedWeek.workouts.length,
          equals(originalWeek.workouts.length),
        );
        for (int wi = 0; wi < duplicatedWeek.workouts.length; wi++) {
          final originalWorkout = originalWeek.workouts[wi];
          final duplicatedWorkout = duplicatedWeek.workouts[wi];

          expect(duplicatedWorkout.name, equals(originalWorkout.name));
          expect(
            duplicatedWorkout.exercises.length,
            equals(originalWorkout.exercises.length),
          );
          for (int ei = 0; ei < duplicatedWorkout.exercises.length; ei++) {
            final originalExercise = originalWorkout.exercises[ei];
            final duplicatedExercise = duplicatedWorkout.exercises[ei];

            expect(duplicatedExercise.name, equals(originalExercise.name));
            expect(
              duplicatedExercise.series.length,
              equals(originalExercise.series.length),
            );
            expect(
              duplicatedExercise.series.first.serieId,
              isNot(equals(originalExercise.series.first.serieId)),
            );
          }
        }
      }
    });
  });

  group('TrainingProgram deletion tracking', () {
    test(
      'markSeriesForDeletion falls back to document ID when serieId missing',
      () {
        final program = TrainingProgram(id: 'p1', name: 'Test');
        final series = Series(
          id: 'doc-123',
          serieId: null,
          exerciseId: 'ex-1',
          order: 1,
          reps: 5,
          weight: 50,
        );

        program.markSeriesForDeletion(series);

        expect(program.trackToDeleteSeries, contains('doc-123'));
      },
    );
  });
}
