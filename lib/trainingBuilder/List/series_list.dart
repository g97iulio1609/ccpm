import 'package:alphanessone/services/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../controller/training_program_controller.dart';
import '../utility_functions.dart';
import '../dialog/reorder_dialog.dart';
import '../series_utils.dart';

final expansionStateProvider = StateNotifierProvider.autoDispose<
    ExpansionStateNotifier, Map<String, bool>>((ref) {
  return ExpansionStateNotifier();
});

class ExpansionStateNotifier extends StateNotifier<Map<String, bool>> {
  ExpansionStateNotifier() : super({});

  void toggleExpansionState(String key) {
    final currentState = state[key] ?? false;
    state = {
      ...state,
      key: !currentState,
    };
  }
}

class TrainingProgramSeriesList extends ConsumerStatefulWidget {
  final TrainingProgramController controller;
  final ExerciseRecordService exerciseRecordService;
  final int weekIndex;
  final int workoutIndex;
  final int exerciseIndex;
  final String exerciseType;

  const TrainingProgramSeriesList({
    required this.controller,
    required this.exerciseRecordService,
    required this.weekIndex,
    required this.workoutIndex,
    required this.exerciseIndex,
    required this.exerciseType,
    super.key,
  });

  @override
  TrainingProgramSeriesListState createState() => TrainingProgramSeriesListState();
}

class TrainingProgramSeriesListState extends ConsumerState<TrainingProgramSeriesList> {
  late num latestMaxWeight;

  @override
  void initState() {
    super.initState();
    _fetchLatestMaxWeight();
  }

  Future<void> _fetchLatestMaxWeight() async {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];
    final exerciseId = exercise.exerciseId;
    final athleteId = widget.controller.program.athleteId;

    latestMaxWeight = await SeriesUtils.getLatestMaxWeight(
      widget.exerciseRecordService,
      athleteId,
      exerciseId ?? '',
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.controller.program.weeks[widget.weekIndex].workouts[widget.workoutIndex];
    
    if (widget.exerciseIndex >= workout.exercises.length) {
      return const Text('Invalid exercise index');
    }
    
    final exercise = workout.exercises[widget.exerciseIndex];
    final groupedSeries = _groupSeries(exercise.series);
    final expansionState = ref.watch(expansionStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groupedSeries.length,
          itemBuilder: (context, index) {
            final item = groupedSeries[index];
            final key = 'series_group_$index';
            final isExpanded = expansionState[key] ?? false;

            if (item is List<Series>) {
              return _buildSeriesGroupCard(context, item, index, isExpanded, key);
            } else {
              return _buildSeriesCard(context, item as Series, index);
            }
          },
        ),
        TextButton(
          onPressed: () => _showReorderSeriesDialog(exercise.series),
          child: const Text('Riordina Serie'),
        ),
        Center(
          child: ElevatedButton(
            onPressed: () => widget.controller.addSeries(widget.weekIndex, widget.workoutIndex,
                widget.exerciseIndex, widget.exerciseType, context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Aggiungi Nuova Serie',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  List<dynamic> _groupSeries(List<Series> series) {
    final groupedSeries = <dynamic>[];
    for (int i = 0; i < series.length; i++) {
      final currentSeries = series[i];
      if (i == 0 ||
          currentSeries.reps != series[i - 1].reps ||
          currentSeries.weight != series[i - 1].weight) {
        groupedSeries.add([currentSeries]);
      } else {
        (groupedSeries.last as List<Series>).add(currentSeries);
      }
    }
    return groupedSeries;
  }

  Widget _buildSeriesGroupCard(
    BuildContext context,
    List<Series> seriesGroup,
    int groupIndex,
    bool isExpanded,
    String key,
  ) {
    final series = seriesGroup.first;
    return ExpansionTile(
      key: Key(key),
      initiallyExpanded: isExpanded,
      onExpansionChanged: (value) {
        ref.read(expansionStateProvider.notifier).toggleExpansionState(key);
      },
      title: Text(
        '${seriesGroup.length} serie${seriesGroup.length > 1 ? 's' : ''}, ${series.reps} reps x ${series.weight} kg',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: _buildSeriesGroupPopupMenu(context, seriesGroup, groupIndex),
      children: [
        for (int i = 0; i < seriesGroup.length; i++)
_buildSeriesCard(context, seriesGroup[i], groupIndex, i, () {
            seriesGroup.removeAt(i);
            widget.controller.updateSeries(widget.weekIndex, widget.workoutIndex, widget.exerciseIndex, seriesGroup);
          }, widget.exerciseType),
      ],
    );
  }

  Widget _buildSeriesGroupPopupMenu(
      BuildContext context, List<Series> seriesGroup, int groupIndex) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Modifica Tutte'),
          onTap: () => _showEditAllSeriesDialog(seriesGroup),
        ),
        PopupMenuItem(
          child: const Text('Elimina'),
          onTap: () => _showDeleteSeriesGroupDialog(seriesGroup, groupIndex),
        ),
      ],
    );
  }

