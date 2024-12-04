class NutritionStats {
  final double dailyCalories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime date;

  NutritionStats({
    required this.dailyCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
  });

  factory NutritionStats.fromMap(Map<String, dynamic> map) {
    return NutritionStats(
      dailyCalories: (map['dailyCalories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyCalories': dailyCalories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'date': date.toIso8601String(),
    };
  }
}
