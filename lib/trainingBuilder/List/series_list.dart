import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../training_model.dart';
import '../controller/training_program_controller.dart';
import '../utility_functions.dart';
import '../../users_services.dart';
import '../reorder_dialog.dart';
import '../series_utils.dart';

final expansionStateProvider = StateNotifierProvider.autoDispose<
    ExpansionStateNotifier, Map<String, bool>>((ref) {
  return ExpansionStateNotifier();
});

class ExpansionStateNotifier extends StateNotifier<Map<String, bool>> {
  ExpansionStateNotifier() : super({});

  void toggleExpansionState(String key) {
    state = {
      ...state,
      key: !state[key]!,
    };
  }
}

class TrainingProgramSeriesList extends ConsumerWidget {
  final TrainingProgramController controller;
  final UsersService usersService;
  final int weekIndex;
  final int workoutIndex;
  final int exerciseIndex;
  final String exerciseType;

  const TrainingProgramSeriesList({
    required this.controller,
    required this.usersService,
    required this.weekIndex,
    required this.workoutIndex,
    required this.exerciseIndex,
    required this.exerciseType,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex]
        .exercises[exerciseIndex];
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
              return _buildSeriesGroupCard(context, item, index, isExpanded,
                  key, ref); // Passa ref come parametro
            } else {
              return _buildSeriesCard(context, item as Series, index);
            }
          },
        ),
        TextButton(
          onPressed: () => _showReorderSeriesDialog(context, exercise.series),
          child: const Text('Riordina Serie'),
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
    WidgetRef ref, // Aggiungi il parametro WidgetRef
  ) {
    final series = seriesGroup.first;
    return ExpansionTile(
      key: Key(key),
      initiallyExpanded: isExpanded,
      onExpansionChanged: (value) {
        ref.read(expansionStateProvider.notifier).toggleExpansionState(
            key); // Usa la variabile ref passata come parametro
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
            controller.notifyListeners();
          }, exerciseType),
      ],
    );
  }

  Widget _buildSeriesGroupPopupMenu(
      BuildContext context, List<Series> seriesGroup, int groupIndex) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Modifica Tutte'),
          onTap: () => _showEditAllSeriesDialog(context, seriesGroup),
        ),
        PopupMenuItem(
          child: const Text('Elimina'),
          onTap: () =>
              _showDeleteSeriesGroupDialog(context, seriesGroup, groupIndex),
        ),
      ],
    );
  }

  void _showDeleteSeriesGroupDialog(
      BuildContext context, List<Series> seriesGroup, int groupIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Gruppo Di Serie'),
        content:
            const Text('Confermi Di Voler Eliminare Questo Gruppo Di Serie'),
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
    final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex]
        .exercises[exerciseIndex];

    // Crea una copia delle serie da eliminare
    List<Series> seriesToRemove = List.from(seriesGroup);

    // Aggiungi gli ID delle serie da eliminare a trackToDeleteSeries
    for (Series series in seriesToRemove) {
      if (series.serieId != null) {
        controller.program.trackToDeleteSeries.add(series.serieId!);
      }
    }

    // Rimuovi le serie dall'elenco delle serie dell'esercizio
    exercise.series.removeWhere((series) => seriesToRemove.contains(series));

    // Aggiorna gli ordini delle serie rimanenti
    for (int i = 0; i < exercise.series.length; i++) {
      exercise.series[i].order = i + 1;
    }

    // Notifica il controller delle modifiche
    controller.notifyListeners();
  }

Widget _buildSeriesCard(BuildContext context, Series series,
    [int? groupIndex,
    int? seriesIndex,
    VoidCallback? onRemove,
    String? exerciseType]) {
  final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex]
      .exercises[exerciseIndex];
  final exerciseId = exercise.exerciseId;
  final athleteId = controller.program.athleteId;

  // Ottieni il latestMaxWeight corretto per l'esercizio
  late num latestMaxWeight;
  SeriesUtils.getLatestMaxWeight(
    usersService,
    athleteId,
    exerciseId ?? '',
  ).then((maxWeight) {
    latestMaxWeight = maxWeight;
  });

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
            controller.editSeries(
              weekIndex,
              workoutIndex,
              exerciseIndex,
              series,
              context,
              exerciseType ?? '',
              latestMaxWeight, // Passa il latestMaxWeight corretto
            );
          },
        ),
        PopupMenuItem(
          child: const Text('Elimina'),
          onTap: () {
            if (onRemove != null) {
              onRemove();
            } else {
              controller.removeSeries(weekIndex, workoutIndex, exerciseIndex,
                  groupIndex ?? 0, seriesIndex ?? 0);
            }
          },
        ),
      ],
    ),
  );
}

  void _showReorderSeriesDialog(BuildContext context, List<Series> series) {
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
          controller.reorderSeries(
              weekIndex, workoutIndex, exerciseIndex, oldIndex, newIndex);
        },
      ),
    );
  }

