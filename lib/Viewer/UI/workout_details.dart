import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/dialog/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/dialog/series_dialog.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/training_program_services.dart';
import '../providers/training_program_provider.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/Main/routes.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';

// Add note provider
final exerciseNotesProvider = StateProvider<Map<String, String>>((ref) => {});

// Add cache providers at the top level
final _exerciseCacheProvider =
    StateProvider<Map<String, List<Map<String, dynamic>>>>((ref) => {});
final _workoutNameCacheProvider =
    StateProvider<Map<String, String>>((ref) => {});

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
  late final ExerciseRecordService _exerciseRecordService;
  final List<StreamSubscription> _subscriptions = [];
  bool _isInitialized = false;
  final Map<String, ValueNotifier<double>> _weightNotifiers = {};

  // Add memoization cache
  final Map<String, Map<String?, List<Map<String, dynamic>>>>
      _groupedExercisesCache = {};

  @override
  void initState() {
    super.initState();
    _exerciseRecordService = ref.read(exerciseRecordServiceProvider);
    _initializeWorkout();
    _loadExerciseNotes();
  }

  void _loadExerciseNotes() async {
    if (!mounted) return;

    try {
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('exercise_notes')
          .where('workoutId', isEqualTo: widget.workoutId)
          .get();

      final notes = {
        for (var doc in notesSnapshot.docs)
          doc['exerciseId'] as String: doc['note'] as String
      };

      if (mounted) {
        ref.read(exerciseNotesProvider.notifier).state = notes;
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _showNoteDialog(String exerciseId, String exerciseName,
      [String? existingNote]) async {
    final TextEditingController noteController =
        TextEditingController(text: existingNote);
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Note per $exerciseName',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Inserisci una nota...',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          if (existingNote != null)
            TextButton(
              onPressed: () async {
                await _deleteNote(exerciseId);
                if (mounted) Navigator.of(context).pop();
              },
              child: Text(
                'Elimina',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annulla',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final note = noteController.text.trim();
              if (note.isNotEmpty) {
                await _saveNote(exerciseId, note);
              }
              if (mounted) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: Text(
              'Salva',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote(String exerciseId, String note) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('exercise_notes')
          .doc('${widget.workoutId}_$exerciseId');

      await docRef.set({
        'workoutId': widget.workoutId,
        'exerciseId': exerciseId,
        'note': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        final currentNotes =
            Map<String, String>.from(ref.read(exerciseNotesProvider));
        currentNotes[exerciseId] = note;
        ref.read(exerciseNotesProvider.notifier).state = currentNotes;
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _deleteNote(String exerciseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('exercise_notes')
          .doc('${widget.workoutId}_$exerciseId')
          .delete();

      if (mounted) {
        final currentNotes =
            Map<String, String>.from(ref.read(exerciseNotesProvider));
        currentNotes.remove(exerciseId);
        ref.read(exerciseNotesProvider.notifier).state = currentNotes;
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void didUpdateWidget(WorkoutDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutId != oldWidget.workoutId) {
      _isInitialized = false;
      _initializeWorkout();
      _loadExerciseNotes();
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
      // Check cache first
      final cachedName = ref.read(_workoutNameCacheProvider)[widget.workoutId];
      if (cachedName != null) {
        ref.read(currentWorkoutNameProvider.notifier).state = cachedName;
        return;
      }

      final workoutName =
          await _workoutService.fetchWorkoutName(widget.workoutId);
      if (mounted) {
        ref.read(currentWorkoutNameProvider.notifier).state = workoutName;
        // Update cache
        final cache =
            Map<String, String>.from(ref.read(_workoutNameCacheProvider));
        cache[widget.workoutId] = workoutName;
        ref.read(_workoutNameCacheProvider.notifier).state = cache;
      }
    }
  }

  Future<void> _fetchExercises() async {
    if (!mounted) return;

    // Check cache first
    final cachedExercises = ref.read(_exerciseCacheProvider)[widget.workoutId];
    if (cachedExercises != null) {
      ref.read(exercisesProvider.notifier).state = cachedExercises;
      // Setup subscriptions for cached exercises
      for (final exercise in cachedExercises) {
        _subscribeToSeriesUpdates(exercise);
      }
      return;
    }

    ref.read(loadingProvider.notifier).state = true;
    try {
      final exercises = await _workoutService.fetchExercises(widget.workoutId);
      if (mounted) {
        ref.read(exercisesProvider.notifier).state = exercises;
        // Update cache
        final cache = Map<String, List<Map<String, dynamic>>>.from(
            ref.read(_exerciseCacheProvider));
        cache[widget.workoutId] = exercises;
        ref.read(_exerciseCacheProvider.notifier).state = cache;
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
    // Cancel existing subscription if any
    _subscriptions.removeWhere((sub) {
      if (sub.hashCode.toString().contains(exercise['id'])) {
        sub.cancel();
        return true;
      }
      return false;
    });

    final seriesQuery = FirebaseFirestore.instance
        .collection('series')
        .where('exerciseId', isEqualTo: exercise['id'])
        .orderBy('order');

    final subscription = seriesQuery.snapshots().listen((querySnapshot) {
      if (!mounted) return;

      final updatedExercises = ref.read(exercisesProvider);
      final index =
          updatedExercises.indexWhere((e) => e['id'] == exercise['id']);
      if (index != -1) {
        final newExercises = List<Map<String, dynamic>>.from(updatedExercises);
        newExercises[index] = Map<String, dynamic>.from(newExercises[index]);
        newExercises[index]['series'] = querySnapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();

        if (mounted) {
          ref.read(exercisesProvider.notifier).state = newExercises;

          // Update cache
          final cache = Map<String, List<Map<String, dynamic>>>.from(
              ref.read(_exerciseCacheProvider));
          cache[widget.workoutId] = newExercises;
          ref.read(_exerciseCacheProvider.notifier).state = cache;
        }
      }
    });

    _subscriptions.add(subscription);
  }

  Map<String?, List<Map<String, dynamic>>> _groupExercisesBySuperSet(
      List<Map<String, dynamic>> exercises) {
    // Use memoization for expensive calculations
    final cacheKey = exercises.map((e) => e['id']).join('_');
    if (_groupedExercisesCache.containsKey(cacheKey)) {
      return _groupedExercisesCache[cacheKey]!;
    }

    final groupedExercises = <String?, List<Map<String, dynamic>>>{};
    for (final exercise in exercises) {
      final superSetId = exercise['superSetId'];
      groupedExercises.putIfAbsent(superSetId, () => []).add(exercise);
    }

    // Cache the result
    _groupedExercisesCache[cacheKey] = groupedExercises;
    return groupedExercises;
  }

  @override
  Widget build(BuildContext context) {
    // Use select instead of watch to prevent unnecessary rebuilds
    final loading = ref.watch(loadingProvider);
    final exercises = ref.watch(exercisesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : exercises.isEmpty
              ? Center(
                  child: Text(
                    'Nessun esercizio trovato',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(AppTheme.spacing.md),
                  itemCount: exercises.length,
                  // Add key to preserve scroll position and reduce rebuilds
                  key: PageStorageKey('workout_exercises_${widget.workoutId}'),
                  itemBuilder: (context, index) =>
                      _buildExerciseCard(exercises[index], context),
                ),
    );
  }

  Widget _buildExerciseCard(
      Map<String, dynamic> exercise, BuildContext context) {
    final superSetId = exercise['superSetId'];
    if (superSetId != null) {
      final groupedExercises =
          _groupExercisesBySuperSet(ref.read(exercisesProvider));
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

  Widget _buildSuperSetCard(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Check if all series in all exercises are completed
    final allSeriesCompleted = superSetExercises.every((exercise) {
      final series = List<Map<String, dynamic>>.from(exercise['series']);
      return series.every((serie) => _isSeriesDone(serie));
    });
    
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
          if (!allSeriesCompleted) ...[
            _buildSuperSetStartButton(superSetExercises, context),
            const SizedBox(height: 24),
          ],
          _buildSeriesHeaderRow(context),
          ..._buildSeriesRows(superSetExercises, context),
        ],
      ),
    );
  }

  Widget _buildSingleExerciseCard(
      Map<String, dynamic> exercise, BuildContext context) {
    final series = List<Map<String, dynamic>>.from(exercise['series']);
    final firstNotDoneSeriesIndex = _findFirstNotDoneSeriesIndex(series);
    final isContinueMode = firstNotDoneSeriesIndex > 0;
    final allSeriesCompleted = series.every((serie) => _isSeriesDone(serie));
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: _buildExerciseName(exercise, context),
            ),
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!allSeriesCompleted) ...[
                    _buildStartButton(exercise, firstNotDoneSeriesIndex,
                        isContinueMode, context),
                    SizedBox(height: AppTheme.spacing.md),
                  ],
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: AppTheme.spacing.xs,
                      horizontal: AppTheme.spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                    ),
                    child: _buildSeriesHeaderRow(context),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  ..._buildSeriesContainers(series, context),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildSuperSetExerciseName(
      int index, Map<String, dynamic> exercise, BuildContext context) {
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

  Widget _buildSuperSetStartButton(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allSeriesCompleted = superSetExercises.every((exercise) =>
        exercise['series'].every((series) => _isSeriesDone(series)));

    if (allSeriesCompleted) return const SizedBox.shrink();

    final firstNotDoneExerciseIndex = superSetExercises.indexWhere((exercise) =>
        exercise['series'].any((series) => !_isSeriesDone(series)));

    return GestureDetector(
      onTap: () => _navigateToExerciseDetails(
          superSetExercises[firstNotDoneExerciseIndex], superSetExercises),
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
        _buildHeaderText('✓', context, 1),
      ],
    );
  }

  Widget _buildHeaderText(String text, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildSeriesRows(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final maxSeriesCount = superSetExercises
        .map((exercise) => exercise['series'].length)
        .reduce((a, b) => a > b ? a : b);

    return List.generate(maxSeriesCount, (seriesIndex) {
      return Column(
        children: [
          Row(
            children: [
              _buildSeriesIndexText(seriesIndex, context, 1),
              ..._buildSuperSetSeriesColumns(
                  superSetExercises, seriesIndex, context),
            ],
          ),
          if (seriesIndex < maxSeriesCount - 1)
            const Divider(height: 16, thickness: 1),
        ],
      );
    });
  }

  Widget _buildSeriesIndexText(
      int seriesIndex, BuildContext context, int flex) {
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

  List<Widget> _buildSuperSetSeriesColumns(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      BuildContext context) {
    return [
      _buildSuperSetSeriesColumn(
          superSetExercises, seriesIndex, 'reps', context, 2),
      _buildSuperSetSeriesColumn(
          superSetExercises, seriesIndex, 'weight', context, 2),
      _buildSuperSetSeriesDoneColumn(
          superSetExercises, seriesIndex, context, 1),
    ];
  }

  Widget _buildSuperSetSeriesColumn(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      String field,
      BuildContext context,
      int flex) {
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
                    onTap: () =>
                        _showEditSeriesDialog(series['exerciseId'], [series]),
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

  Widget _buildSuperSetSeriesDoneColumn(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      BuildContext context,
      int flex) {
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
                      color: _isSeriesDone(series)
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  )
                : const SizedBox(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseName(
      Map<String, dynamic> exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = ref.watch(exerciseNotesProvider);
    final hasNote = notes.containsKey(exercise['id']);
    final userRole = ref.watch(userRoleProvider);
    final isAdmin = userRole == 'admin';

    return Row(
      children: [
        if (hasNote)
          GestureDetector(
            onTap: () => _showNoteDialog(
              exercise['id'],
              exercise['name'],
              notes[exercise['id']],
            ),
            child: Container(
              margin: EdgeInsets.only(right: AppTheme.spacing.xs),
              padding: EdgeInsets.all(AppTheme.spacing.xxs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              child: Text(
                'N',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Expanded(
          child: GestureDetector(
            onLongPress: () => _showNoteDialog(
              exercise['id'],
              exercise['name'],
              notes[exercise['id']],
            ),
            child: Text(
              "${exercise['name']} ${exercise['variant'] ?? ''}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (isAdmin)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurfaceVariant,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change',
                child: Text('Cambia esercizio'),
              ),
              const PopupMenuItem(
                value: 'edit_series',
                child: Text('Modifica serie'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'change':
                  _showChangeExerciseDialog(context, exercise);
                  break;
                case 'edit_series':
                  _showSeriesEditDialog(
                    exercise,
                    List<Map<String, dynamic>>.from(exercise['series'] ?? []),
                  );
                  break;
              }
            },
          ),
        if (!isAdmin)
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change',
                child: Text('Cambia esercizio'),
              ),
            ],
            onSelected: (value) {
              if (value == 'change') {
                _showChangeExerciseDialog(context, exercise);
              }
            },
          ),
      ],
    );
  }

  Widget _buildStartButton(Map<String, dynamic> exercise,
      int firstNotDoneSeriesIndex, bool isContinueMode, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: () => _navigateToExerciseDetails(
          exercise, [exercise], firstNotDoneSeriesIndex),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
      ),
      child: Text(
        isContinueMode ? 'CONTINUA' : 'INIZIA',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  List<Widget> _buildSeriesContainers(
      List<Map<String, dynamic>> series, BuildContext context) {
    return series.asMap().entries.map((entry) {
      final seriesIndex = entry.key;
      final seriesData = entry.value;

      return GestureDetector(
        onTap: () {
          final exercise = {
            'id': seriesData['exerciseId'],
            'type': seriesData['type'] ?? 'weight',
          };
          _showEditSeriesDialog(exercise, [seriesData]);
        },
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

  Widget _buildSeriesDataText(String field, Map<String, dynamic> seriesData,
      BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        child: seriesData != null
            ? GestureDetector(
                onTap: () {
                  final exercise = {
                    'id': seriesData['exerciseId'],
                    'type': seriesData['type'] ?? 'weight',
                  };
                  _showEditSeriesDialog(exercise, [seriesData]);
                },
                child: Text(
                  _formatSeriesValue(seriesData, field),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
              )
            : const SizedBox.shrink(),
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

  Widget _buildSeriesDoneIcon(
      Map<String, dynamic> seriesData, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _toggleSeriesDone(seriesData),
          child: Icon(
            _isSeriesDone(seriesData) ? Icons.check_circle : Icons.cancel,
            color: _isSeriesDone(seriesData)
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _navigateToExerciseDetails(
      Map<String, dynamic> exercise, List<Map<String, dynamic>> exercises,
      [int startIndex = 0]) {
    if (!mounted) return;
    
    final extra = {
      'programId': widget.programId,
      'weekId': widget.weekId,
      'workoutId': widget.workoutId,
      'exerciseId': exercise['id'],
      'userId': widget.userId,
      'superSetExercises': exercises,
      'superSetExerciseIndex': exercises.indexWhere((e) => e['id'] == exercise['id']),
      'seriesList': exercise['series'],
      'startIndex': startIndex
    };
    
    context.pushNamed('exercise_details', extra: extra);
  }

  void _showChangeExerciseDialog(
      BuildContext context, Map<String, dynamic> currentExercise) {
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

  Future<void> _updateExercise(
      Map<String, dynamic> currentExercise, Exercise newExercise) async {
    final exerciseIndex = ref
        .read(exercisesProvider.notifier)
        .state
        .indexWhere((e) => e['id'] == currentExercise['id']);

    if (exerciseIndex != -1) {
      final updatedExercises =
          List<Map<String, dynamic>>.from(ref.read(exercisesProvider));
      updatedExercises[exerciseIndex] = {
        ...updatedExercises[exerciseIndex],
        'name': newExercise.name,
        'exerciseId': newExercise.exerciseId ?? '',
        'type': newExercise.type,
        'variant': newExercise.variant,
      };

      ref.read(exercisesProvider.notifier).state = updatedExercises;

      await _recalculateWeights(
          updatedExercises[exerciseIndex], newExercise.exerciseId ?? '');

      await _workoutService.updateExercise(currentExercise['id'], {
        'name': newExercise.name,
        'exerciseId': newExercise.exerciseId ?? '',
        'type': newExercise.type,
        'variant': newExercise.variant,
      });
    }
  }

  Future<void> _recalculateWeights(
      Map<String, dynamic> exercise, String newExerciseId) async {
    final exerciseRecordService = ref.read(exerciseRecordServiceProvider);

    // Ottieni l'originalExerciseId dalle serie
    final series = exercise['series'] as List<dynamic>;
    final originalExerciseId = series.isNotEmpty
        ? (series.first as Map<String, dynamic>)['originalExerciseId'] ??
            newExerciseId
        : newExerciseId;

    final recordsStream = exerciseRecordService
        .getExerciseRecords(
          userId: widget.userId,
          exerciseId: originalExerciseId,
        )
        .map((records) => records.isNotEmpty
            ? records.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
            : null);

    final latestRecord = await recordsStream.first;

    num latestMaxWeight = 0.0;
    if (latestRecord != null) {
      latestMaxWeight = latestRecord.maxWeight;
    } else {
      latestMaxWeight = 0.0;
    }

    // Ensure we have a weight notifier for this exercise
    _weightNotifiers[exercise['id']] ??= ValueNotifier(0.0);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => SeriesDialog(
        exerciseRecordService: _exerciseRecordService,
        athleteId: widget.userId,
        exerciseId: exercise['id'],
        exerciseType: exercise['type'] ?? 'weight',
        weekIndex: 0, // Not relevant in this context
        exercise: Exercise.fromMap(exercise),
        currentSeriesGroup: series
            .map((s) => Series.fromMap(s as Map<String, dynamic>))
            .toList(),
        latestMaxWeight: latestMaxWeight.toDouble(),
        weightNotifier: _weightNotifiers[exercise['id']]!,
      ),
    );
  }

  void _showSeriesEditDialog(
      Map<String, dynamic> exercise, List<Map<String, dynamic>> series) async {
    final colorScheme = Theme.of(context).colorScheme;

    // Convert the series data to Series model
    final List<Series> seriesList =
        series.map((s) => Series.fromMap(s)).toList();

    final originalExerciseId = seriesList.first.originalExerciseId;
    debugPrint('originalExerciseId: $originalExerciseId');

    // Create a stream for the exercise records
    final recordsStream = _exerciseRecordService
        .getExerciseRecords(
          userId: widget.userId,
          exerciseId: originalExerciseId ?? exercise['id'],
        )
        .map((records) => records.isNotEmpty
            ? records.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
            : null);

    // Get the latest record
    final latestRecord = await recordsStream.first;

    num latestMaxWeight = 0.0;
    if (latestRecord != null) {
      latestMaxWeight = latestRecord.maxWeight;
    } else {
      latestMaxWeight = 0.0;
    }

    // Ensure we have a weight notifier for this exercise
    _weightNotifiers[exercise['id']] ??= ValueNotifier(0.0);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => SeriesDialog(
        exerciseRecordService: _exerciseRecordService,
        athleteId: widget.userId,
        exerciseId: exercise['id'],
        exerciseType: exercise['type'] ?? 'weight',
        weekIndex: 0, // Not relevant in this context
        exercise: Exercise.fromMap(exercise),
        currentSeriesGroup: seriesList,
        latestMaxWeight: latestMaxWeight.toDouble(),
        weightNotifier: _weightNotifiers[exercise['id']]!,
      ),
    );
  }

  void _showEditSeriesDialog(
      Map<String, dynamic> exercise, List<Map<String, dynamic>> series) {
    _showSeriesEditDialog(exercise, series);
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
        ? weightDone >= weight &&
            (weightDone <= maxWeight || weightDone > maxWeight)
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
