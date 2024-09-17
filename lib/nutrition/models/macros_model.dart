import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  String? id;
  String? mealId;
  String name;
  String? brands;
  double carbs;
  double fat;
  double protein;
  double kcal;
  double? quantity;
  String quantityUnit;
  String? portion;
  double sugar;
  double fiber;
  double saturatedFat;
  double polyunsaturatedFat;
  double monounsaturatedFat;
  double transFat;
  double cholesterol;
  double sodium;
  double potassium;
  double vitaminA;
  double vitaminC;
  double calcium;
  double iron;

  Food({
    this.id,
    this.brands,
    this.mealId,
    required this.name,
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.kcal,
    this.quantity,
    this.quantityUnit = 'g',
    this.portion,
    this.sugar = 0.0,
    this.fiber = 0.0,
    this.saturatedFat = 0.0,
    this.polyunsaturatedFat = 0.0,
    this.monounsaturatedFat = 0.0,
    this.transFat = 0.0,
    this.cholesterol = 0.0,
    this.sodium = 0.0,
    this.potassium = 0.0,
    this.vitaminA = 0.0,
    this.vitaminC = 0.0,
    this.calcium = 0.0,
    this.iron = 0.0,
  });

  factory Food.fromJson(String source) => Food.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  Food copyWith({
    String? id,
    String? brands,
    String? name,
    double? carbs,
    double? fat,
    double? protein,
    double? kcal,
    double? quantity,
    String? quantityUnit,
    String? portion,
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
    required String mealId,
  }) {
    return Food(
      id: id ?? this.id,
      mealId: mealId,
      name: name ?? this.name,
      brands: brands ?? this.brands,
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
            mealId: map['mealId'],

      name: map['name'],
      brands: map['brands'],
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      kcal: map['kcal']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toDouble() ?? 0.0,
      quantityUnit: map['quantityUnit'] ?? 'g',
      portion: map['portion'] ?? 'g',
      sugar: map['sugar']?.toDouble() ?? 0.0,
      fiber: map['fiber']?.toDouble() ?? 0.0,
      saturatedFat: map['saturatedFat']?.toDouble() ?? 0.0,
      polyunsaturatedFat: map['polyunsaturatedFat']?.toDouble() ?? 0.0,
      monounsaturatedFat: map['monounsaturatedFat']?.toDouble() ?? 0.0,
      transFat: map['transFat']?.toDouble() ?? 0.0,
      cholesterol: map['cholesterol']?.toDouble() ?? 0.0,
      sodium: map['sodium']?.toDouble() ?? 0.0,
      potassium: map['potassium']?.toDouble() ?? 0.0,
      vitaminA: map['vitaminA']?.toDouble() ?? 0.0,
      vitaminC: map['vitaminC']?.toDouble() ?? 0.0,
      calcium: map['calcium']?.toDouble() ?? 0.0,
      iron: map['iron']?.toDouble() ?? 0.0,
    );
  }

  factory Food.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Food(
      id: doc.id,
            mealId: data['mealId'],

      name: data['name'],
      brands: data['brands'],
      carbs: data['carbs']?.toDouble() ?? 0.0,
      fat: data['fat']?.toDouble() ?? 0.0,
      protein: data['protein']?.toDouble() ?? 0.0,
      kcal: data['kcal']?.toDouble() ?? 0.0,
      quantity: data['quantity']?.toDouble() ?? 0.0,
      quantityUnit: data['quantityUnit'] ?? 'g',
      portion: data['portion'] ?? 'g',
      sugar: data['sugar']?.toDouble() ?? 0.0,
      fiber: data['fiber']?.toDouble() ?? 0.0,
      saturatedFat: data['saturatedFat']?.toDouble() ?? 0.0,
      polyunsaturatedFat: data['polyunsaturatedFat']?.toDouble() ?? 0.0,
      monounsaturatedFat: data['monounsaturatedFat']?.toDouble() ?? 0.0,
      transFat: data['transFat']?.toDouble() ?? 0.0,
      cholesterol: data['cholesterol']?.toDouble() ?? 0.0,
      sodium: data['sodium']?.toDouble() ?? 0.0,
      potassium: data['potassium']?.toDouble() ?? 0.0,
      vitaminA: data['vitaminA']?.toDouble() ?? 0.0,
      vitaminC: data['vitaminC']?.toDouble() ?? 0.0,
      calcium: data['calcium']?.toDouble() ?? 0.0,
      iron: data['iron']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealId':mealId,
      'name': name,
      'brands': brands,
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
