class TimerModel {
  final String programId;
  final String userId;
  final List<Map<String, dynamic>> seriesList;
  final String weekId;
  final String workoutId;
  final String exerciseId;
  final int currentSeriesIndex;
  final int totalSeries;
  final int restTime;
  final bool isEmomMode;
  final int superSetExerciseIndex;

  TimerModel({
    required this.programId,
    required this.userId,
    required this.seriesList,
    required this.weekId,
    required this.workoutId,
    required this.exerciseId,
    required this.currentSeriesIndex,
    required this.totalSeries,
    required this.restTime,
    required this.isEmomMode,
    required this.superSetExerciseIndex,
  });
}
