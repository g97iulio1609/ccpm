import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class WorkoutDetails extends StatefulWidget {
  final String programId;
  final String userId;
  final String weekId;
  final String workoutId;

  const WorkoutDetails({
    super.key,
    required this.userId,
    required this.programId,
    required this.weekId,
    required this.workoutId,
  });

  @override
  _WorkoutDetailsState createState() => _WorkoutDetailsState();
}

class _WorkoutDetailsState extends State<WorkoutDetails> {
  bool loading = true;
  List<Map<String, dynamic>> exercises = [];
  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    listenToExercises();
  }

  void listenToExercises() {
    setState(() => loading = true);

    var exercisesSubscription = FirebaseFirestore.instance
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: widget.workoutId)
        .orderBy('order')
        .snapshots()
        .listen((exerciseSnapshot) {
      List<Map<String, dynamic>> tempExercises = [];

      // Create a batch for reading the exercise documents
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in exerciseSnapshot.docs) {
        batch.set(doc.reference, doc.data(), SetOptions(merge: true));
        var exerciseData = doc.data();
        exerciseData['id'] = doc.id;
        exerciseData['series'] = [];
        tempExercises.add(exerciseData);
      }
      batch.commit();

      for (var exercise in tempExercises) {
        var seriesSubscription = FirebaseFirestore.instance
            .collection('series')
            .where('exerciseId', isEqualTo: exercise['id'])
            .orderBy('order')
            .snapshots()
            .listen((seriesSnapshot) {
          List<Map<String, dynamic>> tempSeries = [];

          // Create a batch for reading the series documents
          final batch = FirebaseFirestore.instance.batch();
          for (var doc in seriesSnapshot.docs) {
            batch.set(doc.reference, doc.data(), SetOptions(merge: true));
            var seriesData = doc.data();
            seriesData['id'] = doc.id;
            tempSeries.add(seriesData);
          }
          batch.commit();

          if (mounted) {
            setState(() {
              exercise['series'] = tempSeries;
              loading = false;
            });
          }
        });

        subscriptions.add(seriesSubscription);
      }

      if (mounted) {
        setState(() {
          exercises = tempExercises;
        });
      }
    });

    subscriptions.add(exercisesSubscription);
  }

  List<Map<String, dynamic>> getExercisesForSuperSet(String superSetId) {
    return exercises.where((exercise) => exercise['superSetId'] == superSetId).toList();
  }

  int findFirstNotDoneSeriesIndex(List<Map<String, dynamic>> series) {
    for (int i = 0; i < series.length; i++) {
      final serie = series[i];

      final repsDone = serie['reps_done'];
      final weightDone = serie['weight_done'];
      final reps = serie['reps'];
      final weight = serie['weight'];
      final done = serie['done'];

      if (done == true ||
          (done == false &&
              repsDone != null &&
              repsDone <= reps &&
              repsDone > 0 &&
              weightDone != null &&
              weightDone <= weight &&
              weightDone > 0)) {
      } else {
        return i;
      }
    }
    return series.length;
  }

  Future<void> showEditSeriesDialog(Map<String, dynamic> series) async {
    final repsController =
        TextEditingController(text: series['reps_done']?.toString() ?? '');
    final weightController =
        TextEditingController(text: series['weight_done']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica Serie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repsDone = int.tryParse(repsController.text) ?? 0;
                final weightDone =
                    double.tryParse(weightController.text) ?? 0.0;
                final done = repsDone >= series['reps'] &&
                    weightDone >= series['weight'];

                // Update the series document in a batch
                final batch = FirebaseFirestore.instance.batch();
                batch.update(
                  FirebaseFirestore.instance
                      .collection('series')
                      .doc(series['id']),
                  {
                    'reps_done': repsDone,
                    'weight_done': weightDone,
                    'done': done,
                  },
                );
                await batch.commit();

                Navigator.pop(context);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Raggruppa gli esercizi per superSetId
    final groupedExercises = <String?, List<Map<String, dynamic>>>{};
    for (final exercise in exercises) {
      final superSetId = exercise['superSetId'];
      if (superSetId != null) {
        groupedExercises.putIfAbsent(superSetId, () => []).add(exercise);
      } else {
        groupedExercises.putIfAbsent(null, () => []).add(exercise);
      }
    }

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: groupedExercises.length,
              itemBuilder: (context, index) {
                final superSetId = groupedExercises.keys.elementAt(index);
                final exercises = groupedExercises[superSetId]!;
                if (superSetId != null) {
                  return _buildSuperSetCard(context, exercises, isDarkMode, colorScheme);
                } else {
                  final exercise = exercises.first;
                  final firstNotDoneSeriesIndex = findFirstNotDoneSeriesIndex(List<Map<String, dynamic>>.from(exercise['series']));
                  final isContinueMode = firstNotDoneSeriesIndex > 0;
                  final allSeriesDone = firstNotDoneSeriesIndex == exercise['series'].length;
                  return _buildSingleExerciseCard(context, exercise, firstNotDoneSeriesIndex, isContinueMode, allSeriesDone, isDarkMode, colorScheme);
                }
              },
            ),
    );
  }

  Widget _buildSuperSetCard(BuildContext context, List<Map<String, dynamic>> superSetExercises, bool isDarkMode, ColorScheme colorScheme) {
    final maxSeriesCount = superSetExercises.fold<int>(0, (max, exercise) => exercise['series'].length > max ? exercise['series'].length : max);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? colorScheme.surface : colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Super Set: ${superSetExercises.map((e) => "${e['name']} ${e['variant'] ?? ''}").join(' + ')}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final firstNotDoneExerciseIndex = superSetExercises.indexWhere((exercise) => findFirstNotDoneSeriesIndex(List<Map<String, dynamic>>.from(exercise['series'])) < exercise['series'].length);
                if (firstNotDoneExerciseIndex != -1) {
                  final exercise = superSetExercises[firstNotDoneExerciseIndex];
                  final firstNotDoneSeriesIndex = findFirstNotDoneSeriesIndex(List<Map<String, dynamic>>.from(exercise['series']));
                  context.go(
                    '/programs_screen/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${exercise['id']}',
                    extra: {
                      'exerciseName': exercise['name'],
                      'exerciseVariant': exercise['variant'],
                      'seriesList': List<Map<String, dynamic>>.from(exercise['series']),
                      'startIndex': firstNotDoneSeriesIndex,
                      'superSetExercises': superSetExercises,
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
                backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('START'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Serie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Reps',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Kg',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Svolto',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(maxSeriesCount, (seriesIndex) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${seriesIndex + 1}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: superSetExercises.map((exercise) {
                            final series = exercise['series'].asMap().containsKey(seriesIndex) ? exercise['series'][seriesIndex] : null;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: series != null
                                  ? GestureDetector(
                                      onTap: () => showEditSeriesDialog(series),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? colorScheme.surfaceVariant : colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${series['reps']}/${series['reps_done'] == 0 ? '' : series['reps_done']}",
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            );
                          }).toList(),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: superSetExercises.map((exercise) {
                            final series = exercise['series'].asMap().containsKey(seriesIndex) ? exercise['series'][seriesIndex] : null;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: series != null
                                  ? GestureDetector(
                                      onTap: () => showEditSeriesDialog(series),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? colorScheme.surfaceVariant : colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${series['weight']}/${series['weight_done'] == 0 ? '' : series['weight_done']}",
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            );
                          }).toList(),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: superSetExercises.map((exercise) {
                            final series = exercise['series'].asMap().containsKey(seriesIndex) ? exercise['series'][seriesIndex] : null;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: series != null
                                  ? Icon(
                                      series['done'] == true ? Icons.check_circle : Icons.cancel,
                                      color: series['done'] == true
                                          ? colorScheme.primary
                                          : isDarkMode
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.onPrimaryContainer,
                                    )
                                  : const SizedBox(),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  if (seriesIndex < maxSeriesCount - 1)
                    const Divider(
                      height: 16,
                      thickness: 1,
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleExerciseCard(
    BuildContext context,
    Map<String, dynamic> exercise,
    int firstNotDoneSeriesIndex,
    bool isContinueMode,
    bool allSeriesDone,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? colorScheme.surface : colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${exercise['name']} ${exercise['variant'] ?? ''}",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!allSeriesDone)
              Align(
                alignment: Alignment.center,child: ElevatedButton(
                  onPressed: () {
                    context.go(
                      '/programs_screen/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${exercise['id']}',
                      extra: {
                        'exerciseName': exercise['name'],
                        'exerciseVariant': exercise['variant'],
                        'seriesList': List<Map<String, dynamic>>.from(exercise['series']),
                        'startIndex': firstNotDoneSeriesIndex,
                        'superSetExercises': [exercise],
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
                    backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(isContinueMode ? 'CONTINUA' : 'START'),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "Serie",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Reps",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Peso(kg)",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Svolto",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ...List<Map<String, dynamic>>.from(exercise['series'])
                .asMap()
                .entries
                .map((entry) {
              final seriesIndex = entry.key;
              final series = entry.value;
              return GestureDetector(
                onTap: () {
                  showEditSeriesDialog(series);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? colorScheme.surfaceVariant : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            "${seriesIndex + 1}",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            "${series['reps']}/${series['reps_done'] == 0 ? '' : series['reps_done']}R",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            "${series['weight']}/${series['weight_done'] == 0 ? '' : series['weight_done']} Kg",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Icon(
                            series['done'] == true ? Icons.check_circle : Icons.cancel,
                            color: series['done'] == true
                                ? colorScheme.primary
                                : isDarkMode
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }
}
