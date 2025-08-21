// diet_plan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DietPlan {
  final String? id;
  final String userId;
  final String name;
  final DateTime startDate;
  final int durationDays;
  final List<DietPlanDay> days;

  DietPlan({
    this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.durationDays,
    required this.days,
  });

  factory DietPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DietPlan(
      id: doc.id,
      userId: data['userId'],
      name: data['name'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      durationDays: data['durationDays'],
      days: (data['days'] as List<dynamic>)
          .map((day) => DietPlanDay.fromMap(day as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'durationDays': durationDays,
      'days': days.map((day) => day.toMap()).toList(),
    };
  }

  DietPlan copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startDate,
    int? durationDays,
    List<DietPlanDay>? days,
  }) {
    return DietPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      days: days ?? List.from(this.days),
    );
  }
}

class DietPlanDay {
  final String dayOfWeek;
  final List<String> mealIds;

  DietPlanDay({required this.dayOfWeek, List<String>? mealIds}) : mealIds = mealIds ?? [];

  factory DietPlanDay.fromMap(Map<String, dynamic> map) {
    return DietPlanDay(
      dayOfWeek: map['dayOfWeek'],
      mealIds: List<String>.from(map['mealIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'dayOfWeek': dayOfWeek, 'mealIds': mealIds};
  }

  DietPlanDay copyWith({String? dayOfWeek, List<String>? mealIds}) {
    return DietPlanDay(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      mealIds: mealIds ?? List.from(this.mealIds),
    );
  }

  DietPlanDay addMealId(String mealId) {
    return DietPlanDay(dayOfWeek: dayOfWeek, mealIds: [...mealIds, mealId]);
  }

  DietPlanDay removeMealId(String mealId) {
    return DietPlanDay(dayOfWeek: dayOfWeek, mealIds: mealIds.where((id) => id != mealId).toList());
  }
}
