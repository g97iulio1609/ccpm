import '../../shared/models/series.dart';

class WeekProgression {
  int weekNumber;
  int sessionNumber;
  List<Series> series;

  WeekProgression({
    required this.weekNumber,
    required this.sessionNumber,
    required this.series,
  });

  factory WeekProgression.fromMap(Map<String, dynamic> map) {
    List<Series> parseSeries(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data
            .where((e) => e != null)
            .map((x) => Series.fromMap(x as Map<String, dynamic>))
            .toList();
      }
      if (data is Map) {
        return data.values
            .where((e) => e != null)
            .map((x) => Series.fromMap(Map<String, dynamic>.from(x as Map)))
            .toList();
      }
      return [];
    }

    return WeekProgression(
      weekNumber: map['weekNumber'],
      sessionNumber: map['sessionNumber'],
      series: parseSeries(map['series']),
    );
  }

  WeekProgression copyWith({
    int? weekNumber,
    int? sessionNumber,
    List<Series>? series,
    bool resetCompletionData = false,
  }) {
    return WeekProgression(
      weekNumber: weekNumber ?? this.weekNumber,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      series: series ?? this.series.map((series) => 
        resetCompletionData 
          ? series.copyWith(
              done: false,
              repsDone: 0,
              weightDone: 0.0,
            )
          : series.copyWith()
      ).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'sessionNumber': sessionNumber,
      'series': series.map((x) => x.toMap()).toList(),
    };
  }
}
