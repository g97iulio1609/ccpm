import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/progressions_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/week_model.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';

class ProgressionControllers {
  final TextEditingController reps;
  final TextEditingController sets;
  final TextEditingController intensity;
  final TextEditingController rpe;
  final TextEditingController weight;
  final FocusNode repsFocusNode;
  final FocusNode setsFocusNode;
  final FocusNode intensityFocusNode;
  final FocusNode rpeFocusNode;
  final FocusNode weightFocusNode;

  ProgressionControllers({
    required this.reps,
    required this.sets,
    required this.intensity,
    required this.rpe,
    required this.weight,
    FocusNode? repsFocusNode,
    FocusNode? setsFocusNode,
    FocusNode? intensityFocusNode,
    FocusNode? rpeFocusNode,
    FocusNode? weightFocusNode,
  }) : repsFocusNode = repsFocusNode ?? FocusNode(),
       setsFocusNode = setsFocusNode ?? FocusNode(),
       intensityFocusNode = intensityFocusNode ?? FocusNode(),
       rpeFocusNode = rpeFocusNode ?? FocusNode(),
       weightFocusNode = weightFocusNode ?? FocusNode();

  void dispose() {
    reps.dispose();
    sets.dispose();
    intensity.dispose();
    rpe.dispose();
    weight.dispose();
    repsFocusNode.dispose();
    setsFocusNode.dispose();
    intensityFocusNode.dispose();
    rpeFocusNode.dispose();
    weightFocusNode.dispose();
  }
}

final progressionControllersProvider = StateNotifierProvider<ProgressionControllersNotifier, List<List<List<ProgressionControllers>>>>((ref) {
  return ProgressionControllersNotifier();
});

class ProgressionControllersNotifier extends StateNotifier<List<List<List<ProgressionControllers>>>> {
  ProgressionControllersNotifier() : super([]);

void initialize(List<List<WeekProgression>> weekProgressions) {
  state = weekProgressions.map((week) => 
    week.map((session) => 
      _groupSeries(session.series).map((group) => ProgressionControllers(
        reps: TextEditingController(text: group.first.reps.toString()),
        sets: TextEditingController(text: group.length.toString()),
        intensity: TextEditingController(text: group.first.intensity),
        rpe: TextEditingController(text: group.first.rpe),
        weight: TextEditingController(text: group.first.weight.toString()),
        repsFocusNode: FocusNode(),
        setsFocusNode: FocusNode(),
        intensityFocusNode: FocusNode(),
        rpeFocusNode: FocusNode(),
        weightFocusNode: FocusNode(),
      )).toList()
    ).toList()
  ).toList();
}

  void updateControllers(int weekIndex, int sessionIndex, int groupIndex, Series series) {
    if (weekIndex >= 0 && weekIndex < state.length &&
        sessionIndex >= 0 && sessionIndex < state[weekIndex].length &&
        groupIndex >= 0 && groupIndex < state[weekIndex][sessionIndex].length) {
      final controllers = state[weekIndex][sessionIndex][groupIndex];
      controllers.reps.text = series.reps.toString();
      controllers.sets.text = series.sets.toString();
      controllers.intensity.text = series.intensity;
      controllers.rpe.text = series.rpe;
      controllers.weight.text = series.weight.toString();
    }
  }

void addControllers(int weekIndex, int sessionIndex, int groupIndex, Series series) {
  if (weekIndex >= 0 && weekIndex < state.length &&
      sessionIndex >= 0 && sessionIndex < state[weekIndex].length) {
    final newControllers = ProgressionControllers(
      reps: TextEditingController(text: series.reps == 0 ? '' : series.reps.toString()),
      sets: TextEditingController(text: series.sets.toString()),
      intensity: TextEditingController(text: series.intensity),
      rpe: TextEditingController(text: series.rpe),
      weight: TextEditingController(text: series.weight == 0.0 ? '' : series.weight.toString()),
    );
    
    // Crea una nuova copia dello stato mantenendo la tipizzazione
    final newState = state.map((week) => 
      week.map((session) => 
        List<ProgressionControllers>.from(session)
      ).toList()
    ).toList();
    
    // Inserisci i nuovi controller nella posizione corretta
    newState[weekIndex][sessionIndex].insert(groupIndex, newControllers);
    
    // Aggiorna lo stato
    state = newState;
  }
}