void _showEditAllSeriesDialog(
    BuildContext context, List<Series> seriesGroup) async {
  final series = seriesGroup.first;
  final exercise =
      controller.program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  final exerciseId = exercise.exerciseId;
  final athleteId = controller.program.athleteId;

  // Ottieni il latestMaxWeight corretto per l'esercizio
  late double? latestMaxWeight;
  await SeriesUtils.getLatestMaxWeight(
    usersService,
    athleteId,
    exerciseId ?? '',
  ).then((maxWeight) {
    latestMaxWeight = maxWeight as double?;
  });

  final repsController = TextEditingController(text: series.reps.toString());
  final setsController =
      TextEditingController(text: seriesGroup.length.toString());
  final intensityController = TextEditingController(text: series.intensity);
  final rpeController = TextEditingController(text: series.rpe);
  final weightController =
      TextEditingController(text: series.weight.toString());

  FocusNode weightFocusNode = FocusNode();
  FocusNode intensityFocusNode = FocusNode();

  final result = await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
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
                      latestMaxWeight as num, // Passa il latestMaxWeight corretto
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text.replaceAll(',', '.');
                      return newValue.copyWith(
                        text: text,
                        selection:
                            TextSelection.collapsed(offset: text.length),
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
                        latestMaxWeight as num, // Passa il latestMaxWeight corretto
                        ValueNotifier<double>(0.0),
                      );
                    }
                  },
                ),
                TextField(
                  controller: rpeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text.replaceAll(',', '.');
                      return newValue.copyWith(
                        text: text,
                        selection:
                            TextSelection.collapsed(offset: text.length),
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
                      latestMaxWeight as num, // Passa il latestMaxWeight corretto
                      ValueNotifier<double>(0.0),
                    );
                  },
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
                        selection:
                            TextSelection.collapsed(offset: text.length),
                      );
                    }),
                  ],
                  focusNode: weightFocusNode,
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  onChanged: (_) {
                    if (weightFocusNode.hasFocus) {
                      SeriesUtils().updateIntensityFromWeight(
                        weightController,
                        intensityController,
                        latestMaxWeight!, // Passa il latestMaxWeight corretto
                      );
                    }
                    SeriesUtils.updateRPE(
                      repsController,
                      weightController,
                      rpeController,
                      intensityController,
                      latestMaxWeight as num, // Passa il latestMaxWeight corretto
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    ),
  );

    weightFocusNode.dispose();
    intensityFocusNode.dispose();

    if (result == true) {
      final reps = int.parse(repsController.text);
      final sets = int.parse(setsController.text);
      final intensity = intensityController.text;
      final rpe = rpeController.text;
      final weight = double.parse(weightController.text);

      // Update the series within the group
      for (int i = 0; i < seriesGroup.length; i++) {
        final s = seriesGroup[i];
        s.reps = reps;
        s.intensity = intensity;
        s.rpe = rpe;
        s.weight = weight;
      }

      // Add or remove series to match the new sets count
      final exercise = controller.program.weeks[weekIndex]
          .workouts[workoutIndex].exercises[exerciseIndex];
      final seriesIndex = exercise.series.indexOf(seriesGroup.first);
      if (sets > seriesGroup.length) {
        for (int i = seriesGroup.length; i < sets; i++) {
          final newSeries = Series(
            serieId: generateRandomId(16).toString(),
            reps: reps,
            sets: 1,
            intensity: intensity,
            rpe: rpe,
            weight:weight,
            order: series.order + i,
            done: false,
            reps_done: 0,
            weight_done: 0.0,
          );
          exercise.series.insert(seriesIndex + i, newSeries);
        }
      } else if (sets < seriesGroup.length) {
        for (int i = sets; i < seriesGroup.length; i++) {
          final removedSeries = exercise.series.removeAt(seriesIndex + sets);
          controller.program.trackToDeleteSeries.add(removedSeries.serieId!);
        }
      }

      controller.notifyListeners();
    }
  }
}
