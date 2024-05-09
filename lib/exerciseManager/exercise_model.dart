import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseModel {
  final String id;
  final String name;
  final String muscleGroup;
  final String type;
  final String status; // Nuovo campo
  final String userId;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.type,
    this.status = 'pending', // Valore di default per nuovi esercizi
    this.userId='userId'
  });

  // Modifica il metodo factory per includere il nuovo campo
  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseModel(
      id: doc.id,
      name: data['name'] ?? '',
      muscleGroup: data['muscleGroup'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'pending', // Valore di default se non presente
      userId: data['userId']?? ''
    );
  }
}