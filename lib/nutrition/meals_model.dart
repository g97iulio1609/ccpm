import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  String? id;
  String userId;
  DateTime date;
  String mealType; // Breakfast, Lunch, Dinner, Snack
  List<String> foodIds; // IDs of the foods in this meal
  double totalCalories;
  double totalCarbs;
  double totalFat;
  double totalProtein;

  Meal({
    this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.foodIds,
    this.totalCalories = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalProtein = 0,
  });

  factory Meal.fromJson(String source) => Meal.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      userId: map['userId'],
      date: (map['date'] as Timestamp).toDate(),
      mealType: map['mealType'],
      foodIds: List<String>.from(map['foodIds']),
      totalCalories: map['totalCalories']?.toDouble() ?? 0.0,
      totalCarbs: map['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: map['totalFat']?.toDouble() ?? 0.0,
      totalProtein: map['totalProtein']?.toDouble() ?? 0.0,
    );
  }

  factory Meal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Meal(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      mealType: data['mealType'],
      foodIds: List<String>.from(data['foodIds']),
      totalCalories: data['totalCalories']?.toDouble() ?? 0.0,
      totalCarbs: data['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: data['totalFat']?.toDouble() ?? 0.0,
      totalProtein: data['totalProtein']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'mealType': mealType,
      'foodIds': foodIds,
      'totalCalories': totalCalories,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalProtein': totalProtein,
    };
  }

  static Meal emptyMeal(String userId, DateTime date, String mealType) {
    return Meal(
      userId: userId,
      date: date,
      mealType: mealType,
      foodIds: [],
    );
  }
}
