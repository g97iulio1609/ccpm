import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'exercise_details.dart';
import 'dart:async';

class WorkoutDetails extends StatefulWidget {
  final String programId;
  final String weekId;
  final String workoutId;

  const WorkoutDetails({
    super.key,
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
      List<Map<String, dynamic>> tempExercises =
          exerciseSnapshot.docs.map((doc) {
        var exerciseData = doc.data();
        exerciseData['id'] = doc.id;
        exerciseData['series'] = [];
        return exerciseData;
      }).toList();

      for (var exercise in tempExercises) {
        var seriesSubscription = FirebaseFirestore.instance
            .collection('series')
            .where('exerciseId', isEqualTo: exercise['id'])
            .orderBy('order')
            .snapshots()
            .listen((seriesSnapshot) {
          List<Map<String, dynamic>> tempSeries =
              seriesSnapshot.docs.map((seriesDoc) {
            var seriesData = seriesDoc.data();
            seriesData['id'] = seriesDoc.id;
            return seriesData;
          }).toList();

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

  int findFirstNotDoneSeriesIndex(List<Map<String, dynamic>> series) {
    //debugPrint('Searching for first not done series...');
    for (int i = 0; i < series.length; i++) {
      final serie = series[i];
      //debugPrint('Checking series at index $i: $serie');
      
      final repsDone = serie['reps_done'];
      final weightDone = serie['weight_done'];
      final reps = serie['reps'];
      final weight = serie['weight'];
      final done = serie['done'];
      
      if (done == true ||
          (done == false && repsDone != null && repsDone <= reps && repsDone > 0 &&
           weightDone != null && weightDone <= weight && weightDone > 0)) {
        //debugPrint('Series at index $i is considered done');
      } else {
        //debugPrint('Found first not done series at index $i');
        return i;
      }
    }
    //debugPrint('All series are done');
    return series.length;
  }

  Future<void> showEditSeriesDialog(Map<String, dynamic> series) async {
    final repsController = TextEditingController(text: series['reps_done']?.toString() ?? '');
    final weightController = TextEditingController(text: series['weight_done']?.toString() ?? '');

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
                final weightDone = double.tryParse(weightController.text) ?? 0.0;
                final done = repsDone >= series['reps'] && weightDone >= series['weight'];

                await FirebaseFirestore.instance
                    .collection('series')
                    .doc(series['id'])
                    .update({
                  'reps_done': repsDone,
                  'weight_done': weightDone,
                  'done': done,
                });
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

    return Scaffold(
      
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final firstNotDoneSeriesIndex =
                    findFirstNotDoneSeriesIndex(List<Map<String, dynamic>>.from(exercise['series']));
                final isContinueMode = firstNotDoneSeriesIndex > 0;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isDarkMode
                      ? colorScheme.surface
                      : colorScheme.background,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${exercise['name']} ${exercise['variant'] ?? ''}",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? colorScheme.onSurface
                                      : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign
                                    .center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                      onPressed: () {
                          context.go(
    '/programs_screen/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${exercise['id']}',
    extra: {
      'exerciseName': exercise['name'],
      'exerciseVariant': exercise['variant'],
      'seriesList': List<Map<String, dynamic>>.from(exercise['series']),
      'startIndex': firstNotDoneSeriesIndex,
    },
  );
},
                          style: ElevatedButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? colorScheme.onPrimary
                                : colorScheme.onSecondary,
                            backgroundColor: isDarkMode
                                ? colorScheme.primary
                                : colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(isContinueMode ? 'CONTINUA' : 'START'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Serie",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDarkMode
                                      ? colorScheme.onSurface
                                      : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Reps",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDarkMode
                                      ? colorScheme.onSurface
                                      : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Peso(kg)",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDarkMode
                                      ? colorScheme.onSurface
                                      : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Svolto",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDarkMode
                                      ? colorScheme.onSurface
                                      : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        ...List<Map<String, dynamic>>.from(exercise['series']).asMap().entries.map((entry) {
                          final seriesIndex = entry.key;
                          final series = entry.value;
                          return GestureDetector(
                            onTap: () {
                              showEditSeriesDialog(series);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? colorScheme.surfaceVariant
                                    : colorScheme.primaryContainer,
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
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          color: isDarkMode
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Text(
                                        "${series['reps']}/${series['reps_done'] == 0 ? '' : series['reps_done']}R",
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          color: isDarkMode
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Text(
                                        "${series['weight']}/${series['weight_done'] == 0 ? '' : series['weight_done']} Kg",
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          color: isDarkMode
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Icon(
                                        series['done'] == true
                                            ? Icons.check_circle
                                            : Icons.cancel,
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
              },
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