  void removeControllers(int weekIndex, int sessionIndex, int groupIndex) {
    if (weekIndex >= 0 && weekIndex < state.length &&
        sessionIndex >= 0 && sessionIndex < state[weekIndex].length &&
        groupIndex >= 0 && groupIndex < state[weekIndex][sessionIndex].length) {
      state[weekIndex][sessionIndex][groupIndex].dispose();
      state[weekIndex][sessionIndex].removeAt(groupIndex);
    }
  }

  List<List<Series>> _groupSeries(List<Series> series) {
    final groupedSeries = <List<Series>>[];
    List<Series> currentGroup = [];

    for (int i = 0; i < series.length; i++) {
      final currentSeries = series[i];
      if (i == 0 || currentSeries.reps != series[i - 1].reps || currentSeries.weight != series[i - 1].weight) {
        if (currentGroup.isNotEmpty) {
          groupedSeries.add(currentGroup);
          currentGroup = [];
        }
        currentGroup.add(currentSeries);
      } else {
        currentGroup.add(currentSeries);
      }
    }

    if (currentGroup.isNotEmpty) {
      groupedSeries.add(currentGroup);
    }

    return groupedSeries;
  }

  @override
  void dispose() {
    for (var week in state) {
      for (var session in week) {
        for (var controller in session) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }
}

class ProgressionsList extends ConsumerStatefulWidget {
  final String exerciseId;
  final Exercise? exercise;
  final num latestMaxWeight;

  const ProgressionsList({
    super.key,
    required this.exerciseId,
    this.exercise,
    required this.latestMaxWeight,
  });

  @override
  ConsumerState<ProgressionsList> createState() => _ProgressionsListState();
}

class _ProgressionsListState extends ConsumerState<ProgressionsList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeControllers());
  }

  void _initializeControllers() {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);
    ref.read(progressionControllersProvider.notifier).initialize(weekProgressions);
  }

@override
Widget build(BuildContext context) {
  super.build(context);
  final programController = ref.watch(trainingProgramControllerProvider);
  final controllers = ref.watch(progressionControllersProvider);
  final colorScheme = Theme.of(context).colorScheme;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);

  // Verifica se controllers è vuoto
  if (controllers.isEmpty) {
    // Se è vuoto, inizializza i controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressionControllersProvider.notifier).initialize(weekProgressions);
    });
    
    // Mostra un indicatore di caricamento mentre i controller vengono inizializzati
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  return Scaffold(
    backgroundColor: colorScheme.surface,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: weekProgressions.length,
              itemBuilder: (context, weekIndex) {
                // Verifica se l'indice weekIndex è valido per controllers
                if (weekIndex >= controllers.length) {
                  return const SizedBox.shrink(); // O gestisci questo caso come preferisci
                }
                return _buildWeekItem(
                  weekIndex, 
                  weekProgressions[weekIndex], 
                  controllers[weekIndex], 
                  isDarkMode, 
                  colorScheme
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSaveButton(isDarkMode, colorScheme),
        ],
      ),
    ),
  );
}

 Widget _buildWeekItem(
  int weekIndex, 
  List<WeekProgression> weekProgression, 
  List<List<ProgressionControllers>> weekControllers, 
  bool isDarkMode, 
  ColorScheme colorScheme
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(
          'Week ${weekIndex + 1}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
        ),
      ),
      ...weekProgression.asMap().entries.map((entry) {
        final sessionIndex = entry.key;
        final session = entry.value;
        return _buildSessionItem(
          weekIndex, 
          sessionIndex, 
          session, 
          weekControllers[sessionIndex], 
          isDarkMode, 
          colorScheme
        );
      }),
    ],
  );
}

Widget _buildSessionItem(
  int weekIndex, 
  int sessionIndex, 
  WeekProgression session, 
  List<ProgressionControllers> sessionControllers, 
  bool isDarkMode, 
  ColorScheme colorScheme
) {
  final groupedSeries = _groupSeries(session.series);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          'Session ${sessionIndex + 1}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
        ),
      ),
      ...groupedSeries.asMap().entries.map((entry) {
        final groupIndex = entry.key;
        final seriesGroup = entry.value;
        return _buildSeriesItem(weekIndex, sessionIndex, groupIndex, seriesGroup, sessionControllers[groupIndex], isDarkMode, colorScheme);
      }),
    ],
  );
}


