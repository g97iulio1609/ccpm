import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_card.dart';
import 'package:alphanessone/UI/components/section_header.dart';
import 'package:alphanessone/UI/components/kpi_badge.dart';
import 'package:alphanessone/UI/components/skeleton.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';

import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/exerciseManager/exercise_model.dart';
import 'package:alphanessone/providers/providers.dart';

import 'package:alphanessone/ExerciseRecords/widgets/edit_record_dialog.dart';
import 'package:alphanessone/ExerciseRecords/providers/max_rm_providers.dart';

class MaxRMGridSliver extends ConsumerWidget {
  final String? selectedUserId;

  const MaxRMGridSliver({super.key, this.selectedUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);

    return exercisesAsyncValue.when(
      data: (exercises) {
        final usersService = ref.watch(usersServiceProvider);
        final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
        final userId = selectedUserId ?? usersService.getCurrentUserId();

        List<Stream<ExerciseRecord?>> exerciseRecordStreams = exercises.map(
          (exercise) {
            return exerciseRecordService
                .getExerciseRecords(userId: userId, exerciseId: exercise.id)
                .map(
                  (records) => records.isNotEmpty
                      ? records.reduce(
                          (a, b) => a.date.compareTo(b.date) > 0 ? a : b,
                        )
                      : null,
                );
          },
        ).toList();

        return StreamBuilder<List<ExerciseRecord?>>(
          stream: CombineLatestStream.list(exerciseRecordStreams),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              final width = MediaQuery.of(context).size.width;
              final crossAxisCount = _getGridCrossAxisCount(context);
              final childAspectRatio = width >= 1400 ? 1.2 : 1.0;
              return SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                sliver: SliverSkeletonGrid(
                  crossAxisCount: crossAxisCount,
                  itemCount: 8,
                  childAspectRatio: childAspectRatio,
                ),
              );
            }

            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              );
            }

            List<ExerciseRecord> latestRecords = (snapshot.data ?? [])
                .where((record) => record != null)
                .map((record) => record!)
                .toList();

            // Filtro per nome esercizio
            final filter = ref.watch(recordsFilterProvider);
            if (filter.isNotEmpty) {
              latestRecords = latestRecords
                  .where(
                    (r) => exercises
                        .firstWhere(
                          (ex) => ex.id == r.exerciseId,
                          orElse: () => ExerciseModel(
                            id: '',
                            name: 'Exercise not found',
                            type: '',
                            muscleGroups: [],
                          ),
                        )
                        .name
                        .toLowerCase()
                        .contains(filter),
                  )
                  .toList();
            }

            // Ordinamento
            final sort = ref.watch(recordsSortProvider);
            latestRecords.sort((a, b) {
              if (sort == 'weight_desc') {
                return b.maxWeight.compareTo(a.maxWeight);
              }
              return b.date.compareTo(a.date);
            });

            if (latestRecords.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppTheme.spacing.xl),
                  child: AppCard(
                    glass: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withAlpha(128),
                        ),
                        SizedBox(height: AppTheme.spacing.md),
                        Text(
                          'No Records Found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.spacing.sm),
                        Text(
                          'Start adding your max records',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant.withAlpha(128),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final crossAxisCount = _getGridCrossAxisCount(context);
            final rows = <List<ExerciseRecord>>[];
            for (var i = 0; i < latestRecords.length; i += crossAxisCount) {
              rows.add(
                latestRecords.sublist(
                  i,
                  i + crossAxisCount > latestRecords.length
                      ? latestRecords.length
                      : i + crossAxisCount,
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, rowIndex) {
                if (rowIndex >= rows.length) return null;
                final rowRecords = rows[rowIndex];

                return Padding(
                  padding: EdgeInsets.only(bottom: AppTheme.spacing.xl),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < crossAxisCount; i++) ...[
                          if (i < rowRecords.length)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: i < crossAxisCount - 1
                                      ? AppTheme.spacing.xl
                                      : 0,
                                ),
                                child: AppCard(
                                  glass: true,
                                  header: SectionHeader(
                                    title: exercises
                                            .firstWhere(
                                              (ex) =>
                                                  ex.id == rowRecords[i].exerciseId,
                                              orElse: () => ExerciseModel(
                                                id: '',
                                                name: 'Exercise not found',
                                                type: '',
                                                muscleGroups: [],
                                              ),
                                            )
                                            .muscleGroups
                                            .firstOrNull ??
                                        '',
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () => _showRecordOptions(
                                        context,
                                        rowRecords[i],
                                        exercises.firstWhere(
                                          (ex) =>
                                              ex.id == rowRecords[i].exerciseId,
                                          orElse: () => ExerciseModel(
                                            id: '',
                                            name: 'Exercise not found',
                                            type: '',
                                            muscleGroups: [],
                                          ),
                                        ),
                                        ProviderScope.containerOf(context),
                                      ),
                                    ),
                                  ),
                                  child: _buildRecordBody(
                                    rowRecords[i],
                                    exercises.firstWhere(
                                      (ex) => ex.id == rowRecords[i].exerciseId,
                                      orElse: () => ExerciseModel(
                                        id: '',
                                        name: 'Exercise not found',
                                        type: '',
                                        muscleGroups: [],
                                      ),
                                    ),
                                    theme,
                                    colorScheme,
                                    context,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox.shrink()),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Center(
          child: Text('Error loading max RMs: $error'),
        ),
      ),
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildRecordBody(
    ExerciseRecord record,
    ExerciseModel exercise,
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppTheme.spacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            KpiBadge(
              text: '${record.maxWeight} kg',
              icon: Icons.fitness_center,
              color: colorScheme.primary,
            ),
            Text(
              DateFormat('d MMM yyyy').format(record.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRecordOptions(
    BuildContext context,
    ExerciseRecord record,
    ExerciseModel exercise,
    ProviderContainer ref,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: exercise.name,
        subtitle: '${record.maxWeight} kg',
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(76),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Modifica Record',
            icon: Icons.edit_outlined,
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return EditRecordDialog(
                    record: record,
                    exercise: exercise,
                    exerciseRecordService: ref.read(exerciseRecordServiceProvider),
                    usersService: ref.read(usersServiceProvider),
                  );
                },
              );
            },
          ),
          BottomMenuItem(
            title: 'Elimina Record',
            icon: Icons.delete_outline,
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(context, ref, record, exercise);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ProviderContainer ref,
    ExerciseRecord record,
    ExerciseModel exercise,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Confirmation',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref
                      .read(exerciseRecordServiceProvider)
                      .deleteExerciseRecord(
                        userId: ref.read(selectedUserIdProvider) ??
                            ref.read(usersServiceProvider).getCurrentUserId(),
                        exerciseId: exercise.id,
                        recordId: record.id,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Record deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete record: $e')),
                    );
                  }
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}


