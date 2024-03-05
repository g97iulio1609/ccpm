// trainingprogram.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trainingprogrammodel.dart';
import 'trainingstoreservices.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final weekListProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

class TrainingProgramPage extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final athleteIdController = TextEditingController();
  final mesocycleNumberController = TextEditingController();

  TrainingProgramPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.read(firestoreServiceProvider);
    final weekList = ref.watch(weekListProvider);


void addWeek() {
  final newWeek = {
    'number': weekList.length + 1,
    'createdAt': Timestamp.now(),
    'workouts': [],
  };
  ref.read(weekListProvider.notifier).state = [...weekList, newWeek];
}

void addWorkout(int weekIndex) {
  final newWorkout = {
    'order': weekList[weekIndex]['workouts'].length + 1,
    'createdAt': Timestamp.now(),
    'exercises': [],
  };
  List<Map<String, dynamic>> updatedWeekList = [...weekList];
  updatedWeekList[weekIndex]['workouts'].add(newWorkout);
  ref.read(weekListProvider.notifier).state = updatedWeekList;
}


    void addExercise(int weekIndex, int workoutIndex, BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final exerciseController = TextEditingController();
          final variantController = TextEditingController();

          return AlertDialog(
            title: const Text('Add New Exercise'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: exerciseController,
                    decoration: const InputDecoration(labelText: 'Exercise'),
                  ),
                  TextFormField(
                    controller: variantController,
                    decoration: const InputDecoration(labelText: 'Variant'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Add'),
                onPressed: () {
                  final newExercise = {
                    'order': weekList[weekIndex]['workouts'][workoutIndex]['exercises'].length + 1,
                    'createdAt': Timestamp.now(),
                    'exercise': exerciseController.text,
                    'variant': variantController.text,
                    'series': [],
                  };
                  List<Map<String, dynamic>> updatedWeekList = [...weekList];
                  updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'].add(newExercise);
                  ref.read(weekListProvider.notifier).state = updatedWeekList;
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

        void addSeries(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final repsController = TextEditingController();
          final setsController = TextEditingController();
          final intensityController = TextEditingController();
          final rpeController = TextEditingController();
          final weightController = TextEditingController();

          return AlertDialog(
            title: const Text('Add New Series'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: repsController,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: setsController,
                    decoration: const InputDecoration(labelText: 'Sets'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: intensityController,
                    decoration: const InputDecoration(labelText: 'Intensity'),
                  ),
                  TextFormField(
                    controller: rpeController,
                    decoration: const InputDecoration(labelText: 'RPE'),
                  ),
                  TextFormField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Add'),
                onPressed: () {
                  final newSeries = {
                    'reps': int.parse(repsController.text),
                    'sets': int.parse(setsController.text),
                    'intensity': intensityController.text,
                    'rpe': rpeController.text,
                    'weight': double.parse(weightController.text),
                    'createdAt': Timestamp.now(),
                  };
                  List<Map<String, dynamic>> updatedWeekList = [...weekList];
                  updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'].add(newSeries);
                  ref.read(weekListProvider.notifier).state = updatedWeekList;
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Training Program'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Program Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a program name' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              TextFormField(
                controller: athleteIdController,
                decoration: const InputDecoration(labelText: 'Athlete ID'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter an athlete ID' : null,
              ),
              TextFormField(
                controller: mesocycleNumberController,
                decoration: const InputDecoration(labelText: 'Mesocycle Number'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a mesocycle number' : null,
              ),
              ...weekList.map((week) => ExpansionTile(
                title: Text('Week ${week['number']}'),
                subtitle: Text('Added on ${week['createdAt'] is Timestamp ? (week['createdAt'] as Timestamp).toDate().toString() : 'Pending'}'),
                children: [
                  ...week['workouts'].asMap().entries.map((workoutEntry) {
                    int workoutIndex = workoutEntry.key;
                    Map<String, dynamic> workout = workoutEntry.value;

                    return ExpansionTile(
                      title: Text('Workout ${workout['order']}'),
                      subtitle: Text('Added on ${workout['createdAt'] is Timestamp ? (workout['createdAt'] as Timestamp).toDate().toString() : 'Pending'}'),
                      children: [
                        ...workout['exercises'].asMap().entries.map((exerciseEntry) {
                          int exerciseIndex = exerciseEntry.key;
                          Map<String, dynamic> exercise = exerciseEntry.value;

                          return ExpansionTile(
                            title: Text('${exercise['exercise']} ${exercise['variant']}'),
                            subtitle: Text('Added on ${exercise['createdAt'] is Timestamp ? (exercise['createdAt'] as Timestamp).toDate().toString() : 'Pending'}'),
                            children: [
                              ...exercise['series'].map((series) {
                                return ListTile(
                                  title: Text('Series: Sets ${series['sets']}, Reps ${series['reps']}, Weight ${series['weight']}'),
                                  subtitle: Text('Intensity: ${series['intensity']}, RPE: ${series['rpe']}'),
                                );
                              }).toList(),
                              ElevatedButton(
                                onPressed: () => addSeries(weekList.indexOf(week), workoutIndex, exerciseIndex, context),
                                child: const Text('Add New Series'),
                              ),
                            ],
                          );
                        }).toList(),
                        ElevatedButton(
                          onPressed: () => addExercise(weekList.indexOf(week), workoutIndex, context),
                          child: const Text('Add New Exercise'),
                        ),
                      ],
                    );
                  }).toList(),
                  ElevatedButton(
                    onPressed: () {
                      addWorkout(weekList.indexOf(week));
                    },
                    child: const Text('Add New Workout'),
                  ),
                ],
              )).toList(),
              ElevatedButton(
                onPressed: addWeek,
                child: const Text('Add New Week'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final weeksConverted = weekList.map((week) => Week.fromMap(week)).toList();

                    final newProgram = TrainingProgram(
                      id: null,
                      name: nameController.text,
                      description: descriptionController.text,
                      athleteId: athleteIdController.text,
                      mesocycleNumber: int.tryParse(mesocycleNumberController.text) ?? 0,
                      weeks: weeksConverted,
                    );

                    firestoreService.addOrUpdateTrainingProgram(newProgram).then((result) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program added/updated successfully')));
                      // Reset fields
                      nameController.clear();
                      descriptionController.clear();
                      athleteIdController.clear();
                      mesocycleNumberController.clear();
                      ref.read(weekListProvider.notifier).state = [];
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding/updating program: $error')));
                    });
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
