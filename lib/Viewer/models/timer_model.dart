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

  TimerModel copyWith({
    String? programId,
    String? userId,
    List<Map<String, dynamic>>? seriesList,
    String? weekId,
    String? workoutId,
    String? exerciseId,
    int? currentSeriesIndex,
    int? totalSeries,
    int? restTime,
    bool? isEmomMode,
    int? superSetExerciseIndex,
  }) {
    return TimerModel(
      programId: programId ?? this.programId,
      userId: userId ?? this.userId,
      seriesList: seriesList ?? this.seriesList,
      weekId: weekId ?? this.weekId,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      currentSeriesIndex: currentSeriesIndex ?? this.currentSeriesIndex,
      totalSeries: totalSeries ?? this.totalSeries,
      restTime: restTime ?? this.restTime,
      isEmomMode: isEmomMode ?? this.isEmomMode,
      superSetExerciseIndex:
          superSetExerciseIndex ?? this.superSetExerciseIndex,
    );
  }
}
