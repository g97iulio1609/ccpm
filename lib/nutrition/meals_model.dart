import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  String? id;
  String userId;
  String dailyStatsId;
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
    required this.dailyStatsId,
    required this.date,
    required this.mealType,
    required this.foodIds,
    this.totalCalories = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalProtein = 0,
  });

  Meal copyWith({
    String? id,
    String? userId,
    String? dailyStatsId,
    DateTime? date,
    String? mealType,
    List<String>? foodIds,
    double? totalCalories,
    double? totalCarbs,
    double? totalFat,
    double? totalProtein,
  }) {
    return Meal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyStatsId: dailyStatsId ?? this.dailyStatsId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foodIds: foodIds ?? this.foodIds,
      totalCalories: totalCalories ?? this.totalCalories,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      totalProtein: totalProtein ?? this.totalProtein,
    );
  }

  factory Meal.fromJson(String source) => Meal.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      userId: map['userId'],
      dailyStatsId: map['dailyStatsId'],
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
      dailyStatsId: data['dailyStatsId'],
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
      'dailyStatsId': dailyStatsId,
      'date': Timestamp.fromDate(date),
      'mealType': mealType,
      'foodIds': foodIds,
      'totalCalories': totalCalories,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalProtein': totalProtein,
    };
  }

  static Meal emptyMeal(String userId, String dailyStatsId, DateTime date, String mealType) {
    return Meal(
      userId: userId,
      dailyStatsId: dailyStatsId,
      date: date,
      mealType: mealType,
      foodIds: [],
    );
  }
}

class DailyStats {
  String? id;
  String userId;
  DateTime date;
  double totalCalories;
  double totalCarbs;
  double totalFat;
  double totalProtein;

  DailyStats({
    this.id,
    required this.userId,
    required this.date,
    this.totalCalories = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalProtein = 0,
  });

  factory DailyStats.fromJson(String source) => DailyStats.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      id: map['id'],
      userId: map['userId'],
      date: (map['date'] as Timestamp).toDate(),
      totalCalories: map['totalCalories']?.toDouble() ?? 0.0,
      totalCarbs: map['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: map['totalFat']?.toDouble() ?? 0.0,
      totalProtein: map['totalProtein']?.toDouble() ?? 0.0,
    );
  }

  factory DailyStats.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DailyStats(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
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
      'totalCalories': totalCalories,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalProtein': totalProtein,
    };
  }
}

class Food {
  String? id;
  String name;
  double kcal;
  double carbs;
  double fat;
  double protein;
  double quantity;
  String portion;

  Food({
    this.id,
    required this.name,
    required this.kcal,
    required this.carbs,
    required this.fat,
    required this.protein,
    this.quantity = 100,
    this.portion = 'g',
  });

  factory Food.fromJson(String source) => Food.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      kcal: map['kcal']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toDouble() ?? 100,
      portion: map['portion'] ?? 'g',
    );
  }

  factory Food.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Food(
      id: doc.id,
      name: data['name'],
      kcal: data['kcal']?.toDouble() ?? 0.0,
      carbs: data['carbs']?.toDouble() ?? 0.0,
      fat: data['fat']?.toDouble() ?? 0.0,
      protein: data['protein']?.toDouble() ?? 0.0,
      quantity: data['quantity']?.toDouble() ?? 100,
      portion: data['portion'] ?? 'g',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'kcal': kcal,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
      'quantity': quantity,
      'portion': portion,
    };
  }
}

class MyFood {
  String? id;
  String mealId;
  String foodId;
  double kcal;
  double carbs;
  double fat;
  double protein;
  double quantity;
  String portion;

  MyFood({
    this.id,
    required this.mealId,
    required this.foodId,
    required this.kcal,
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.quantity,
    required this.portion,
  });

  factory MyFood.fromJson(String source) => MyFood.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory MyFood.fromMap(Map<String, dynamic> map) {
    return MyFood(
      id: map['id'],
      mealId: map['mealId'],
      foodId: map['foodId'],
      kcal: map['kcal']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toDouble() ?? 100,
      portion: map['portion'] ?? 'g',
    );
  }

  factory MyFood.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MyFood(
      id: doc.id,
      mealId: data['mealId'],
      foodId: data['foodId'],
      kcal: data['kcal']?.toDouble() ?? 0.0,
      carbs: data['carbs']?.toDouble() ?? 0.0,
      fat: data['fat']?.toDouble() ?? 0.0,
      protein: data['protein']?.toDouble() ?? 0.0,
      quantity: data['quantity']?.toDouble() ?? 100,
      portion: data['portion'] ?? 'g',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealId': mealId,
      'foodId': foodId,
      'kcal': kcal,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
      'quantity': quantity,
      'portion': portion,
    };
  }
}
