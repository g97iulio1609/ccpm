import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/exercise_record.dart';
import '../exerciseManager/exercise_model.dart';
import 'providers/providers.dart';

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
                    _buildRecordList(records, context),
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

  Widget _buildRecordList(List<ExerciseRecord> records, BuildContext context) {
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
                trailing: index == 0 ? Text(
                  'Latest',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ) : null,
              ),
            );
          },
        ),
      ],
    );
  }
}
