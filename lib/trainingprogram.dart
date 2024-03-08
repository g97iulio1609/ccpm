// trainingprogram.dart
import 'package:alphanessone/exercise_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'exercisesServices.dart';
import 'trainingServices.dart';
import 'trainingModel.dart';
import 'usersServices.dart';

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

final trainingProgramProvider = StateProvider<TrainingProgram>((ref) {
  // Assicurati che le liste come trackToDeleteWeeks siano inizializzate come liste vuote modificabili.
  return TrainingProgram(
    trackToDeleteWeeks: [],
    trackToDeleteWorkouts: [],
    trackToDeleteExercises: [],
    trackToDeleteSeries: [],
    // Aggiungi qui altre proprietà necessarie per l'inizializzazione di TrainingProgram
  );
});

class TrainingProgramPage extends HookConsumerWidget {
  final String? programId; // Aggiunto per gestire la modalità editing

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final athleteIdController = TextEditingController();
  final athleteNameController = TextEditingController();
  final mesocycleNumberController = TextEditingController();

  TrainingProgramPage({super.key, this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.read(firestoreServiceProvider);
    final weekList = ref.watch(weekListProvider);

        // Utilizzo di useEffect per caricare i dati del programma se in modalità editing
    useEffect(() {
      if (programId != null) {
        // Carica i dati del programma e aggiorna gli stati
        firestoreService.fetchTrainingProgram(programId!).then((program) {
          // Aggiorna gli stati con i dettagli del programma esistente
          nameController.text = program.name;
          descriptionController.text = program.description;
          athleteIdController.text = program.athleteId;
          mesocycleNumberController.text = program.mesocycleNumber.toString();
          // Aggiorna la lista delle settimane
          ref.read(weekListProvider.notifier).state = program.weeks.map((week) => week.toMap()).toList();
        }).catchError((error) {
          // Gestire l'errore
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading program: $error')));
        });
      }
      return null; // Callback di pulizia se necessario
    }, [programId]); // Esegue questo effetto solo quando programId cambia

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
              ElevatedButton(
                onPressed: () => _showAthleteSelectionDialog(context, ref),
                child: Text(athleteNameController.text.isEmpty ? 'Select Athlete' : athleteNameController.text),
              ),
              TextFormField(
                controller: mesocycleNumberController,
                decoration: const InputDecoration(labelText: 'Mesocycle Number'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a mesocycle number' : null,
              ),
              ElevatedButton(
                onPressed: () => _addWeek(ref),
                child: const Text('Add New Week'),
              ),
              ..._buildWeekList(weekList, context, ref),
              ElevatedButton(
                onPressed: () => _addWeek(ref),
                child: const Text('Add New Week'),
              ),
              ElevatedButton(
                onPressed: () => _submitProgram(context, ref, firestoreService),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAthleteSelectionDialog(BuildContext context, WidgetRef ref) {
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
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
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
                fieldTextEditingController.text = athleteNameController.text;
                return TextFormField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Select Athlete',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    athleteNameController.text = value;
                  },
                );
              },
              onSelected: (UserModel selection) {
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

  void _addWeek(WidgetRef ref) {
    final weekList = ref.read(weekListProvider);
    final newWeek = {
      'number': weekList.length + 1,
      'createdAt': Timestamp.now(),
      'workouts': [],
    };
    ref.read(weekListProvider.notifier).state = [...weekList, newWeek];
  }

  List<Widget> _buildWeekList(List<Map<String, dynamic>> weekList, BuildContext context, WidgetRef ref) {
    return weekList.map((week) {
      return ExpansionTile(
        title: Text('Week ${week['number']}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _removeWeek(weekList.indexOf(week), ref),
        ),
        children: [
          ..._buildWorkoutList(week, weekList.indexOf(week), context, ref),
          ElevatedButton(
            onPressed: () => _addWorkout(weekList.indexOf(week), ref),
            child: const Text('Add New Workout'),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildWorkoutList(Map<String, dynamic> week, int weekIndex, BuildContext context, WidgetRef ref) {
    return (week['workouts'] as List).asMap().entries.map((workoutEntry) {
      int workoutIndex = workoutEntry.key;
      Map<String, dynamic> workout = workoutEntry.value;
      return ExpansionTile(
        title: Text('Workout ${workout['order']}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _removeWorkout(weekIndex, workoutIndex, ref),
        ),
        children: [
          ..._buildExerciseList(workout, weekIndex, workoutIndex, context, ref),
          ElevatedButton(
            onPressed: () => _addExercise(weekIndex, workoutIndex, context, ref),
            child: const Text('Add New Exercise'),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildExerciseList(Map<String, dynamic> workout, int weekIndex, int workoutIndex, BuildContext context, WidgetRef ref) {
    return (workout['exercises'] as List).asMap().entries.map((exerciseEntry) {
      int exerciseIndex = exerciseEntry.key;
      Map<String, dynamic> exercise = exerciseEntry.value;
      return ExpansionTile(
        title: Text('Exercise ${exercise['order']}: ${exercise['name']} ${exercise['variant']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editExercise(weekIndex, workoutIndex, exerciseIndex, context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeExercise(weekIndex, workoutIndex, exerciseIndex, ref),
            ),
          ],
        ),
        children: [
          ..._buildSeriesList(exercise, weekIndex, workoutIndex, exerciseIndex, context, ref),
          ElevatedButton(
            onPressed: () => _addSeries(weekIndex, workoutIndex, exerciseIndex, context, ref),
            child: const Text('Add New Series'),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildSeriesList(Map<String, dynamic> exercise, int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context, WidgetRef ref) {
    return (exercise['series'] as List).map((series) {
      int seriesIndex = (exercise['series'] as List).indexOf(series);
      return ListTile(
        title: Text('Series: Sets ${series['sets']} x Reps ${series['reps']} x ${series['weight']} Kg'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editSeries(weekIndex, workoutIndex, exerciseIndex, seriesIndex, context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeSeries(weekIndex, workoutIndex, exerciseIndex, seriesIndex, ref),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _addWorkout(int weekIndex, WidgetRef ref) {
    final weekList = ref.read(weekListProvider);
    final newWorkout = {
      'order': weekList[weekIndex]['workouts'].length + 1,
      'createdAt': Timestamp.now(),
      'exercises': [],
    };
    List<Map<String, dynamic>> updatedWeekList = [...weekList];
    updatedWeekList[weekIndex]['workouts'].add(newWorkout);
    ref.read(weekListProvider.notifier).state = updatedWeekList;
  }

  void _addExercise(int weekIndex, int workoutIndex, BuildContext context, WidgetRef ref) {
    _showExerciseDialog(weekIndex, workoutIndex, context, ref);
  }

  void _showExerciseDialog(int weekIndex, int workoutIndex, BuildContext context, WidgetRef ref) {
    final exerciseController = TextEditingController();
    final variantController = TextEditingController();
    String selectedExerciseId = '';

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
                            selectedExerciseId = selection.id;
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
                  final FirebaseFirestore db = FirebaseFirestore.instance;
                // Creiamo un nuovo ID per l'esercizio
                String exerciseId = db.collection('exercisesWorkout').doc().id;
                final newExercise = {
                  'order': ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'].length + 1,
                  'createdAt': Timestamp.now(),
                  'name': exerciseController.text,
                  'variant': variantController.text,
                  'series': [],
                  'id': selectedExerciseId,
                  'exerciseId':exerciseId
                };
                List<Map<String, dynamic>> updatedWeekList = [...ref.read(weekListProvider)];
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

  void _addSeries(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context, WidgetRef ref) {
    _showSeriesDialog(weekIndex, workoutIndex, exerciseIndex, context, ref);
  }

void _showSeriesDialog(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context, WidgetRef ref) {
  final repsController = TextEditingController();
  final setsController = TextEditingController();
  final intensityController = TextEditingController();
  final rpeController = TextEditingController();
  final weightController = TextEditingController();

  int latestMaxWeight = 0;

  String athleteId = athleteIdController.text;
  Map<String, dynamic> selectedExercise = ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex];
  String exerciseId = selectedExercise['id'];

  final usersService = ref.read(usersServiceProvider);
  usersService.getExerciseRecords(userId: athleteId, exerciseId: exerciseId).first.then((records) {
    if (records.isNotEmpty) {
      ExerciseRecord latestRecord = records.first;
      latestMaxWeight = latestRecord.maxWeight;
      print("Debug - Latest max weight for the exercise: $latestMaxWeight");
    } else {
      print("Debug - No records found for this exercise.");
    }
  }).catchError((error) {
    print("Debug - Error retrieving exercise records: $error");
  });

  intensityController.addListener(() {
    double intensity = double.tryParse(intensityController.text) ?? 0;
    double calculatedWeight = (latestMaxWeight * intensity) / 100;
    weightController.text = calculatedWeight.toStringAsFixed(2);
  });

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add New Series'),
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
                decoration: const InputDecoration(labelText: 'Intensity (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: rpeController,
                decoration: const InputDecoration(labelText: 'RPE'),
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                readOnly: true,
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
              final FirebaseFirestore db = FirebaseFirestore.instance;
              String serieId = db.collection('series').doc().id; // Genera un nuovo ID per la serie

              final newSeries = Series(
                serieId: serieId, // Imposta il campo serieId con il nuovo ID
                reps: int.parse(repsController.text),
                sets: int.parse(setsController.text),
                intensity: intensityController.text,
                rpe: rpeController.text,
                weight: double.parse(weightController.text),
                order: ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'].length + 1,
              );

              List<Map<String, dynamic>> updatedWeekList = [...ref.read(weekListProvider)];
              updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'].add(newSeries.toMap());
              ref.read(weekListProvider.notifier).state = updatedWeekList;
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
  void _editExercise(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context, WidgetRef ref) {
    final exerciseNameController = TextEditingController(text: ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['name']);
    final variantController = TextEditingController(text: ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['variant']);
    String selectedExerciseId = ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['id'];

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
                            selectedExerciseId = selection.id;
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
                List<Map<String, dynamic>> updatedWeekList = [...ref.read(weekListProvider)];
                updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['name'] = exerciseNameController.text;
                updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['variant'] = variantController.text;
                updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['id'] = selectedExerciseId;
                ref.read(weekListProvider.notifier).state = updatedWeekList;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

void _editSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex, BuildContext context, WidgetRef ref) {
    final seriesData = ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex];
    final repsController = TextEditingController(text: seriesData['reps'].toString());
    final setsController = TextEditingController(text: seriesData['sets'].toString());
    final intensityController = TextEditingController(text: seriesData['intensity']);
    final rpeController = TextEditingController(text: seriesData['rpe']);
    final weightController = TextEditingController();

    int latestMaxWeight = 0;

    String athleteId = athleteIdController.text;
    Map<String, dynamic> selectedExercise = ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex];
    String exerciseId = selectedExercise['id'];

    final usersService = ref.read(usersServiceProvider);
    usersService.getExerciseRecords(userId: athleteId, exerciseId: exerciseId).first.then((records) {
        if (records.isNotEmpty) {
            ExerciseRecord latestRecord = records.first;
            latestMaxWeight = latestRecord.maxWeight;

            double initialIntensity = double.tryParse(intensityController.text) ?? 0;
            weightController.text = ((latestMaxWeight * initialIntensity) / 100).toStringAsFixed(2);
        }
    }).catchError((error) {
        print("Error retrieving exercise records: $error");
    });

    intensityController.addListener(() {
        double intensity = double.tryParse(intensityController.text) ?? 0;
        double calculatedWeight = (latestMaxWeight * intensity) / 100;
        weightController.text = calculatedWeight.toStringAsFixed(2);
    });

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
                                decoration: const InputDecoration(labelText: 'Intensity (%)'),
                                keyboardType: TextInputType.number,
                            ),
                            TextField(
                                controller: rpeController,
                                decoration: const InputDecoration(labelText: 'RPE'),
                            ),
                            TextField(
                                controller: weightController,
                                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                                keyboardType: TextInputType.number,
                                readOnly: true,
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
                            // Assicurati di mantenere il serieId esistente
                            String existingSerieId = seriesData['serieId'];
                            List<Map<String, dynamic>> updatedWeekList = [...ref.read(weekListProvider)];
                            updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex] = {
                                'reps': int.parse(repsController.text),
                                'sets': int.parse(setsController.text),
                                'intensity': intensityController.text,
                                'rpe': rpeController.text,
                                'weight': double.parse(weightController.text),
                                'createdAt': seriesData['createdAt'],
                                'order': seriesData['order'],
                                'serieId': existingSerieId // Mantieni il serieId esistente
                            };
                            ref.read(weekListProvider.notifier).state = updatedWeekList;
                            Navigator.of(context).pop();
                        },
                    ),
                ],
            );
        },
    );
}

void _removeWeek(int weekIndex, WidgetRef ref) {
    String weekIdToRemove = ref.read(weekListProvider)[weekIndex]['id'];
    ref.read(trainingProgramProvider.notifier).state.trackToDeleteWeeks.add(weekIdToRemove);

    // Update local state
    List<Map<String, dynamic>> updatedWeekList = [...ref.read(weekListProvider)];
    updatedWeekList.removeAt(weekIndex);
    ref.read(weekListProvider.notifier).state = updatedWeekList;
}

void _removeWorkout(int weekIndex, int workoutIndex, WidgetRef ref) {
    String workoutIdToRemove = ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['id'];
    ref.read(trainingProgramProvider.notifier).state.trackToDeleteWorkouts.add(workoutIdToRemove);

    // Update local state
    List<Map<String, dynamic>> updatedWeekList = [...ref.read(weekListProvider)];
    updatedWeekList[weekIndex]['workouts'].removeAt(workoutIndex);
    ref.read(weekListProvider.notifier).state = updatedWeekList;
}

void _removeExercise(int weekIndex, int workoutIndex, int exerciseIndex, WidgetRef ref) {
    String exerciseIdToRemove = ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['id'];
    ref.read(trainingProgramProvider.notifier).state.trackToDeleteExercises.add(exerciseIdToRemove);

    // Update local state
    List<Map<String, dynamic>> updatedWeekList = [...ref.read(weekListProvider)];
    updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'].removeAt(exerciseIndex);
    ref.read(weekListProvider.notifier).state = updatedWeekList;
}

void _removeSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex, WidgetRef ref) {
    String seriesIdToRemove = ref.read(weekListProvider)[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'][seriesIndex]['serieId'];
    ref.read(trainingProgramProvider.notifier).state.trackToDeleteSeries.add(seriesIdToRemove);

    // Update local state
    List<Map<String, dynamic>> updatedWeekList = [...ref.read(weekListProvider)];
    updatedWeekList[weekIndex]['workouts'][workoutIndex]['exercises'][exerciseIndex]['series'].removeAt(seriesIndex);
    ref.read(weekListProvider.notifier).state = updatedWeekList;
}

   void _submitProgram(BuildContext context, WidgetRef ref, FirestoreService firestoreService) {
    if (_formKey.currentState!.validate()) {
      final weeksConverted = ref.read(weekListProvider).map((week) => Week.fromMap(week)).toList();
      final updatedProgram = ref.read(trainingProgramProvider);
      updatedProgram.id = programId; // Ensure correct program ID
      updatedProgram.name = nameController.text;
      updatedProgram.description = descriptionController.text;
      updatedProgram.athleteId = athleteIdController.text;
      updatedProgram.mesocycleNumber = int.tryParse(mesocycleNumberController.text) ?? 0;
      updatedProgram.weeks = weeksConverted;

      firestoreService.removeToDeleteItems(updatedProgram).then((_) {
        firestoreService.addOrUpdateTrainingProgram(updatedProgram).then((result) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Program added/updated successfully')));
          _resetFields(ref);
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding/updating program: $error')));
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing items: $error')));
      });
    }
  }

  void _resetFields(WidgetRef ref) {
    nameController.clear();
    descriptionController.clear();
    athleteIdController.clear();
    mesocycleNumberController.clear();
    ref.read(weekListProvider.notifier).state = [];
    // Reset the tracked IDs in TrainingProgram state as well
    final resetProgram = ref.read(trainingProgramProvider.notifier).state;
    resetProgram.trackToDeleteWeeks.clear();
    resetProgram.trackToDeleteWorkouts.clear();
    resetProgram.trackToDeleteExercises.clear();
    resetProgram.trackToDeleteSeries.clear();
    ref.read(trainingProgramProvider.notifier).state = resetProgram;
  }
}