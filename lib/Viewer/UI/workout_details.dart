import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/training_program_services.dart';
import '../providers/training_program_provider.dart';

class WorkoutDetails extends ConsumerStatefulWidget {
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
  ConsumerState<WorkoutDetails> createState() => _WorkoutDetailsState();
}

class _WorkoutDetailsState extends ConsumerState<WorkoutDetails> {
  final TrainingProgramServices _workoutService = TrainingProgramServices();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workoutIdProvider.notifier).state = widget.workoutId;
      _fetchExercises();
    });
  }

  @override
  void didUpdateWidget(covariant WorkoutDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutId != oldWidget.workoutId) {
      Future.microtask(() {
        ref.read(workoutIdProvider.notifier).state = widget.workoutId;
        _fetchExercises();
      });
    }
  }

  Future<void> _fetchExercises() async {
    ref.read(loadingProvider.notifier).state = true;
    try {
      final exercises = await _workoutService.fetchExercises(widget.workoutId);
      if (mounted) {
        ref.read(exercisesProvider.notifier).state = exercises;
      }

      for (final exercise in exercises) {
        final seriesQuery = FirebaseFirestore.instance
            .collection('series')
            .where('exerciseId', isEqualTo: exercise['id'])
            .orderBy('order');
        seriesQuery.snapshots().listen((querySnapshot) {
          final updatedExercises = ref.read(exercisesProvider.notifier).state;
          final index =
              updatedExercises.indexWhere((e) => e['id'] == exercise['id']);
          if (index != -1) {
            updatedExercises[index]['series'] = querySnapshot.docs
                .map((doc) => doc.data()..['id'] = doc.id)
                .toList();
            if (mounted) {
              ref.read(exercisesProvider.notifier).state =
                  List.from(updatedExercises);
            }
          }
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        ref.read(loadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(loadingProvider);
    final exercises = ref.watch(exercisesProvider);

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final superSetId = exercise['superSetId'];

                if (superSetId != null) {
                  final groupedExercises = groupExercisesBySuperSet(exercises);
                  final superSetExercises = groupedExercises[superSetId]!;
                  if (superSetExercises.first == exercise) {
                    return buildSuperSetCard(superSetExercises, context);
                  } else {
                    return Container();
                  }
                } else {
                  return buildSingleExerciseCard(exercise, context);
                }
              },
            ),
    );
  }

  Map<String?, List<Map<String, dynamic>>> groupExercisesBySuperSet(
      List<Map<String, dynamic>> exercises) {
    final groupedExercises = <String?, List<Map<String, dynamic>>>{};

    for (final exercise in exercises) {
      final superSetId = exercise['superSetId'];
      groupedExercises.putIfAbsent(superSetId, () => []).add(exercise);
    }

    return groupedExercises;
  }

  Widget buildSuperSetCard(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? colorScheme.surface : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Super Set',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? colorScheme.onSurface
                      : colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...superSetExercises
              .asMap()
              .entries
              .map((entry) =>
                  buildSuperSetExerciseName(entry.key, entry.value, context))
              ,
          const SizedBox(height: 24),
          buildSuperSetStartButton(superSetExercises, context),
          const SizedBox(height: 24),
          buildSeriesHeaderRow(context),
          ...buildSeriesRows(superSetExercises, context),
        ],
      ),
    );
  }

  Widget buildSingleExerciseCard(
      Map<String, dynamic> exercise, BuildContext context) {
    final series = List<Map<String, dynamic>>.from(exercise['series']);
    final firstNotDoneSeriesIndex = findFirstNotDoneSeriesIndex(series);
    final isContinueMode = firstNotDoneSeriesIndex > 0;
    final allSeriesCompleted = firstNotDoneSeriesIndex == series.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildExerciseName(exercise, context),
          const SizedBox(height: 24),
          if (!allSeriesCompleted)
            buildStartButton(
                exercise, firstNotDoneSeriesIndex, isContinueMode, context),
          if (!allSeriesCompleted) const SizedBox(height: 24),
          buildSeriesHeaderRow(context),
          const SizedBox(height: 8),
          ...buildSeriesContainers(series, context),
        ],
      ),
    );
  }

  Widget buildSuperSetExerciseName(
      int index, Map<String, dynamic> exercise, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '${index + 1}. ${exercise['name']} ${exercise['variant'] ?? ''}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
      ),
    );
  }

  Widget buildSuperSetStartButton(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final allSeriesCompleted = superSetExercises.every((exercise) =>
        exercise['series'].every((series) => series['done'] == true));

    if (allSeriesCompleted) {
      return const SizedBox.shrink();
    }

    final firstNotDoneExerciseIndex = superSetExercises.indexWhere((exercise) =>
        exercise['series'].any((series) => series['done'] != true));

    return GestureDetector(
      onTap: () {
        final exercise = superSetExercises[firstNotDoneExerciseIndex];
        final firstNotDoneSeriesIndex =
            exercise['series'].indexWhere((series) => series['done'] != true);

        context.go(
          '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${exercise['id']}',
          extra: {
            'exerciseName': exercise['name'],
            'exerciseVariant': exercise['variant'],
            'seriesList': exercise['series'],
            'startIndex': firstNotDoneSeriesIndex,
            'superSetExercises': superSetExercises,
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? colorScheme.primary : colorScheme.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'START',
          style: TextStyle(
            color: isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget buildSeriesHeaderRow(BuildContext context) {
    return Row(
      children: [
        buildHeaderText('Serie', context, 1),
        buildHeaderText('Reps', context, 2),
        buildHeaderText('Kg', context, 2),
        buildHeaderText('Svolto', context, 1),
      ],
    );
  }

  Widget buildHeaderText(String text, BuildContext context, int flex) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> buildSeriesRows(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final maxSeriesCount = superSetExercises
        .map((exercise) => exercise['series'].length)
        .reduce((a, b) => a > b ? a : b);

    return List.generate(maxSeriesCount, (seriesIndex) {
      return Column(
        children: [
          Row(
            children: [
              buildSeriesIndexText(seriesIndex, context, 1),
              ...buildSuperSetSeriesColumns(
                  superSetExercises, seriesIndex, context),
            ],
          ),
          if (seriesIndex < maxSeriesCount - 1)
            const Divider(height: 16, thickness: 1),
        ],
      );
    });
  }

  Widget buildSeriesIndexText(int seriesIndex, BuildContext context, int flex) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        '${seriesIndex + 1}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> buildSuperSetSeriesColumns(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      BuildContext context) {
    return [
      buildSuperSetSeriesColumn(
          superSetExercises, seriesIndex, 'reps', context, 2),
      buildSuperSetSeriesColumn(
          superSetExercises, seriesIndex, 'weight', context, 2),
      buildSuperSetSeriesDoneColumn(superSetExercises, seriesIndex, context, 1),
    ];
  }

  Widget buildSuperSetSeriesColumn(List<Map<String, dynamic>> superSetExercises,
      int seriesIndex, String field, BuildContext context, int flex) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Column(
        children: superSetExercises.map((exercise) {
          final series = exercise['series'].asMap().containsKey(seriesIndex)
              ? exercise['series'][seriesIndex]
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: series != null
                ? GestureDetector(
                    onTap: () => showEditSeriesDialog(
                        series['id'].toString(), series, context),
                    child: Text(
                      "${series[field]}/${series['${field}_done'] ?? ''}",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDarkMode
                                ? colorScheme.onSurface
                                : colorScheme.onSurface,
                          ),
                      textAlign: TextAlign.center,
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
      BuildContext context,
      int flex) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Column(
        children: superSetExercises.map((exercise) {
          final series = exercise['series'].asMap().containsKey(seriesIndex)
              ? exercise['series'][seriesIndex]
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: series != null
                ? GestureDetector(
                    onTap: () async {
                      final seriesId = series['id'].toString();
                      final done = series['done'] == true ? false : true;
                      final reps = series['reps'] ?? 0;
                      final weight = series['weight'] ?? 0.0;
                      await _workoutService.updateSeries(
                        seriesId,
                        done ? reps : 0,
                        done ? weight.toDouble() : 0.0,
                      );
                    },
                    child: Icon(
                      series['done'] == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: series['done'] == true
                          ? colorScheme.primary
                          : isDarkMode
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimaryContainer,
                    ),
                  )
                : const SizedBox(),
          );
        }).toList(),
      ),
    );
  }

  Widget buildExerciseName(
      Map<String, dynamic> exercise, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      "${exercise['name']} ${exercise['variant'] ?? ''}",
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color:
                isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget buildStartButton(Map<String, dynamic> exercise,
      int firstNotDoneSeriesIndex, bool isContinueMode, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final series = exercise['series'];
    final allSeriesCompleted = series.every((series) => series['done'] == true);

    if (allSeriesCompleted) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        context.go(
          '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${exercise['id']}',
          extra: {
            'exerciseName': exercise['name'],
            'exerciseVariant': exercise['variant'] ?? '',
            'seriesList': exercise['series'],
            'startIndex': firstNotDoneSeriesIndex,
            'superSetExercises': [exercise],
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? colorScheme.primary : colorScheme.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isContinueMode ? 'CONTINUA' : 'START',
          style: TextStyle(
            color: isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<Widget> buildSeriesContainers(
      List<Map<String, dynamic>> series, BuildContext context) {
    return series.asMap().entries.map((entry) {
      final seriesIndex = entry.key;
      final seriesData = entry.value;

      return GestureDetector(
        onTap: () => showEditSeriesDialog(
            seriesData['id'].toString(), seriesData, context),
        child: Column(
          children: [
            Row(
              children: [
                buildSeriesIndexText(seriesIndex, context, 1),
                buildSeriesDataText('reps', seriesData, context, 2),
                buildSeriesDataText('weight', seriesData, context, 2),
                buildSeriesDoneIcon(seriesData, context, 1),
              ],
            ),
            if (seriesIndex < series.length - 1)
              const Divider(height: 16, thickness: 1),
          ],
        ),
      );
    }).toList();
  }

  Widget buildSeriesDataText(String field, Map<String, dynamic> seriesData,
      BuildContext context, int flex) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final value = seriesData[field];
    final valueDone = seriesData['${field}_done'];
    final unit = field == 'reps' ? 'R' : 'Kg';

    String text;
    if (valueDone == null || valueDone == 0) {
      text = '$value$unit';
    } else {
      text = '$value/$valueDone$unit';
    }

    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildSeriesDoneIcon(
      Map<String, dynamic> seriesData, BuildContext context, int flex) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () async {
          final seriesId = seriesData['id'].toString();
          final done = seriesData['done'] == true ? false : true;
          final reps = seriesData['reps'] ?? 0;
          final weight = seriesData['weight'] ?? 0.0;

          await _workoutService.updateSeries(
            seriesId,
            done ? reps : 0,
            done ? weight.toDouble() : 0.0,
          );
        },
        child: Icon(
          seriesData['done'] == true ? Icons.check_circle : Icons.cancel,
          color: seriesData['done'] == true
              ? colorScheme.primary
              : isDarkMode
                  ? colorScheme.onSurface
                  : colorScheme.onSurface,
        ),
      ),
    );
  }

 Future<void> showEditSeriesDialog(String seriesId,
      Map<String, dynamic> series, BuildContext context) async {
    final repsController =
        TextEditingController(text: series['reps']?.toString() ?? '');
    final weightController =
        TextEditingController(text: series['weight']?.toString() ?? '');

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text.replaceAll(',', '.');
                    return newValue.copyWith(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }),
                ],
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final repsDone = int.tryParse(repsController.text) ?? 0;
                final weightDone = double.tryParse(
                        weightController.text.replaceAll(',', '.')) ??
                    0.0;
                Navigator.pop(dialogContext);
                _workoutService.updateSeries(seriesId, repsDone, weightDone);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  int findFirstNotDoneSeriesIndex(List<Map<String, dynamic>> series) {
    return series.indexWhere((serie) => serie['done'] != true);
  }
}
