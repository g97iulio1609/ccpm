import 'package:alphanessone/exercise_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exercisesServices.dart';
import 'trainingstoreservices.dart';
import 'trainingprogrammodel.dart';
import 'usersServices.dart'; // Assicurati che il percorso sia corretto


final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});


final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final usersService = ref.watch(usersServiceProvider);
  return usersService.getUsers();
});


final exercisesStreamProvider = StreamProvider<List<ExerciseModel>>((ref) {
  final exercisesService = ref.watch(exercisesServiceProvider);
  return exercisesService.getExercises();
});

final weekListProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

class TrainingProgramPage extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final athleteIdController = TextEditingController();
  final athleteNameController = TextEditingController();
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

    void addExercise(int weekIndex, int workoutIndex, BuildContext context, WidgetRef ref) {
      final exerciseController = TextEditingController();
      final variantController = TextEditingController();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add New Exercise'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Consumer(
                    builder: (context, ref, child) {
                      final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
                      return exercisesAsyncValue.when(
                        data: (exercises) {
                          return Autocomplete<ExerciseModel>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<ExerciseModel>.empty();
                              }
                              return exercises.where((ExerciseModel exercise) {
                                return exercise.name.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
                              });
                            },
                            displayStringForOption: (ExerciseModel exercise) => exercise.name,
                            fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              return TextFormField(
                                controller: fieldTextEditingController,
                                focusNode: fieldFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Exercise',
                                  border: OutlineInputBorder(),
                                ),
                              );
                            },
                            onSelected: (ExerciseModel selection) {
                              exerciseController.text = selection.name;
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, st) => Text('Failed to load exercises: $e'),
                      );
                    },
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
                    'name': exerciseController.text,
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
                    'order': weekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'].length + 1,
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

 void editExercise(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context, WidgetRef ref) {
  final exerciseNameController = TextEditingController();
  final variantController = TextEditingController(text: weekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['variant']);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Edit Exercise'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Consumer(
                builder: (context, ref, child) {
                  final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
                  return exercisesAsyncValue.when(
                    data: (exercises) {
                      return Autocomplete<ExerciseModel>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<ExerciseModel>.empty();
                          }
                          return exercises.where((ExerciseModel exercise) {
                            return exercise.name.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
                          });
                        },
                        displayStringForOption: (ExerciseModel exercise) => exercise.name,
                        fieldViewBuilder: (
                          BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          return TextFormField(
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Exercise',
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                        onSelected: (ExerciseModel selection) {
                          exerciseNameController.text = selection.name;
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text('Failed to load exercises: $e'),
                  );
                },
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
            child: const Text('Update'),
            onPressed: () {
              List<Map<String, dynamic>> updatedWeekList = [...weekList];
              updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['name'] = exerciseNameController.text;
              updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['variant'] = variantController.text;
              ref.read(weekListProvider.notifier).state = updatedWeekList;
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

    void editSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex, BuildContext context) {
      final repsController = TextEditingController(text: weekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['reps'].toString());
      final setsController = TextEditingController(text: weekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['sets'].toString());
      final intensityController = TextEditingController(text: weekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['intensity']);
      final rpeController = TextEditingController(text: weekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['rpe']);
      final weightController = TextEditingController(text: weekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['weight'].toString());

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Edit Series'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: repsController,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: setsController,
                    decoration: const InputDecoration(labelText: 'Sets'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: intensityController,
                    decoration: const InputDecoration(labelText: 'Intensity'),
                  ),
                  TextField(
                    controller: rpeController,
                    decoration: const InputDecoration(labelText: 'RPE'),
                  ),
                  TextField(
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
                child: const Text('Update'),
                onPressed: () {
                  List<Map<String, dynamic>> updatedWeekList = [...weekList];
                  updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['reps'] = int.parse(repsController.text);
                  updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['sets'] = int.parse(setsController.text);
                  updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['intensity'] = intensityController.text;
                  updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['rpe'] = rpeController.text;
                  updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['weight'] = double.parse(weightController.text);
                  ref.read(weekListProvider.notifier).state = updatedWeekList;
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    void removeWeek(int weekIndex) {
      List<Map<String, dynamic>> updatedWeekList = [...weekList];
      updatedWeekList.removeAt(weekIndex);
      ref.read(weekListProvider.notifier).state = updatedWeekList;
    }

    void removeWorkout(int weekIndex, int workoutIndex) {
      List<Map<String, dynamic>> updatedWeekList = [...weekList];
      updatedWeekList[weekIndex]['workouts'].removeAt(workoutIndex);
      ref.read(weekListProvider.notifier).state = updatedWeekList;
    }

    void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
      List<Map<String, dynamic>> updatedWeekList = [...weekList];
      updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'].removeAt(exerciseIndex);
      ref.read(weekListProvider.notifier).state = updatedWeekList;
    }

    void removeSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex) {
      List<Map<String, dynamic>> updatedWeekList = [...weekList];
      updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'].removeAt(seriesIndex);
      ref.read(weekListProvider.notifier).state = updatedWeekList;
    }

Widget _buildAthleteIdField(BuildContext context, WidgetRef ref) {
  return Consumer(
    builder: (context, ref, _) {
      final usersAsyncValue = ref.watch(usersStreamProvider);
      return usersAsyncValue.when(
        data: (users) {
          return Autocomplete<UserModel>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<UserModel>.empty();
              }
              return users.where((UserModel user) {
                return user.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            displayStringForOption: (UserModel user) => user.name,
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted,
            ) {
              // Make sure to assign the TextEditingController correctly
              fieldTextEditingController.text = athleteNameController.text;
              return TextFormField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Select Athlete',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // This ensures the displayed name is always updated as user types
                  athleteNameController.text = value;
                },
              );
            },
            onSelected: (UserModel selection) {
              // Update both controllers when an athlete is selected
              athleteIdController.text = selection.id;
              athleteNameController.text = selection.name;
            },
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Text('Failed to load users: $e'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
// Sostituisci il vecchio pulsante con questo
ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Athlete'),
          content: SizedBox(
            width: double.maxFinite,
            child: _buildAthleteIdField(context, ref),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                // Just pop the dialog, athleteNameController's changes will update UI automatically
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  },
  child: Text(athleteNameController.text.isEmpty ? 'Select Athlete' : athleteNameController.text),
),

              TextFormField(
                controller: mesocycleNumberController,
                decoration: const InputDecoration(labelText: 'Mesocycle Number'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a mesocycle number' : null,
),
ElevatedButton(
onPressed: addWeek,
child: const Text('Add New Week'),
),
...weekList.map((week) => ExpansionTile(
title: Text('Week ${week['number']}'),
trailing: IconButton(
icon: const Icon(Icons.delete),
onPressed: () => removeWeek(weekList.indexOf(week)),
),
children: [
...(week['workouts'] as List).asMap().entries.map((workoutEntry) {
int workoutIndex = workoutEntry.key;
Map<String, dynamic> workout = workoutEntry.value;
return ExpansionTile(
title: Text('Workout ${workout['order']}'),
trailing: IconButton(
icon: const Icon(Icons.delete),
onPressed: () => removeWorkout(weekList.indexOf(week), workoutIndex),
),
children: [
...(workout['exercises'] as List).asMap().entries.map((exerciseEntry) {
int exerciseIndex = exerciseEntry.key;
Map<String, dynamic> exercise = exerciseEntry.value;
return ExpansionTile(
title: Text('Exercise ${exercise['order']}: ${exercise['name']} ${exercise['variant']}'),
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
IconButton(
icon: const Icon(Icons.edit),
onPressed: () => editExercise(weekList.indexOf(week), workoutIndex, exerciseIndex, context,ref),
),
IconButton(
icon: const Icon(Icons.delete),
onPressed: () => removeExercise(weekList.indexOf(week), workoutIndex, exerciseIndex),
),
],
),
children: [
...(exercise['series'] as List).map((series) {
int seriesIndex = (exercise['series'] as List).indexOf(series);
return ListTile(
title: Text('Series: Sets ${series['sets']} x Reps ${series['reps']} x ${series['weight']} Kg'),
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
IconButton(
icon: const Icon(Icons.edit),
onPressed: () => editSeries(weekList.indexOf(week), workoutIndex, exerciseIndex, seriesIndex, context),
),
IconButton(
icon: const Icon(Icons.delete),
onPressed: () => removeSeries(weekList.indexOf(week), workoutIndex, exerciseIndex, seriesIndex),
),
],
),
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
onPressed: () => addExercise(weekList.indexOf(week), workoutIndex, context, ref),
child: const Text('Add New Exercise'),
),
],
);
}).toList(),
ElevatedButton(
onPressed: () => addWorkout(weekList.indexOf(week)),
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
final weeksConverted = weekList.map((week) => Week.fromMap(week)).toList();final newProgram = TrainingProgram(
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
);}}