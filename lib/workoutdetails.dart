import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for text input formatters

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
  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};

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

            if (!_repsControllers.containsKey(seriesDoc.id)) {
                _repsControllers[seriesDoc.id] = TextEditingController(text: seriesData['reps_done']?.toString() ?? '');
            }
            if (!_weightControllers.containsKey(seriesDoc.id)) {
                _weightControllers[seriesDoc.id] = TextEditingController(text: seriesData['weight_done']?.toString() ?? '');
            }

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

  Future<void> updateSeriesData(String seriesId, bool done, int? repsDone, double? weightDone) async {
    await FirebaseFirestore.instance.collection('series').doc(seriesId).update({
      'done': done,
      'reps_done': repsDone ?? 0,
      'weight_done': weightDone ?? 0.0,
    });
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
  TextEditingController repsController = _repsControllers[series['id']]!;
  TextEditingController weightController = _weightControllers[series['id']]!;

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
            SizedBox(width: 8),
            Container(
              width: 40,
              child: Align(
                alignment: Alignment.center,
                child: TextField(
                  controller: repsController,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '_',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${series['weight']} Kg", style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            SizedBox(width: 8),
            Container(
              width: 60,
              child: Align(
                alignment: Alignment.center,
                child: TextField(
                  controller: weightController,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '_',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 1,
        child: Checkbox(
          value: series['done'] ?? false,
          onChanged: (bool? newValue) {
            setState(() => series['done'] = newValue);
            updateSeriesData(series['id'], newValue ?? false, int.tryParse(repsController.text), double.tryParse(weightController.text));
          },
        ),
      ),
    ],
  );
}).toList(),
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
    _repsControllers.forEach((key, controller) => controller.dispose());
    _weightControllers.forEach((key, controller) => controller.dispose());
    _subscriptions.forEach((subscription) => subscription.cancel());
  }
}