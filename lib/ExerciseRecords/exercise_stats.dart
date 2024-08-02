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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: StreamBuilder<List<ExerciseRecord>>(
          stream: recordsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final records = snapshot.data ?? [];

            if (records.isEmpty) {
              return const Center(child: Text('No records found for this exercise.'));
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceSummary(records, context),
                    const SizedBox(height: 24),
                    if (records.length > 1) _buildPerformanceChart(records, context),
                    const SizedBox(height: 24),
                    _buildRecordList(records, context, ref),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(List<ExerciseRecord> records, BuildContext context) {
    if (records.length < 2) {
      return Card(
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                records.isEmpty
                  ? 'No records available to display.'
                  : 'Not enough records to show performance summary.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final latestRecord = records.first;
    final oldestRecord = records.last;
    final improvement = latestRecord.maxWeight - oldestRecord.maxWeight;
    final improvementPercentage = (improvement / oldestRecord.maxWeight) * 100;

    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text('Latest Max Weight: ${latestRecord.maxWeight} kg',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            Text('Initial Max Weight: ${oldestRecord.maxWeight} kg',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Improvement: ${improvement.toStringAsFixed(2)} kg (${improvementPercentage.toStringAsFixed(2)}%)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: improvement >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(List<ExerciseRecord> records, BuildContext context) {
    final sortedRecords = records.reversed.toList();
    final minWeight = sortedRecords.map((r) => r.maxWeight).reduce((a, b) => a < b ? a : b).toDouble();
    final maxWeight = sortedRecords.map((r) => r.maxWeight).reduce((a, b) => a > b ? a : b).toDouble();
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (sortedRecords.length / 2).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedRecords.length) {
                    return Text(
                      DateFormat('MMM d').format(DateTime.parse(sortedRecords[value.toInt()].date)),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedRecords.length - 1).toDouble(),
          minY: minWeight - (weightRange * 0.1),
          maxY: maxWeight + (weightRange * 0.1),
          lineBarsData: [
            LineChartBarData(
              spots: sortedRecords.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.maxWeight.toDouble());
              }).toList(),
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: maxWeight,
                color: Colors.green.withOpacity(0.8),
                strokeWidth: 2,
                dashArray: [5, 10],
              ),
              HorizontalLine(
                y: minWeight,
                color: Colors.red.withOpacity(0.8),
                strokeWidth: 2,
                dashArray: [5, 10],
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildRecordList(List<ExerciseRecord> records, BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Theme.of(context).colorScheme.surface,
              child: ListTile(
                title: Text('${record.maxWeight} kg x ${record.repetitions} reps',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                subtitle: Text(DateFormat('MMMM d, yyyy').format(DateTime.parse(record.date)),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(context, ref, record),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteDialog(context, ref, record),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ExerciseRecord record) {
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ExerciseRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Confirmation',
            style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          content: Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Theme.of(dialogContext).colorScheme.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performDelete(context, ref, record);
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  void _performDelete(BuildContext context, WidgetRef ref, ExerciseRecord record) async {
    try {
      await ref.read(exerciseRecordServiceProvider).deleteExerciseRecord(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete record: $e')),
        );
      }
    }
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
    final maxWeightController = useTextEditingController(text: record.maxWeight.toString());
    final repetitionsController = useTextEditingController(text: record.repetitions.toString());
    final keepWeight = useState(false);
    final selectedDate = useState(DateTime.parse(record.date));

    return AlertDialog(
      title: Text(
        'Edit Record',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextFormField(maxWeightController, 'Max weight', context),
            _buildDialogTextFormField(repetitionsController, 'Repetitions', context),
            _buildDatePicker(context, selectedDate),
            Row(
              children: [
                Text(
                  'Keep current weight',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _handleSave(context, ref, maxWeightController.text, repetitionsController.text, selectedDate.value, keepWeight.value);
          },
          child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _buildDialogTextFormField(TextEditingController controller, String labelText, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.number,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, ValueNotifier<DateTime> selectedDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate.value,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null && picked != selectedDate.value) {
            selectedDate.value = picked;
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date',
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(selectedDate.value),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave(BuildContext context, WidgetRef ref, String maxWeightText, String repetitionsText, DateTime selectedDate, bool keepWeight) async {
    double newMaxWeight = double.parse(maxWeightText);
    int newRepetitions = int.parse(repetitionsText);

    if (newRepetitions > 1) {
      newMaxWeight = (newMaxWeight / (1.0278 - (0.0278 * newRepetitions))).roundToDouble();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update record: $e')),
        );
      }
    }
  }
}
