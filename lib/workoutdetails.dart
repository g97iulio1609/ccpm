import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // Import for text input formatters

class WorkoutDetails extends StatefulWidget {
  final String workoutId;

  const WorkoutDetails({Key? key, required this.workoutId}) : super(key: key);

  @override
  State<WorkoutDetails> createState() => _WorkoutDetailsState();
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

            // Initialize controllers for reps and weight if they don't exist
            _repsControllers[seriesDoc.id] ??= TextEditingController(text: seriesData['reps_done']?.toString() ?? '');
            _weightControllers[seriesDoc.id] ??= TextEditingController(text: seriesData['weight_done']?.toString() ?? '');

            return seriesData;
          }).toList();

          if (mounted) {
            setState(() {
              exercise['series'] = tempSeries;
              if (!loading) loading = false;
            });
          }
        });

        _subscriptions.add(seriesSubscription);
      }

      if (mounted) {
        setState(() {
          exercises = tempExercises;
          if (loading) loading = false;
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Dettagli dell'allenamento", style: GoogleFonts.roboto()),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  var exercise = exercises[index];
                  return Card(
                    shadowColor: Colors.black,
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ListTile(
                            tileColor: Theme.of(context).colorScheme.secondaryContainer,
                            title: Text(
                              "Esercizio ${index + 1}: ${exercise['name']} ${exercise['variant'] ?? ''}",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: exercise['series'].length,
                            itemBuilder: (context, seriesIndex) {
                              var series = exercise['series'][seriesIndex];
                              TextEditingController repsController = _repsControllers[series['id']]!;
                              TextEditingController weightController = _weightControllers[series['id']]!;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    '${seriesIndex + 1}',
                                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text("${series['reps']} reps", style: const TextStyle(fontSize: 16)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text("${series['weight']} kg", style: const TextStyle(fontSize: 16)),
                                    ),
                                    const SizedBox(width: 10), // Added for spacing
                                    Expanded(
                                      flex: 1,
                                      child: Transform.scale(
                                        scale: 1.5,
                                        child: Checkbox(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                          activeColor: Theme.of(context).colorScheme.primary,
                                          checkColor: Colors.white,
                                          value: series['done'] ?? false,
                                          onChanged: (bool? newValue) {
                                            setState(() {
                                              series['done'] = newValue;
                                            });
                                            updateSeriesData(series['id'], newValue ?? false, int.tryParse(repsController.text), double.tryParse(weightController.text));
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10), // Added for spacing
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        controller: repsController,
                                        decoration: const InputDecoration(
                                          labelText: 'Reps fatte',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onChanged: (value) { // Update on change
                                          updateSeriesData(series['id'], series['done'] ?? false, int.tryParse(value), double.tryParse(weightController.text));
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        controller: weightController,
                                        decoration: const InputDecoration(
                                          labelText: 'Peso usato',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        onChanged: (value) { // Update on change
                                          updateSeriesData(series['id'], series['done'] ?? false, int.tryParse(repsController.text), double.tryParse(value));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _repsControllers.forEach((_, controller) => controller.dispose());
    _weightControllers.forEach((_, controller) => controller.dispose());
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}