Widget _buildSeriesItem(int weekIndex, int sessionIndex, int groupIndex, List<Series> seriesGroup, ProgressionControllers controllers, bool isDarkMode, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: Slidable(
        key: ValueKey('$weekIndex-$sessionIndex-$groupIndex'),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _addSeriesGroup(weekIndex, sessionIndex, groupIndex),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.add,
              label: 'Add',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _removeSeriesGroup(weekIndex, sessionIndex, groupIndex),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          color: isDarkMode ? colorScheme.surface : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeriesFields(weekIndex, sessionIndex, groupIndex, seriesGroup.first, controllers),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSeriesFields(int weekIndex, int sessionIndex, int groupIndex, Series series, ProgressionControllers controllers) {
  return Row(
    children: [
      _buildTextField(
        controller: controllers.reps,
        focusNode: controllers.repsFocusNode,
        labelText: 'Reps',
        keyboardType: TextInputType.number,
        onChanged: (value) => _updateSeries(weekIndex, sessionIndex, groupIndex, reps: int.tryParse(value) ?? 0),
      ),
      _buildTextField(
        controller: controllers.sets,
        focusNode: controllers.setsFocusNode,
        labelText: 'Sets',
        keyboardType: TextInputType.number,
        onChanged: (value) => _updateSeries(weekIndex, sessionIndex, groupIndex, sets: int.tryParse(value) ?? 1),
      ),
      _buildTextField(
        controller: controllers.intensity,
        focusNode: controllers.intensityFocusNode,
        labelText: '1RM%',
        keyboardType: TextInputType.number,
        onChanged: (value) {
          _updateSeries(weekIndex, sessionIndex, groupIndex, intensity: value);
          _updateWeightFromIntensity(weekIndex, sessionIndex, groupIndex, value);
        },
      ),
      _buildTextField(
        controller: controllers.rpe,
        focusNode: controllers.rpeFocusNode,
        labelText: 'RPE',
        keyboardType: TextInputType.number,
        onChanged: (value) {
          _updateSeries(weekIndex, sessionIndex, groupIndex, rpe: value);
          _updateWeightFromRPE(weekIndex, sessionIndex, groupIndex, value, series.reps);
        },
      ),
      _buildTextField(
        controller: controllers.weight,
        focusNode: controllers.weightFocusNode,
        labelText: 'Weight',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          final updatedWeight = double.tryParse(value) ?? 0;
          _updateSeries(weekIndex, sessionIndex, groupIndex, weight: updatedWeight);
          _updateIntensityFromWeight(weekIndex, sessionIndex, groupIndex, updatedWeight);
        },
      ),
    ],
  );
}
Widget _buildTextField({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String labelText,
  required TextInputType keyboardType,
  required Function(String) onChanged,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;

  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: isDarkMode ? colorScheme.surface : Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? colorScheme.onSurface.withOpacity(0.12) : colorScheme.onSurface.withOpacity(0.12),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? colorScheme.primary : colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          final cursorPosition = controller.selection.base.offset;
          onChanged(value);
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: cursorPosition),
          );
        },
      ),
    ),
  );
}
  void _updateSeries(int weekIndex, int sessionIndex, int groupIndex, {int? reps, int? sets, String? intensity, String? rpe, double? weight}) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);

    if (weekIndex >= 0 && weekIndex < weekProgressions.length &&
        sessionIndex >= 0 && sessionIndex < weekProgressions[weekIndex].length) {
      final groupedSeries = _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        final updatedGroup = groupedSeries[groupIndex].map((series) => series.copyWith(
          reps: reps ?? series.reps,
          sets: sets ?? series.sets,
          intensity: intensity ?? series.intensity,
          rpe: rpe ?? series.rpe,
          weight: weight ?? series.weight,
        )).toList();

        groupedSeries[groupIndex] = updatedGroup;
        weekProgressions[weekIndex][sessionIndex].series = groupedSeries.expand((group) => group).toList();
        _updateProgressionsWithNewSeries(weekProgressions);
        ref.read(progressionControllersProvider.notifier).updateControllers(weekIndex, sessionIndex, groupIndex, updatedGroup.first);
      }
    }
  }

  void _updateProgressionsWithNewSeries(List<List<WeekProgression>> weekProgressions) {
    ref.read(trainingProgramControllerProvider).updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);
  }

