import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_details.dart';
import 'dart:async';


class WorkoutDetails extends StatefulWidget {
  final String workoutId;

  const WorkoutDetails({Key? key, required this.workoutId}) : super(key: key);

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
      List<Map<String, dynamic>> tempExercises = exerciseSnapshot.docs.map((doc) {
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
          List<Map<String, dynamic>> tempSeries = seriesSnapshot.docs.map((seriesDoc) {
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
    ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    var exercise = exercises[index];
                    return Card(
                      elevation: 8,
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Esercizio ${index + 1}: ${exercise['name']} ${exercise['variant'] ?? ''}",
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(flex: 1, child: Text("Serie", style: theme.textTheme.titleMedium, textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: Text("Reps", style: theme.textTheme.titleMedium, textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: Text("Peso(kg)", style: theme.textTheme.titleMedium, textAlign: TextAlign.center)),
                                Expanded(flex: 1, child: Text("Svolto", style: theme.textTheme.titleMedium, textAlign: TextAlign.center)),
                              ],
                            ),
                            ...exercise['series'].asMap().entries.map((entry) {
                              int seriesIndex = entry.key;
                              Map<String, dynamic> series = entry.value;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Center(child: Text("${seriesIndex + 1}", style: theme.textTheme.bodyLarge)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("${series['reps']}", style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                                        const SizedBox(width: 8),
                                        Text("${series['reps_done'] ?? '-'}", style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("${series['weight']} Kg", style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                                        const SizedBox(width: 8),
                                        Text("${series['weight_done'] ?? '-'} Kg", style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Checkbox(
                                      value: series['done'] ?? false,
                                      onChanged: null,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExerciseDetails(
                                        exerciseId: exercise['id'],
                                        exerciseName: exercise['name'],
                                        exerciseVariant: exercise['variant'],
                                        seriesList: exercise['series'].cast<Map<String, dynamic>>(),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('START'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subscriptions.forEach((subscription) => subscription.cancel());
  }
}