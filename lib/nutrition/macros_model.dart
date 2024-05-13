import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  String? id;
  String name;
  double carbs;
  double fat;
  double protein;
  double kcal;
  double quantity;
  String quantityUnit;
  double portion;
  double? sugar;
  double? fiber;
  double? saturatedFat;
  double? polyunsaturatedFat;
  double? monounsaturatedFat;
  double? transFat;
  double? cholesterol;
  double? sodium;
  double? potassium;
  double? vitaminA;
  double? vitaminC;
  double? calcium;
  double? iron;

  Food({
    this.id,
    required this.name,
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.kcal,
    required this.quantity,
    this.quantityUnit = 'g',
    required this.portion,
    this.sugar,
    this.fiber,
    this.saturatedFat,
    this.polyunsaturatedFat,
    this.monounsaturatedFat,
    this.transFat,
    this.cholesterol,
    this.sodium,
    this.potassium,
    this.vitaminA,
    this.vitaminC,
    this.calcium,
    this.iron,
  });

  factory Food.fromJson(String source) => Food.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  Food copyWith({
    String? id,
    String? name,
    double? carbs,
    double? fat,
    double? protein,
    double? kcal,
    double? quantity,
    String? quantityUnit,
    double? portion,
    double? sugar,
    double? fiber,
    double? saturatedFat,
    double? polyunsaturatedFat,
    double? monounsaturatedFat,
    double? transFat,
    double? cholesterol,
    double? sodium,
    double? potassium,
    double? vitaminA,
    double? vitaminC,
    double? calcium,
    double? iron,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      protein: protein ?? this.protein,
      kcal: kcal ?? this.kcal,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      portion: portion ?? this.portion,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      polyunsaturatedFat: polyunsaturatedFat ?? this.polyunsaturatedFat,
      monounsaturatedFat: monounsaturatedFat ?? this.monounsaturatedFat,
      transFat: transFat ?? this.transFat,
      cholesterol: cholesterol ?? this.cholesterol,
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
      vitaminA: vitaminA ?? this.vitaminA,
      vitaminC: vitaminC ?? this.vitaminC,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
    );
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      kcal: map['kcal']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toDouble() ?? 0.0,
      quantityUnit: map['quantityUnit'] ?? 'g',
      portion: map['portion']?.toDouble() ?? 0.0,
      sugar: map['sugar']?.toDouble(),
      fiber: map['fiber']?.toDouble(),
      saturatedFat: map['saturatedFat']?.toDouble(),
      polyunsaturatedFat: map['polyunsaturatedFat']?.toDouble(),
      monounsaturatedFat: map['monounsaturatedFat']?.toDouble(),
      transFat: map['transFat']?.toDouble(),
      cholesterol: map['cholesterol']?.toDouble(),
      sodium: map['sodium']?.toDouble(),
      potassium: map['potassium']?.toDouble(),
      vitaminA: map['vitaminA']?.toDouble(),
      vitaminC: map['vitaminC']?.toDouble(),
      calcium: map['calcium']?.toDouble(),
      iron: map['iron']?.toDouble(),
    );
  }

  factory Food.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Food(
      id: doc.id,
      name: data['name'],
      carbs: data['carbs']?.toDouble() ?? 0.0,
      fat: data['fat']?.toDouble() ?? 0.0,
      protein: data['protein']?.toDouble() ?? 0.0,
      kcal: data['kcal']?.toDouble() ?? 0.0,
      quantity: data['quantity']?.toDouble() ?? 0.0,
      quantityUnit: data['quantityUnit'] ?? 'g',
      portion: data['portion']?.toDouble() ?? 0.0,
      sugar: data['sugar']?.toDouble(),
      fiber: data['fiber']?.toDouble(),
      saturatedFat: data['saturatedFat']?.toDouble(),
      polyunsaturatedFat: data['polyunsaturatedFat']?.toDouble(),
      monounsaturatedFat: data['monounsaturatedFat']?.toDouble(),
      transFat: data['transFat']?.toDouble(),
      cholesterol: data['cholesterol']?.toDouble(),
      sodium: data['sodium']?.toDouble(),
      potassium: data['potassium']?.toDouble(),
      vitaminA: data['vitaminA']?.toDouble(),
      vitaminC: data['vitaminC']?.toDouble(),
      calcium: data['calcium']?.toDouble(),
      iron: data['iron']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
      'kcal': kcal,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'portion': portion,
      'sugar': sugar,
      'fiber': fiber,
      'saturatedFat': saturatedFat,
      'polyunsaturatedFat': polyunsaturatedFat,
      'monounsaturatedFat': monounsaturatedFat,
      'transFat': transFat,
      'cholesterol': cholesterol,
      'sodium': sodium,
      'potassium': potassium,
      'vitaminA': vitaminA,
      'vitaminC': vitaminC,
      'calcium': calcium,
      'iron': iron,
    };
  }
}