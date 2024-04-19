// workout_details.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class WorkoutDetails extends StatefulWidget {
  final String programId;
  final String userId;
  final String weekId;
  final String workoutId;

  const WorkoutDetails({
    super.key,
    required this.userId,
    required this.programId,
    required this.weekId,
    required this.workoutId,
  });

  @override
  _WorkoutDetailsState createState() => _WorkoutDetailsState();
}

class _WorkoutDetailsState extends State<WorkoutDetails> {
  bool loading = true;
  List<Map<String, dynamic>> exercises = [];

 @override
  void initState() {
    super.initState();
    fetchExercises();
  }

Future<void> fetchExercises() async {
  setState(() => loading = true);

  final exercisesSnapshot = await FirebaseFirestore.instance
      .collection('exercisesWorkout')
      .where('workoutId', isEqualTo: widget.workoutId)
      .orderBy('order')
      .get();

  FirebaseFirestore.instance.batch();
  final exerciseDataList = <Map<String, dynamic>>[];

  for (final doc in exercisesSnapshot.docs) {
    final exerciseData = doc.data()..['id'] = doc.id;
    final seriesQuery = FirebaseFirestore.instance
        .collection('series')
        .where('exerciseId', isEqualTo: doc.id)
        .orderBy('order');
    final seriesSnapshot = await seriesQuery.get();
    exerciseData['series'] = seriesSnapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
    exerciseDataList.add(exerciseData);
  }

  setState(() {
    exercises = exerciseDataList;
    loading = false;
  });
}

Stream<List<Map<String, dynamic>>> fetchSeries(String exerciseId) {
  final seriesStream = FirebaseFirestore.instance
      .collection('series')
      .where('exerciseId', isEqualTo: exerciseId)
      .orderBy('order')
      .snapshots();

  return seriesStream.map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final groupedExercises = groupExercisesBySuperSet();

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final superSetId = exercise['superSetId'];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: fetchSeries(exercise['id']),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      exercise['series'] = snapshot.data!;

                      if (superSetId != null) {
                        final superSetExercises = groupedExercises[superSetId]!;
                        if (superSetExercises.first == exercise) {
                          return buildSuperSetCard(
                              superSetExercises, isDarkMode, colorScheme);
                        } else {
                          return Container();
                        }
                      } else {
                        return buildSingleExerciseCard(
                            exercise, isDarkMode, colorScheme);
                      }
                    } else {
                      return Container();
                    }
                  },
                );
              },
            ),
    );
  }

  Map<String?, List<Map<String, dynamic>>> groupExercisesBySuperSet() {
    final groupedExercises = <String?, List<Map<String, dynamic>>>{};

    for (final exercise in exercises) {
      final superSetId = exercise['superSetId'];
      groupedExercises.putIfAbsent(superSetId, () => []).add(exercise);
    }

    return groupedExercises;
  }

  Widget buildSuperSetCard(List<Map<String, dynamic>> superSetExercises,
      bool isDarkMode, ColorScheme colorScheme) {
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Super Set:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? colorScheme.onSurface
                        : colorScheme.onBackground,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ...superSetExercises
                .asMap()
                .entries
                .map((entry) => buildSuperSetExerciseName(
                    entry.key,
                    entry.value,
                    isDarkMode,
                    colorScheme,
                    Theme.of(context).textTheme))
                .toList(),
            const SizedBox(height: 16),
            buildSuperSetStartButton(
                superSetExercises, isDarkMode, colorScheme),
            const SizedBox(height: 16),
            buildSeriesHeaderRow(
                isDarkMode, colorScheme, Theme.of(context).textTheme),
            const SizedBox(height: 8),
            ...buildSeriesRows(superSetExercises, isDarkMode, colorScheme,
                Theme.of(context)),
          ],
        ),
      ),
    );
  }

  Future<void> showEditSeriesDialog(String seriesId, Map<String, dynamic> series) async {
  final repsController = TextEditingController(text: series['reps_done']?.toString() ?? '');
  final weightController = TextEditingController(text: series['weight_done']?.toString() ?? '');

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Modifica Serie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repsDone = int.tryParse(repsController.text) ?? 0;
              final weightDone = double.tryParse(weightController.text) ?? 0.0;
              await updateSeries(seriesId, repsDone, weightDone);
              Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
      );
    },
  );
}

