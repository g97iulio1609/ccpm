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
    return WeekProgression(
      weekNumber: map['weekNumber'],
      sessionNumber: map['sessionNumber'],
      series: List<Series>.from(map['series']?.map((x) => Series.fromMap(x)) ?? []),
    );
  }

  WeekProgression copyWith({
    int? weekNumber,
    int? sessionNumber,
    List<Series>? series,
  }) {
    return WeekProgression(
      weekNumber: weekNumber ?? this.weekNumber,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      series: series ?? this.series.map((series) => series.copyWith()).toList(),
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