  void _showDeleteSeriesGroupDialog(List<Series> seriesGroup, int groupIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Gruppo Di Serie'),
        content: const Text('Confermi Di Voler Eliminare Questo Gruppo Di Serie'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _deleteSeriesGroup(seriesGroup, groupIndex);
              Navigator.pop(context);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _deleteSeriesGroup(List<Series> seriesGroup, int groupIndex) {
    final exercise = widget.controller.program.weeks[widget.weekIndex].workouts[widget.workoutIndex]
        .exercises[widget.exerciseIndex];

    List<Series> seriesToRemove = List.from(seriesGroup);

    for (Series series in seriesToRemove) {
      if (series.serieId != null) {
        widget.controller.program.trackToDeleteSeries.add(series.serieId!);
      }
    }

    exercise.series.removeWhere((series) => seriesToRemove.contains(series));

    for (int i = 0; i < exercise.series.length; i++) {
      exercise.series[i].order = i + 1;
    }

    widget.controller.updateSeries(widget.weekIndex, widget.workoutIndex, widget.exerciseIndex, exercise.series);
  }

  Widget _buildSeriesCard(BuildContext context, Series series,
      [int? groupIndex, int? seriesIndex, VoidCallback? onRemove, String? exerciseType]) {
    return ListTile(
      title: Text(
        '${series.reps} reps x ${series.weight} kg',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text('RPE: ${series.rpe}, Intensity: ${series.intensity}'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            child: const Text('Modifica'),
            onTap: () {
              widget.controller.editSeries(
                widget.weekIndex,
                widget.workoutIndex,
                widget.exerciseIndex,
                series,
                context,
                exerciseType ?? '',
                latestMaxWeight,
              );
            },
          ),
          PopupMenuItem(
            child: const Text('Elimina'),
            onTap: () {
              if (onRemove != null) {
                onRemove();
              } else {
                widget.controller.removeSeries(widget.weekIndex, widget.workoutIndex, widget.exerciseIndex,
                    groupIndex ?? 0, seriesIndex ?? 0);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showReorderSeriesDialog(List<Series> series) {
    final seriesNames = series.map((s) {
      if (s.sets == 1) {
        return 'Series ${s.order}: ${s.reps} reps x ${s.weight} kg';
      } else {
        return 'Series Group ${s.order}: ${s.sets} sets, ${s.reps} reps x ${s.weight} kg';
      }
    }).toList();

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: seriesNames,
        onReorder: (oldIndex, newIndex) {
          widget.controller.reorderSeries(
              widget.weekIndex, widget.workoutIndex, widget.exerciseIndex, oldIndex, newIndex);
        },
      ),
    );
  }

  void _showEditAllSeriesDialog(List<Series> seriesGroup) {
    final series = seriesGroup.first;
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];

    final repsController = TextEditingController(text: series.reps.toString());
    final setsController = TextEditingController(text: seriesGroup.length.toString());
    final intensityController = TextEditingController(text: series.intensity);
    final rpeController = TextEditingController(text: series.rpe);
    final weightController = TextEditingController(text: series.weight.toString());

    FocusNode weightFocusNode = FocusNode();
    FocusNode intensityFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Modifica Tutte Le Serie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    onChanged: (_) {
                      SeriesUtils.updateRPE(
                        repsController,
                        weightController,
                        rpeController,
                        intensityController,
                        latestMaxWeight,
                      );
                    },
                  ),
                  TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sets'),
                  ),
                  TextField(
                    controller: intensityController,
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
                    focusNode: intensityFocusNode,
                    decoration: const InputDecoration(labelText: 'Intensità (%)'),
                    onChanged: (_) {
                      if (intensityFocusNode.hasFocus) {
                        SeriesUtils.updateWeightFromIntensity(
                          weightController,
                          intensityController,
                          exercise.type,
                          latestMaxWeight,
                          ValueNotifier<double>(0.0),
                        );
                      }
                    },
                  ),
                  TextField(
                    controller: rpeController,
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
                    decoration: const InputDecoration(labelText: 'RPE'),
                    onChanged: (_) {
                      SeriesUtils.updateWeightFromRPE(
                        repsController,
                        weightController,
                        rpeController,
                        intensityController,
                        exercise.type,
                        latestMaxWeight,
                        ValueNotifier<double>(0.0),
                      );
                    },
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
                    focusNode: weightFocusNode,
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    onChanged: (_) {
                      if (weightFocusNode.hasFocus) {
                        SeriesUtils.updateIntensityFromWeight(
                          weightController,
                          intensityController,
                          latestMaxWeight,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed: () {
                  final reps = int.parse(repsController.text);
                  final sets = int.parse(setsController.text);
                  final intensity = intensityController.text;
                  final rpe = rpeController.text;
                  final weight = double.parse(weightController.text);

                  _updateSeriesGroup(seriesGroup, reps, sets, intensity, rpe, weight);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      weightFocusNode.dispose();
      intensityFocusNode.dispose();
    });
  }

  void _updateSeriesGroup(List<Series> seriesGroup, int reps, int sets, String intensity, String rpe, double weight) {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];
    final seriesIndex = exercise.series.indexOf(seriesGroup.first);

    for (int i = 0; i < seriesGroup.length; i++) {
      final s = seriesGroup[i];
      s.reps = reps;
      s.sets = sets;
      s.intensity = intensity;
      s.rpe = rpe;
      s.weight = weight;
    }

    if (sets > seriesGroup.length) {
      for (int i = seriesGroup.length; i < sets; i++) {
        final newSeries = Series(
          serieId: generateRandomId(16).toString(),
          reps: reps,
          sets: 1,
          intensity: intensity,
          rpe: rpe,
          weight: weight,
          order: seriesGroup.first.order + i,
          done: false,
          reps_done: 0,
          weight_done: 0.0,
        );
        exercise.series.insert(seriesIndex + i, newSeries);
      }
    } else if (sets < seriesGroup.length) {
      for (int i = sets; i < seriesGroup.length; i++) {
        final removedSeries = exercise.series.removeAt(seriesIndex + sets);
        widget.controller.program.trackToDeleteSeries.add(removedSeries.serieId!);
      }
    }

    widget.controller.updateSeries(widget.weekIndex, widget.workoutIndex, widget.exerciseIndex, exercise.series);
  }
}