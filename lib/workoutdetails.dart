import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_details.dart';
import 'dart:async';

class WorkoutDetails extends StatefulWidget {
  final String workoutId;

  const WorkoutDetails({super.key, required this.workoutId});

  @override
  _WorkoutDetailsState createState() => _WorkoutDetailsState();
}

class _WorkoutDetailsState extends State<WorkoutDetails> {
  bool loading = true;
  List<Map<String, dynamic>> exercises = [];
  final List<StreamSubscription> _subscriptions = [];

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
        var exerciseData = doc.data() as Map<String, dynamic>? ?? {};
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
            var seriesData = seriesDoc.data() as Map<String, dynamic>? ?? {};
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

        _subscriptions.add(seriesSubscription);
      }

      if (mounted) {
        setState(() {
          exercises = tempExercises;
        });
      }
    });

    _subscriptions.add(exercisesSubscription);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli allenamento'),
        elevation: 0,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
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
                              child: Text(
                                "${exercise['name']} ${exercise['variant'] ?? ''}",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center, // Center the exercise name
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseDetails(
                                  exerciseId: exercise['id'],
                                  exerciseName: exercise['name'],
                                  exerciseVariant: exercise['variant'],
                                  seriesList: exercise['series']
                                      .cast<Map<String, dynamic>>(),
                                ),
                              ),
                            );
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Serie",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Reps",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Peso(kg)",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Svolto",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        ...exercise['series'].asMap().entries.map((entry) {
                          final seriesIndex = entry.key;
                          final series = entry.value;
                          return Container(
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
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      "${series['reps']}/${series['reps_done'] ?? '-'}R",
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      "${series['weight']}/${series['weight_done'] ?? '-'} Kg",
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
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
                                          : Icons.circle_outlined,
                                      color: series['done'] == true
                                          ? colorScheme.primary
                                          : isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
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
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}