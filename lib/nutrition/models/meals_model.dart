import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  String? id;
  String userId;
  String dailyStatsId;
  DateTime date;
  String mealType; // Breakfast, Lunch, Dinner, Snack
  double totalCalories;
  double totalCarbs;
  double totalFat;
  double totalProtein;
  bool isFavorite; // Aggiunto
  String? favoriteName; // Aggiunto

  Meal({
    this.id,
    required this.userId,
    required this.dailyStatsId,
    required this.date,
    required this.mealType,
    this.totalCalories = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalProtein = 0,
    this.isFavorite = false, // Aggiunto
    this.favoriteName, // Aggiunto
  });

  Meal copyWith({
    String? id,
    String? dailyStatsId,
    String? userId,
    DateTime? date,
    String? mealType,
    double? totalCalories,
    double? totalCarbs,
    double? totalFat,
    double? totalProtein,
    bool? isFavorite, // Aggiunto
    String? favoriteName, // Aggiunto
  }) {
    return Meal(
      id: id ?? this.id,
      dailyStatsId: dailyStatsId ?? this.dailyStatsId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      totalCalories: totalCalories ?? this.totalCalories,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      totalProtein: totalProtein ?? this.totalProtein,
      isFavorite: isFavorite ?? this.isFavorite, // Aggiunto
      favoriteName: favoriteName ?? this.favoriteName, // Aggiunto
    );
  }

  factory Meal.fromJson(String source) => Meal.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory Meal.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.parse(date);
      } else {
        throw FormatException('Invalid date format: $date');
      }
    }

    return Meal(
      id: map['id'],
      userId: map['userId'],
      dailyStatsId: map['dailyStatsId'],
      date: parseDate(map['date']),
      mealType: map['mealType'],
      totalCalories: map['totalCalories']?.toDouble() ?? 0.0,
      totalCarbs: map['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: map['totalFat']?.toDouble() ?? 0.0,
      totalProtein: map['totalProtein']?.toDouble() ?? 0.0,
      isFavorite: map['isFavorite'] ?? false,
      favoriteName: map['favoriteName'],
    );
  }

  factory Meal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.parse(date);
      } else {
        throw FormatException('Invalid date format: $date');
      }
    }

    return Meal(
      id: doc.id,
      userId: data['userId'],
      dailyStatsId: data['dailyStatsId'],
      date: parseDate(data['date']),
      mealType: data['mealType'],
      totalCalories: data['totalCalories']?.toDouble() ?? 0.0,
      totalCarbs: data['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: data['totalFat']?.toDouble() ?? 0.0,
      totalProtein: data['totalProtein']?.toDouble() ?? 0.0,
      isFavorite: data['isFavorite'] ?? false,
      favoriteName: data['favoriteName'],
    );
  }

  Null get carbs => null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'dailyStatsId': dailyStatsId,
      'date': Timestamp.fromDate(date),
      'mealType': mealType,
      'totalCalories': totalCalories,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalProtein': totalProtein,
      'isFavorite': isFavorite,
      'favoriteName': favoriteName,
    };
  }

  static Meal emptyMeal(
    String userId,
    String dailyStatsId,
    DateTime date,
    String mealType,
  ) {
    return Meal(
      userId: userId,
      dailyStatsId: dailyStatsId,
      date: date,
      mealType: mealType,
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

  factory DailyStats.fromJson(String source) =>
      DailyStats.fromMap(json.decode(source));

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
  String mealId;
  String name;
  double kcal;
  double carbs;
  double fat;
  double protein;
  double quantity;
  String portion;

  Food({
    this.id,
    required this.mealId,
    required this.name,
    required this.kcal,
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.quantity,
    required this.portion,
  });

  factory Food.fromJson(String source) => Food.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      mealId: map['mealId'],
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
      mealId: data['mealId'],
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
      'mealId': mealId,
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

class FavoriteDay {
  String? id;
  String userId;
  DateTime date;
  String favoriteName;

  FavoriteDay({
    this.id,
    required this.userId,
    required this.date,
    required this.favoriteName,
  });

  factory FavoriteDay.fromJson(String source) =>
      FavoriteDay.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory FavoriteDay.fromMap(Map<String, dynamic> map) {
    return FavoriteDay(
      id: map['id'],
      userId: map['userId'],
      date: (map['date'] as Timestamp).toDate(),
      favoriteName: map['favoriteName'],
    );
  }

  factory FavoriteDay.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FavoriteDay(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      favoriteName: data['favoriteName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'favoriteName': favoriteName,
    };
  }
}
