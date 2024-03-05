import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

// Providers
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final exercisesProvider = StreamProvider((ref) {
  return ref.read(firestoreProvider).collection('exercises').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList());
});

class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String type;

  Exercise({required this.id, required this.name, required this.muscleGroup, required this.type});

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    return Exercise(
      id: doc.id,
      name: doc.get('name') ?? '',
      muscleGroup: doc.get('muscleGroup') ?? '',
      type: doc.get('type') ?? '',
    );
  }
}

class ExerciseRecord {
  final String id;
  final String exerciseId;
  final int maxWeight;
  final int repetitions;
  final String date;

  ExerciseRecord({required this.id, required this.exerciseId, required this.maxWeight, required this.repetitions, required this.date});

  factory ExerciseRecord.fromFirestore(DocumentSnapshot doc) {
    return ExerciseRecord(
      id: doc.id,
      exerciseId: doc['exerciseId'],
      maxWeight: doc['maxWeight'],
      repetitions: doc['repetitions'],
      date: doc['date'],
    );
  }
}

class MaxRMDashboard extends HookConsumerWidget {
  const MaxRMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirebaseAuth auth = ref.watch(authProvider);
    final User? user = auth.currentUser;
    final exercisesAsyncValue = ref.watch(exercisesProvider);
    final selectedExerciseController = useState<Exercise?>(null);
    final maxWeightController = useTextEditingController();
    final repetitionsController = useTextEditingController();
    final dateFormat = DateFormat('yyyy-MM-dd');

    Future<void> addRecord({
      required String userId,
      required String exerciseId,
      required String exerciseName,
      required int maxWeight,
      required int repetitions,
    }) async {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('exercises').doc(exerciseId).collection('records').add({
        'date': dateFormat.format(DateTime.now()),
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'maxWeight': maxWeight,
        'repetitions': repetitions,
        'userId': userId,
      });
    }
   return Scaffold(
 
      body: Column(
        children: [
          // Dropdown per selezionare l'esercizio direttamente nel form
          exercisesAsyncValue.when(
            data: (exercises) {
              return DropdownButtonFormField<Exercise>(
                value: selectedExerciseController.value,
                decoration: const InputDecoration(labelText: 'Seleziona esercizio'),
                onChanged: (Exercise? newValue) {
                  selectedExerciseController.value = newValue;
                },
                items: exercises.map<DropdownMenuItem<Exercise>>((Exercise exercise) {
                  return DropdownMenuItem<Exercise>(
                    value: exercise,
                    child: Text(exercise.name),
                  );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => const Text("Errore nel caricamento degli esercizi"),
          ),
          TextField(
            controller: maxWeightController,
            decoration: const InputDecoration(labelText: 'Inserisci il massimo peso sollevato'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: repetitionsController,
            decoration: const InputDecoration(labelText: 'Inserisci il numero di ripetizioni'),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: () {
              final int repetitions = int.tryParse(repetitionsController.text) ?? 0;
              int maxWeight = int.tryParse(maxWeightController.text) ?? 0;
              if (repetitions > 1) {
                // Calcola il massimale indiretto basato sul numero di ripetizioni e sul peso
                maxWeight = (maxWeight / (1.0278 - (0.0278 * repetitions))).round();
              }
              final Exercise? selectedExercise = selectedExerciseController.value;
              if (user != null && selectedExercise != null && maxWeight > 0) {
                addRecord(
                  userId: user.uid,
                  exerciseId: selectedExercise.id,
                  exerciseName: selectedExercise.name,
                  maxWeight: maxWeight,
                  repetitions: 1, // Setta le ripetizioni a 1 dopo il calcolo
                );
                maxWeightController.clear();
                repetitionsController.clear();
                selectedExerciseController.value = null; // Pulisci la selezione
              }
            },
            child: const Text('Aggiungi Record'),
          ),
          _buildAllExercisesMaxRMs(ref),
        ],
      ),
    );
  }
Widget _buildAllExercisesMaxRMs(WidgetRef ref) {
  final FirebaseAuth auth = ref.watch(authProvider);
  final User? user = auth.currentUser;
  final exercisesStream = ref.watch(exercisesProvider);

  return Expanded(
    child: exercisesStream.when(
      data: (exercises) {
        List<Stream<List<ExerciseRecord>>> exerciseRecordStreams = exercises.map((exercise) {
          return FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('exercises')
              .doc(exercise.id)
              .collection('records')
              .orderBy('date', descending: true)
                            .limit(1) // Prendi solo il record più recente e più pesante

              .snapshots()
              .map((snapshot) => snapshot.docs.map((doc) => ExerciseRecord.fromFirestore(doc)).toList());
        }).toList();

        return StreamBuilder<List<List<ExerciseRecord>>>(
          stream: CombineLatestStream.list(exerciseRecordStreams),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var allRecords = snapshot.data!.expand((x) => x).toList();
            var width = MediaQuery.of(context).size.width;
            int crossAxisCount = width > 1200 ? 4 : width > 800 ? 3 : width > 600 ? 2 : 1;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: allRecords.length,
              itemBuilder: (context, index) {
                var record = allRecords[index];
                Exercise exercise = exercises.firstWhere((ex) => ex.id == record.exerciseId);

                return Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ListTile(
                        title: Text('${record.maxWeight} kg x ${record.repetitions} ripetizioni'),
                        subtitle: Text(record.date),
                      ),
                 Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    // Pulsante Modifica con background verde
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.green, // Text color
      ),
      child: const Text('Modifica'),
      onPressed: () => showEditDialog(context, record, exercise, user),
    ),
    // Pulsante Elimina con background rosso
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.red, // Text color
      ),
      child: const Text('Elimina'),
      onPressed: () => showDeleteDialog(context, record, exercise, user),
    ),
  ],
),

                    ],
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(child: Text('Errore nel caricamento dei massimali')),
    ),
  );
}

void showEditDialog(BuildContext context, ExerciseRecord record, Exercise exercise, User? user) {
  TextEditingController maxWeightController = TextEditingController(text: record.maxWeight.toString());
  TextEditingController repetitionsController = TextEditingController(text: record.repetitions.toString());

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
            onPressed: () => Navigator.of(context).pop(), // Close the dialog
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              // Aggiorna il record in Firestore
              int newMaxWeight = int.parse(maxWeightController.text);
              int newRepetitions = int.parse(repetitionsController.text);
              if (newRepetitions > 1) {
                // Calcolo indiretto del massimale se le ripetizioni sono maggiori di 1
                newMaxWeight = (newMaxWeight / (1.0278 - (0.0278 * newRepetitions))).round();
                newRepetitions = 1; // Imposta le ripetizioni a 1 dopo il calcolo
              }
              FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('exercises')
                .doc(exercise.id)
                .collection('records')
                .doc(record.id)
                .update({
                  'maxWeight': newMaxWeight,
                  'repetitions': newRepetitions,
                })
                .then((_) => Navigator.of(context).pop()); // Chiude la finestra di dialogo dopo l'aggiornamento
            },
            child: const Text('Salva'),
          ),
        ],
      );
    },
  );
}

void showDeleteDialog(BuildContext context, ExerciseRecord record, Exercise exercise, User? user) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Conferma'),
        content: const Text('Sei sicuro di voler eliminare questo record?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close the dialog
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('exercises')
                .doc(exercise.id)
                .collection('records')
                .doc(record.id)
                .delete()
                .then((_) => Navigator.of(context).pop()); // Close the dialog after deletion
            },
            child: const Text('Elimina'),
          ),
        ],
      );
    },
  );
}}