Future<void> updateSeries(String seriesId, int repsDone, double weightDone) async {
  final seriesRef = FirebaseFirestore.instance.collection('series').doc(seriesId);
  final seriesDoc = await seriesRef.get();
  final seriesData = seriesDoc.data();

  if (seriesData != null) {
    final reps = seriesData['reps'] ?? 0;
    final weight = seriesData['weight'] ?? 0.0;
    final done = repsDone >= reps && weightDone >= weight;

    final batch = FirebaseFirestore.instance.batch();
    batch.update(seriesRef, {
      'reps_done': repsDone,
      'weight_done': weightDone,
      'done': done,
    });
    await batch.commit();
  }
}

Widget buildSingleExerciseCard(
    Map<String, dynamic> exercise, bool isDarkMode, ColorScheme colorScheme) {
  final series = List<Map<String, dynamic>>.from(exercise['series']);
  final firstNotDoneSeriesIndex = findFirstNotDoneSeriesIndex(series);
  final isContinueMode = firstNotDoneSeriesIndex > 0;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildExerciseName(exercise, isDarkMode, colorScheme),
          const SizedBox(height: 16),
          buildStartButton(exercise, firstNotDoneSeriesIndex,
              isContinueMode, isDarkMode, colorScheme),
          const SizedBox(height: 16),
          buildSeriesHeaderRow(
              isDarkMode, colorScheme, Theme.of(context).textTheme),
          ...buildSeriesContainers(series, isDarkMode, colorScheme),
        ],
      ),
    ),
  );
}

  Widget buildSuperSetExerciseName(int index, Map<String, dynamic> exercise,
      bool isDarkMode, ColorScheme colorScheme, TextTheme textTheme) {
    return Text(
      '${index + 1}. ${exercise['name']} ${exercise['variant'] ?? ''}',
      style: textTheme.titleMedium?.copyWith(
        color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget buildSuperSetStartButton(List<Map<String, dynamic>> superSetExercises,
      bool isDarkMode, ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: () {
        final firstNotDoneExerciseIndex = superSetExercises.indexWhere(
            (exercise) =>
                findFirstNotDoneSeriesIndex(exercise['series']) <
                exercise['series'].length);

        if (firstNotDoneExerciseIndex != -1) {
          final exercise = superSetExercises[firstNotDoneExerciseIndex];
          final firstNotDoneSeriesIndex =
              findFirstNotDoneSeriesIndex(exercise['series']);

          context.go(
            '/programs_screen/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${exercise['id']}',
            extra: {
              'exerciseName': exercise['name'],
              'exerciseVariant': exercise['variant'],
              'seriesList': exercise['series'],
              'startIndex': firstNotDoneSeriesIndex,
              'superSetExercises': superSetExercises,
            },
          );
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor:
            isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
        backgroundColor:
            isDarkMode ? colorScheme.primary : colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text('START'),
    );
  }

  Widget buildSeriesHeaderRow(
      bool isDarkMode, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildHeaderText('Serie', textTheme, isDarkMode, colorScheme),
        buildHeaderText('Reps', textTheme, isDarkMode, colorScheme),
        buildHeaderText('Kg', textTheme, isDarkMode, colorScheme),
        buildHeaderText('Svolto', textTheme, isDarkMode, colorScheme),
      ],
    );
  }

  Widget buildHeaderText(String text, TextTheme textTheme, bool isDarkMode,
      ColorScheme colorScheme) {
    return Expanded(
      child: Text(
        text,
        style: textTheme.titleMedium?.copyWith(
          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> buildSeriesRows(
      List<Map<String, dynamic>> superSetExercises,
      bool isDarkMode,
      ColorScheme colorScheme,
      ThemeData theme) {
    final maxSeriesCount = superSetExercises
        .map((exercise) => exercise['series'].length)
        .reduce((a, b) => a > b ? a : b);

    return List.generate(maxSeriesCount, (seriesIndex) {
      return Column(
        children: [
          Row(
            children: [
              buildSeriesIndexText(seriesIndex, theme, isDarkMode, colorScheme),
              ...buildSuperSetSeriesColumns(superSetExercises, seriesIndex,
                  isDarkMode, colorScheme, theme.textTheme),
            ],
          ),
          if (seriesIndex < maxSeriesCount - 1)
            const Divider(height: 16, thickness: 1),
        ],
      );
    });
  }

  Widget buildSeriesIndexText(
      int seriesIndex, ThemeData theme, bool isDarkMode, ColorScheme colorScheme) {
    return Expanded(
      child: Text(
        '${seriesIndex + 1}',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> buildSuperSetSeriesColumns(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      bool isDarkMode,
      ColorScheme colorScheme,
      TextTheme textTheme) {
    return [
      buildSuperSetSeriesColumn(superSetExercises, seriesIndex, 'reps',
          isDarkMode, colorScheme, textTheme),
      buildSuperSetSeriesColumn(superSetExercises, seriesIndex, 'weight',
          isDarkMode, colorScheme, textTheme),
      buildSuperSetSeriesDoneColumn(
          superSetExercises, seriesIndex, isDarkMode, colorScheme),
    ];
  }

  Widget buildSuperSetSeriesColumn(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      String field,
      bool isDarkMode,
      ColorScheme colorScheme,
      TextTheme textTheme) {
    return Expanded(
      flex: 2,
      child: Column(
        children: superSetExercises.map((exercise) {
          final series = exercise['series'].asMap().containsKey(seriesIndex)
              ? exercise['series'][seriesIndex]
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: series != null
                ? GestureDetector(
                    onTap: () =>
                        showEditSeriesDialog(series['serieId'].toString(), series),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? colorScheme.surfaceVariant
                            : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${series[field]}/${series['${field}_done'] == 0 ? '' : series['${field}_done']}",
                        style: textTheme.bodyLarge?.copyWith(
                          color: isDarkMode
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : const SizedBox(),
          );
        }).toList(),
      ),
    );
  }

  Widget buildSuperSetSeriesDoneColumn(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      bool isDarkMode,
      ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        children: superSetExercises.map((exercise) {
          final series = exercise['series'].asMap().containsKey(seriesIndex)
              ? exercise['series'][seriesIndex]
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: series != null
                ? Icon(
                    series['done'] == true ? Icons.check_circle : Icons.cancel,
                    color: series['done'] == true
                        ? colorScheme.primary
                        : isDarkMode
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onPrimaryContainer,
                  )
                : const SizedBox(),
          );
        }).toList(),
      ),
    );
  }

Widget buildExerciseName(
    Map<String, dynamic> exercise, bool isDarkMode, ColorScheme colorScheme) {
  return Text(
    "${exercise['name']} ${exercise['variant'] ?? ''}",
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
        ),
    textAlign: TextAlign.center,
  );
}

  Widget buildStartButton(
      Map<String, dynamic> exercise,
      int firstNotDoneSeriesIndex,
      bool isContinueMode,
      bool isDarkMode,
      ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: () {
          context.go(
            '/programs_screen/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${exercise['id']}',
            extra: {
              'exerciseName': exercise['name'],
              'exerciseVariant': exercise['variant'] ?? '',
              'seriesList': exercise['series'],
              'startIndex': firstNotDoneSeriesIndex,
              'superSetExercises': [exercise],
            },
          );
        },
        style: ElevatedButton.styleFrom(
          foregroundColor:
              isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
          backgroundColor:
              isDarkMode ? colorScheme.primary : colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(isContinueMode ? 'CONTINUA' : 'START'),
      ),
    );
  }

  List<Widget> buildSeriesContainers(List<Map<String, dynamic>> series,
      bool isDarkMode, ColorScheme colorScheme) {
    return series.asMap().entries.map((entry) {
      final seriesIndex = entry.key;
      final seriesData = entry.value;

      return GestureDetector(
        onTap: () =>
            showEditSeriesDialog(seriesData['serieId'].toString(), seriesData),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? colorScheme.surfaceVariant
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildSeriesIndexText(
                  seriesIndex, Theme.of(context), isDarkMode, colorScheme),
              buildSeriesDataText(
                  'reps', seriesData, Theme.of(context), isDarkMode, colorScheme),
              buildSeriesDataText('weight', seriesData, Theme.of(context),
                  isDarkMode, colorScheme),
              buildSeriesDoneIcon(seriesData, colorScheme, isDarkMode),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget buildSeriesDataText(String field, Map<String, dynamic> seriesData,
      ThemeData theme, bool isDarkMode, ColorScheme colorScheme) {
    return Expanded(
      flex: 2,
      child: Center(
        child: Text(
          "${seriesData[field]}/${seriesData['${field}_done'] == 0 ? '' : seriesData['${field}_done']}${field == 'reps' ? 'R' : ' Kg'}",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDarkMode
                ? colorScheme.onSurfaceVariant
                : colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget buildSeriesDoneIcon(
      Map<String, dynamic> seriesData, ColorScheme colorScheme, bool isDarkMode) {
    return Expanded(
      child: Center(
        child: Icon(
          seriesData['done'] == true ? Icons.check_circle : Icons.cancel,
          color: seriesData['done'] == true
              ? colorScheme.primary
              : isDarkMode
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }


  int findFirstNotDoneSeriesIndex(List<Map<String, dynamic>> series) {
    return series.indexWhere((serie) => serie['done'] != true);
  }
}


