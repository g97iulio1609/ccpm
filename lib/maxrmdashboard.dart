import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'exerciseModel.dart';
import 'exercisesServices.dart';
import 'usersServices.dart';

// Providers
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final exercisesStreamProvider = StreamProvider<List<ExerciseModel>>((ref) {
  final service = ref.watch(exercisesServiceProvider);
  return service.getExercises();
});
final userServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, FirebaseFirestore.instance, FirebaseAuth.instance);
});


class MaxRMDashboard extends HookConsumerWidget {
  const MaxRMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirebaseAuth auth = ref.watch(authProvider);
    final User? user = auth.currentUser;
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final usersService = ref.watch(userServiceProvider);
    final selectedExerciseController = useState<ExerciseModel?>(null);
    final maxWeightController = useTextEditingController();
    final repetitionsController = useTextEditingController();
    final dateFormat = DateFormat('yyyy-MM-dd');

    Future<void> addRecord({
      required String exerciseId,
      required String exerciseName,
      required int maxWeight,
      required int repetitions,
    }) async {
      if (user != null) {
        await usersService.addExerciseRecord(
          userId: user.uid,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          maxWeight: maxWeight,
          repetitions: repetitions,
          date: dateFormat.format(DateTime.now()),
        );
      }
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: exercisesAsyncValue.when(
                data: (exercises) {
                  return Autocomplete<ExerciseModel>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<ExerciseModel>.empty();
                      }
                      return exercises.where((ExerciseModel exercise) {
                        return exercise.name
                            .toLowerCase()
                            .startsWith(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (ExerciseModel exercise) =>
                        exercise.name,
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
                          labelText: 'Seleziona esercizio',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    onSelected: (ExerciseModel selection) {
                      selectedExerciseController.value = selection;
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) =>
                    Text("Errore nel caricamento degli esercizi: $error"),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: maxWeightController,
                decoration: const InputDecoration(
                  labelText: 'Massimo peso sollevato',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: repetitionsController,
                decoration: const InputDecoration(
                  labelText: 'Numero di ripetizioni',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  final int repetitions =
                      int.tryParse(repetitionsController.text) ?? 0;
                  int maxWeight = int.tryParse(maxWeightController.text) ?? 0;
                  if (repetitions > 1) {
                    maxWeight =
                        (maxWeight / (1.0278 - (0.0278 * repetitions))).round();
                  }
                  final ExerciseModel? selectedExercise =
                      selectedExerciseController.value;
                  if (selectedExercise != null && maxWeight > 0) {
                    addRecord(
                      exerciseId: selectedExercise.id,
                      exerciseName: selectedExercise.name,
                      maxWeight: maxWeight,
                      repetitions: 1,
                    );
                    maxWeightController.clear();
                    repetitionsController.clear();
                    selectedExerciseController.value = null;
                  }
                },
                child: const Text('Aggiungi Record'),
              ),
            ),
            _buildAllExercisesMaxRMs(ref, user),
          ],
        ),
      ),
    );
  }


   Widget _buildAllExercisesMaxRMs(WidgetRef ref, User? user) {
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final usersService = ref.watch(userServiceProvider);

    return exercisesAsyncValue.when(
      data: (exercises) {
        List<Stream<ExerciseRecord?>> exerciseRecordStreams = [];
        if (user != null) {
          exerciseRecordStreams = exercises.map((exercise) {
            return usersService.getExerciseRecords(
              userId: user.uid,
              exerciseId: exercise.id,
            ).map((records) => records.isNotEmpty ? records.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b) : null);
          }).toList();
        }

        return StreamBuilder<List<ExerciseRecord?>>(
          stream: CombineLatestStream.list(exerciseRecordStreams),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var latestRecords = snapshot.data ?? [];
            // Filtra i record per rimuovere quelli nulli.
            latestRecords = latestRecords.where((record) => record != null).toList();
            var width = MediaQuery.of(context).size.width;
            int crossAxisCount = width > 1200 ? 4 : width > 800 ? 3 : width > 600 ? 2 : 1;

            return Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 3 / 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: latestRecords.length,
                itemBuilder: (context, index) {
                  var record = latestRecords[index];
                  // Non è più necessario il controllo per record nulli qui perché abbiamo già filtrato la lista.
                  ExerciseModel exercise = exercises.firstWhere((ex) => ex.id == record?.exerciseId);

                  return Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ListTile(
                          title: Text('${record?.maxWeight} kg x ${record?.repetitions} ripetizioni'),
                          subtitle: Text(record!.date),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Modifica'),
                              onPressed: () => showEditDialog(context, record, exercise, user, usersService),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Elimina'),
                              onPressed: () => showDeleteDialog(context, record, exercise, user, usersService),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Errore nel caricamento dei massimali: $error')),
    );
  }

  void showEditDialog(
    BuildContext context,
    ExerciseRecord record,
    ExerciseModel exercise,
    User? user,
    UsersService usersService,
  ) {
    TextEditingController maxWeightController =
        TextEditingController(text: record.maxWeight.toString());
    TextEditingController repetitionsController =
        TextEditingController(text: record.repetitions.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifica Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: maxWeightController,
                decoration: const InputDecoration(labelText: 'Massimo peso'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repetitionsController,
                decoration: const InputDecoration(labelText: 'Ripetizioni'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                int newMaxWeight = int.parse(maxWeightController.text);
                int newRepetitions = int.parse(repetitionsController.text);
                if (newRepetitions > 1) {
                  newMaxWeight =
                      (newMaxWeight / (1.0278 - (0.0278 * newRepetitions)))
                          .round();
                  newRepetitions = 1;
                }
                if (user != null) {
                  usersService.updateExerciseRecord(
                    userId: user.uid,
                    exerciseId: exercise.id,
                    recordId: record.id,
                    maxWeight: newMaxWeight,
                    repetitions: newRepetitions,
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void showDeleteDialog(
    BuildContext context,
    ExerciseRecord record,
    ExerciseModel exercise,
    User? user,
    UsersService usersService,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma'),
          content: const Text('Sei sicuro di voler eliminare questo record?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (user != null) {
                  usersService.deleteExerciseRecord(
                    userId: user.uid,
                    exerciseId: exercise.id,
                    recordId: record.id,
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }
}