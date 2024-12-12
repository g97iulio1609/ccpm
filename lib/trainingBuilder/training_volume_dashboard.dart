import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/providers/training_providers.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';

class TrainingVolumeDashboard extends ConsumerStatefulWidget {
  final String programId;
  final String userId;

  const TrainingVolumeDashboard({super.key, required this.programId, required this.userId});

  @override
  TrainingVolumeDashboardState createState() => TrainingVolumeDashboardState();
}

class TrainingVolumeDashboardState extends ConsumerState<TrainingVolumeDashboard> {
  String? selectedExercise;
  Map<String, List<double>> exerciseVolumes = {};
  Map<String, List<List<ExerciseStats>>> detailedStats = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final program = ref.read(trainingProgramStateProvider);
    final volumes = _calculateExerciseVolumes(program);
    final stats = await _calculateDetailedExerciseStats(program);
    setState(() {
      exerciseVolumes = volumes;
      detailedStats = stats;
      if (selectedExercise == null && volumes.isNotEmpty) {
        selectedExercise = volumes.keys.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<String>(
                value: selectedExercise,
                items: exerciseVolumes.keys.map((String exercise) {
                  return DropdownMenuItem<String>(
                    value: exercise,
                    child: Text(exercise),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedExercise = newValue;
                  });
                },
                isExpanded: true,
                hint: const Text('Seleziona un esercizio'),
              ),
            ),
            if (selectedExercise != null) ...[
              Expanded(
                flex: 2,
                child: _buildExerciseVolumeCard(context, selectedExercise!, exerciseVolumes[selectedExercise!]!),
              ),
              Expanded(
                flex: 3,
                child: _buildDetailedStatsTable(context, selectedExercise!, detailedStats[selectedExercise!]!),
              ),
            ] else
              const Expanded(child: Center(child: Text('Nessun esercizio selezionato'))),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseVolumeCard(BuildContext context, String exerciseName, List<double> volumeData) {
    final maxY = volumeData.reduce((a, b) => a > b ? a : b);
    final minY = volumeData.reduce((a, b) => a < b ? a : b);
    final yInterval = ((maxY - minY) / 5).ceilToDouble();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('W${value.toInt() + 1}');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: volumeData.length.toDouble() - 1,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: volumeData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatsTable(BuildContext context, String exerciseName, List<List<ExerciseStats>> detailedStats) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Settimana')),
              DataColumn(label: Text('Allenamento')),
              DataColumn(label: Text('Volume')),
              DataColumn(label: Text('NBLS')),
              DataColumn(label: Text('%RM Media')),
            ],
            rows: List<DataRow>.generate(
              detailedStats.length,
              (weekIndex) {
                return DataRow(
                  cells: [
                    DataCell(Text('${weekIndex + 1}')),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List<Widget>.generate(
                          detailedStats[weekIndex].length,
                          (workoutIndex) => Text('${workoutIndex + 1}'),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: detailedStats[weekIndex].map((stats) => Text(stats.volume.toStringAsFixed(2))).toList(),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: detailedStats[weekIndex].map((stats) => Text(stats.nbls.toString())).toList(),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: detailedStats[weekIndex].map((stats) => Text('${stats.rmAverage.toStringAsFixed(2)}%')).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<double>> _calculateExerciseVolumes(TrainingProgram program) {
    Map<String, List<double>> exerciseVolumes = {};

    for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
      var week = program.weeks[weekIndex];
      Map<String, double> weeklyVolumes = {};

      for (var workout in week.workouts) {
        for (var exercise in workout.exercises) {
          double volume = _calculateExerciseVolume(exercise);
          weeklyVolumes[exercise.name] = (weeklyVolumes[exercise.name] ?? 0) + volume;
        }
      }

      weeklyVolumes.forEach((exerciseName, volume) {
        if (!exerciseVolumes.containsKey(exerciseName)) {
          exerciseVolumes[exerciseName] = List.filled(program.weeks.length, 0);
        }
        exerciseVolumes[exerciseName]![weekIndex] = volume;
      });
    }

    return exerciseVolumes;
  }

  Future<Map<String, List<List<ExerciseStats>>>> _calculateDetailedExerciseStats(TrainingProgram program) async {
    Map<String, List<List<ExerciseStats>>> detailedStats = {};
    final exerciseRecordService = ref.read(exerciseRecordServiceProvider);

    for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
      var week = program.weeks[weekIndex];

      for (int workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
        var workout = week.workouts[workoutIndex];

        for (var exercise in workout.exercises) {
          if (!detailedStats.containsKey(exercise.name)) {
            detailedStats[exercise.name] = List.generate(program.weeks.length, (_) => []);
          }

          final stats = await _calculateExerciseStats(exercise, exerciseRecordService, widget.userId);
          detailedStats[exercise.name]![weekIndex].add(stats);
        }
      }
    }

    return detailedStats;
  }

  Future<ExerciseStats> _calculateExerciseStats(Exercise exercise, ExerciseRecordService exerciseRecordService, String userId) async {
    double totalVolume = 0;
    int totalLifts = 0;
    double totalIntensity = 0;

    final latestRecord = await exerciseRecordService.getLatestExerciseRecord(
      userId: userId,
      exerciseId: exercise.exerciseId ?? '',
    );
    final latestMaxWeight = latestRecord?.maxWeight ?? 1;

    for (var series in exercise.series) {
      double seriesVolume = _calculateSeriesVolume(series);
      totalVolume += seriesVolume;
      totalLifts += series.reps * series.sets;
      totalIntensity += (series.weight / latestMaxWeight) * series.reps * series.sets;
    }

    double averageRM = totalLifts > 0 ? (totalIntensity / totalLifts) * 100 : 0;

    return ExerciseStats(
      volume: totalVolume,
      nbls: totalLifts,
      rmAverage: averageRM,
    );
  }

  double _calculateExerciseVolume(Exercise exercise) {
    double totalVolume = 0;
    for (var series in exercise.series) {
      totalVolume += _calculateSeriesVolume(series);
    }
    return totalVolume;
  }

  double _calculateSeriesVolume(Series series) {
    return series.reps * series.weight * series.sets;
  }
}

class ExerciseStats {
  final double volume;
  final int nbls;
  final double rmAverage;

  ExerciseStats({required this.volume, required this.nbls, required this.rmAverage});
}