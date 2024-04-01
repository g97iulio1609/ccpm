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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    decoration: InputDecoration(
                      labelText: 'Data Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
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
                    decoration: InputDecoration(
                      labelText: 'Exercise',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showChart ? Icons.table_chart : Icons.bar_chart,
                    color: Colors.white,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    gradient: LinearGradient(
                      colors: [Colors.grey[900]!, Colors.grey[700]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildChart(exerciseVolumes),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildDataTable(exerciseVolumes),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(Map<int, Map<String, Map<int, _ExerciseVolume>>> exerciseVolumes) {
    return SingleChildScrollView(
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
        rows: exerciseVolumes.entries.expand((entry) {
          final weekNumber = entry.key;
          final exerciseVolumesForWeek = entry.value;
          return exerciseVolumesForWeek.entries.expand((exerciseEntry) {
            final exerciseName = exerciseEntry.key;
            if (_selectedExercise != null && _selectedExercise != exerciseName) {
              return [];
            }
            final volumesByDay = exerciseEntry.value;
            return volumesByDay.entries.map((dayEntry) {
              final dayNumber = dayEntry.key;
              final volume = dayEntry.value;
              return DataRow(
                cells: [
                  DataCell(Text('Week $weekNumber', style: const TextStyle(color: Colors.white))),
                  DataCell(Text('Day $dayNumber', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(exerciseName, style: const TextStyle(color: Colors.white))),
                  DataCell(Text(volume.dailyVolume.toStringAsFixed(2), style: const TextStyle(color: Colors.white))),
                  DataCell(Text(volume.weeklyVolume.toStringAsFixed(2), style: const TextStyle(color: Colors.white))),
                  DataCell(Text(volume.monthlyVolume.toStringAsFixed(2), style: const TextStyle(color: Colors.white))),
                  DataCell(Text(volume.volumeDelta.toStringAsFixed(2), style: const TextStyle(color: Colors.white))),
                  DataCell(Text(volume.seriesCompleted.toString(), style: const TextStyle(color: Colors.white))),
                  DataCell(Text(volume.numberOfLifts.toString(), style: const TextStyle(color: Colors.white))),
                ],
              );
            });
          });
        }).toList().cast<DataRow>(),
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
            isCurved: true,
            barWidth: 4,
            color: Colors.white,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.white.withOpacity(0.3),
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
                return Text(
                  'W$weekNumber D$dayNumber',
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white24,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
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
          final volumesByDay =
              exerciseVolumesForWeek.putIfAbsent(exercise.name, () => {});
          final volume = volumesByDay.putIfAbsent(dayNumber, _ExerciseVolume.new);

          for (final series in exercise.series) {
            volume.addSeries(series);
          }

          volume.calculateWeeklyVolume(volumesByDay.values);
          volume.calculateVolumeDelta(
            weekIndex > 0
                ? _getPreviousWeekVolume(
                    exerciseVolumes, weekIndex, exercise.name, dayNumber)
                : 0,
          );
          volume.calculateMonthlyVolume(program, weekIndex);
        }
      }

      exerciseVolumes[weekNumber] = exerciseVolumesForWeek;
    }

    return exerciseVolumes;
  }

  double _getPreviousWeekVolume(
    Map<int, Map<String, Map<int, _ExerciseVolume>>> exerciseVolumes,
    int weekIndex,
    String exerciseName,
    int dayNumber,
  ) {
    final previousWeekNumber = weekIndex - 1;
    final exerciseVolumesForPreviousWeek =
        exerciseVolumes[previousWeekNumber]?[exerciseName];
    return exerciseVolumesForPreviousWeek?[dayNumber]?.weeklyVolume ?? 0;
  }
}

class _ExerciseVolume {
  double dailyVolume = 0;
  double weeklyVolume = 0;
  double monthlyVolume = 0;
  double volumeDelta = 0;
  int seriesCompleted = 0;
  int numberOfLifts = 0;

  void addSeries(Series series) {
    dailyVolume += series.weight * series.reps;
    seriesCompleted++;
    numberOfLifts += series.reps;
  }

  void calculateWeeklyVolume(Iterable<_ExerciseVolume> dailyVolumes) {
    weeklyVolume = dailyVolumes.fold(0, (sum, volume) => sum + volume.dailyVolume);
  }

  void calculateVolumeDelta(double previousWeekVolume) {
    volumeDelta = weeklyVolume - previousWeekVolume;
  }

  void calculateMonthlyVolume(TrainingProgram program, int weekIndex) {
    double monthlyVolume = 0;
    int weeksInMonth = 0;

    for (int i = weekIndex; i >= 0 && weeksInMonth < 4; i--, weeksInMonth++) {
      final week = program.weeks[i];
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          for (final series in exercise.series) {
            monthlyVolume += series.weight * series.reps;
          }
        }
      }
    }

    this.monthlyVolume = monthlyVolume;
  }
}