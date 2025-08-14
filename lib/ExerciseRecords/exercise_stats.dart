import 'dart:math';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/exercise_record.dart';
import '../../exerciseManager/exercise_model.dart';
import '../providers/providers.dart';
import 'package:alphanessone/UI/app_bar_custom.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/kpi_badge.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/UI/components/input.dart';
import 'package:alphanessone/UI/components/date_picker_field.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';

class ExerciseStats extends HookConsumerWidget {
  final ExerciseModel exercise;
  final String userId;

  const ExerciseStats({
    super.key,
    required this.exercise,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
    final recordsStream = exerciseRecordService.getExerciseRecords(
      userId: userId,
      exerciseId: exercise.id,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    useEffect(() {
      Future.microtask(() {
        ref.read(currentMaxRMExerciseNameProvider.notifier).state =
            exercise.name;
      });
      return () {
        Future.microtask(() {
          ref.read(currentMaxRMExerciseNameProvider.notifier).state = '';
        });
      };
    }, [exercise.name]);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withAlpha(128),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<ExerciseRecord>>(
            stream: recordsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      SizedBox(height: AppTheme.spacing.md),
                      Text(
                        'Error: ${snapshot.error}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final records = snapshot.data ?? [];

              if (records.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      ),
                      SizedBox(height: AppTheme.spacing.sm),
                      Text(
                        'Start adding your max records',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant.withAlpha(128),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(AppTheme.spacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPerformanceSummary(records, context),
                          SizedBox(height: AppTheme.spacing.xl),
                          if (records.length > 1) ...[
                            Text(
                              'Progress Chart',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacing.lg),
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacing.lg),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radii.lg,
                                ),
                                border: Border.all(
                                  color: colorScheme.outline.withAlpha(26),
                                ),
                                boxShadow: AppTheme.elevations.small,
                              ),
                              child: _buildPerformanceChart(records, context),
                            ),
                          ],
                          SizedBox(height: AppTheme.spacing.xl),
                          Text(
                            'History',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacing.lg),
                          _buildRecordList(records, context, ref),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(
    List<ExerciseRecord> records,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (records.length < 2) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          border: Border.all(color: colorScheme.outline.withAlpha(26)),
          boxShadow: AppTheme.elevations.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: AppTheme.spacing.md),
            Text(
              records.isEmpty
                  ? 'No records available to display.'
                  : 'Not enough records to show performance summary.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final latestRecord = records.first;
    final oldestRecord = records.last;
    final improvement = latestRecord.maxWeight - oldestRecord.maxWeight;
    final improvementPercentage = (improvement / oldestRecord.maxWeight) * 100;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.md,
                  vertical: AppTheme.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: improvement >= 0
                      ? colorScheme.tertiaryContainer.withAlpha(76)
                      : colorScheme.errorContainer.withAlpha(76),
                  borderRadius: BorderRadius.circular(AppTheme.radii.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      improvement >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: improvement >= 0
                          ? colorScheme.tertiary
                          : colorScheme.error,
                    ),
                    SizedBox(width: AppTheme.spacing.xs),
                    Text(
                      '${improvementPercentage.abs().toStringAsFixed(1)}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: improvement >= 0
                            ? colorScheme.tertiary
                            : colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Latest Max',
                  '${latestRecord.maxWeight} kg',
                  DateFormat('MMM d, y').format(latestRecord.date),
                  colorScheme.primaryContainer.withAlpha(76),
                  colorScheme.primary,
                ),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Initial Max',
                  '${oldestRecord.maxWeight} kg',
                  DateFormat('MMM d, y').format(oldestRecord.date),
                  colorScheme.secondaryContainer.withAlpha(76),
                  colorScheme.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.md),
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: improvement >= 0
                  ? colorScheme.tertiaryContainer.withAlpha(26)
                  : colorScheme.errorContainer.withAlpha(26),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(
                color:
                    (improvement >= 0
                            ? colorScheme.tertiary
                            : colorScheme.error)
                        .withAlpha(51),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spacing.sm),
                  decoration: BoxDecoration(
                    color:
                        (improvement >= 0
                                ? colorScheme.tertiaryContainer
                                : colorScheme.errorContainer)
                            .withAlpha(76),
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  child: Icon(
                    improvement >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: improvement >= 0
                        ? colorScheme.tertiary
                        : colorScheme.error,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Improvement',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: improvement >= 0
                              ? colorScheme.tertiary
                              : colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacing.xs),
                      Text(
                        '${improvement.abs().toStringAsFixed(1)} kg',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: improvement >= 0
                              ? colorScheme.tertiary
                              : colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    Color backgroundColor,
    Color textColor,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: textColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(
    List<ExerciseRecord> records,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sortedRecords = records.reversed.toList();
    final minWeight = sortedRecords
        .map((r) => r.maxWeight)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final maxWeight = sortedRecords
        .map((r) => r.maxWeight)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final weightRange = maxWeight - minWeight;
    final interval = _calculateOptimalInterval(minWeight, maxWeight);

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.onSurface.withAlpha(26),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (sortedRecords.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedRecords.length) {
                    return Text(
                      DateFormat(
                        'MMM d',
                      ).format(sortedRecords[value.toInt()].date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedRecords.length - 1).toDouble(),
          minY: minWeight - (weightRange * 0.1),
          maxY: maxWeight + (weightRange * 0.1),
          lineBarsData: [
            LineChartBarData(
              spots: sortedRecords.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.maxWeight.toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withAlpha(26),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: maxWeight,
                color: colorScheme.tertiary.withAlpha(204),
                strokeWidth: 2,
                dashArray: [5, 10],
              ),
              HorizontalLine(
                y: minWeight,
                color: colorScheme.error.withAlpha(204),
                strokeWidth: 2,
                dashArray: [5, 10],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordList(
    List<ExerciseRecord> records,
    BuildContext context,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: AppTheme.spacing.sm),
      itemBuilder: (context, index) {
        final record = records[index];
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(color: colorScheme.outline.withAlpha(26)),
            boxShadow: AppTheme.elevations.small,
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.lg,
                vertical: AppTheme.spacing.sm,
              ),
              title: Row(
                children: [
                  KpiBadge(
                    text: '${record.maxWeight} kg',
                    icon: Icons.fitness_center,
                    color: colorScheme.primary,
                  ),
                  if (record.repetitions > 1) ...[
                    SizedBox(width: AppTheme.spacing.sm),
                    KpiBadge(
                      text: '${record.repetitions} reps',
                      icon: Icons.repeat,
                      color: colorScheme.secondary,
                    ),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: AppTheme.spacing.sm),
                child: Text(
                  DateFormat('MMMM d, yyyy').format(record.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () => _showEditDialog(context, ref, record),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () => _showDeleteDialog(context, ref, record),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ExerciseRecord record,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditRecordDialog(
          record: record,
          exercise: exercise,
          exerciseRecordService: ref.read(exerciseRecordServiceProvider),
          userId: userId,
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ExerciseRecord record,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: const Text('Elimina Record'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performDelete(context, ref, record);
            },
            child: const Text('Elimina'),
          ),
        ],
        child: Text(
          'Sei sicuro di voler eliminare questo record?',
          style: TextStyle(
            color: Theme.of(dialogContext).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _performDelete(
    BuildContext context,
    WidgetRef ref,
    ExerciseRecord record,
  ) async {
    try {
      await ref
          .read(exerciseRecordServiceProvider)
          .deleteExerciseRecord(
            userId: userId,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete record: $e')));
      }
    }
  }

  double _calculateOptimalInterval(double min, double max) {
    final range = max - min;
    if (range == 0) return min; // Avoid division by zero
    const targetSteps = 5;
    final roughInterval = range / targetSteps;
    final magnitude = pow(10, (log(roughInterval) / ln10).floor());
    final normalizedInterval = roughInterval / magnitude;

    if (normalizedInterval < 1.5) return magnitude.toDouble();
    if (normalizedInterval < 3) return (2 * magnitude).toDouble();
    if (normalizedInterval < 7) return (5 * magnitude).toDouble();
    return (10 * magnitude).toDouble();
  }
}

class EditRecordDialog extends HookConsumerWidget {
  final ExerciseRecord record;
  final ExerciseModel exercise;
  final ExerciseRecordService exerciseRecordService;
  final String userId;

  const EditRecordDialog({
    super.key,
    required this.record,
    required this.exercise,
    required this.exerciseRecordService,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxWeightController = useTextEditingController(
      text: record.maxWeight.toString(),
    );
    final repetitionsController = useTextEditingController(
      text: record.repetitions.toString(),
    );
    final keepWeight = useState(false);
    final selectedDate = useState(record.date);

    return AppDialog(
      title: const Text('Edit Record'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _handleSave(
              context,
              ref,
              maxWeightController.text,
              repetitionsController.text,
              selectedDate.value,
              keepWeight.value,
            );
          },
          child: const Text('Save'),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextFormField(
              maxWeightController,
              'Max weight',
              context,
            ),
            _buildDialogTextFormField(
              repetitionsController,
              'Repetitions',
              context,
            ),
            _buildDatePicker(context, selectedDate),
            Row(
              children: [
                Text(
                  'Keep current weight',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Switch(
                  value: keepWeight.value,
                  onChanged: (value) {
                    keepWeight.value = value;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextFormField(
    TextEditingController controller,
    String labelText,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AppInput.number(controller: controller, label: labelText),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    ValueNotifier<DateTime> selectedDate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DatePickerField(
        value: selectedDate.value,
        label: 'Date',
        onDateSelected: (date) => selectedDate.value = date,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      ),
    );
  }

  void _handleSave(
    BuildContext context,
    WidgetRef ref,
    String maxWeightText,
    String repetitionsText,
    DateTime selectedDate,
    bool keepWeight,
  ) async {
    double newMaxWeight = double.parse(maxWeightText);
    int newRepetitions = int.parse(repetitionsText);

    if (newRepetitions > 1) {
      newMaxWeight = ExerciseService.calculateMaxRM(
        newMaxWeight,
        newRepetitions,
      ).roundToDouble();
      newRepetitions = 1;
    }

    try {
      await exerciseRecordService.updateExerciseRecord(
        userId: userId,
        exerciseId: exercise.id,
        recordId: record.id,
        maxWeight: newMaxWeight,
        repetitions: newRepetitions,
      );

      if (keepWeight) {
        await exerciseRecordService.updateIntensityForProgram(
          userId,
          exercise.id,
          newMaxWeight,
        );
      } else {
        await exerciseRecordService.updateWeightsForProgram(
          userId,
          exercise.id,
          newMaxWeight,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update record: $e')));
      }
    }
  }
}
