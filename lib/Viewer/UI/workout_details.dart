import 'dart:async';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/dialog/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
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
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);

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
        exercise['series'].every((series) => _isSeriesDone(series)));

    if (allSeriesCompleted) return const SizedBox.shrink();

    final firstNotDoneExerciseIndex = superSetExercises.indexWhere((exercise) =>
        exercise['series'].any((series) => !_isSeriesDone(series)));

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
                      _formatSeriesValue(series, field),
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
                ? GestureDetector(
                    onTap: () => _toggleSeriesDone(series),
                    child: Icon(
_isSeriesDone(series) ? Icons.check_circle : Icons.cancel,
                      color: _isSeriesDone(series) ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                  ): const SizedBox(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseName(Map<String, dynamic> exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showChangeExerciseDialog(context, exercise),
      child: Text(
        "${exercise['name']} ${exercise['variant'] ?? ''}",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStartButton(Map<String, dynamic> exercise, int firstNotDoneSeriesIndex, bool isContinueMode, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final series = exercise['series'];
    final allSeriesCompleted = series.every((series) => _isSeriesDone(series));

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
    return Expanded(
      flex: flex,
      child: Text(
        _formatSeriesValue(seriesData, field),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatSeriesValue(Map<String, dynamic> seriesData, String field) {
    final value = seriesData[field];
    final maxValue = seriesData['max${field.capitalize()}'];
    final valueDone = seriesData['${field}_done'];
    final isDone = seriesData['done'] == true;
    final unit = field == 'reps' ? 'R' : 'Kg';

    if (isDone || (valueDone != null && valueDone != 0)) {
      return '$valueDone$unit';
    }

    String text = maxValue != null && maxValue != value
        ? '$value-$maxValue$unit'
        : '$value$unit';

    return text;
  }

  Widget _buildSeriesDoneIcon(Map<String, dynamic> seriesData, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _toggleSeriesDone(seriesData),
        child: Icon(
          _isSeriesDone(seriesData) ? Icons.check_circle : Icons.cancel,
          color: _isSeriesDone(seriesData) ? colorScheme.primary : colorScheme.onSurface,
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

void _showChangeExerciseDialog(BuildContext context, Map<String, dynamic> currentExercise) {
  final exerciseRecordService = ref.read(exerciseRecordServiceProvider);
  
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return ExerciseDialog(
        exerciseRecordService: exerciseRecordService,
        athleteId: widget.userId,
        exercise: Exercise(
          id: currentExercise['id'] ?? '',
          exerciseId: currentExercise['exerciseId'] ?? '',
          name: currentExercise['name'] ?? '',
          type: currentExercise['type'] ?? '',
          variant: currentExercise['variant'] ?? '',
          order: currentExercise['order'] ?? 0,
          series: [],
          weekProgressions: [],
        ),
      );
    },
  ).then((newExercise) {
    if (newExercise != null) {
      _updateExercise(currentExercise, newExercise as Exercise);
    }
  });
}

Future<void> _updateExercise(Map<String, dynamic> currentExercise, Exercise newExercise) async {
  final exerciseIndex = ref.read(exercisesProvider.notifier).state
      .indexWhere((e) => e['id'] == currentExercise['id']);

  if (exerciseIndex != -1) {
    final updatedExercises = List<Map<String, dynamic>>.from(ref.read(exercisesProvider));
    updatedExercises[exerciseIndex] = {
      ...updatedExercises[exerciseIndex],
      'name': newExercise.name,
      'exerciseId': newExercise.exerciseId ?? '',
      'type': newExercise.type,
      'variant': newExercise.variant,
    };

    ref.read(exercisesProvider.notifier).state = updatedExercises;

    await _recalculateWeights(updatedExercises[exerciseIndex], newExercise.exerciseId ?? '');

    await _workoutService.updateExercise(currentExercise['id'], {
      'name': newExercise.name,
      'exerciseId': newExercise.exerciseId ?? '',
      'type': newExercise.type,
      'variant': newExercise.variant,
    });
  }
}

Future<void> _recalculateWeights(Map<String, dynamic> exercise, String newExerciseId) async {
  final exerciseRecordService = ref.read(exerciseRecordServiceProvider);
  final newExerciseMaxWeight = await SeriesUtils.getLatestMaxWeight(
    exerciseRecordService,
    widget.userId,
    newExerciseId,
  );
  
  final series = exercise['series'] as List<Map<String, dynamic>>;

  for (var serie in series) {
    final minIntensity = double.tryParse(serie['intensity']?.toString() ?? '0') ?? 0;
    final maxIntensity = double.tryParse(serie['maxIntensity']?.toString() ?? '0');

    // Calcolo di weight
    final newWeight = SeriesUtils.calculateWeightFromIntensity(newExerciseMaxWeight.toDouble(), minIntensity);
    final roundedWeight = SeriesUtils.roundWeight(newWeight, exercise['type'] ?? '');

    // Calcolo di maxWeight solo se maxIntensity è presente e valida
    double? newMaxWeight;
    if (maxIntensity != null && maxIntensity > 0) {
      final calculatedMaxWeight = SeriesUtils.calculateWeightFromIntensity(newExerciseMaxWeight.toDouble(), maxIntensity);
      newMaxWeight = SeriesUtils.roundWeight(calculatedMaxWeight, exercise['type'] ?? '');
    } else {
      newMaxWeight = null; // Mantieni maxWeight null se maxIntensity era null o non valido
    }

    // Calcolo del nuovo RPE e RPE Max
    final newRpe = SeriesUtils.calculateRPE(roundedWeight, newExerciseMaxWeight, serie['reps'])?.toStringAsFixed(1) ?? '';
    final newMaxRpe = newMaxWeight != null 
      ? SeriesUtils.calculateRPE(newMaxWeight, newExerciseMaxWeight, serie['reps'])?.toStringAsFixed(1) 
      : null;

    // Mantieni intensity, maxIntensity, rpe e rpeMax separati
    final newIntensity = minIntensity.toString(); // Mantieni solo il valore di intensity
    final rpeValue = newRpe; // Mantieni solo il valore di rpe, senza concatenare rpeMax
    final rpeMaxValue = newMaxRpe; // Mantieni il valore di rpeMax separato

    await _workoutService.updateSeriesForExerciseChange(
      serie['id'] ?? '',
      weight: roundedWeight,
      maxWeight: newMaxWeight, // Passa newMaxWeight che può essere null
      reps: serie['reps'],
      intensity: newIntensity, // Mantieni solo intensity
      rpe: rpeValue, // Mantieni solo rpe
      rpeMax: rpeMaxValue, // Mantieni solo rpeMax separato
    );

    // Aggiorna i valori locali
    serie['weight'] = roundedWeight;
    serie['maxWeight'] = newMaxWeight; // Mantieni maxWeight null se applicabile
    serie['intensity'] = newIntensity; // Aggiorna solo con intensity
    serie['rpe'] = rpeValue; // Aggiorna solo con rpe
    serie['rpeMax'] = rpeMaxValue; // Aggiorna solo con rpeMax
  }

  setState(() {});
}


  Future<void> _showEditSeriesDialog(String seriesId, Map<String, dynamic> series, BuildContext context) async {
    final userRole = ref.read(userRoleProvider);
    final isCoachOrAdmin = userRole == 'coach' || userRole == 'admin';

    final repsController = TextEditingController(text: series['reps']?.toString() ?? '');
    final maxRepsController = TextEditingController(text: series['maxReps']?.toString() ?? '');
    final weightController = TextEditingController(text: series['weight']?.toString() ?? '');
    final maxWeightController = TextEditingController(text: series['maxWeight']?.toString() ?? '');
    final repsDoneController = TextEditingController(text: series['reps_done']?.toString() ?? series['reps']?.toString() ?? '');
    final weightDoneController = TextEditingController(text: series['weight_done']?.toString() ?? series['weight']?.toString() ?? '');

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Modifica Serie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCoachOrAdmin) ...[
                  TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                  TextField(
                    controller: maxRepsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Reps'),
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
                  TextField(
                    controller: maxWeightController,
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
                    decoration: const InputDecoration(labelText: 'Max Peso (kg)'),
                  ),
                ],
                TextField(
                  controller: repsDoneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps Svolte'),
                ),
                TextField(
                  controller: weightDoneController,
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
                  decoration: const InputDecoration(labelText: 'Peso Svolto (kg)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final repsDone = int.tryParse(repsDoneController.text) ?? 0;
                final weightDone = double.tryParse(weightDoneController.text.replaceAll(',', '.')) ?? 0.0;

                if (isCoachOrAdmin) {
                  final reps = int.tryParse(repsController.text) ?? 0;
                  final maxReps = int.tryParse(maxRepsController.text);
                  final weight = double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0.0;
                  final maxWeight = double.tryParse(maxWeightController.text.replaceAll(',', '.'));

                  _workoutService.updateSeriesWithMaxValues(
                    seriesId,
                    reps,
                    maxReps,
                    weight,
                    maxWeight,
                    repsDone,
                    weightDone,
                  );
                } else {
                  _workoutService.updateSeriesData(seriesId, repsDone, weightDone);
                }

                Navigator.pop(dialogContext);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  bool _isSeriesDone(Map<String, dynamic> seriesData) {
    final repsDone = seriesData['reps_done'] ?? 0;
    final weightDone = seriesData['weight_done'] ?? 0.0;
    final reps = seriesData['reps'] ?? 0;
    final maxReps = seriesData['maxReps'];
    final weight = seriesData['weight'] ?? 0.0;
    final maxWeight = seriesData['maxWeight'];

    bool repsCompleted = maxReps != null
        ? repsDone >= reps && (repsDone <= maxReps || repsDone > maxReps)
        : repsDone >= reps;

    bool weightCompleted = maxWeight != null
        ? weightDone >= weight && (weightDone <= maxWeight || weightDone > maxWeight)
        : weightDone >= weight;

    return repsCompleted && weightCompleted;
  }

  void _toggleSeriesDone(Map<String, dynamic> series) async {
    if (!mounted) return;

    final seriesId = series['id'].toString();
    final currentlyDone = _isSeriesDone(series);
    final reps = series['reps'] ?? 0;
    final maxReps = series['maxReps'];
    final weight = (series['weight'] ?? 0.0).toDouble();
    final maxWeight = series['maxWeight']?.toDouble();

    if (!currentlyDone) {
await _workoutService.updateSeriesWithMaxValues(
        seriesId,
        reps,
        maxReps,
        weight,
        maxWeight,
        maxReps ?? reps,
        maxWeight ?? weight,
      );
    } else {
      await _workoutService.updateSeriesWithMaxValues(
        seriesId,
        reps,
        maxReps,
        weight,
        maxWeight,
        0,
        0.0,
      );
    }
  }

  int _findFirstNotDoneSeriesIndex(List<Map<String, dynamic>> series) {
    return series.indexWhere((serie) => !_isSeriesDone(serie));
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}