void _addSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
  final programController = ref.read(trainingProgramControllerProvider);
  final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);
  final controllersNotifier = ref.read(progressionControllersProvider.notifier);

  if (weekIndex >= 0 && weekIndex < weekProgressions.length &&
      sessionIndex >= 0 && sessionIndex < weekProgressions[weekIndex].length) {
    final currentSession = weekProgressions[weekIndex][sessionIndex];
    final groupedSeries = _groupSeries(currentSession.series);

    if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
      // Crea una nuova serie con valori predefiniti
      final newSeries = Series(
        serieId: generateRandomId(16).toString(),
        reps: 0,
        sets: 1,
        intensity: '',
        rpe: '',
        weight: 0.0,
        order: groupedSeries.length + 1,
        done: false,
        reps_done: 0,
        weight_done: 0.0,
      );

      // Inserisci il nuovo gruppo di serie dopo il gruppo corrente
      groupedSeries.insert(groupIndex + 1, [newSeries]);

      // Aggiorna le serie della sessione corrente
      currentSession.series = groupedSeries.expand((group) => group).toList();

      // Aggiorna le progressioni
      _updateProgressionsWithNewSeries(weekProgressions);

      // Aggiungi nuovi controller per il nuovo gruppo di serie
      controllersNotifier.addControllers(weekIndex, sessionIndex, groupIndex + 1, newSeries);

      // Aggiorna lo stato per ricostruire la UI
      setState(() {});
    }
  }
}

  void _removeSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);

    if (weekIndex >= 0 && weekIndex < weekProgressions.length &&
        sessionIndex >= 0 && sessionIndex < weekProgressions[weekIndex].length) {
      final groupedSeries = _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        groupedSeries.removeAt(groupIndex);
        weekProgressions[weekIndex][sessionIndex].series = groupedSeries.expand((group) => group).toList();
        _updateProgressionsWithNewSeries(weekProgressions);
        ref.read(progressionControllersProvider.notifier).removeControllers(weekIndex, sessionIndex, groupIndex);
      }
    }
  }

  void _updateWeightFromIntensity(int weekIndex, int sessionIndex, int groupIndex, String intensity) {
    final controllers = ref.read(progressionControllersProvider);
    if (weekIndex >= 0 && weekIndex < controllers.length &&
        sessionIndex >= 0 && sessionIndex < controllers[weekIndex].length &&
        groupIndex >= 0 && groupIndex < controllers[weekIndex][sessionIndex].length) {
      final weightController = controllers[weekIndex][sessionIndex][groupIndex].weight;
      final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(
        widget.latestMaxWeight.toDouble(),
        double.tryParse(intensity) ?? 0,
      );
      final roundedWeight = SeriesUtils.roundWeight(calculatedWeight, widget.exercise?.type);
      weightController.text = roundedWeight.toStringAsFixed(2);
      _updateSeries(weekIndex, sessionIndex, groupIndex, weight: roundedWeight);
    }
  }

  void _updateWeightFromRPE(int weekIndex, int sessionIndex, int groupIndex, String rpe, int reps) {
    final controllers = ref.read(progressionControllersProvider);
    if (weekIndex >= 0 && weekIndex < controllers.length &&
        sessionIndex >= 0 && sessionIndex < controllers[weekIndex].length &&
        groupIndex >= 0 && groupIndex < controllers[weekIndex][sessionIndex].length) {
      final weightController = controllers[weekIndex][sessionIndex][groupIndex].weight;
      final intensityController = controllers[weekIndex][sessionIndex][groupIndex].intensity;
      
      SeriesUtils.updateWeightFromRPE(
        TextEditingController(text: reps.toString()),
        weightController,
        TextEditingController(text: rpe),
        intensityController,
        widget.exercise?.type ?? '',
        widget.latestMaxWeight,
        ValueNotifier<double>(0.0),
      );
      
      _updateSeries(
        weekIndex,
        sessionIndex,
        groupIndex,
        weight: double.tryParse(weightController.text) ?? 0,
        intensity: intensityController.text,
      );
    }
  }

  void _updateIntensityFromWeight(int weekIndex, int sessionIndex, int groupIndex, double weight) {
    final controllers = ref.read(progressionControllersProvider);
    if (weekIndex >= 0 && weekIndex < controllers.length &&
        sessionIndex >= 0 && sessionIndex < controllers[weekIndex].length &&
        groupIndex >= 0 && groupIndex < controllers[weekIndex][sessionIndex].length) {
      final intensityController = controllers[weekIndex][sessionIndex][groupIndex].intensity;
      final calculatedIntensity = SeriesUtils.calculateIntensityFromWeight(weight, widget.latestMaxWeight.toDouble());
      intensityController.text = calculatedIntensity.toStringAsFixed(2);
      _updateSeries(weekIndex, sessionIndex, groupIndex, intensity: intensityController.text);
    }
  }

  List<List<WeekProgression>> _buildWeekProgressions(List<Week> weeks, Exercise exercise) {
    return List.generate(weeks.length, (weekIndex) {
      final week = weeks[weekIndex];
      return week.workouts.map((workout) {
        final exerciseInWorkout = workout.exercises.firstWhere(
          (e) => e.exerciseId == exercise.exerciseId,
          orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
        );

        final existingProgressions = exerciseInWorkout.weekProgressions;
        WeekProgression? sessionProgression;
        if (existingProgressions.isNotEmpty && existingProgressions.length > weekIndex) {
          sessionProgression = existingProgressions[weekIndex].firstWhere(
            (progression) => progression.sessionNumber == workout.order,
            orElse: () => WeekProgression(weekNumber: weekIndex + 1, sessionNumber: workout.order, series: []),
          );
        }

        if (sessionProgression != null && sessionProgression.series.isNotEmpty) {
          return sessionProgression;
        } else {
          return WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: workout.order,
            series: exerciseInWorkout.series,
          );
        }
      }).toList();
    });
  }

  List<List<Series>> _groupSeries(List<Series> series) {
    final groupedSeries = <List<Series>>[];
    List<Series> currentGroup = [];

    for (int i = 0; i < series.length; i++) {
      final currentSeries = series[i];
      if (i == 0 || currentSeries.reps != series[i - 1].reps || currentSeries.weight != series[i - 1].weight) {
        if (currentGroup.isNotEmpty) {
          groupedSeries.add(currentGroup);
          currentGroup = [];
        }
        currentGroup.add(currentSeries);
      } else {
        currentGroup.add(currentSeries);
      }
    }

    if (currentGroup.isNotEmpty) {
      groupedSeries.add(currentGroup);
    }

    return groupedSeries;
  }

  Widget _buildSaveButton(bool isDarkMode, ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: _handleSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.primary,
        foregroundColor: isDarkMode ? colorScheme.onPrimary : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Save',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

Future<void> _handleSave() async {
  final programController = ref.read(trainingProgramControllerProvider);
  final controllers = ref.read(progressionControllersProvider);
  
  try {
    List<List<WeekProgression>> updatedWeekProgressions = [];
    
    for (int weekIndex = 0; weekIndex < controllers.length; weekIndex++) {
      List<WeekProgression> weekProgressions = [];
      for (int sessionIndex = 0; sessionIndex < controllers[weekIndex].length; sessionIndex++) {
        List<Series> updatedSeries = [];
        for (int groupIndex = 0; groupIndex < controllers[weekIndex][sessionIndex].length; groupIndex++) {
          final groupControllers = controllers[weekIndex][sessionIndex][groupIndex];
          final sets = int.tryParse(groupControllers.sets.text) ?? 1;
          final reps = int.tryParse(groupControllers.reps.text) ?? 0;
          final intensity = groupControllers.intensity.text;
          final rpe = groupControllers.rpe.text;
          final weight = double.tryParse(groupControllers.weight.text) ?? 0.0;
          
          for (int i = 0; i < sets; i++) {
            final series = Series(
              serieId: generateRandomId(16).toString(), // Assicurati di gestire correttamente gli ID esistenti
              reps: reps,
              sets: 1, // Ogni Series rappresenta un singolo set
              intensity: intensity,
              rpe: rpe,
              weight: weight,
              order: updatedSeries.length + 1, // L'ordine è basato sulla posizione nella lista
              done: false,
              reps_done: 0,
              weight_done: 0.0,
            );
            updatedSeries.add(series);
          }
        }
        weekProgressions.add(WeekProgression(
          weekNumber: weekIndex + 1,
          sessionNumber: sessionIndex + 1,
          series: updatedSeries,
        ));
      }
      updatedWeekProgressions.add(weekProgressions);
    }
    
    programController.updateWeekProgressions(updatedWeekProgressions, widget.exercise!.exerciseId!);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progressions saved successfully')),
    );
    Navigator.of(context).pop();
  } catch (e) {
    debugPrint('ERROR: Failed to save changes: $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving progressions: $e')),
    );
  }
}
}