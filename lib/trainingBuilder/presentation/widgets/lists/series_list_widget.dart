import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/providers/training_providers.dart';
import '../cards/series_card.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import '../forms/series_form_fields.dart';

class SeriesListWidget extends ConsumerStatefulWidget {
  final Exercise exercise;
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;
  final int exerciseIndex;
  final num latestMaxWeight;

  const SeriesListWidget({
    super.key,
    required this.exercise,
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    required this.exerciseIndex,
    required this.latestMaxWeight,
  });

  @override
  ConsumerState<SeriesListWidget> createState() => _SeriesListWidgetState();
}

class _SeriesListWidgetState extends ConsumerState<SeriesListWidget> {
  final Map<String, bool> _expansionStates = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupedSeries = _groupSeries(widget.exercise.series);
    final isWide = MediaQuery.of(context).size.width >= 900;

    final listView = ListView.builder(
      shrinkWrap: !isWide,
      physics: isWide ? null : const NeverScrollableScrollPhysics(),
      itemCount: groupedSeries.length,
      itemBuilder: (context, index) {
        final seriesGroup = groupedSeries[index];
        final key = 'series_group_${index}_${seriesGroup.first.serieId}';
        final isExpanded = _expansionStates[key] ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card con badge del numero di serie nel gruppo
            Stack(
              children: [
                SeriesCard(
                  series: seriesGroup.first,
                  maxWeight: widget.latestMaxWeight,
                  exerciseName: widget.exercise.name,
                  exerciseType: widget.exercise.type,
                  isExpanded: isExpanded,
                  showExpandedContent: false,
                  onExpansionChanged: () {
                    setState(() {
                      _expansionStates[key] = !isExpanded;
                    });
                  },
                  onEdit: () => _editSeriesGroup(seriesGroup),
                  onDelete: () => _deleteSeriesGroup(seriesGroup),
                  onDuplicate: () => _duplicateSeriesGroup(seriesGroup),
                  onSeriesUpdated: (updatedSeries) => _updateSeries(updatedSeries),
                ),
                Positioned(
                  right: 16,
                  top: -12, // più in alto per un posizionamento migliore
                  child: _GroupCountBadge(count: seriesGroup.length),
                ),
              ],
            ),
            if (isExpanded)
              Padding(
                padding: EdgeInsets.only(top: AppTheme.spacing.xs),
                child: _GroupedSeriesExpanded(
                  group: seriesGroup,
                  maxWeight: widget.latestMaxWeight,
                  exerciseName: widget.exercise.name,
                  onSeriesUpdated: (updated) => _updateSeries(updated),
                ),
              ),
          ],
        );
      },
    );

    return Column(
      children: [
        if (groupedSeries.isNotEmpty) isWide ? Expanded(child: listView) : listView,
        SizedBox(height: AppTheme.spacing.md),
        _buildActionButtons(theme, colorScheme),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return AppButton(
      label: isSmallScreen ? 'Add' : 'Aggiungi Serie',
      icon: Icons.add,
      onPressed: _addNewSeries,
      variant: AppButtonVariant.primary,
      size: isSmallScreen ? AppButtonSize.sm : AppButtonSize.md,
      block: true,
    );
  }

  List<List<Series>> _groupSeries(List<Series> series) {
    if (series.isEmpty) return [];

    final groupedSeries = <List<Series>>[];
    List<Series> currentGroup = [series[0]];

    for (int i = 1; i < series.length; i++) {
      final currentSeries = series[i];
      final previousSeries = series[i - 1];

      if (_areSeriesEqual(currentSeries, previousSeries)) {
        currentGroup.add(currentSeries);
      } else {
        groupedSeries.add(List<Series>.from(currentGroup));
        currentGroup = [currentSeries];
      }
    }

    if (currentGroup.isNotEmpty) {
      groupedSeries.add(currentGroup);
    }

    return groupedSeries;
  }

  bool _areSeriesEqual(Series a, Series b) {
    return a.reps == b.reps &&
        a.maxReps == b.maxReps &&
        a.intensity == b.intensity &&
        a.maxIntensity == b.maxIntensity &&
        a.rpe == b.rpe &&
        a.maxRpe == b.maxRpe &&
        a.weight == b.weight &&
        a.maxWeight == b.maxWeight;
  }

  void _editSeriesGroup(List<Series> seriesGroup) {
    // Implementa la modifica del gruppo di serie
    widget.controller.editSeries(
      widget.weekIndex,
      widget.workoutIndex,
      widget.exerciseIndex,
      seriesGroup,
      context,
      widget.exercise.type,
      widget.latestMaxWeight,
    );
  }

  void _deleteSeriesGroup(List<Series> seriesGroup) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: const Text('Elimina Gruppo Serie'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          FilledButton(
            onPressed: () {
              final updated = widget.exercise.series
                  .where((s) => !seriesGroup.contains(s))
                  .toList();
              ref
                  .read(trainingProgramControllerProvider.notifier)
                  .updateSeries(
                    widget.weekIndex,
                    widget.workoutIndex,
                    widget.exerciseIndex,
                    updated,
                  );
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Elimina'),
          ),
        ],
        child: const Text('Sei sicuro di voler eliminare questo gruppo di serie?'),
      ),
    );
  }

  void _duplicateSeriesGroup(List<Series> seriesGroup) {
    final duplicatedSeries = seriesGroup
        .map(
          (series) => series.copyWith(
            serieId: DateTime.now().millisecondsSinceEpoch.toString(),
            order: widget.exercise.series.length + seriesGroup.indexOf(series) + 1,
          ),
        )
        .toList();

    final updated = List<Series>.from(widget.exercise.series)..addAll(duplicatedSeries);
    ref
        .read(trainingProgramControllerProvider.notifier)
        .updateSeries(widget.weekIndex, widget.workoutIndex, widget.exerciseIndex, updated);
    setState(() {});
  }

  void _addNewSeries() {
    widget.controller.addSeries(
      widget.weekIndex,
      widget.workoutIndex,
      widget.exerciseIndex,
      widget.exercise.type,
      context,
    );
  }



  void _updateSeries(Series updatedSeries) {
    final index = widget.exercise.series.indexWhere((s) => s.serieId == updatedSeries.serieId);

    if (index != -1) {
      final updated = List<Series>.from(widget.exercise.series);
      updated[index] = updatedSeries;
      ref
          .read(trainingProgramControllerProvider.notifier)
          .updateSeries(widget.weekIndex, widget.workoutIndex, widget.exerciseIndex, updated);
      setState(() {});
    }
  }

  // removed: no longer needed after immutability refactor
}

class _GroupCountBadge extends StatelessWidget {
  final int count;
  const _GroupCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        // Glassmorphism background con gradiente
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface.withValues(alpha: 0.9),
            cs.surfaceContainerHighest.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          // Ombra principale
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // Ombra interna per effetto vetro
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Highlight interno per effetto vetro
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.onSurface.withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Center(
          child: Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupedSeriesExpanded extends StatelessWidget {
  final List<Series> group;
  final num maxWeight;
  final String exerciseName;
  final ValueChanged<Series> onSeriesUpdated;

  const _GroupedSeriesExpanded({
    required this.group,
    required this.maxWeight,
    required this.exerciseName,
    required this.onSeriesUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: group.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
        itemBuilder: (context, idx) {
          final s = group[idx];
          return Padding(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  child: SeriesFormFields(
                    series: s,
                    maxWeight: maxWeight,
                    exerciseName: exerciseName,
                    onSeriesUpdated: onSeriesUpdated,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
