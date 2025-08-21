import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/Viewer/UI/workout_provider.dart' as workout_provider;
import 'package:alphanessone/Viewer/UI/widgets/workout_formatters.dart';
import 'package:alphanessone/Viewer/UI/widgets/workout_dialogs.dart';
import 'package:alphanessone/Viewer/UI/widgets/series_widgets.dart';

class SupersetCard extends ConsumerWidget {
  final List<Map<String, dynamic>> superSetExercises;
  final Function(Map<String, dynamic>, List<Map<String, dynamic>>) onNavigateToDetails;

  const SupersetCard({
    super.key,
    required this.superSetExercises,
    required this.onNavigateToDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isListMode = screenWidth < 600;

    final allSeriesCompleted = superSetExercises.every((exercise) {
      final series = List<Map<String, dynamic>>.from(exercise['series']);
      return series.every(
        (serie) => ref.read(workout_provider.workoutServiceProvider).isSeriesDone(serie),
      );
    });

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26), width: 1),
        boxShadow: AppTheme.elevations.small,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Column(
          children: [
            // Header della superserie
            _buildSupersetHeader(context, colorScheme),

            // Contenuto della superserie - gestione responsive migliorata
            if (isListMode)
              // Layout per mobile - più lineare e scrollabile
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!allSeriesCompleted) ...[
                      _buildSuperSetStartButton(context),
                      SizedBox(height: AppTheme.spacing.lg),
                    ],
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.spacing.xs,
                        horizontal: AppTheme.spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(77),
                        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                      ),
                      child: const SeriesHeaderRow(),
                    ),
                    SizedBox(height: AppTheme.spacing.sm),
                    // Serie ottimizzate per mobile
                    ..._buildMobileSuperSetSeriesRows(context, ref, colorScheme),
                  ],
                ),
              )
            else
              // Layout per desktop/tablet
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!allSeriesCompleted) ...[
                          _buildSuperSetStartButton(context),
                          SizedBox(height: AppTheme.spacing.lg),
                        ],
                        const SeriesHeaderRow(),
                        SizedBox(height: AppTheme.spacing.sm),
                        ..._buildSeriesRows(context, ref),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupersetHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        border: Border(bottom: BorderSide(color: colorScheme.outline.withAlpha(26))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_work, color: colorScheme.primary, size: 20),
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                'Super Set',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.md),
          // Lista esercizi della superserie - ottimizzata per mobile
          Column(
            children: superSetExercises
                .asMap()
                .entries
                .map(
                  (entry) =>
                      _buildSuperSetExerciseName(entry.key, entry.value, context, colorScheme),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperSetExerciseName(
    int index,
    Map<String, dynamic> exercise,
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.xs),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index), // A, B, C...
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: Text(
              '${exercise['name']} ${exercise['variant'] ?? ''}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperSetStartButton(BuildContext context) {
    return AppButton(
      label: 'START',
      onPressed: () {
        // Trova il primo esercizio con almeno una serie non completata/compilata
        final firstNotDoneExerciseIndex = superSetExercises.indexWhere(
          (exercise) => (exercise['series'] as List).any(
            (series) => !WorkoutFormatters.hasAttemptedSeries(series),
          ),
        );

        if (firstNotDoneExerciseIndex == -1) {
          // Tutte le serie risultano già segnate: non facciamo nulla
          return;
        }

        onNavigateToDetails(superSetExercises[firstNotDoneExerciseIndex], superSetExercises);
      },
      variant: AppButtonVariant.primary,
      size: AppButtonSize.md,
      block: true,
    );
  }

  List<Widget> _buildSeriesRows(BuildContext context, WidgetRef ref) {
    final maxSeriesCount = superSetExercises
        .map((exercise) => exercise['series'].length)
        .reduce((a, b) => a > b ? a : b);

    return List.generate(maxSeriesCount, (seriesIndex) {
      return Column(
        children: [
          Row(
            children: [
              _buildSeriesIndexText(seriesIndex, context, 1),
              ..._buildSuperSetSeriesColumns(seriesIndex, context, ref),
            ],
          ),
          if (seriesIndex < maxSeriesCount - 1) const Divider(height: 16, thickness: 1),
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
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildSuperSetSeriesColumns(int seriesIndex, BuildContext context, WidgetRef ref) {
    return [
      _buildSuperSetSeriesColumn(seriesIndex, 'reps', context, ref, 2),
      _buildSuperSetSeriesColumn(seriesIndex, 'weight', context, ref, 2),
      _buildSuperSetSeriesDoneColumn(seriesIndex, context, ref, 1),
    ];
  }

  Widget _buildSuperSetSeriesColumn(
    int seriesIndex,
    String field,
    BuildContext context,
    WidgetRef ref,
    int flex,
  ) {
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
                    onTap: () {
                      WorkoutDialogs.showUserSeriesInputDialog(context, ref, series, field);
                    },
                    child: Text(
                      WorkoutFormatters.formatSeriesValue(series, field, ref).toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
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
    int seriesIndex,
    BuildContext context,
    WidgetRef ref,
    int flex,
  ) {
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
                        ref.read(workout_provider.workoutServiceProvider).toggleSeriesDone(series),
                    child: Icon(
                      WorkoutFormatters.determineSeriesStatus(series, ref)
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: WorkoutFormatters.determineSeriesStatus(series, ref)
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

  // Nuovo metodo per gestire le serie delle superserie su mobile
  List<Widget> _buildMobileSuperSetSeriesRows(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final maxSeriesCount = superSetExercises
        .map((exercise) => exercise['series'].length)
        .reduce((a, b) => a > b ? a : b);

    return List.generate(maxSeriesCount, (seriesIndex) {
      return Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(38),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          border: Border.all(color: colorScheme.outline.withAlpha(26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intestazione della serie
            Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
              child: Text(
                'Serie ${seriesIndex + 1}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            // Esercizi della serie
            ...superSetExercises.asMap().entries.map((exerciseEntry) {
              final exerciseIndex = exerciseEntry.key;
              final exercise = exerciseEntry.value;
              final series = exercise['series'].length > seriesIndex
                  ? exercise['series'][seriesIndex]
                  : null;

              if (series == null) return const SizedBox.shrink();

              return Container(
                margin: EdgeInsets.only(bottom: AppTheme.spacing.xs),
                padding: EdgeInsets.all(AppTheme.spacing.sm),
                decoration: BoxDecoration(
                  color: WorkoutFormatters.determineSeriesStatus(series, ref)
                      ? colorScheme.primaryContainer.withAlpha(51)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                ),
                child: Row(
                  children: [
                    // Indicatore esercizio (A, B, C...)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + exerciseIndex), // A, B, C...
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.sm),
                    // Nome esercizio (troncato se necessario)
                    Expanded(
                      flex: 3,
                      child: Text(
                        exercise['name'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.sm),
                    // Reps
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            WorkoutDialogs.showUserSeriesInputDialog(context, ref, series, 'reps'),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: AppTheme.spacing.xs,
                            horizontal: AppTheme.spacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                            border: Border.all(color: colorScheme.outline.withAlpha(26)),
                          ),
                          child: Text(
                            WorkoutFormatters.formatSeriesValueForMobile(series, 'reps', ref),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.xs),
                    // Weight
                    Expanded(
                      child: GestureDetector(
                        onTap: () => WorkoutDialogs.showUserSeriesInputDialog(
                          context,
                          ref,
                          series,
                          'weight',
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: AppTheme.spacing.xs,
                            horizontal: AppTheme.spacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                            border: Border.all(color: colorScheme.outline.withAlpha(26)),
                          ),
                          child: Text(
                            WorkoutFormatters.formatSeriesValueForMobile(series, 'weight', ref),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.xs),
                    // Completion button
                    GestureDetector(
                      onTap: () => ref
                          .read(workout_provider.workoutServiceProvider)
                          .toggleSeriesDone(series),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: WorkoutFormatters.determineSeriesStatus(series, ref)
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                          border: Border.all(
                            color: WorkoutFormatters.determineSeriesStatus(series, ref)
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: WorkoutFormatters.determineSeriesStatus(series, ref)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
