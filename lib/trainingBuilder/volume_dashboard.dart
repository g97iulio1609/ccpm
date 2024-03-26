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
  String? _selectedExercise;
  bool _showChart = false;

  @override
  Widget build(BuildContext context) {
    final exerciseVolumes = _calculateExerciseVolumes(widget.program);
    final exercises = exerciseVolumes.values
        .expand((weekData) => weekData.keys)
        .toSet()
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                    decoration: const InputDecoration(
                      labelText: 'Data Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedExercise,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedExercise = newValue;
                      });
                    },
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Exercises'),
                      ),
                      ...exercises.map((exercise) => DropdownMenuItem<String>(
                            value: exercise,
                            child: Text(exercise),
                          )),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Exercise',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showChart ? Icons.table_chart : Icons.bar_chart,
                  ),
                  onPressed: () {
                    setState(() {
                      _showChart = !_showChart;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_showChart)
            SizedBox(
              height: 300,
              child: _buildChart(exerciseVolumes),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Week')),
                DataColumn(label: Text('Day')),
                DataColumn(label: Text('Exercise')),
                DataColumn(label: Text('Daily Volume')),
                DataColumn(label: Text('Weekly Volume')),
                DataColumn(label: Text('Monthly Volume')),
                DataColumn(label: Text('Volume Delta')),
                DataColumn(label: Text('Series Completed')),
                DataColumn(label: Text('Number of Lifts')),
              ],
rows: exerciseVolumes.entries
    .expand((entry) {
      final weekNumber = entry.key;
      final exerciseVolumesForWeek = entry.value;
      return exerciseVolumesForWeek.entries.expand((exerciseEntry) {
        final exerciseName = exerciseEntry.key;
        if (_selectedExercise != null &&
            _selectedExercise != exerciseName) {
          return [];
        }
        final volumesByDay = exerciseEntry.value;
        return volumesByDay.entries.map((dayEntry) {
          final dayNumber = dayEntry.key;
          final volume = dayEntry.value;
          return DataRow(cells: [
            DataCell(Text('Week $weekNumber')),
            DataCell(Text('Day $dayNumber')),
            DataCell(Text(exerciseName)),
            DataCell(Text(volume.dailyVolume.toStringAsFixed(2))),
            DataCell(Text(volume.weeklyVolume.toStringAsFixed(2))),
            DataCell(Text(volume.monthlyVolume.toStringAsFixed(2))),
            DataCell(Text(volume.volumeDelta.toStringAsFixed(2))),
            DataCell(Text(volume.seriesCompleted.toString())),
            DataCell(Text(volume.numberOfLifts.toString())),
          ]);
        });
      });
    })
    .toList()
    .cast<DataRow>(),
                 
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
      Map<int, Map<String, Map<int, _ExerciseVolume>>> exerciseVolumes) {
  final spots = exerciseVolumes.entries.expand((entry) {
  final weekNumber = entry.key;
  final exerciseVolumesForWeek = entry.value;
  return exerciseVolumesForWeek.entries.expand((exerciseEntry) {
    final exerciseName = exerciseEntry.key;
    if (_selectedExercise != null &&
        _selectedExercise != exerciseName) {
      return [];
    }
    final volumesByDay = exerciseEntry.value;
    return volumesByDay.entries.map((dayEntry) {
      final dayNumber = dayEntry.key;
      final volume = dayEntry.value;
      final value = _selectedDataType == 'Volume'
          ? volume.dailyVolume
          : volume.numberOfLifts.toDouble();
      return FlSpot(weekNumber * 10 + dayNumber.toDouble(), value);
    });
  });
}).toList().cast<FlSpot>();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 2,
            color: Colors.blue,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
        minY: 0,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final weekNumber = (value ~/ 10).toInt();
                final dayNumber = (value % 10).toInt();
                return Text('W$weekNumber D$dayNumber');
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

  Map<int, Map<String, Map<int, _ExerciseVolume>>> _calculateExerciseVolumes(
      TrainingProgram program) {
    final exerciseVolumes = <int, Map<String, Map<int, _ExerciseVolume>>>{};

    for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
      final week = program.weeks[weekIndex];
      final weekNumber = week.number;
      final exerciseVolumesForWeek = <String, Map<int, _ExerciseVolume>>{};

      for (final workout in week.workouts) {
        final dayNumber = workout.order;

        for (final exercise in workout.exercises) {
          if (!exerciseVolumesForWeek.containsKey(exercise.name)) {
            exerciseVolumesForWeek[exercise.name] = <int, _ExerciseVolume>{};
          }

          final volumesByDay = exerciseVolumesForWeek[exercise.name]!;
          if (!volumesByDay.containsKey(dayNumber)) {
            volumesByDay[dayNumber] = _ExerciseVolume();
          }

          final volume = volumesByDay[dayNumber]!;
          for (final series in exercise.series) {
            volume.dailyVolume += _calculateSeriesVolume(series);
            volume.seriesCompleted++;
            volume.numberOfLifts += series.reps;
          }
          volume.weeklyVolume = _calculateWeeklyVolume(volumesByDay.values);

          final previousWeekVolume = weekIndex > 0
              ? _getPreviousWeekVolume(
                  exerciseVolumes, weekIndex, exercise.name, dayNumber)
              : 0;
          volume.volumeDelta = volume.weeklyVolume - previousWeekVolume;

          volume.monthlyVolume =
              _calculateMonthlyVolume(program, weekIndex, volume.weeklyVolume);
        }
      }

      exerciseVolumes[weekNumber] = exerciseVolumesForWeek;
    }

    return exerciseVolumes;
  }

  double _calculateSeriesVolume(Series series) {
    return series.weight * series.reps;
  }

  double _calculateWeeklyVolume(Iterable<_ExerciseVolume> dailyVolumes) {
    return dailyVolumes.fold(0, (sum, volume) => sum + volume.dailyVolume);
  }

  double _getPreviousWeekVolume(
      Map<int, Map<String, Map<int, _ExerciseVolume>>> exerciseVolumes,
      int weekIndex,
      String exerciseName,
      int dayNumber) {
    final previousWeekNumber = weekIndex;
    if (exerciseVolumes.containsKey(previousWeekNumber)) {
      final exerciseVolumesForPreviousWeek =
          exerciseVolumes[previousWeekNumber]!;
      if (exerciseVolumesForPreviousWeek.containsKey(exerciseName)) {
        final volumesByDayForPreviousWeek =
            exerciseVolumesForPreviousWeek[exerciseName]!;
        if (volumesByDayForPreviousWeek.containsKey(dayNumber)) {
          return volumesByDayForPreviousWeek[dayNumber]!.weeklyVolume;
        }
      }
    }
    return 0;
  }

double _calculateMonthlyVolume(
    TrainingProgram program, int weekIndex, double weeklyVolume) {
  double monthlyVolume = 0;
  int weeksInMonth = 0;

  for (int i = weekIndex; i >= 0; i--) {
    if (weeksInMonth < 4) {
      double weekVolume = 0;
      final week = program.weeks[i];
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          for (final series in exercise.series) {
            weekVolume += _calculateSeriesVolume(series);
          }
        }
      }
      monthlyVolume += weekVolume;
      weeksInMonth++;
    } else {
      break;
    }
  }

  return monthlyVolume;
    }}

class _ExerciseVolume {
  double dailyVolume = 0;
  double weeklyVolume = 0;
  double monthlyVolume = 0;
  double volumeDelta = 0;
  int seriesCompleted = 0;
  int numberOfLifts = 0;
}