import 'dart:async';
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
  final List<StreamSubscription> _subscriptions = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  @override
  void didUpdateWidget(WorkoutDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutId != oldWidget.workoutId) {
      _isInitialized = false;
      _initializeWorkout();
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _initializeWorkout() {
    if (!_isInitialized) {
      Future.microtask(() {
        if (mounted) {
          _updateWorkoutId();
          _fetchExercises();
          _updateWorkoutName();
          _isInitialized = true;
        }
      });
    }
  }

  void _updateWorkoutId() {
    ref.read(workoutIdProvider.notifier).state = widget.workoutId;
  }

  void _updateWorkoutName() async {
    final currentName = ref.read(currentWorkoutNameProvider);
    if (currentName != widget.workoutId) {
      final workoutName = await _workoutService.fetchWorkoutName(widget.workoutId);
      if (mounted) {
        ref.read(currentWorkoutNameProvider.notifier).state = workoutName;
      }
    }
  }

  Future<void> _fetchExercises() async {
    if (!mounted) return;

    ref.read(loadingProvider.notifier).state = true;
    try {
      final exercises = await _workoutService.fetchExercises(widget.workoutId);
      if (mounted) {
        ref.read(exercisesProvider.notifier).state = exercises;
      }

      for (final exercise in exercises) {
        _subscribeToSeriesUpdates(exercise);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        ref.read(loadingProvider.notifier).state = false;
      }
    }
  }

  void _subscribeToSeriesUpdates(Map<String, dynamic> exercise) {
    final seriesQuery = FirebaseFirestore.instance
        .collection('series')
        .where('exerciseId', isEqualTo: exercise['id'])
        .orderBy('order');

    final subscription = seriesQuery.snapshots().listen((querySnapshot) {
      if (!mounted) return;

      final updatedExercises = ref.read(exercisesProvider.notifier).state;
      final index = updatedExercises.indexWhere((e) => e['id'] == exercise['id']);
      if (index != -1) {
        updatedExercises[index]['series'] = querySnapshot.docs
            .map((doc) => doc.data()..['id'] = doc.id)
            .toList();
        if (mounted) {
          ref.read(exercisesProvider.notifier).state = List.from(updatedExercises);
        }
      }
    });

    _subscriptions.add(subscription);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(loadingProvider);
    final exercises = ref.watch(exercisesProvider);

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
              ? const Center(child: Text('No exercises found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) => _buildExerciseCard(exercises[index], context),
                ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, BuildContext context) {
    final superSetId = exercise['superSetId'];
    if (superSetId != null) {
      final groupedExercises = _groupExercisesBySuperSet(ref.read(exercisesProvider));
      final superSetExercises = groupedExercises[superSetId];
      if (superSetExercises != null && superSetExercises.first == exercise) {
        return _buildSuperSetCard(superSetExercises, context);
      } else {
        return Container();
      }
    } else {
      return _buildSingleExerciseCard(exercise, context);
    }
  }

  Map<String?, List<Map<String, dynamic>>> _groupExercisesBySuperSet(List<Map<String, dynamic>> exercises) {
    final groupedExercises = <String?, List<Map<String, dynamic>>>{};
    for (final exercise in exercises) {
      final superSetId = exercise['superSetId'];
      groupedExercises.putIfAbsent(superSetId, () => []).add(exercise);
    }
    return groupedExercises;
  }

  Widget _buildSuperSetCard(List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Super Set',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...superSetExercises.asMap().entries.map((entry) => 
              _buildSuperSetExerciseName(entry.key, entry.value, context)),
          const SizedBox(height: 24),
          _buildSuperSetStartButton(superSetExercises, context),
          const SizedBox(height: 24),
          _buildSeriesHeaderRow(context),
          ..._buildSeriesRows(superSetExercises, context),
        ],
      ),
    );
  }

  Widget _buildSingleExerciseCard(Map<String, dynamic> exercise, BuildContext context) {
    final series = List<Map<String, dynamic>>.from(exercise['series']);
    final firstNotDoneSeriesIndex = _findFirstNotDoneSeriesIndex(series);
    final isContinueMode = firstNotDoneSeriesIndex > 0;
    final allSeriesCompleted = firstNotDoneSeriesIndex == series.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildExerciseName(exercise, context),
          const SizedBox(height: 24),
          if (!allSeriesCompleted) ...[
            _buildStartButton(exercise, firstNotDoneSeriesIndex, isContinueMode, context),
            const SizedBox(height: 24),
          ],
          _buildSeriesHeaderRow(context),
          const SizedBox(height: 8),
          ..._buildSeriesContainers(series, context),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildSuperSetExerciseName(int index, Map<String, dynamic> exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '${index + 1}. ${exercise['name']} ${exercise['variant'] ?? ''}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
      ),
    );
  }

  Widget _buildSuperSetStartButton(List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allSeriesCompleted = superSetExercises.every((exercise) =>
        exercise['series'].every((series) => series['done'] == true));

    if (allSeriesCompleted) return const SizedBox.shrink();

    final firstNotDoneExerciseIndex = superSetExercises.indexWhere((exercise) =>
        exercise['series'].any((series) => series['done'] != true));

    return GestureDetector(
      onTap: () => _navigateToExerciseDetails(superSetExercises[firstNotDoneExerciseIndex], superSetExercises),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'START',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSeriesHeaderRow(BuildContext context) {
    return Row(
      children: [
        _buildHeaderText('Serie', context, 1),
        _buildHeaderText('Reps', context, 2),
        _buildHeaderText('Kg', context, 2),
        _buildHeaderText('Svolto', context, 1),
      ],
    );
  }

  Widget _buildHeaderText(String text, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildSeriesRows(List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final maxSeriesCount = superSetExercises
        .map((exercise) => exercise['series'].length)
        .reduce((a, b) => a > b ? a : b);

    return List.generate(maxSeriesCount, (seriesIndex) {
      return Column(
        children: [
          Row(
            children: [
              _buildSeriesIndexText(seriesIndex, context, 1),
              ..._buildSuperSetSeriesColumns(superSetExercises, seriesIndex, context),
            ],
          ),
          if (seriesIndex < maxSeriesCount - 1)
            const Divider(height: 16, thickness: 1),
        ],
      );
    });
  }

  Widget _buildSeriesIndexText(int seriesIndex, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        '${seriesIndex + 1}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildSuperSetSeriesColumns(List<Map<String, dynamic>> superSetExercises, int seriesIndex, BuildContext context) {
    return [
      _buildSuperSetSeriesColumn(superSetExercises, seriesIndex, 'reps', context, 2),
      _buildSuperSetSeriesColumn(superSetExercises, seriesIndex, 'weight', context, 2),
      _buildSuperSetSeriesDoneColumn(superSetExercises, seriesIndex, context, 1),
    ];
  }

  Widget _buildSuperSetSeriesColumn(List<Map<String, dynamic>> superSetExercises, int seriesIndex, String field, BuildContext context, int flex) {
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
                    onTap: () => _showEditSeriesDialog(series['id'].toString(), series, context),
                    child: Text(
                      "${series[field]}/${series['${field}_done'] ?? ''}",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
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

  Widget _buildSuperSetSeriesDoneColumn(List<Map<String, dynamic>> superSetExercises, int seriesIndex, BuildContext context, int flex) {
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
                ? GestureDetector(onTap: () => _toggleSeriesDone(series),
                    child: Icon(
                      series['done'] == true ? Icons.check_circle : Icons.cancel,
                      color: series['done'] == true ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                  )
                : const SizedBox(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseName(Map<String, dynamic> exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      "${exercise['name']} ${exercise['variant'] ?? ''}",
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStartButton(Map<String, dynamic> exercise, int firstNotDoneSeriesIndex, bool isContinueMode, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final series = exercise['series'];
    final allSeriesCompleted = series.every((series) => series['done'] == true);

    if (allSeriesCompleted) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _navigateToExerciseDetails(exercise, [exercise], firstNotDoneSeriesIndex),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isContinueMode ? 'CONTINUA' : 'START',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<Widget> _buildSeriesContainers(List<Map<String, dynamic>> series, BuildContext context) {
    return series.asMap().entries.map((entry) {
      final seriesIndex = entry.key;
      final seriesData = entry.value;

      return GestureDetector(
        onTap: () => _showEditSeriesDialog(seriesData['id']?.toString() ?? '', seriesData, context),
        child: Column(
          children: [
            Row(
              children: [
                _buildSeriesIndexText(seriesIndex, context, 1),
                _buildSeriesDataText('reps', seriesData, context, 2),
                _buildSeriesDataText('weight', seriesData, context, 2),
                _buildSeriesDoneIcon(seriesData, context, 1),
              ],
            ),
            if (seriesIndex < series.length - 1)
              const Divider(height: 16, thickness: 1),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSeriesDataText(String field, Map<String, dynamic> seriesData, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    final value = seriesData[field];
    final valueDone = seriesData['${field}_done'];
    final unit = field == 'reps' ? 'R' : 'Kg';

    String text = valueDone == null || valueDone == 0 ? '$value$unit' : '$value/$valueDone$unit';

    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSeriesDoneIcon(Map<String, dynamic> seriesData, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _toggleSeriesDone(seriesData),
        child: Icon(
          seriesData['done'] == true ? Icons.check_circle : Icons.cancel,
          color: seriesData['done'] == true ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
    );
  }

  void _navigateToExerciseDetails(Map<String, dynamic> exercise, List<Map<String, dynamic>> exercises, [int startIndex = 0]) {
    if (!mounted) return;

    context.go(
      '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${exercise['id']}',
      extra: {
        'exerciseName': exercise['name'],
        'exerciseVariant': exercise['variant'] ?? '',
        'seriesList': exercise['series'],
        'startIndex': startIndex,
        'superSetExercises': exercises,
      },
    );
  }

  Future<void> _showEditSeriesDialog(String seriesId, Map<String, dynamic> series, BuildContext context) async {
    final repsController = TextEditingController(text: series['reps']?.toString() ?? '');
    final weightController = TextEditingController(text: series['weight']?.toString() ?? '');

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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                final weightDone = double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0.0;
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

  int _findFirstNotDoneSeriesIndex(List<Map<String, dynamic>> series) {
    return series.indexWhere((serie) => serie['done'] != true);
  }

  void _toggleSeriesDone(Map<String, dynamic> series) async {
    if (!mounted) return;

    final seriesId = series['id'].toString();
    final done = series['done'] == true ? false : true;
    final reps = series['reps'] ?? 0;
    final weight = series['weight'] ?? 0.0;

    await _workoutService.updateSeries(
      seriesId,
      done ? reps : 0,
      done ? weight.toDouble() : 0.0,
    );
  }
}