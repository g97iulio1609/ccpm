import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'training_model.dart';

class VolumeDashboard extends StatefulWidget {
  final TrainingProgram program;

  const VolumeDashboard({required this.program, super.key});

  @override
  _VolumeDashboardState createState() => _VolumeDashboardState();
}

class _VolumeDashboardState extends State<VolumeDashboard> {
  String _selectedDataType = 'Volume';

  @override
  Widget build(BuildContext context) {
    final exerciseVolumes = _calculateExerciseVolumes(widget.program);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volume Dashboard'),
        actions: [
          DropdownButton<String>(
            value: _selectedDataType,
            onChanged: (String? newValue) {
              setState(() {
                _selectedDataType = newValue!;
              });
            },
            items: <String>['Volume', 'Number of Lifts']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: _buildChart(exerciseVolumes),
            ),
            DataTable(
              columns: const [
                DataColumn(label: Text('Week')),
                DataColumn(label: Text('Exercise')),
                DataColumn(label: Text('Weekly Volume')),
                DataColumn(label: Text('Monthly Volume')),
                DataColumn(label: Text('Volume Delta')),
                DataColumn(label: Text('Series Completed')),
                DataColumn(label: Text('Number of Lifts')),
              ],
              rows: exerciseVolumes.entries.expand((entry) {
                final weekNumber = entry.key;
                final exerciseVolumesForWeek = entry.value;
                return exerciseVolumesForWeek.entries.map((exerciseEntry) {
                  final exerciseName = exerciseEntry.key;
                  final volume = exerciseEntry.value;
                  return DataRow(cells: [
                    DataCell(Text('Week $weekNumber')),
                    DataCell(Text(exerciseName)),
                    DataCell(Text(volume.weeklyVolume.toStringAsFixed(2))),
                    DataCell(Text(volume.monthlyVolume.toStringAsFixed(2))),
                    DataCell(Text(volume.volumeDelta.toStringAsFixed(2))),
                    DataCell(Text(volume.seriesCompleted.toString())),
                    DataCell(Text(volume.numberOfLifts.toString())),
                  ]);
                }).toList();
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<int, Map<String, _ExerciseVolume>> exerciseVolumes) {
    final spots = exerciseVolumes.entries.map((entry) {
      final weekNumber = entry.key;
      final exerciseVolumesForWeek = entry.value;
      final totalWeeklyVolume = exerciseVolumesForWeek.values.fold(
        0.0,
        (sum, volume) => sum + (_selectedDataType == 'Volume' ? volume.weeklyVolume : volume.numberOfLifts.toDouble()),
      );
      return FlSpot(weekNumber.toDouble(), totalWeeklyVolume);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 4,
            color: Colors.blue,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
        minY: 0,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('Week ${value.toInt()}');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
            ),
          ),
        ),
      ),
    );
  }

  Map<int, Map<String, _ExerciseVolume>> _calculateExerciseVolumes(TrainingProgram program) {
    final exerciseVolumes = <int, Map<String, _ExerciseVolume>>{};

    for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
      final week = program.weeks[weekIndex];
      final weekNumber = week.number;
      final exerciseVolumesForWeek = <String, _ExerciseVolume>{};

      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          if (!exerciseVolumesForWeek.containsKey(exercise.name)) {
            exerciseVolumesForWeek[exercise.name] = _ExerciseVolume();
          }

          final volume = exerciseVolumesForWeek[exercise.name]!;
          for (final series in exercise.series) {
            volume.weeklyVolume += _calculateSeriesVolume(series);
            volume.seriesCompleted++;
            volume.numberOfLifts += series.reps;
          }

          final previousWeekVolume = weekIndex > 0
              ? _getPreviousWeekVolume(exerciseVolumes, weekIndex, exercise.name)
              : 0;
          volume.volumeDelta = volume.weeklyVolume - previousWeekVolume;
        }
      }

      for (final volume in exerciseVolumesForWeek.values) {
        volume.monthlyVolume = _calculateMonthlyVolume(exerciseVolumes, weekIndex, volume.weeklyVolume);
      }

      exerciseVolumes[weekNumber] = exerciseVolumesForWeek;
    }

    return exerciseVolumes;
  }

  double _calculateSeriesVolume(Series series) {
    return series.weight * series.reps;
  }

  double _getPreviousWeekVolume(
      Map<int, Map<String, _ExerciseVolume>> exerciseVolumes,
      int weekIndex,
      String exerciseName) {
    final previousWeekNumber = weekIndex;
    if (exerciseVolumes.containsKey(previousWeekNumber)) {
      final exerciseVolumesForPreviousWeek = exerciseVolumes[previousWeekNumber]!;
      if (exerciseVolumesForPreviousWeek.containsKey(exerciseName)) {
        return exerciseVolumesForPreviousWeek[exerciseName]!.weeklyVolume;
      }
    }
    return 0;
  }

  double _calculateMonthlyVolume(
      Map<int, Map<String, _ExerciseVolume>> exerciseVolumes,
      int weekIndex,
      double weeklyVolume) {
    final weeksInMonth = 4;
    final monthIndex = weekIndex ~/ weeksInMonth;
    final startWeekIndex = monthIndex * weeksInMonth;
    final endWeekIndex = (monthIndex + 1) * weeksInMonth - 1;

    double monthlyVolume = 0;
    for (int i = startWeekIndex; i <= endWeekIndex && i < exerciseVolumes.length; i++) {
      final exerciseVolumesForWeek = exerciseVolumes[i + 1] ?? {};
      monthlyVolume += exerciseVolumesForWeek.values.fold(
        0,
        (sum, volume) => sum + volume.weeklyVolume,
      );
    }

    return monthlyVolume;
  }
}

class _ExerciseVolume {
  double weeklyVolume = 0;
  double monthlyVolume = 0;
  double volumeDelta = 0;
  int seriesCompleted = 0;
  int numberOfLifts = 0;
}