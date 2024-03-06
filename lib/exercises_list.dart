import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'exercise_model.dart';
import 'exercisesServices.dart';

final muscleGroupsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance.collection('muscleGroups').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc['name'].toString()).toList());
});

final exerciseTypesProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance.collection('ExerciseTypes').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc['name'].toString()).toList());
});

class ExercisesList extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesService = ref.watch(exercisesServiceProvider);
    final muscleGroupsStream = ref.watch(muscleGroupsProvider);
    final exerciseTypesStream = ref.watch(exerciseTypesProvider);
    final searchText = useState('');
    final selectedMuscleGroup = useState<String?>(null);
    final selectedExerciseType = useState<String?>(null);
    final TextEditingController nameController = useTextEditingController();
    final editingExerciseId = useState<String?>(null);

    void addOrEditExercise() {
      final data = {
        'name': nameController.text.trim(),
        'muscleGroup': selectedMuscleGroup.value,
        'type': selectedExerciseType.value
      };

      if (editingExerciseId.value != null) {
        exercisesService.updateExercise(
          editingExerciseId.value!,
          data['name']!,
          data['muscleGroup']!,
          data['type']!,
        );
      } else if (nameController.text.trim().isNotEmpty &&
          selectedMuscleGroup.value != null &&
          selectedExerciseType.value != null) {
        exercisesService.addExercise(
          data['name']!,
          data['muscleGroup']!,
          data['type']!,
        );
      }

      nameController.clear();
      selectedMuscleGroup.value = null;
      selectedExerciseType.value = null;
      editingExerciseId.value = null;
    }

    Future<void> editExercise(ExerciseModel exercise) async {
      nameController.text = exercise.name;
      selectedMuscleGroup.value = exercise.muscleGroup;
      selectedExerciseType.value = exercise.type;
      editingExerciseId.value = exercise.id;
    }

    Future<void> deleteExercise(String id) async {
      await exercisesService.deleteExercise(id);
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: editingExerciseId.value != null
                          ? 'Modifica esercizio'
                          : 'Nuovo esercizio',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: addOrEditExercise,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  muscleGroupsStream.when(
                    data: (muscleGroups) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Gruppo muscolare',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedMuscleGroup.value,
                      isExpanded: true,
                      onChanged: (newValue) {
                        selectedMuscleGroup.value = newValue;
                      },
                      items: muscleGroups
                          .toSet()
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Errore: $error'),
                  ),
                  const SizedBox(height: 10),
                  exerciseTypesStream.when(
                    data: (exerciseTypes) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo di esercizio',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedExerciseType.value,
                      isExpanded: true,
                      onChanged: (newValue) {
                        selectedExerciseType.value = newValue;
                      },
                      items: exerciseTypes
                          .toSet()
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Errore: $error'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) => searchText.value = value,
                decoration: const InputDecoration(
                  labelText: 'Cerca esercizio...',
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            StreamBuilder<List<ExerciseModel>>(
              stream: exercisesService.getExercises(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final exercises = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      childAspectRatio: 3 / 2,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      if (exercise.name
                          .toLowerCase()
                          .contains(searchText.value.toLowerCase())) {
                        return Card(
                          child: InkWell(
                            onTap: () => editExercise(exercise),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                      '${exercise.muscleGroup} - ${exercise.type}'),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.green,
                                        ),
                                        child: const Text('Modifica'),
                                        onPressed: () => editExercise(exercise),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Elimina'),
                                        onPressed: () =>
                                            deleteExercise(exercise.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Errore: ${snapshot.error}');
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}