import 'package:cloud_firestore/cloud_firestore.dart';

import 'series_model.dart';
import 'progressions_model.dart';

class Exercise {
  String? id;
  String name;
  String type;
  String variant;
  int order;
  String? exerciseId;
  String? superSetId;
  List<Series> series;
  List<List<WeekProgression>> weekProgressions;
  num? latestMaxWeight;

  Exercise({
    this.id,
    required this.name,
    required this.type,
    required this.variant,
    required this.order,
    this.exerciseId,
    this.superSetId,
    List<Series>? series,
    List<List<WeekProgression>>? weekProgressions,
    this.latestMaxWeight,
  })  : series = series ?? [],
        weekProgressions = weekProgressions ?? [];

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      id: map['id'],
      exerciseId: map['exerciseId'],
      superSetId: map['superSetId'],
      variant: map['variant'] ?? '',
      order: map['order'] ?? 0,
      series:
          List<Series>.from(map['series']?.map((x) => Series.fromMap(x)) ?? []),
      weekProgressions: List<List<WeekProgression>>.from(map['weekProgressions']
              ?.map((x) => List<WeekProgression>.from(
                  x.map((y) => WeekProgression.fromMap(y)))) ??
          []),
      latestMaxWeight: map['latestMaxWeight'],
    );
  }

  Exercise copyWith({
    String? id,
    String? exerciseId,
    String? superSetId,
    String? name,
    String? type,
    String? variant,
    int? order,
    List<Series>? series,
    List<List<WeekProgression>>? weekProgressions,
    num? latestMaxWeight,
  }) {
    return Exercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      superSetId: superSetId ?? this.superSetId,
      name: name ?? this.name,
      type: type ?? this.type,
      variant: variant ?? this.variant,
      order: order ?? this.order,
      series: series ?? this.series.map((series) => series.copyWith()).toList(),
      weekProgressions: weekProgressions ??
          this
              .weekProgressions
              .map((weekProgression) => weekProgression
                  .map((progression) => progression.copyWith())
                  .toList())
              .toList(),
      latestMaxWeight: latestMaxWeight ?? this.latestMaxWeight,
    );
  }

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      exerciseId: data['exerciseId'] ?? '',
      superSetId: data['superSetId'],
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      variant: data['variant'] ?? '',
      order: data['order']?.toInt() ?? 0,
      series: (data['series'] as List<dynamic>? ?? [])
          .map((doc) => Series.fromFirestore(doc))
          .toList(),
      weekProgressions: (data['weekProgressions'] as List<dynamic>? ?? [])
          .map((weekProgression) => (weekProgression as List<dynamic>)
              .map((progression) => WeekProgression.fromMap(progression))
              .toList())
          .toList(),
      latestMaxWeight: data['latestMaxWeight'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'superSetId': superSetId,
      'name': name,
      'type': type,
      'variant': variant,
      'order': order,
      'series': series.map((x) => x.toMap()).toList(),
      'weekProgressions': weekProgressions
          .map((x) => x.map((y) => y.toMap()).toList())
          .toList(),
      'latestMaxWeight': latestMaxWeight,
    };
  }
}
